//
//  NotificationService.swift
//  AsaSmartAlarm
//
//  通知管理サービス
//

import Foundation
import UserNotifications

// MARK: - 通知アクション

/// 通知に対するアクションの識別子
enum NotificationAction: String {
    case snooze = "SNOOZE_ACTION"
    case stop = "STOP_ACTION"
}

/// 通知カテゴリの識別子
enum NotificationCategory: String {
    case alarm = "ALARM_CATEGORY"
}

// MARK: - 通知サービス

/// アラーム通知の管理を行うシングルトンサービス
final class NotificationService: NSObject {
    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Properties

    private let center = UNUserNotificationCenter.current()
    private var snoozeMinutes: Int = 5

    // MARK: - Initializer

    private override init() {
        super.init()
        center.delegate = self
        setupNotificationCategories()
    }

    // MARK: - Public Methods

    /// 通知権限をリクエスト
    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            print("🔔 通知権限: \(granted ? "許可" : "拒否")")
            return granted
        } catch {
            print("🔔 通知権限リクエストエラー: \(error.localizedDescription)")
            return false
        }
    }

    /// 通知権限の状態を取得
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    /// 通知が許可されているかどうか
    func isAuthorized() async -> Bool {
        let status = await getAuthorizationStatus()
        return status == .authorized
    }

    /// スヌーズ時間を設定
    func setSnoozeMinutes(_ minutes: Int) {
        snoozeMinutes = minutes
    }

    /// アラーム通知をスケジュール
    /// - Parameters:
    ///   - alarm: アラームモデル
    ///   - scheduledDate: スケジュールする日時
    ///   - adjustmentInfo: 調整情報（オプション）
    func scheduleAlarmNotification(
        for alarm: SmartAlarm,
        at scheduledDate: Date,
        adjustmentInfo: String? = nil
    ) async {
        // 権限チェック
        guard await isAuthorized() else {
            print("🔔 通知権限がありません")
            return
        }

        // 過去の日時はスキップ
        guard scheduledDate > Date() else {
            print("🔔 過去の日時のためスキップ: \(scheduledDate)")
            return
        }

        // 既存の通知をキャンセル
        await cancelNotification(for: alarm.id)

        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "アラーム" : alarm.label
        content.body = createNotificationBody(for: alarm, adjustmentInfo: adjustmentInfo)
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.alarm.rawValue
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "scheduledDate": scheduledDate.timeIntervalSince1970
        ]

        // トリガーを作成
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        // リクエストを作成
        let identifier = alarmNotificationIdentifier(for: alarm.id)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // スケジュール
        do {
            try await center.add(request)
            print("🔔 アラーム通知をスケジュール: \(alarm.timeString) -> \(scheduledDate)")
        } catch {
            print("🔔 通知スケジュールエラー: \(error.localizedDescription)")
        }
    }

    /// スヌーズ通知をスケジュール
    func scheduleSnoozeNotification(
        for alarmId: UUID,
        label: String,
        minutes: Int? = nil
    ) async {
        let snoozeTime = minutes ?? snoozeMinutes
        let snoozeDate = Date().addingTimeInterval(TimeInterval(snoozeTime * 60))

        let content = UNMutableNotificationContent()
        content.title = label.isEmpty ? "スヌーズ" : label
        content.body = "スヌーズ \(snoozeTime)分経過しました"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.alarm.rawValue
        content.userInfo = [
            "alarmId": alarmId.uuidString,
            "isSnooze": true
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(snoozeTime * 60),
            repeats: false
        )

        let identifier = snoozeNotificationIdentifier(for: alarmId)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("🔔 スヌーズ通知をスケジュール: \(snoozeTime)分後")
        } catch {
            print("🔔 スヌーズスケジュールエラー: \(error.localizedDescription)")
        }
    }

    /// アラームの通知をキャンセル
    func cancelNotification(for alarmId: UUID) async {
        let identifiers = [
            alarmNotificationIdentifier(for: alarmId),
            snoozeNotificationIdentifier(for: alarmId)
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        print("🔔 通知をキャンセル: \(alarmId)")
    }

    /// すべての通知をキャンセル
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("🔔 すべての通知をキャンセル")
    }

    /// スケジュールされている通知を取得
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    // MARK: - Private Methods

    /// 通知カテゴリをセットアップ
    private func setupNotificationCategories() {
        // スヌーズアクション
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze.rawValue,
            title: "スヌーズ",
            options: []
        )

        // 停止アクション
        let stopAction = UNNotificationAction(
            identifier: NotificationAction.stop.rawValue,
            title: "停止",
            options: [.destructive]
        )

        // アラームカテゴリ
        let alarmCategory = UNNotificationCategory(
            identifier: NotificationCategory.alarm.rawValue,
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([alarmCategory])
        print("🔔 通知カテゴリをセットアップ")
    }

    /// 通知本文を作成
    private func createNotificationBody(
        for alarm: SmartAlarm,
        adjustmentInfo: String?
    ) -> String {
        var body = "起きる時間です！"

        if let info = adjustmentInfo {
            body += "\n\(info)"
        }

        return body
    }

    /// アラーム通知の識別子
    private func alarmNotificationIdentifier(for alarmId: UUID) -> String {
        "AsaSmartAlarm.Alarm.\(alarmId.uuidString)"
    }

    /// スヌーズ通知の識別子
    private func snoozeNotificationIdentifier(for alarmId: UUID) -> String {
        "AsaSmartAlarm.Snooze.\(alarmId.uuidString)"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// フォアグラウンドで通知を受信した場合
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 フォアグラウンドで通知受信: \(notification.request.identifier)")
        // フォアグラウンドでも通知を表示
        completionHandler([.banner, .sound, .badge])
    }

    /// 通知アクションを処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        print("🔔 通知アクション: \(actionIdentifier)")

        if let alarmIdString = userInfo["alarmId"] as? String,
           let alarmId = UUID(uuidString: alarmIdString) {

            switch actionIdentifier {
            case NotificationAction.snooze.rawValue:
                // スヌーズ
                let label = response.notification.request.content.title
                Task {
                    await scheduleSnoozeNotification(for: alarmId, label: label)
                }

            case NotificationAction.stop.rawValue:
                // 停止（何もしない）
                print("🔔 アラーム停止: \(alarmId)")

            case UNNotificationDefaultActionIdentifier:
                // 通知をタップ
                print("🔔 通知をタップ: \(alarmId)")

            default:
                break
            }
        }

        completionHandler()
    }
}
