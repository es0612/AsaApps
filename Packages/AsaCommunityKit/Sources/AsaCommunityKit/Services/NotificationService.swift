import Foundation
import UserNotifications

// MARK: - NotificationService

/// ローカル通知管理サービス
@MainActor
public final class NotificationService: NotificationServiceProtocol {
    private let center: UNUserNotificationCenter

    public init() {
        self.center = UNUserNotificationCenter.current()
    }

    // MARK: - 権限管理

    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    public func checkAuthorizationStatus() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - ゴミ出しリマインダー

    public func scheduleGarbageReminder(
        garbageType: GarbageType,
        weekday: Int,
        hour: Int,
        minute: Int
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "ゴミ出しリマインダー"
        content.body = "明日は「\(garbageType.rawValue)」の収集日です。忘れずに出しましょう。"
        content.sound = .default

        // 毎週の指定曜日・時刻でトリガー
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let identifier = "garbage-\(garbageType.rawValue)-\(weekday)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - イベントリマインダー

    public func scheduleEventReminder(
        eventTitle: String,
        eventDate: Date,
        minutesBefore: Int
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "イベントリマインダー"
        content.body = "「\(eventTitle)」が\(minutesBefore)分後に始まります。"
        content.sound = .default

        // イベント開始の指定分前にトリガー
        let triggerDate = eventDate.addingTimeInterval(-TimeInterval(minutesBefore * 60))
        let interval = triggerDate.timeIntervalSinceNow

        // 過去の日時の場合はスキップ
        guard interval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let identifier = "event-\(eventTitle.hashValue)-\(minutesBefore)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - 安全アラート

    public func sendSafetyAlert(
        title: String,
        body: String,
        level: SafetyAlertLevel
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "【\(level.rawValue)】\(title)"
        content.body = body
        content.sound = level == .emergency ? .defaultCritical : .default

        // 即時通知（1秒後にトリガー）
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        let identifier = "safety-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - 通知削除

    public func removeAllPendingNotifications() async {
        center.removeAllPendingNotificationRequests()
    }

    public func removePendingNotification(identifier: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
