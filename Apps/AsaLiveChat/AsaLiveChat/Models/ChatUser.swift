//
//  ChatUser.swift
//  AsaLiveChat
//
//  チャットユーザーモデル
//

import Foundation

/// チャットユーザーを表す構造体
///
/// WebSocket通信でのユーザー識別とオンライン状態管理に使用します。
struct ChatUser: Identifiable, Codable, Equatable, Sendable {
    // MARK: - Properties

    /// ユーザーID
    let id: String

    /// ユーザー名
    var name: String

    /// アバター絵文字
    var avatarEmoji: String

    /// オンライン状態
    var isOnline: Bool

    /// 最終アクティブ日時
    var lastActiveAt: Date?

    /// 入力中フラグ
    var isTyping: Bool

    // MARK: - Computed Properties

    /// 表示用のオンライン状態
    var statusText: String {
        if isTyping {
            return "入力中..."
        } else if isOnline {
            return "オンライン"
        } else if let lastActive = lastActiveAt {
            return formatLastActive(lastActive)
        } else {
            return "オフライン"
        }
    }

    /// 表示用のイニシャル
    var initial: String {
        String(name.prefix(1))
    }

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        name: String,
        avatarEmoji: String = "😊",
        isOnline: Bool = true,
        lastActiveAt: Date? = nil,
        isTyping: Bool = false
    ) {
        self.id = id
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.isOnline = isOnline
        self.lastActiveAt = lastActiveAt
        self.isTyping = isTyping
    }

    // MARK: - Private Methods

    private func formatLastActive(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "たった今"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)時間前"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M/d HH:mm"
            return formatter.string(from: date)
        }
    }
}

// MARK: - デフォルトアバター

extension ChatUser {
    /// 利用可能なアバター絵文字リスト
    static let availableAvatars: [String] = [
        "😊", "😎", "🥳", "🤓", "😺",
        "🐶", "🐱", "🦊", "🐻", "🐼",
        "🌸", "🌻", "🍀", "🌈", "⭐️",
        "☕️", "🎮", "📚", "🎵", "🏃"
    ]

    /// ランダムなアバターを取得
    static func randomAvatar() -> String {
        availableAvatars.randomElement() ?? "😊"
    }
}
