//
//  UserSettings.swift
//  AsaLiveChat
//
//  ユーザー設定モデル - Swift Data永続化
//

import Foundation
import SwiftData

/// ユーザー設定を表すモデル
///
/// ユーザー名、アバター、通知設定などを管理します。
@Model
final class UserSettings {
    // MARK: - Properties

    /// 一意の識別子
    @Attribute(.unique) var id: UUID

    /// ユーザーID（デバイス固有）
    var userId: String

    /// ユーザー名
    var userName: String

    /// アバター絵文字
    var avatarEmoji: String

    /// 通知有効フラグ
    var notificationsEnabled: Bool

    /// サウンド有効フラグ
    var soundEnabled: Bool

    /// バイブレーション有効フラグ
    var vibrationEnabled: Bool

    /// 入力中表示の送信フラグ
    var sendTypingIndicator: Bool

    /// 既読表示の送信フラグ
    var sendReadReceipts: Bool

    /// WebSocketサーバーURL
    var serverURL: String

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    // MARK: - Computed Properties

    /// ChatUser表現
    var asChatUser: ChatUser {
        ChatUser(
            id: userId,
            name: userName,
            avatarEmoji: avatarEmoji,
            isOnline: true
        )
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userId: String? = nil,
        userName: String = "ゲスト",
        avatarEmoji: String = "😊",
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true,
        sendTypingIndicator: Bool = true,
        sendReadReceipts: Bool = true,
        serverURL: String = "wss://echo.websocket.org"
    ) {
        self.id = id
        self.userId = userId ?? UUID().uuidString
        self.userName = userName
        self.avatarEmoji = avatarEmoji
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
        self.sendTypingIndicator = sendTypingIndicator
        self.sendReadReceipts = sendReadReceipts
        self.serverURL = serverURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// 設定を更新（updatedAtを自動更新）
    func update() {
        updatedAt = Date()
    }
}

// MARK: - Default Settings

extension UserSettings {
    /// デフォルト設定を作成
    static func createDefault() -> UserSettings {
        UserSettings()
    }

    /// 利用可能なサーバーURLリスト
    static let availableServers: [(name: String, url: String)] = [
        ("Echo Server", "wss://echo.websocket.org"),
        ("SocketsBay Echo", "wss://socketsbay.com/wss/v2/1/demo/"),
        ("ローカル開発", "ws://localhost:8080"),
        ("カスタム", "")
    ]
}
