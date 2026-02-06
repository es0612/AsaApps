#if os(iOS)
import Foundation

// MARK: - 設定ViewModel

/// アプリ設定の管理ViewModel
@MainActor
@Observable
public final class SettingsViewModel {
    // MARK: - Properties

    public var defaultRadius: Double = 100
    public var defaultTriggerOnEntry: Bool = true
    public var defaultTriggerOnExit: Bool = false
    public var hapticFeedbackEnabled: Bool = true
    public var errorMessage: String?

    private let dataService: ReminderDataService

    // MARK: - Init

    public init(dataService: ReminderDataService) {
        self.dataService = dataService
    }

    // MARK: - 設定読み込み

    /// 保存された設定を読み込み
    public func loadSettings() {
        do {
            let settings = try dataService.getUserSettings()
            defaultRadius = settings.defaultRadius
            defaultTriggerOnEntry = settings.defaultTriggerOnEntry
            defaultTriggerOnExit = settings.defaultTriggerOnExit
            hapticFeedbackEnabled = settings.hapticFeedbackEnabled
        } catch {
            errorMessage = "設定の読み込みに失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - 設定保存

    /// 現在の設定を保存
    public func saveSettings() {
        do {
            let settings = try dataService.getUserSettings()
            settings.defaultRadius = defaultRadius
            settings.defaultTriggerOnEntry = defaultTriggerOnEntry
            settings.defaultTriggerOnExit = defaultTriggerOnExit
            settings.hapticFeedbackEnabled = hapticFeedbackEnabled
            try dataService.saveSettings(settings)
        } catch {
            errorMessage = "設定の保存に失敗: \(error.localizedDescription)"
        }
    }

    /// 半径の表示テキスト
    public var radiusDisplayText: String {
        if defaultRadius >= 1000 {
            String(format: "%.1fkm", defaultRadius / 1000)
        } else {
            "\(Int(defaultRadius))m"
        }
    }
}
#endif
