import Foundation
import UserNotifications

/// 通知管理サービス
/// 朝活リマインダー、復習通知、達成通知を管理
@MainActor
final class NotificationService {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Notification Identifiers

    private enum NotificationID {
        static let morningReminder = "com.asastudyplanner.morning"
        static let reviewReminder = "com.asastudyplanner.review"
        static let studyReminder = "com.asastudyplanner.study"
        static let achievement = "com.asastudyplanner.achievement"
        static let streakReminder = "com.asastudyplanner.streak"
    }

    // MARK: - Initializer

    private init() {}

    // MARK: - Authorization

    /// 通知権限をリクエスト
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    /// 通知権限の状態を確認
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Morning Reminder

    /// 朝活リマインダーを設定
    func scheduleMorningReminder(hour: Int, minute: Int) async {
        // 既存の朝活リマインダーを削除
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.morningReminder]
        )

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let content = UNMutableNotificationContent()
        content.title = "☀️ 朝活の時間です"
        content.body = "今日も朝活で学習を始めましょう！"
        content.sound = .default
        content.badge = 1

        let request = UNNotificationRequest(
            identifier: NotificationID.morningReminder,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Morning reminder scheduled for \(hour):\(minute)")
        } catch {
            print("Error scheduling morning reminder: \(error)")
        }
    }

    /// 朝活リマインダーをキャンセル
    func cancelMorningReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.morningReminder]
        )
    }

    // MARK: - Review Reminder

    /// 復習リマインダーを設定
    func scheduleReviewReminder(for item: StudyItem) async {
        guard let reviewDate = item.nextReviewDate else { return }

        let identifier = "\(NotificationID.reviewReminder).\(item.id.uuidString)"

        // 既存の通知を削除
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )

        // 復習日の朝8時に通知
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: reviewDate
        )
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let content = UNMutableNotificationContent()
        content.title = "🔄 復習のお知らせ"
        content.body = "「\(item.title)」の復習タイミングです"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Review reminder scheduled for \(item.title)")
        } catch {
            print("Error scheduling review reminder: \(error)")
        }
    }

    /// 復習リマインダーをキャンセル
    func cancelReviewReminder(for itemId: UUID) {
        let identifier = "\(NotificationID.reviewReminder).\(itemId.uuidString)"
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    // MARK: - Study Reminder

    /// 学習リマインダーを設定（期限が近い項目）
    func scheduleStudyReminder(for item: StudyItem, daysBefore: Int = 1) async {
        guard let targetDate = item.targetDate else { return }

        let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBefore,
            to: targetDate
        )!

        // 過去の日付は無視
        guard reminderDate > Date() else { return }

        let identifier = "\(NotificationID.studyReminder).\(item.id.uuidString)"

        // 既存の通知を削除
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )

        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: reminderDate
        )
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let content = UNMutableNotificationContent()
        content.title = "📚 期限が近づいています"
        content.body = "「\(item.title)」の期限まであと\(daysBefore)日です"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Study reminder scheduled for \(item.title)")
        } catch {
            print("Error scheduling study reminder: \(error)")
        }
    }

    // MARK: - Achievement Notification

    /// 達成通知を送信
    func sendAchievementNotification(title: String, message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "🎉 \(title)"
        content.body = message
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(NotificationID.achievement).\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Error sending achievement notification: \(error)")
        }
    }

    /// 朝活達成通知
    func sendMorningAchievement(minutes: Int) async {
        await sendAchievementNotification(
            title: "朝活達成！",
            message: "今朝は\(minutes)分の学習を完了しました！素晴らしい！"
        )
    }

    /// ストリーク達成通知
    func sendStreakAchievement(days: Int) async {
        await sendAchievementNotification(
            title: "\(days)日連続達成！",
            message: "\(days)日間連続で学習を続けています！継続は力なり！"
        )
    }

    /// 目標達成通知
    func sendGoalAchievement(goalType: String) async {
        await sendAchievementNotification(
            title: "\(goalType)達成！",
            message: "今日の\(goalType)を達成しました！おめでとうございます！"
        )
    }

    // MARK: - Streak Reminder

    /// ストリーク維持リマインダー
    func scheduleStreakReminder(at hour: Int = 20) async {
        let identifier = NotificationID.streakReminder

        // 既存の通知を削除
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let content = UNMutableNotificationContent()
        content.title = "🔥 ストリークを維持しよう"
        content.body = "今日の学習を忘れずに！連続記録を更新しましょう"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Streak reminder scheduled for \(hour):00")
        } catch {
            print("Error scheduling streak reminder: \(error)")
        }
    }

    // MARK: - Clear All

    /// すべての通知をクリア
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    /// バッジをクリア
    func clearBadge() async {
        do {
            try await notificationCenter.setBadgeCount(0)
        } catch {
            print("Error clearing badge: \(error)")
        }
    }
}
