import Foundation
import UserNotifications

// MARK: - NotificationService

/// 通知サービス
@MainActor
final class NotificationService: Sendable {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private init() {}

    // MARK: - Authorization

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

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Budget Notifications

    /// 予算警告通知をスケジュール
    func scheduleBudgetWarning(
        budgetId: UUID,
        percentage: Int,
        budgetName: String,
        remaining: Double
    ) {
        let content = UNMutableNotificationContent()
        content.title = "予算警告"
        content.body = "\(budgetName)の\(percentage)%を使用しました。残り\(formatCurrency(remaining))です。"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = NotificationCategory.budgetWarning.rawValue
        content.userInfo = [
            "budgetId": budgetId.uuidString,
            "percentage": percentage
        ]

        let identifier = "budget-warning-\(budgetId.uuidString)-\(percentage)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule budget warning: \(error)")
            }
        }
    }

    /// 予算超過通知
    func sendBudgetExceededNotification(budgetId: UUID, budgetName: String, overage: Double) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ 予算超過"
        content.body = "\(budgetName)を\(formatCurrency(overage))超過しました。"
        content.sound = .defaultCritical
        content.badge = 1
        content.categoryIdentifier = NotificationCategory.budgetExceeded.rawValue
        content.userInfo = [
            "budgetId": budgetId.uuidString,
            "overage": overage
        ]

        let identifier = "budget-exceeded-\(budgetId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        notificationCenter.add(request)
    }

    // MARK: - Anomaly Notifications

    /// 異常検知通知
    func sendAnomalyNotification(
        transactionId: UUID,
        title: String,
        amount: Double,
        reasons: [String]
    ) {
        let content = UNMutableNotificationContent()
        content.title = "🔍 異常な支出を検出"
        content.body = "\(title): \(formatCurrency(amount))"
        if let firstReason = reasons.first {
            content.subtitle = firstReason
        }
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.anomaly.rawValue
        content.userInfo = [
            "transactionId": transactionId.uuidString,
            "amount": amount,
            "reasons": reasons
        ]

        let identifier = "anomaly-\(transactionId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        notificationCenter.add(request)
    }

    // MARK: - Daily Report Notifications

    /// 日次レポート通知をスケジュール
    func scheduleDailyReport(hour: Int, minute: Int = 0) {
        // 既存の日次レポート通知を削除
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["daily-report"]
        )

        let content = UNMutableNotificationContent()
        content.title = "📊 本日の支出レポート"
        content.body = "今日の支出状況を確認しましょう"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.dailyReport.rawValue

        // 毎日指定時刻にトリガー
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily-report",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule daily report: \(error)")
            }
        }
    }

    /// 日次レポート通知をキャンセル
    func cancelDailyReport() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["daily-report"]
        )
    }

    // MARK: - AI Insight Notifications

    /// AI洞察通知
    func sendAIInsightNotification(insight: AIInsight) {
        let content = UNMutableNotificationContent()
        content.title = "💡 \(insight.category.displayName)の洞察"
        content.body = insight.title
        content.subtitle = insight.description
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.aiInsight.rawValue
        content.userInfo = [
            "insightId": insight.id.uuidString,
            "category": insight.category.rawValue
        ]

        let identifier = "ai-insight-\(insight.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        notificationCenter.add(request)
    }

    // MARK: - Notification Categories Setup

    func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "詳細を見る",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "閉じる",
            options: [.destructive]
        )

        let categories = NotificationCategory.allCases.map { category in
            UNNotificationCategory(
                identifier: category.rawValue,
                actions: [viewAction, dismissAction],
                intentIdentifiers: [],
                options: []
            )
        }

        notificationCenter.setNotificationCategories(Set(categories))
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func clearBadge() {
        Task {
            try? await notificationCenter.setBadgeCount(0)
        }
    }

    // MARK: - Helper Methods

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

// MARK: - NotificationCategory

enum NotificationCategory: String, CaseIterable {
    case budgetWarning = "BUDGET_WARNING"
    case budgetExceeded = "BUDGET_EXCEEDED"
    case anomaly = "ANOMALY"
    case dailyReport = "DAILY_REPORT"
    case aiInsight = "AI_INSIGHT"
}
