import Foundation

// MARK: - SettingsViewModel

/// 設定画面のViewModel
///
/// トラッキング設定の切り替え、データエクスポート機能を管理する。
@MainActor @Observable
public final class SettingsViewModel {
    // MARK: - Dependencies

    private let dataService: any LifeLogDataServiceProtocol
    private let exportService: ExportService

    // MARK: - Properties

    public var preferences: UserPreferences?
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var exportedData: Data?

    // MARK: - Init

    public init(
        dataService: any LifeLogDataServiceProtocol,
        exportService: ExportService = ExportService()
    ) {
        self.dataService = dataService
        self.exportService = exportService
    }

    // MARK: - Methods

    /// 設定を読み込む
    public func loadPreferences() async {
        isLoading = true
        errorMessage = nil
        do {
            preferences = try await dataService.fetchOrCreatePreferences()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 設定を保存する
    public func savePreferences() async {
        guard let prefs = preferences else { return }
        errorMessage = nil
        do {
            try await dataService.savePreferences(prefs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// ヘルストラッキングを切り替える
    public func toggleHealthTracking() async {
        preferences?.enableHealthTracking.toggle()
        await savePreferences()
    }

    /// 位置情報トラッキングを切り替える
    public func toggleLocationTracking() async {
        preferences?.enableLocationTracking.toggle()
        await savePreferences()
    }

    /// 写真統合を切り替える
    public func togglePhotoIntegration() async {
        preferences?.enablePhotoIntegration.toggle()
        await savePreferences()
    }

    /// アクティビティ認識を切り替える
    public func toggleActivityRecognition() async {
        preferences?.enableActivityRecognition.toggle()
        await savePreferences()
    }

    /// AIインサイトを切り替える
    public func toggleAIInsights() async {
        preferences?.enableAIInsights.toggle()
        await savePreferences()
    }

    /// JSON形式でデータをエクスポートする
    public func exportDataAsJSON() async {
        isLoading = true
        errorMessage = nil
        do {
            let calendar = Calendar.current
            guard let startDate = calendar.date(byAdding: .year, value: -1, to: Date()) else { return }
            let entries = try await dataService.fetchEntries(from: startDate, to: Date())
            exportedData = try exportService.exportAsJSON(entries: entries)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// CSV形式でデータをエクスポートする
    public func exportDataAsCSV() async {
        isLoading = true
        errorMessage = nil
        do {
            let calendar = Calendar.current
            guard let startDate = calendar.date(byAdding: .year, value: -1, to: Date()) else { return }
            let entries = try await dataService.fetchEntries(from: startDate, to: Date())
            exportedData = try exportService.exportAsCSV(entries: entries)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
