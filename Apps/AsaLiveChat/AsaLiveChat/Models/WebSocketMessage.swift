//
//  WebSocketMessage.swift
//  AsaLiveChat
//
//  WebSocket通信用メッセージプロトコル
//

import Foundation

/// WebSocket通信で送受信するメッセージ
///
/// JSON形式でエンコード/デコードして通信に使用します。
///
/// ## メッセージ形式
/// ```json
/// {
///     "type": "message",
///     "roomCode": "ABC123",
///     "payload": {
///         "id": "uuid-string",
///         "content": "こんにちは！",
///         "senderId": "user-123",
///         "senderName": "パパ",
///         "timestamp": 1704067200
///     }
/// }
/// ```
struct WebSocketMessage: Codable, Sendable {
    // MARK: - Properties

    /// メッセージタイプ
    let type: MessageType

    /// ルームコード
    let roomCode: String

    /// メッセージペイロード
    let payload: MessagePayload

    // MARK: - Initialization

    init(type: MessageType, roomCode: String, payload: MessagePayload) {
        self.type = type
        self.roomCode = roomCode
        self.payload = payload
    }

    // MARK: - Factory Methods

    /// ルーム参加メッセージを作成
    static func join(roomCode: String, user: ChatUser) -> WebSocketMessage {
        WebSocketMessage(
            type: .join,
            roomCode: roomCode,
            payload: MessagePayload(user: user)
        )
    }

    /// ルーム退出メッセージを作成
    static func leave(roomCode: String, userId: String) -> WebSocketMessage {
        WebSocketMessage(
            type: .leave,
            roomCode: roomCode,
            payload: MessagePayload(userId: userId)
        )
    }

    /// テキストメッセージを作成
    static func message(
        roomCode: String,
        content: String,
        sender: ChatUser
    ) -> WebSocketMessage {
        WebSocketMessage(
            type: .message,
            roomCode: roomCode,
            payload: MessagePayload(
                id: UUID().uuidString,
                content: content,
                senderId: sender.id,
                senderName: sender.name,
                timestamp: Date()
            )
        )
    }

    /// タイピングインジケータメッセージを作成
    static func typing(roomCode: String, user: ChatUser, isTyping: Bool) -> WebSocketMessage {
        WebSocketMessage(
            type: .typing,
            roomCode: roomCode,
            payload: MessagePayload(
                userId: user.id,
                userName: user.name,
                isTyping: isTyping
            )
        )
    }

    /// ユーザーリスト要求メッセージを作成
    static func userList(roomCode: String) -> WebSocketMessage {
        WebSocketMessage(
            type: .userList,
            roomCode: roomCode,
            payload: MessagePayload()
        )
    }
}

// MARK: - MessageType

/// WebSocketメッセージの種類
enum MessageType: String, Codable, Sendable {
    /// ルーム参加
    case join = "join"

    /// ルーム退出
    case leave = "leave"

    /// テキストメッセージ
    case message = "message"

    /// タイピング状態
    case typing = "typing"

    /// ユーザーリスト
    case userList = "userList"

    /// エラー
    case error = "error"

    /// 接続確認（Ping/Pong）
    case ping = "ping"
    case pong = "pong"
}

// MARK: - MessagePayload

/// WebSocketメッセージのペイロード
///
/// メッセージタイプに応じて使用するフィールドが異なります。
struct MessagePayload: Codable, Sendable {
    // MARK: - Common Fields

    /// メッセージID
    var id: String?

    /// ユーザーID
    var userId: String?

    /// ユーザー名
    var userName: String?

    // MARK: - Message Fields

    /// メッセージ内容
    var content: String?

    /// 送信者ID
    var senderId: String?

    /// 送信者名
    var senderName: String?

    /// タイムスタンプ
    var timestamp: Date?

    // MARK: - Typing Fields

    /// タイピング中フラグ
    var isTyping: Bool?

    // MARK: - User List Fields

    /// ユーザーリスト
    var users: [ChatUser]?

    // MARK: - Join Fields

    /// 参加ユーザー情報
    var user: ChatUser?

    // MARK: - Error Fields

    /// エラーメッセージ
    var errorMessage: String?

    /// エラーコード
    var errorCode: String?

    // MARK: - Initialization

    init(
        id: String? = nil,
        userId: String? = nil,
        userName: String? = nil,
        content: String? = nil,
        senderId: String? = nil,
        senderName: String? = nil,
        timestamp: Date? = nil,
        isTyping: Bool? = nil,
        users: [ChatUser]? = nil,
        user: ChatUser? = nil,
        errorMessage: String? = nil,
        errorCode: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.content = content
        self.senderId = senderId
        self.senderName = senderName
        self.timestamp = timestamp
        self.isTyping = isTyping
        self.users = users
        self.user = user
        self.errorMessage = errorMessage
        self.errorCode = errorCode
    }
}

// MARK: - JSON Encoding/Decoding

extension WebSocketMessage {
    /// JSONデータにエンコード
    func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(self)
    }

    /// JSON文字列にエンコード
    func toJSONString() throws -> String {
        let data = try toJSONData()
        guard let string = String(data: data, encoding: .utf8) else {
            throw WebSocketError.encodingFailed
        }
        return string
    }

    /// JSONデータからデコード
    static func from(data: Data) throws -> WebSocketMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(WebSocketMessage.self, from: data)
    }

    /// JSON文字列からデコード
    static func from(string: String) throws -> WebSocketMessage {
        guard let data = string.data(using: .utf8) else {
            throw WebSocketError.decodingFailed
        }
        return try from(data: data)
    }
}

// MARK: - WebSocketError

/// WebSocket通信エラー
enum WebSocketError: Error, LocalizedError, Sendable {
    case connectionFailed(String)
    case disconnected
    case sendFailed(String)
    case receiveFailed(String)
    case encodingFailed
    case decodingFailed
    case invalidMessage
    case timeout
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "接続に失敗しました: \(message)"
        case .disconnected:
            return "接続が切断されました"
        case .sendFailed(let message):
            return "送信に失敗しました: \(message)"
        case .receiveFailed(let message):
            return "受信に失敗しました: \(message)"
        case .encodingFailed:
            return "メッセージのエンコードに失敗しました"
        case .decodingFailed:
            return "メッセージのデコードに失敗しました"
        case .invalidMessage:
            return "無効なメッセージです"
        case .timeout:
            return "タイムアウトしました"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        }
    }
}
