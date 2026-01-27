//
//  ChatRoom.swift
//  AsaLiveChat
//
//  チャットルームモデル - Swift Data永続化
//

import Foundation
import SwiftData

/// チャットルームを表すモデル
///
/// 複数のメッセージを持ち、ルームコードで他のユーザーと共有できます。
///
/// ## 使用例
/// ```swift
/// let room = ChatRoom(name: "家族チャット")
/// print(room.roomCode) // "ABC123"のような6文字コード
/// ```
@Model
final class ChatRoom {
    // MARK: - Properties

    /// 一意の識別子
    @Attribute(.unique) var id: UUID

    /// ルーム名
    var name: String

    /// 参加用ルームコード（6文字の英数字）
    var roomCode: String

    /// ルーム作成日時
    var createdAt: Date

    /// 最後のメッセージ送信日時
    var lastMessageAt: Date?

    /// 未読メッセージ数
    var unreadCount: Int

    /// ルーム内のメッセージ（1対多リレーション）
    @Relationship(deleteRule: .cascade, inverse: \Message.room)
    var messages: [Message] = []

    // MARK: - Computed Properties

    /// 最新のメッセージ
    var lastMessage: Message? {
        messages.sorted { $0.timestamp > $1.timestamp }.first
    }

    /// メッセージ総数
    var messageCount: Int {
        messages.count
    }

    /// 表示用の最終更新日時
    var displayLastUpdate: String {
        guard let lastMessageAt = lastMessageAt else {
            return formatDate(createdAt)
        }
        return formatDate(lastMessageAt)
    }

    /// 表示用の絵文字（ルーム名の最初の文字に基づく）
    var displayEmoji: String {
        let emojis = ["💬", "👨‍👩‍👧", "🏠", "🎉", "📚", "🎮", "☕️", "🌸"]
        let index = abs(name.hashValue) % emojis.count
        return emojis[index]
    }

    /// 最後のメッセージのプレビュー
    var lastMessagePreview: String? {
        lastMessage?.content
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        roomCode: String? = nil,
        createdAt: Date = Date(),
        lastMessageAt: Date? = nil,
        unreadCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.roomCode = roomCode ?? Self.generateRoomCode()
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
    }

    // MARK: - Methods

    /// メッセージを追加
    func addMessage(_ message: Message) {
        messages.append(message)
        lastMessageAt = message.timestamp
        if !message.isSentByMe {
            unreadCount += 1
        }
    }

    /// 未読をクリア
    func markAsRead() {
        unreadCount = 0
        for message in messages where !message.isRead {
            message.isRead = true
        }
    }

    // MARK: - Private Methods

    /// 6文字のランダムなルームコードを生成
    private static func generateRoomCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    /// 日付をフォーマット
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "E"
        } else {
            formatter.dateFormat = "M/d"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Identifiable

extension ChatRoom: Identifiable {}
