#if os(iOS)
import Foundation

// MARK: - ExportViewModel

/// エクスポート画面のViewModel
/// 動画/画像/PDFエクスポートの進捗管理
@MainActor
@Observable
public final class ExportViewModel {
    // MARK: - Properties

    public var story: PhotoStory
    public var settings: ExportSettings = .default
    public var exportProgress: Double = 0
    public var isExporting: Bool = false
    public var exportedURL: URL?
    public var exportedData: Data?
    public var errorMessage: String?

    private let exportService: SlideshowExportService

    // MARK: - Init

    public init(story: PhotoStory, exportService: SlideshowExportService = SlideshowExportService()) {
        self.story = story
        self.exportService = exportService
    }

    // MARK: - エクスポート操作

    /// 動画としてエクスポート
    public func exportAsVideo() async {
        isExporting = true
        exportProgress = 0
        exportedURL = nil
        errorMessage = nil

        do {
            let url = try await exportService.exportAsVideo(
                pages: story.sortedPages,
                settings: settings,
                progress: { [weak self] progress in
                    Task { @MainActor in
                        self?.exportProgress = progress
                    }
                }
            )
            exportedURL = url
        } catch {
            errorMessage = "動画エクスポートに失敗: \(error.localizedDescription)"
        }

        isExporting = false
    }

    /// 画像としてエクスポート
    public func exportAsImages() async {
        isExporting = true
        exportProgress = 0
        exportedData = nil
        errorMessage = nil

        do {
            let images = try await exportService.exportAsImages(
                pages: story.sortedPages,
                settings: settings
            )
            // 複数画像をZipする場合はここで処理
            // 今回はFirst画像のデータを設定
            exportedData = images.first
            exportProgress = 1.0
        } catch {
            errorMessage = "画像エクスポートに失敗: \(error.localizedDescription)"
        }

        isExporting = false
    }

    /// PDFとしてエクスポート
    public func exportAsPDF() async {
        isExporting = true
        exportProgress = 0
        exportedData = nil
        errorMessage = nil

        do {
            let data = try await exportService.exportAsPDF(
                pages: story.sortedPages,
                settings: settings
            )
            exportedData = data
            exportProgress = 1.0
        } catch {
            errorMessage = "PDFエクスポートに失敗: \(error.localizedDescription)"
        }

        isExporting = false
    }

    /// エラーをクリア
    public func clearError() {
        errorMessage = nil
    }

    /// エクスポート状態をリセット
    public func reset() {
        exportProgress = 0
        isExporting = false
        exportedURL = nil
        exportedData = nil
        errorMessage = nil
    }
}
#endif
