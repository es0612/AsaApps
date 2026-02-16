import Foundation
import UserNotifications

// MARK: - 通知スケジューラー

@MainActor
public final class NotificationScheduler: Sendable {
    public init() {}

    public func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    public func scheduleMorningReminder(hour: Int, minute: Int) async throws {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "おはようございます! ☀️"
        content.body = "朝活ルーティンを始めましょう"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "morning-routine-reminder",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    public func scheduleRoutineComplete() async throws {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "朝活完了! 🎉"
        content.body = "素晴らしい朝のスタートです"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "routine-complete-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    public func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
