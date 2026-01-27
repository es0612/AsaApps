//
//  Message.swift
//  AsaLiveChat
//
//  メッセージモデル - Swift Data永続化
//

import Foundation
import SwiftData

/// チャットメッセージを表すモデル
///
/// 送信者情報、タイムスタンプ、既読状態を管理します。
///
/// ## 使用例
/// ```swift
/// let message = Message(
///     content: "おはようございます！",
///     senderName: "パパ",
///     senderId: "user-123",
///     isSentByMe: true
/// )
/// ```
@Model
final class Message {
    // MARK: - Properties

    /// 一意の識別子
    @Attribute(.unique) var id: UUID

    /// メッセージ内容
    var content: String

    /// 送信者名
    var senderName: String

    /// 送信者ID
    var senderId: String

    /// 送信日時
    var timestamp: Date

    /// 既読フラグ
    var isRead: Bool

    /// 自分が送信したメッセージかどうか
    var isSentByMe: Bool

    /// 送信ステータス（Raw Value保存）
    var statusRawValue: String

    /// 所属するチャットルーム
    var room: ChatRoom?

    // MARK: - Computed Properties

    /// 送信ステータス
    var status: MessageStatus {
        get { MessageStatus(rawValue: statusRawValue) ?? .sent }
        set { statusRawValue = newValue.rawValue }
    }

    /// 表示用のタイムスタンプ
    var displayTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }

    /// 詳細表示用のタイムスタンプ
    var detailedTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: timestamp)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        content: String,
        senderName: String,
        senderId: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        isSentByMe: Bool,
        status: MessageStatus = .sent,
        room: ChatRoom? = nil
    ) {
        self.id = id
        self.content = content
        self.senderName = senderName
        self.senderId = senderId
        self.timestamp = timestamp
        self.isRead = isRead
        self.isSentByMe = isSentByMe
        self.statusRawValue = status.rawValue
        self.room = room
    }
}

// MARK: - Identifiable

extension Message: Identifiable {}

// MARK: - MessageStatus

/// メッセージの送信ステータス
enum MessageStatus: String, Codable, CaseIterable {
    /// 送信待ち（キュー中）
    case pending = "pending"

    /// 送信中
    case sending = "sending"

    /// 送信完了
    case sent = "sent"

    /// 配信済み
    case delivered = "delivered"

    /// 既読
    case read = "read"

    /// 送信失敗
    case failed = "failed"

    /// 表示用アイコン
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .sending: return "arrow.up.circle"
        case .sent: return "checkmark"
        case .delivered: return "checkmark.circle"
        case .read: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle"
        }
    }

    /// 日本語表示名
    var displayName: String {
        switch self {
        case .pending: return "送信待ち"
        case .sending: return "送信中"
        case .sent: return "送信済み"
        case .delivered: return "配信済み"
        case .read: return "既読"
        case .failed: return "送信失敗"
        }
    }
}
