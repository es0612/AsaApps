import Foundation
import SwiftUI
import PhotosUI
import SwiftData

// MARK: - EditorMode
/// エディターモードの列挙型
enum EditorMode: String, CaseIterable, Identifiable {
    case adjustment = "調整"
    case filter = "フィルター"
    case crop = "クロップ"
    case text = "テキスト"
    case drawing = "描画"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .adjustment: return "slider.horizontal.3"
        case .filter: return "camera.filters"
        case .crop: return "crop"
        case .text: return "textformat"
        case .drawing: return "pencil.tip.crop.circle"
        }
    }
}

// MARK: - PhotoEditorViewModel
/// 写真編集のメインViewModel
@MainActor
@Observable
final class PhotoEditorViewModel {
    // MARK: - Properties

    /// 選択された写真
    var selectedPhotoItem: PhotosPickerItem?

    /// オリジナル画像
    var originalImage: UIImage?

    /// プレビュー画像（編集結果）
    var previewImage: UIImage?

    /// 現在のエディターモード
    var currentMode: EditorMode = .adjustment

    /// 処理中フラグ
    var isProcessing: Bool = false

    /// エラーメッセージ
    var errorMessage: String?

    /// アラート表示フラグ
    var showingAlert: Bool = false

    /// 保存成功フラグ
    var showingSaveSuccess: Bool = false

    /// プロジェクト一覧表示フラグ
    var showingProjectList: Bool = false

    /// エクスポートシート表示フラグ
    var showingExportSheet: Bool = false

    /// 設定シート表示フラグ
    var showingSettings: Bool = false

    // MARK: - Edit Parameters

    /// 画像調整パラメータ
    var adjustment: ImageAdjustment = .default

    /// フィルター設定
    var filterSettings: FilterSettings = .default

    /// クロップ設定
    var cropSettings: CropSettings = .default

    /// テキストレイヤー
    var textLayers: [TextLayer] = []

    /// 描画レイヤー
    var drawingLayers: [DrawingLayer] = []

    /// 選択中のテキストレイヤーID
    var selectedTextLayerID: UUID?

    /// 選択中の描画レイヤーID
    var selectedDrawingLayerID: UUID?

    // MARK: - Drawing State

    /// 現在の描画ツール
    var currentDrawingTool: DrawingTool = .pen

    /// 描画カラー
    var drawingColor: Color = .asaCoffeeBrown

    /// 描画線幅
    var drawingLineWidth: CGFloat = 3.0

    /// 現在描画中のストローク
    var currentStroke: DrawingStroke?

    // MARK: - Services

    private let imageProcessor = ImageProcessingService()
    private let layerCompositor = LayerCompositorService()
    private let exportService = ExportService()

    /// 履歴マネージャー
    let historyManager = EditHistoryManager(maxHistoryCount: 20)

    /// プレビュー更新タスクの参照（デバウンス＋キャンセル用）
    private var previewUpdateTask: Task<Void, Never>?

    /// 現在のプロジェクト
    var currentProject: EditProject?

    // MARK: - Computed Properties

    /// 編集が行われているかどうか
    var hasEdits: Bool {
        !adjustment.isDefault ||
        !filterSettings.isDefault ||
        !cropSettings.isDefault ||
        !textLayers.isEmpty ||
        !drawingLayers.isEmpty
    }

    /// 元に戻せるかどうか
    var canUndo: Bool {
        historyManager.canUndo
    }

    /// やり直せるかどうか
    var canRedo: Bool {
        historyManager.canRedo
    }

    /// 選択中の描画レイヤー
    var selectedDrawingLayer: DrawingLayer? {
        guard let id = selectedDrawingLayerID else { return nil }
        return drawingLayers.first { $0.id == id }
    }

    // MARK: - Initializer

    init() {
        // 初期描画レイヤーを追加
        let initialLayer = DrawingLayer(name: "レイヤー1")
        drawingLayers.append(initialLayer)
        selectedDrawingLayerID = initialLayer.id
    }

    // MARK: - Photo Loading

    /// 写真を読み込む
    func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }

        isProcessing = true

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                originalImage = image
                previewImage = image
                resetAllEdits()
                recordHistory()
            }
        } catch {
            errorMessage = "画像の読み込みに失敗しました"
            showingAlert = true
        }

        isProcessing = false
    }

    // MARK: - Preview Update

    /// プレビューを更新
    func updatePreview() async {
        guard let original = originalImage else { return }
        guard !Task.isCancelled else { return }

        isProcessing = true

        // プレビュー用にダウンサンプリング（フル解像度→最大1200px幅）
        let previewSource = await imageProcessor.resizeForPreview(
            original,
            targetSize: CGSize(width: 1200, height: 1200)
        )

        guard !Task.isCancelled else {
            isProcessing = false
            return
        }

        // CIImage統合パイプラインで基本編集を適用（GPU同期1回のみ）
        var result = await imageProcessor.applyAllEditsCombined(
            to: previewSource,
            adjustment: adjustment,
            filterSettings: filterSettings,
            cropSettings: cropSettings
        ) ?? previewSource

        guard !Task.isCancelled else {
            isProcessing = false
            return
        }

        // レイヤーを合成
        if !drawingLayers.isEmpty || !textLayers.isEmpty {
            result = await layerCompositor.compositeAllLayers(
                baseImage: result,
                drawingLayers: drawingLayers,
                textLayers: textLayers
            )
        }

        guard !Task.isCancelled else {
            isProcessing = false
            return
        }

        previewImage = result
        isProcessing = false
    }

    /// プレビューを非同期で更新（デバウンス＋前タスクキャンセル）
    func schedulePreviewUpdate() {
        // 前回のタスクをキャンセル
        previewUpdateTask?.cancel()

        previewUpdateTask = Task {
            // デバウンス: 150ms待機（スライダー連続操作中は実行しない）
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await updatePreview()
        }
    }

    // MARK: - History Management

    /// 履歴を記録
    func recordHistory() {
        let state = EditState(
            adjustment: adjustment,
            filterSettings: filterSettings,
            cropSettings: cropSettings,
            textLayers: textLayers,
            drawingLayers: drawingLayers
        )
        historyManager.record(state)
    }

    /// 元に戻す
    func undo() {
        let currentState = EditState(
            adjustment: adjustment,
            filterSettings: filterSettings,
            cropSettings: cropSettings,
            textLayers: textLayers,
            drawingLayers: drawingLayers
        )

        if let previousState = historyManager.undo(currentState: currentState) {
            applyState(previousState)
            schedulePreviewUpdate()
        }
    }

    /// やり直す
    func redo() {
        let currentState = EditState(
            adjustment: adjustment,
            filterSettings: filterSettings,
            cropSettings: cropSettings,
            textLayers: textLayers,
            drawingLayers: drawingLayers
        )

        if let nextState = historyManager.redo(currentState: currentState) {
            applyState(nextState)
            schedulePreviewUpdate()
        }
    }

    private func applyState(_ state: EditState) {
        adjustment = state.adjustment
        filterSettings = state.filterSettings
        cropSettings = state.cropSettings
        textLayers = state.textLayers
        drawingLayers = state.drawingLayers
    }

    // MARK: - Edit Operations

    /// すべての編集をリセット
    func resetAllEdits() {
        adjustment = .default
        filterSettings = .default
        cropSettings = .default
        textLayers = []
        drawingLayers = [DrawingLayer(name: "レイヤー1")]
        selectedDrawingLayerID = drawingLayers.first?.id
        historyManager.clear()
        schedulePreviewUpdate()
    }

    /// 調整をリセット
    func resetAdjustment() {
        recordHistory()
        adjustment = .default
        schedulePreviewUpdate()
    }

    /// フィルターをリセット
    func resetFilter() {
        recordHistory()
        filterSettings = .default
        schedulePreviewUpdate()
    }

    /// クロップをリセット
    func resetCrop() {
        recordHistory()
        cropSettings = .default
        schedulePreviewUpdate()
    }

    // MARK: - Text Layer Operations

    /// テキストレイヤーを追加
    func addTextLayer() {
        recordHistory()
        let newLayer = TextLayer()
        textLayers.append(newLayer)
        selectedTextLayerID = newLayer.id
        schedulePreviewUpdate()
    }

    /// テキストレイヤーを削除
    func deleteTextLayer(_ id: UUID) {
        recordHistory()
        textLayers.removeAll { $0.id == id }
        if selectedTextLayerID == id {
            selectedTextLayerID = textLayers.first?.id
        }
        schedulePreviewUpdate()
    }

    /// テキストレイヤーを更新
    func updateTextLayer(_ layer: TextLayer) {
        if let index = textLayers.firstIndex(where: { $0.id == layer.id }) {
            textLayers[index] = layer
            schedulePreviewUpdate()
        }
    }

    // MARK: - Drawing Operations

    /// 描画レイヤーを追加
    func addDrawingLayer() {
        guard drawingLayers.count < 10 else { return }
        recordHistory()
        let newLayer = DrawingLayer(name: "レイヤー\(drawingLayers.count + 1)")
        drawingLayers.insert(newLayer, at: 0)
        selectedDrawingLayerID = newLayer.id
    }

    /// 描画レイヤーを削除
    func deleteDrawingLayer(_ id: UUID) {
        guard drawingLayers.count > 1 else { return }
        recordHistory()
        drawingLayers.removeAll { $0.id == id }
        if selectedDrawingLayerID == id {
            selectedDrawingLayerID = drawingLayers.first?.id
        }
        schedulePreviewUpdate()
    }

    /// 描画を開始
    func startDrawing(at point: CGPoint) {
        guard let layerID = selectedDrawingLayerID,
              let index = drawingLayers.firstIndex(where: { $0.id == layerID }),
              !drawingLayers[index].isLocked else { return }

        currentStroke = DrawingStroke(
            points: [point],
            colorHex: drawingColor.toHex() ?? "#C68C53",
            lineWidth: drawingLineWidth,
            tool: currentDrawingTool,
            opacity: currentDrawingTool.defaultOpacity
        )
    }

    /// 描画ポイントを追加
    func addDrawingPoint(_ point: CGPoint) {
        currentStroke?.addPoint(point)
    }

    /// 描画を終了
    func finishDrawing() {
        guard let stroke = currentStroke,
              let layerID = selectedDrawingLayerID,
              let index = drawingLayers.firstIndex(where: { $0.id == layerID }),
              !stroke.isEmpty else {
            currentStroke = nil
            return
        }

        recordHistory()
        drawingLayers[index].addStroke(stroke)
        currentStroke = nil
        schedulePreviewUpdate()
    }

    /// 描画を1ステップ戻す
    func undoDrawing() {
        guard let layerID = selectedDrawingLayerID,
              let index = drawingLayers.firstIndex(where: { $0.id == layerID }) else { return }

        recordHistory()
        drawingLayers[index].removeLastStroke()
        schedulePreviewUpdate()
    }

    /// 描画レイヤーをクリア
    func clearDrawingLayer() {
        guard let layerID = selectedDrawingLayerID,
              let index = drawingLayers.firstIndex(where: { $0.id == layerID }) else { return }

        recordHistory()
        drawingLayers[index].clear()
        schedulePreviewUpdate()
    }

    // MARK: - Export Operations

    /// エクスポート用にフル解像度で編集を適用
    private func renderFullResolution() async -> UIImage? {
        guard let original = originalImage else { return nil }

        // フル解像度で統合パイプラインを実行
        var result = await imageProcessor.applyAllEditsCombined(
            to: original,
            adjustment: adjustment,
            filterSettings: filterSettings,
            cropSettings: cropSettings
        ) ?? original

        // レイヤーを合成
        if !drawingLayers.isEmpty || !textLayers.isEmpty {
            result = await layerCompositor.compositeAllLayers(
                baseImage: result,
                drawingLayers: drawingLayers,
                textLayers: textLayers
            )
        }

        return result
    }

    /// 写真ライブラリに保存
    func saveToPhotoLibrary() async {
        isProcessing = true

        guard let image = await renderFullResolution() else {
            isProcessing = false
            return
        }

        do {
            try await exportService.saveToPhotoLibrary(image: image)
            showingSaveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingAlert = true
        }

        isProcessing = false
    }

    /// 指定解像度でエクスポート
    func exportImage(
        resolution: ExportService.ExportResolution,
        format: ExportService.ExportFormat
    ) async -> ExportService.ExportResult? {
        guard let image = await renderFullResolution() else { return nil }
        return await exportService.export(image: image, resolution: resolution, format: format)
    }

    // MARK: - Project Operations

    /// プロジェクトを保存
    func saveProject(to context: ModelContext) {
        guard let image = originalImage else { return }

        if let project = currentProject {
            // 既存プロジェクトを更新
            project.adjustment = adjustment
            project.filterSettings = filterSettings
            project.cropSettings = cropSettings
            project.textLayers = textLayers
            project.drawingLayers = drawingLayers

            if let preview = previewImage {
                project.thumbnailData = createThumbnail(from: preview)?.jpegData(compressionQuality: 0.7)
            }
        } else {
            // 新規プロジェクトを作成
            let project = EditProject(
                name: "プロジェクト \(Date().formatted(date: .abbreviated, time: .shortened))",
                originalImageData: image.jpegData(compressionQuality: 0.9)
            )
            project.adjustment = adjustment
            project.filterSettings = filterSettings
            project.cropSettings = cropSettings
            project.textLayers = textLayers
            project.drawingLayers = drawingLayers

            if let preview = previewImage {
                project.thumbnailData = createThumbnail(from: preview)?.jpegData(compressionQuality: 0.7)
            }

            context.insert(project)
            currentProject = project
        }

        do {
            try context.save()
            showingSaveSuccess = true
        } catch {
            errorMessage = "プロジェクトの保存に失敗しました"
            showingAlert = true
        }
    }

    /// プロジェクトを読み込む
    func loadProject(_ project: EditProject) {
        currentProject = project

        if let data = project.originalImageData,
           let image = UIImage(data: data) {
            originalImage = image
        }

        adjustment = project.adjustment
        filterSettings = project.filterSettings
        cropSettings = project.cropSettings
        textLayers = project.textLayers
        drawingLayers = project.drawingLayers.isEmpty
            ? [DrawingLayer(name: "レイヤー1")]
            : project.drawingLayers
        selectedDrawingLayerID = drawingLayers.first?.id

        historyManager.clear()
        schedulePreviewUpdate()
    }

    // MARK: - Private Methods

    private func createThumbnail(from image: UIImage, maxSize: CGFloat = 200) -> UIImage? {
        let size = image.size
        let scale = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Color Extension
extension Color {
    static let asaCoffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325)
    static let asaMocha = Color(red: 0.545, green: 0.353, blue: 0.169)
    static let asaSoftCream = Color(red: 0.910, green: 0.835, blue: 0.725)
    static let asaDarkSlate = Color(red: 0.184, green: 0.243, blue: 0.275)
    static let asaMutedSage = Color(red: 0.478, green: 0.569, blue: 0.553)
}
