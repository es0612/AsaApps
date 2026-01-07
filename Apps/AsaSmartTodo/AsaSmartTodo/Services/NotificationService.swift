//
//  NotificationService.swift
//  AsaSmartTodo
//
//  通知管理サービス（AsaTimerProパターン準拠）
//  UserNotificationsのシングルトンラッパー
//

import Foundation
@preconcurrency import UserNotifications
import UIKit

/// タスク期限通知を管理するサービス
///
/// UserNotificationsフレームワークを使用して、タスクの期限前通知を
/// スケジューリング・キャンセル・管理します。
///
/// ## 主要機能
/// - **通知権限管理**: ユーザーからの通知許可リクエスト
/// - **通知スケジューリング**: 期限前通知の自動スケジュール（1時間前/1日前）
/// - **通知キャンセル**: タスク削除・完了時の通知削除
/// - **デリゲート処理**: フォアグラウンド通知の処理
///
/// ## 使用例
/// ```swift
/// let notificationService = NotificationService.shared
///
/// // 権限リクエスト
/// let granted = await notificationService.requestNotificationPermission()
///
/// // タスク通知をスケジュール
/// await notificationService.scheduleTaskNotification(
///     for: task,
///     settings: userSettings
/// )
///
/// // 通知をキャンセル
/// await notificationService.cancelNotification(for: task.id)
/// ```
///
/// - Note: シングルトンパターンで実装されています（`NotificationService.shared`）
/// - Warning: iOS 10以降、`UNUserNotificationCenter`を使用します
final class NotificationService: NSObject {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let categoryIdentifier = "AsaSmartTodo.TaskReminder"

    override init() {
        super.init()
        center.delegate = self
        setupNotificationCategories()
    }

    // MARK: - 権限管理

    /// 通知権限をリクエスト
    func requestNotificationPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("通知権限の要求に失敗: \(error.localizedDescription)")
            return false
        }
    }

    /// 通知権限の状態を取得
    func getNotificationAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    /// 設定アプリの通知設定画面を開く
    func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        Task { @MainActor in
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }

    // MARK: - タスク通知スケジューリング

    /// タスク期限通知をスケジュール
    func scheduleTaskNotification(for task: SmartTask, settings: UserSettings) async {
        guard settings.notificationsEnabled else { return }
        guard let dueDate = task.dueDate, dueDate > Date() else { return }

        let authStatus = await getNotificationAuthorizationStatus()
        guard authStatus == .authorized else { return }

        // 既存通知をキャンセル
        await cancelNotification(for: task.id)

        var notifications: [NotificationRequest] = []

        // 1. 期限日当日の通知
        if settings.dueDayReminderEnabled {
            let dueDayTime = Calendar.current.date(
                bySettingHour: settings.notificationHour,
                minute: settings.notificationMinute,
                second: 0,
                of: dueDate
            ) ?? dueDate

            if dueDayTime > Date() {
                notifications.append(NotificationRequest(
                    id: "\(task.id.uuidString)_dueDay",
                    title: "タスク期限です",
                    body: "「\(task.title)」の期限が今日です",
                    date: dueDayTime
                ))
            }
        }

        // 2. 1日前の通知
        if settings.oneDayBeforeReminderEnabled,
           let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: dueDate) {
            let reminderTime = Calendar.current.date(
                bySettingHour: settings.notificationHour,
                minute: settings.notificationMinute,
                second: 0,
                of: oneDayBefore
            ) ?? oneDayBefore

            if reminderTime > Date() {
                notifications.append(NotificationRequest(
                    id: "\(task.id.uuidString)_oneDayBefore",
                    title: "タスク期限が近づいています",
                    body: "「\(task.title)」の期限は明日です",
                    date: reminderTime
                ))
            }
        }

        // 通知をスケジュール
        for notif in notifications {
            await scheduleNotification(notif, category: task.category)
        }
    }

    /// 朝活リマインダーをスケジュール
    func scheduleMorningReminder(settings: UserSettings) async {
        guard settings.morningReminderEnabled else {
            await cancelMorningReminder()
            return
        }

        let authStatus = await getNotificationAuthorizationStatus()
        guard authStatus == .authorized else { return }

        await cancelMorningReminder()

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: settings.morningReminderTime)

        let content = UNMutableNotificationContent()
        content.title = "朝活タイム！"
        content.body = "今日のタスクを確認して、生産的な1日を始めましょう"
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "AsaSmartTodo.MorningReminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("朝活リマインダーをスケジュールしました")
        } catch {
            print("朝活リマインダーのスケジュールに失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - 通知キャンセル

    /// タスクの通知をキャンセル
    func cancelNotification(for taskId: UUID) async {
        let identifiers = [
            "\(taskId.uuidString)_dueDay",
            "\(taskId.uuidString)_oneDayBefore"
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// 朝活リマインダーをキャンセル
    func cancelMorningReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: ["AsaSmartTodo.MorningReminder"])
    }

    // MARK: - Private Helpers

    private struct NotificationRequest {
        let id: String
        let title: String
        let body: String
        let date: Date
    }

    private func scheduleNotification(_ request: NotificationRequest, category: TaskCategory) async {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = ["taskId": request.id]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: request.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let notificationRequest = UNNotificationRequest(
            identifier: request.id,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(notificationRequest)
            print("通知をスケジュールしました: \(request.id)")
        } catch {
            print("通知のスケジュールに失敗: \(error.localizedDescription)")
        }
    }

    private func setupNotificationCategories() {
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでも通知を表示
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let taskIdString = userInfo["taskId"] as? String {
            print("ユーザーがタスク通知をタップしました: \(taskIdString)")
            // TODO: タスク詳細画面への遷移実装
        }

        completionHandler()
    }
}
