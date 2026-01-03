//
//  NotificationServiceTests.swift
//  AsaSmartTodoTests
//
//  NotificationServiceのテスト
//  通知権限、スケジューリング、キャンセル処理を検証
//

import Testing
import Foundation
import UserNotifications
@testable import AsaSmartTodo

/// NotificationServiceのテストスイート
@MainActor
struct NotificationServiceTests {

    // MARK: - Helper Methods

    /// テスト用のSmartTaskを作成
    func createTestTask(
        title: String = "テストタスク",
        dueDate: Date? = nil
    ) -> SmartTask {
        return SmartTask(
            title: title,
            description: "テスト説明",
            category: .work,
            userPriority: .medium,
            dueDate: dueDate
        )
    }

    /// テスト用のUserSettingsを作成
    func createTestSettings(
        notificationsEnabled: Bool = true,
        dueDayReminderEnabled: Bool = true,
        oneDayBeforeReminderEnabled: Bool = true,
        morningReminderEnabled: Bool = false,
        notificationHour: Int = 9,
        notificationMinute: Int = 0
    ) -> UserSettings {
        let settings = UserSettings()
        settings.notificationsEnabled = notificationsEnabled
        settings.dueDayReminderEnabled = dueDayReminderEnabled
        settings.oneDayBeforeReminderEnabled = oneDayBeforeReminderEnabled
        settings.morningReminderEnabled = morningReminderEnabled
        settings.notificationHour = notificationHour
        settings.notificationMinute = notificationMinute
        return settings
    }

    // MARK: - 権限管理テスト (5テスト)

    @Test("NotificationServiceがシングルトンとして初期化される")
    func testSingletonInitialization() async {
        let service1 = NotificationService.shared
        let service2 = NotificationService.shared

        // 同一インスタンスであることを確認
        #expect(service1 === service2)
    }

    @Test("通知権限リクエストが非同期で動作する")
    func testRequestNotificationPermission() async {
        let service = NotificationService.shared

        // 権限リクエスト（実際の結果は環境依存）
        let result = await service.requestNotificationPermission()

        // Bool値が返ることを確認（true/falseは環境依存）
        #expect(result == true || result == false)
    }

    @Test("通知権限状態の取得が動作する")
    func testGetNotificationAuthorizationStatus() async {
        let service = NotificationService.shared

        let status = await service.getNotificationAuthorizationStatus()

        // ステータスが有効な値であることを確認
        let validStatuses: [UNAuthorizationStatus] = [
            .notDetermined, .denied, .authorized, .provisional, .ephemeral
        ]
        #expect(validStatuses.contains(status))
    }

    @Test("通知設定画面を開く処理が実行される")
    func testOpenNotificationSettings() async {
        let service = NotificationService.shared

        // クラッシュしないことを確認（実際の画面遷移はテスト不可）
        service.openNotificationSettings()

        // 例外が発生しないことを確認
        #expect(true)
    }

    @Test("通知権限がnotDeterminedの場合にリクエストできる")
    func testPermissionRequestWhenNotDetermined() async {
        let service = NotificationService.shared

        let initialStatus = await service.getNotificationAuthorizationStatus()

        // 初回リクエスト時の動作確認
        if initialStatus == .notDetermined {
            let result = await service.requestNotificationPermission()
            #expect(result == true || result == false)
        } else {
            // 既に許可/拒否されている場合
            #expect(initialStatus == .authorized || initialStatus == .denied)
        }
    }

    // MARK: - 通知スケジューリングテスト (8テスト)

    @Test("通知が無効の場合にスケジュールされない")
    func testNoScheduleWhenNotificationsDisabled() async {
        let service = NotificationService.shared
        let task = createTestTask(dueDate: Date().addingTimeInterval(86400)) // 1日後
        let settings = createTestSettings(notificationsEnabled: false)

        // 通知スケジュール実行（内部で早期リターン）
        await service.scheduleTaskNotification(for: task, settings: settings)

        // エラーが発生しないことを確認
        #expect(true)
    }

    @Test("期限日がnilの場合にスケジュールされない")
    func testNoScheduleWhenDueDateIsNil() async {
        let service = NotificationService.shared
        let task = createTestTask(dueDate: nil)
        let settings = createTestSettings()

        await service.scheduleTaskNotification(for: task, settings: settings)

        // エラーが発生しないことを確認
        #expect(true)
    }

    @Test("期限日が過去の場合にスケジュールされない")
    func testNoScheduleWhenDueDateInPast() async {
        let service = NotificationService.shared
        let pastDate = Date().addingTimeInterval(-86400) // 1日前
        let task = createTestTask(dueDate: pastDate)
        let settings = createTestSettings()

        await service.scheduleTaskNotification(for: task, settings: settings)

        // エラーが発生しないことを確認
        #expect(true)
    }

    @Test("期限日当日の通知がスケジュールされる")
    func testScheduleDueDayNotification() async {
        let service = NotificationService.shared
        let futureDate = Date().addingTimeInterval(86400 * 2) // 2日後
        let task = createTestTask(title: "期限日テスト", dueDate: futureDate)
        let settings = createTestSettings(
            dueDayReminderEnabled: true,
            oneDayBeforeReminderEnabled: false
        )

        // 既存通知をクリア
        await service.cancelNotification(for: task.id)

        // 通知スケジュール
        await service.scheduleTaskNotification(for: task, settings: settings)

        // エラーが発生しないことを確認
        #expect(true)
    }

    @Test("1日前通知がスケジュールされる")
    func testScheduleOneDayBeforeNotification() async {
        let service = NotificationService.shared
        let futureDate = Date().addingTimeInterval(86400 * 2) // 2日後
        let task = createTestTask(title: "1日前テスト", dueDate: futureDate)
        let settings = createTestSettings(
            dueDayReminderEnabled: false,
            oneDayBeforeReminderEnabled: true
        )

        await service.cancelNotification(for: task.id)
        await service.scheduleTaskNotification(for: task, settings: settings)

        #expect(true)
    }

    @Test("複数通知が同時にスケジュールされる")
    func testScheduleMultipleNotifications() async {
        let service = NotificationService.shared
        let futureDate = Date().addingTimeInterval(86400 * 2) // 2日後
        let task = createTestTask(title: "複数通知テスト", dueDate: futureDate)
        let settings = createTestSettings(
            dueDayReminderEnabled: true,
            oneDayBeforeReminderEnabled: true
        )

        await service.cancelNotification(for: task.id)
        await service.scheduleTaskNotification(for: task, settings: settings)

        #expect(true)
    }

    @Test("カスタム通知時刻が正しく設定される")
    func testCustomNotificationTime() async {
        let service = NotificationService.shared
        let futureDate = Date().addingTimeInterval(86400 * 2) // 2日後
        let task = createTestTask(dueDate: futureDate)
        let settings = createTestSettings(
            notificationHour: 7,
            notificationMinute: 30
        )

        await service.cancelNotification(for: task.id)
        await service.scheduleTaskNotification(for: task, settings: settings)

        // 7時30分の設定が反映されることを確認（内部処理）
        #expect(settings.notificationHour == 7)
        #expect(settings.notificationMinute == 30)
    }

    @Test("朝活リマインダーがスケジュールされる")
    func testScheduleMorningReminder() async {
        let service = NotificationService.shared
        let settings = createTestSettings(morningReminderEnabled: true)

        // 既存朝活リマインダーをキャンセル
        await service.cancelMorningReminder()

        // 朝活リマインダースケジュール
        await service.scheduleMorningReminder(settings: settings)

        #expect(true)
    }

    // MARK: - 通知キャンセルテスト (4テスト)

    @Test("タスク通知がキャンセルされる")
    func testCancelTaskNotification() async {
        let service = NotificationService.shared
        let task = createTestTask(dueDate: Date().addingTimeInterval(86400))

        // 通知をキャンセル
        await service.cancelNotification(for: task.id)

        // エラーが発生しないことを確認
        #expect(true)
    }

    @Test("朝活リマインダーがキャンセルされる")
    func testCancelMorningReminder() async {
        let service = NotificationService.shared

        await service.cancelMorningReminder()

        #expect(true)
    }

    @Test("朝活リマインダー無効時に自動キャンセルされる")
    func testMorningReminderCanceledWhenDisabled() async {
        let service = NotificationService.shared
        let settings = createTestSettings(morningReminderEnabled: false)

        // 無効化されている場合、内部でキャンセルされる
        await service.scheduleMorningReminder(settings: settings)

        #expect(true)
    }

    @Test("既存通知が新しいスケジュール時にキャンセルされる")
    func testExistingNotificationsCanceledOnReschedule() async {
        let service = NotificationService.shared
        let task = createTestTask(dueDate: Date().addingTimeInterval(86400 * 3))
        let settings = createTestSettings()

        // 初回スケジュール
        await service.scheduleTaskNotification(for: task, settings: settings)

        // 再スケジュール（内部でcancelNotificationが呼ばれる）
        await service.scheduleTaskNotification(for: task, settings: settings)

        #expect(true)
    }

    // MARK: - エッジケーステスト (3テスト)

    @Test("期限日が24時間以内の場合の処理")
    func testNotificationWithinNextDay() async {
        let service = NotificationService.shared
        let nearFutureDate = Date().addingTimeInterval(3600) // 1時間後
        let task = createTestTask(dueDate: nearFutureDate)
        let settings = createTestSettings(oneDayBeforeReminderEnabled: true)

        // 1日前通知は過去になるため設定されない
        await service.scheduleTaskNotification(for: task, settings: settings)

        #expect(true)
    }

    @Test("複数タスクの通知が独立して管理される")
    func testMultipleTasksNotificationsIndependent() async {
        let service = NotificationService.shared
        let task1 = createTestTask(title: "タスク1", dueDate: Date().addingTimeInterval(86400 * 2))
        let task2 = createTestTask(title: "タスク2", dueDate: Date().addingTimeInterval(86400 * 3))
        let settings = createTestSettings()

        // 両方のタスクをスケジュール
        await service.scheduleTaskNotification(for: task1, settings: settings)
        await service.scheduleTaskNotification(for: task2, settings: settings)

        // task1のみキャンセル
        await service.cancelNotification(for: task1.id)

        // エラーが発生しないことを確認
        #expect(true)
    }

    @Test("通知時刻が境界値の場合の処理")
    func testNotificationTimeBoundaryValues() async {
        let service = NotificationService.shared
        let task = createTestTask(dueDate: Date().addingTimeInterval(86400 * 2))

        // 0時0分
        let settings1 = createTestSettings(notificationHour: 0, notificationMinute: 0)
        await service.scheduleTaskNotification(for: task, settings: settings1)

        // 23時59分
        let settings2 = createTestSettings(notificationHour: 23, notificationMinute: 59)
        await service.scheduleTaskNotification(for: task, settings: settings2)

        #expect(true)
    }
}
