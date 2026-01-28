import Foundation
import SwiftData

/// ユーザーの学習プロファイル設定
/// 朝活時間、学習目標、AI最適化設定などを管理
@Model
final class UserLearningProfile {
    // MARK: - Core Properties

    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Morning Activity Settings

    /// 朝活開始目標時刻（時）
    var morningStartHour: Int

    /// 朝活開始目標時刻（分）
    var morningStartMinute: Int

    /// 朝活目標時間（分）
    var morningGoalMinutes: Int

    /// 朝活リマインダー有効
    var morningReminderEnabled: Bool

    // MARK: - Daily Goals

    /// 1日の学習目標時間（分）
    var dailyGoalMinutes: Int

    /// 週間学習目標時間（分）
    var weeklyGoalMinutes: Int

    // MARK: - AI Optimization Settings

    /// AI最適化有効
    var aiOptimizationEnabled: Bool

    /// 使用する最適化重みプリセット
    var optimizationPresetRawValue: String

    /// カスタム重み（JSON）
    var customWeightsJSON: Data?

    // MARK: - Notification Settings

    /// 学習リマインダー有効
    var studyReminderEnabled: Bool

    /// 復習リマインダー有効
    var reviewReminderEnabled: Bool

    /// 達成通知有効
    var achievementNotificationEnabled: Bool

    // MARK: - Preferences

    /// デフォルトセッション時間（分）
    var defaultSessionMinutes: Int

    /// 休憩リマインダー有効
    var breakReminderEnabled: Bool

    /// 休憩間隔（分）
    var breakIntervalMinutes: Int

    // MARK: - Computed Properties

    /// 朝活開始時刻
    var morningStartTime: Date {
        var components = DateComponents()
        components.hour = morningStartHour
        components.minute = morningStartMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    /// 最適化重みプリセット
    var optimizationPreset: OptimizationPreset {
        get { OptimizationPreset(rawValue: optimizationPresetRawValue) ?? .default }
        set { optimizationPresetRawValue = newValue.rawValue }
    }

    /// カスタム重み
    var customWeights: OptimizationWeights? {
        get {
            guard let data = customWeightsJSON else { return nil }
            return try? JSONDecoder().decode(OptimizationWeights.self, from: data)
        }
        set {
            customWeightsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// 実際に使用する重み
    var effectiveWeights: OptimizationWeights {
        switch optimizationPreset {
        case .default: return .default
        case .deadlineFocused: return .deadlineFocused
        case .morningFocused: return .morningFocused
        case .reviewFocused: return .reviewFocused
        case .custom: return customWeights ?? .default
        }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID()
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()

        // 朝活設定のデフォルト
        self.morningStartHour = 5
        self.morningStartMinute = 30
        self.morningGoalMinutes = 60
        self.morningReminderEnabled = true

        // 学習目標のデフォルト
        self.dailyGoalMinutes = 120
        self.weeklyGoalMinutes = 600

        // AI設定のデフォルト
        self.aiOptimizationEnabled = true
        self.optimizationPresetRawValue = OptimizationPreset.default.rawValue
        self.customWeightsJSON = nil

        // 通知設定のデフォルト
        self.studyReminderEnabled = true
        self.reviewReminderEnabled = true
        self.achievementNotificationEnabled = true

        // その他設定のデフォルト
        self.defaultSessionMinutes = 25
        self.breakReminderEnabled = true
        self.breakIntervalMinutes = 25
    }

    // MARK: - Methods

    /// 設定更新
    func update() {
        updatedAt = Date()
    }
}

/// 最適化重みのプリセット
enum OptimizationPreset: String, CaseIterable, Codable, Sendable {
    case `default` = "default"
    case deadlineFocused = "deadlineFocused"
    case morningFocused = "morningFocused"
    case reviewFocused = "reviewFocused"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .default: return "バランス型"
        case .deadlineFocused: return "期限重視"
        case .morningFocused: return "朝活重視"
        case .reviewFocused: return "復習重視"
        case .custom: return "カスタム"
        }
    }

    var description: String {
        switch self {
        case .default: return "すべての要因をバランスよく考慮"
        case .deadlineFocused: return "期限が近い項目を優先的に学習"
        case .morningFocused: return "朝の集中力を活かした難問優先"
        case .reviewFocused: return "復習タイミングを重視して定着を図る"
        case .custom: return "各要因の重みをカスタマイズ"
        }
    }
}
