import Foundation

// MARK: - NotificationServiceProtocol

/// 通知抽象化プロトコル
@MainActor
public protocol NotificationServiceProtocol {
    /// 通知権限をリクエスト
    func requestAuthorization() async throws -> Bool

    /// 通知権限の状態を確認
    func checkAuthorizationStatus() async -> Bool

    /// ゴミ出しリマインダーを設定
    func scheduleGarbageReminder(
        garbageType: GarbageType,
        weekday: Int,
        hour: Int,
        minute: Int
    ) async throws

    /// イベントリマインダーを設定
    func scheduleEventReminder(
        eventTitle: String,
        eventDate: Date,
        minutesBefore: Int
    ) async throws

    /// 安全アラート通知を送信
    func sendSafetyAlert(
        title: String,
        body: String,
        level: SafetyAlertLevel
    ) async throws

    /// すべてのスケジュール済み通知を削除
    func removeAllPendingNotifications() async

    /// 特定IDの通知を削除
    func removePendingNotification(identifier: String) async
}
