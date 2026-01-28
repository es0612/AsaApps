import Foundation

// MARK: - HistoryManager
/// Undo/Redo履歴を管理するジェネリッククラス
/// 任意の型の状態を保存し、元に戻す/やり直しを提供
@Observable
final class HistoryManager<State: Equatable & Codable> {
    // MARK: - Properties

    /// 履歴スタック
    private var undoStack: [State] = []

    /// やり直しスタック
    private var redoStack: [State] = []

    /// 最大履歴数
    let maxHistoryCount: Int

    /// 元に戻せるかどうか
    var canUndo: Bool {
        !undoStack.isEmpty
    }

    /// やり直せるかどうか
    var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// 現在の履歴数
    var historyCount: Int {
        undoStack.count
    }

    // MARK: - Initializer

    init(maxHistoryCount: Int = 20) {
        self.maxHistoryCount = maxHistoryCount
    }

    // MARK: - Public Methods

    /// 状態を記録（新しいアクションの前に呼び出す）
    func record(_ state: State) {
        // 同じ状態なら記録しない
        if undoStack.last == state { return }

        undoStack.append(state)

        // 最大履歴数を超えたら古いものを削除
        if undoStack.count > maxHistoryCount {
            undoStack.removeFirst()
        }

        // 新しいアクションを記録したらredoスタックをクリア
        redoStack.removeAll()
    }

    /// 元に戻す
    func undo(currentState: State) -> State? {
        guard let previousState = undoStack.popLast() else { return nil }

        // 現在の状態をredoスタックに保存
        redoStack.append(currentState)

        return previousState
    }

    /// やり直す
    func redo(currentState: State) -> State? {
        guard let nextState = redoStack.popLast() else { return nil }

        // 現在の状態をundoスタックに保存
        undoStack.append(currentState)

        return nextState
    }

    /// 履歴をクリア
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    /// 履歴をリセットして初期状態を設定
    func reset(with initialState: State) {
        clear()
        undoStack.append(initialState)
    }
}

// MARK: - EditState
/// 編集状態を表す構造体（履歴管理用）
struct EditState: Codable, Equatable {
    var adjustment: ImageAdjustment
    var filterSettings: FilterSettings
    var cropSettings: CropSettings
    var textLayers: [TextLayer]
    var drawingLayers: [DrawingLayer]

    static let `default` = EditState(
        adjustment: .default,
        filterSettings: .default,
        cropSettings: .default,
        textLayers: [],
        drawingLayers: []
    )

    var isDefault: Bool {
        adjustment.isDefault &&
        filterSettings.isDefault &&
        cropSettings.isDefault &&
        textLayers.isEmpty &&
        drawingLayers.isEmpty
    }
}

// MARK: - EditHistoryManager
/// 編集履歴専用のマネージャー
typealias EditHistoryManager = HistoryManager<EditState>

extension EditHistoryManager {
    /// 現在の編集状態から EditState を作成
    static func createEditState(
        adjustment: ImageAdjustment,
        filterSettings: FilterSettings,
        cropSettings: CropSettings,
        textLayers: [TextLayer],
        drawingLayers: [DrawingLayer]
    ) -> EditState {
        EditState(
            adjustment: adjustment,
            filterSettings: filterSettings,
            cropSettings: cropSettings,
            textLayers: textLayers,
            drawingLayers: drawingLayers
        )
    }
}
