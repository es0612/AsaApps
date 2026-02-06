#if os(iOS)
import CoreLocation
import Foundation
import UserNotifications

// MARK: - 通知サービス

/// UNLocationNotificationTriggerを使った位置ベース通知の管理
@MainActor
public final class NotificationService {

    public init() {}

    // MARK: - 通知スケジュール

    /// 位置ベースの通知をスケジュール
    /// - Parameters:
    ///   - reminder: 通知対象のリマインダー
    ///   - location: ジオフェンスの中心位置
    /// - Returns: スケジュールされた通知のID
    @discardableResult
    public func scheduleLocationNotification(
        reminder: LocationReminder,
        location: ReminderLocation
    ) async throws -> String {
        let content = UNMutableNotificationContent()
        content.title = "📍 \(location.name)"
        content.body = reminder.title
        if let note = reminder.note, !note.isEmpty {
            content.subtitle = note
        }
        content.sound = .default
        content.categoryIdentifier = "LOCATION_REMINDER"

        // ジオフェンスのリージョン設定
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: location.radius,
            identifier: reminder.id.uuidString
        )
        region.notifyOnEntry = reminder.triggerOnEntry
        region.notifyOnExit = reminder.triggerOnExit

        let trigger = UNLocationNotificationTrigger(
            region: region,
            repeats: reminder.isRepeating
        )

        let notificationID = "reminder-\(reminder.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)

        // リマインダーに通知IDを記録
        reminder.notificationIdentifier = notificationID

        return notificationID
    }

    // MARK: - 通知キャンセル

    /// 特定のリマインダーの通知をキャンセル
    public func cancelNotification(for reminder: LocationReminder) {
        guard let identifier = reminder.notificationIdentifier else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
        reminder.notificationIdentifier = nil
    }

    /// 複数の通知をキャンセル
    public func cancelNotifications(for reminders: [LocationReminder]) {
        let identifiers = reminders.compactMap(\.notificationIdentifier)
        guard !identifiers.isEmpty else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers)
        for reminder in reminders {
            reminder.notificationIdentifier = nil
        }
    }

    /// 全通知をキャンセル
    public func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - 通知状態確認

    /// 保留中の通知数を取得
    public func pendingNotificationCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.filter { $0.identifier.hasPrefix("reminder-") }.count
    }
}
#endif
