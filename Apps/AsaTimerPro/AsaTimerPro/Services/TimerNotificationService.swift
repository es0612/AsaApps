//
//  TimerNotificationService.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import Foundation
import UserNotifications
import UIKit

/// タイマー通知管理サービス
final class TimerNotificationService: NSObject, Sendable {
    static let shared = TimerNotificationService()
    
    private let center = UNUserNotificationCenter.current()
    private let notificationIdentifierPrefix = "AsaTimerPro.Timer"
    
    override init() {
        super.init()
        center.delegate = self
        requestNotificationPermission()
    }
    
    // MARK: - Permission Management
    
    /// 通知権限を要求
    private func requestNotificationPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知権限の要求に失敗: \(error.localizedDescription)")
            }
            
            if granted {
                print("通知権限が許可されました")
            } else {
                print("通知権限が拒否されました")
            }
        }
    }
    
    /// 現在の通知権限状態を取得
    func getNotificationAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    /// 設定アプリに遷移して通知権限を有効にするよう促す
    func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        Task { @MainActor in
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// タイマー完了通知をスケジュール
    func scheduleTimerNotification(for session: TimerSession) async {
        let identifier = notificationIdentifier(for: session.id)
        
        // 既存の通知をキャンセル
        await cancelNotification(for: session.id)
        
        // 通知権限をチェック
        let authStatus = await getNotificationAuthorizationStatus()
        guard authStatus == .authorized else {
            print("通知権限がありません: \(authStatus)")
            return
        }
        
        // 通知内容を作成
        let content = UNMutableNotificationContent()
        content.title = "タイマー完了"
        content.body = "「\(session.name)」のタイマーが完了しました"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("notification.mp3"))
        content.badge = 1
        
        // カテゴリアイコンの追加
        content.categoryIdentifier = session.category.rawValue
        
        // ユーザー情報を追加
        content.userInfo = [
            "timerId": session.id.uuidString,
            "timerName": session.name,
            "category": session.category.rawValue,
            "duration": session.duration
        ]
        
        // トリガーを設定（remainingTimeに基づいて）
        let timeInterval = max(1.0, Double(session.remainingTime))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // 通知リクエストを作成
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("タイマー通知をスケジュールしました: \(session.name) (\(timeInterval)秒後)")
        } catch {
            print("通知のスケジュールに失敗: \(error.localizedDescription)")
        }
    }
    
    /// 繰り返しタイマーの通知をスケジュール
    func scheduleRepeatingTimerNotification(for session: TimerSession, repeatCount: Int) async {
        guard session.isRepeating else {
            await scheduleTimerNotification(for: session)
            return
        }
        
        let identifier = notificationIdentifier(for: session.id)
        
        let content = UNMutableNotificationContent()
        content.title = "繰り返しタイマー完了"
        content.body = "「\(session.name)」(\(repeatCount)回目) が完了しました"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("notification.mp3"))
        content.badge = NSNumber(value: repeatCount)
        
        content.userInfo = [
            "timerId": session.id.uuidString,
            "timerName": session.name,
            "category": session.category.rawValue,
            "duration": session.duration,
            "repeatCount": repeatCount,
            "isRepeating": true
        ]
        
        let timeInterval = max(1.0, Double(session.remainingTime))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("繰り返しタイマー通知をスケジュールしました: \(session.name) (\(repeatCount)回目)")
        } catch {
            print("繰り返しタイマー通知のスケジュールに失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notification Cancellation
    
    /// 特定のタイマー通知をキャンセル
    func cancelNotification(for timerId: UUID) async {
        let identifier = notificationIdentifier(for: timerId)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        print("タイマー通知をキャンセルしました: \(timerId)")
    }
    
    /// 複数のタイマー通知をキャンセル
    func cancelNotifications(for timerIds: [UUID]) async {
        let identifiers = timerIds.map { notificationIdentifier(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        print("複数のタイマー通知をキャンセルしました: \(timerIds.count)件")
    }
    
    /// 全てのタイマー通知をキャンセル
    func cancelAllTimerNotifications() async {
        let pendingNotifications = await center.pendingNotificationRequests()
        let timerNotificationIds = pendingNotifications
            .filter { $0.identifier.hasPrefix(notificationIdentifierPrefix) }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: timerNotificationIds)
        center.removeDeliveredNotifications(withIdentifiers: timerNotificationIds)
        print("全てのタイマー通知をキャンセルしました: \(timerNotificationIds.count)件")
    }
    
    // MARK: - Notification Management
    
    /// 配信予定の通知リストを取得
    func getPendingNotifications() async -> [UNNotificationRequest] {
        let pending = await center.pendingNotificationRequests()
        return pending.filter { $0.identifier.hasPrefix(notificationIdentifierPrefix) }
    }
    
    /// 配信済みの通知リストを取得
    func getDeliveredNotifications() async -> [UNNotification] {
        let delivered = await center.deliveredNotifications()
        return delivered.filter { $0.request.identifier.hasPrefix(notificationIdentifierPrefix) }
    }
    
    /// タイマー通知統計を取得
    func getNotificationStats() async -> NotificationStats {
        let pending = await getPendingNotifications()
        let delivered = await getDeliveredNotifications()
        
        return NotificationStats(
            pendingCount: pending.count,
            deliveredCount: delivered.count,
            totalScheduled: pending.count + delivered.count
        )
    }
    
    // MARK: - Private Methods
    
    private func notificationIdentifier(for timerId: UUID) -> String {
        return "\(notificationIdentifierPrefix).\(timerId.uuidString)"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension TimerNotificationService: UNUserNotificationCenterDelegate {
    /// フォアグラウンドで通知を受信した時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでも通知を表示
        completionHandler([.alert, .sound, .badge])
    }
    
    /// ユーザーが通知をタップした時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let timerIdString = userInfo["timerId"] as? String,
           let timerId = UUID(uuidString: timerIdString) {
            
            print("ユーザーがタイマー通知をタップしました: \(timerId)")
            
            // ここで必要に応じてアプリの特定画面に遷移する処理を追加
            // 例: NotificationCenter.default.post(...) でViewModelに通知
        }
        
        completionHandler()
    }
}

// MARK: - Supporting Types

/// 通知統計情報
struct NotificationStats {
    let pendingCount: Int       // 配信予定の通知数
    let deliveredCount: Int     // 配信済みの通知数
    let totalScheduled: Int     // 総スケジュール数
    
    var hasActiveNotifications: Bool {
        return pendingCount > 0
    }
}