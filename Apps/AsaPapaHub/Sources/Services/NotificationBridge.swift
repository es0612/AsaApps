import Foundation
import UserNotifications

// MARK: - 通知ブリッジ

/// 通知スケジュール管理ブリッジ
@MainActor
final class NotificationBridge {
    static let shared = NotificationBridge()

    private init() {}

    // MARK: - 通知許可

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - 朝活リマインダー

    func scheduleMorningReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["morningReminder"])

        let content = UNMutableNotificationContent()
        content.title = "おはようございます！"
        content.body = "朝活ルーティンを始めましょう"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "morningReminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - 通知解除

    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
}
