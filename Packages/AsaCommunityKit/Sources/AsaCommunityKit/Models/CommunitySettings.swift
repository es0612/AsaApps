import Foundation
import SwiftData

// MARK: - CommunitySettings

/// アプリ設定モデル
@Model
public final class CommunitySettings {
    public var id: UUID = UUID()
    /// ゴミ出しリマインダー有効
    public var isGarbageReminderEnabled: Bool = true
    /// リマインダー通知時刻（前夜の時）
    public var reminderHour: Int = 21
    public var reminderMinute: Int = 0
    /// イベント通知有効
    public var isEventNotificationEnabled: Bool = true
    /// 安全アラート通知有効
    public var isSafetyAlertEnabled: Bool = true
    /// マップ表示半径（メートル）
    public var mapRadiusMeters: Int = 1000
    /// テーマ（light/dark/auto）
    public var themeRawValue: String = "auto"
    /// 表示名
    public var displayName: String = ""
    /// 最終オンボーディング完了
    public var hasCompletedOnboarding: Bool = false

    public init(
        isGarbageReminderEnabled: Bool = true,
        reminderHour: Int = 21,
        isEventNotificationEnabled: Bool = true,
        isSafetyAlertEnabled: Bool = true,
        mapRadiusMeters: Int = 1000
    ) {
        self.id = UUID()
        self.isGarbageReminderEnabled = isGarbageReminderEnabled
        self.reminderHour = reminderHour
        self.isEventNotificationEnabled = isEventNotificationEnabled
        self.isSafetyAlertEnabled = isSafetyAlertEnabled
        self.mapRadiusMeters = mapRadiusMeters
    }

    // MARK: - Theme

    /// テーマ選択肢
    public enum Theme: String, CaseIterable, Sendable {
        case light = "ライト"
        case dark = "ダーク"
        case auto = "自動"
    }

    public var theme: Theme {
        get { Theme(rawValue: themeRawValue) ?? .auto }
        set { themeRawValue = newValue.rawValue }
    }
}
