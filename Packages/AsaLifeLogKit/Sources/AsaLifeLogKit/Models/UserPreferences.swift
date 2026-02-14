import Foundation
import SwiftData

// MARK: - UserPreferences

/// ユーザー設定
///
/// トラッキング機能の有効/無効、リマインダー設定、朝活時間帯などを管理する。
@Model
public final class UserPreferences {
    @Attribute(.unique) public var id: UUID = UUID()
    public var enableHealthTracking: Bool = true
    public var enableLocationTracking: Bool = true
    public var enablePhotoIntegration: Bool = true
    public var enableActivityRecognition: Bool = true
    public var enableAIInsights: Bool = true
    public var dailyReminderTime: Date?
    public var preferredChartPeriodRawValue: String = ChartPeriod.week.rawValue
    public var morningRoutineStartHour: Int = 5
    public var morningRoutineEndHour: Int = 7

    // MARK: - Computed Properties

    /// 優先チャート期間
    public var preferredChartPeriod: ChartPeriod {
        get { ChartPeriod(rawValue: preferredChartPeriodRawValue) ?? .week }
        set { preferredChartPeriodRawValue = newValue.rawValue }
    }

    // MARK: - Init

    public init(
        enableHealthTracking: Bool = true,
        enableLocationTracking: Bool = true,
        enablePhotoIntegration: Bool = true,
        enableActivityRecognition: Bool = true,
        enableAIInsights: Bool = true,
        dailyReminderTime: Date? = nil,
        preferredChartPeriod: ChartPeriod = .week,
        morningRoutineStartHour: Int = 5,
        morningRoutineEndHour: Int = 7
    ) {
        self.id = UUID()
        self.enableHealthTracking = enableHealthTracking
        self.enableLocationTracking = enableLocationTracking
        self.enablePhotoIntegration = enablePhotoIntegration
        self.enableActivityRecognition = enableActivityRecognition
        self.enableAIInsights = enableAIInsights
        self.dailyReminderTime = dailyReminderTime
        self.preferredChartPeriodRawValue = preferredChartPeriod.rawValue
        self.morningRoutineStartHour = morningRoutineStartHour
        self.morningRoutineEndHour = morningRoutineEndHour
    }
}
