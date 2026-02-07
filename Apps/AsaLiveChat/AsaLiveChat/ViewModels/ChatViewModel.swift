//
//  ChatViewModel.swift
//  AsaLiveChat
//
//  チャット画面のViewModel
//

import Foundation

/// チャット画面を管理するViewModel
///
/// WebSocket接続、メッセージ送受信、入力状態を管理します。
@MainActor
@Observable
final class ChatViewModel {
    // MARK: - Dependencies

    private let webSocketService: WebSocketServiceProtocol
    private let dataService: ChatDataService
    private let userSettings: UserSettings

    // MARK: - State

    /// 現在のルーム
    let room: ChatRoom

    /// メッセージ一覧
    private(set) var messages: [Message] = []

    /// 接続状態
    private(set) var connectionState: ConnectionState = .disconnected

    /// オンラインユーザー一覧
    private(set) var onlineUsers: [ChatUser] = []

    /// タイピング中のユーザー名リスト
    private(set) var typingUsers: [String] = []

    /// エラーメッセージ
    private(set) var errorMessage: String?

    // MARK: - UI State

    /// 入力中のメッセージテキスト
    var messageText = ""

    /// ユーザー一覧シート表示フラグ
    var showingUserList = false

    /// ルーム情報シート表示フラグ
    var showingRoomInfo = false

    /// 参加者シート表示フラグ
    var showingParticipants = false

    /// 退出確認アラート表示フラグ
    var showingLeaveConfirm = false

    // MARK: - Private State

    private var typingTimer: Timer?
    private var isTyping = false

    // MARK: - Computed Properties

    /// 現在のユーザー
    var currentUser: ChatUser {
        userSettings.asChatUser
    }

    /// タイピング中の表示テキスト
    var typingIndicatorText: String? {
        guard !typingUsers.isEmpty else { return nil }

        if typingUsers.count == 1 {
            return "\(typingUsers[0])が入力中..."
        } else if typingUsers.count == 2 {
            return "\(typingUsers[0])と\(typingUsers[1])が入力中..."
        } else {
            return "\(typingUsers.count)人が入力中..."
        }
    }

    /// エコーサーバーに接続中かどうか
    private var isEchoServer: Bool {
        let url = userSettings.serverURL.lowercased()
        return url.contains("echo") || url.contains("socketsbay.com")
    }

    /// 送信可能かどうか
    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        connectionState.isConnected
    }

    /// 送信可能かどうか（エイリアス）
    var canSendMessage: Bool {
        canSend
    }

    /// タイピング中の表示テキスト（エイリアス）
    var typingDisplayText: String? {
        typingIndicatorText
    }

    // MARK: - Helper Methods

    /// メッセージに送信者名を表示すべきかどうか
    func shouldShowSenderName(for message: Message) -> Bool {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return true
        }

        // 最初のメッセージは常に表示
        if index == 0 {
            return true
        }

        // 前のメッセージと異なる送信者なら表示
        let previousMessage = messages[index - 1]
        return previousMessage.senderId != message.senderId
    }

    /// タイピングインジケータを送信
    func sendTypingIndicator() {
        updateTypingState()
    }

    // MARK: - Initialization

    init(
        room: ChatRoom,
        dataService: ChatDataService,
        userSettings: UserSettings,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.room = room
        self.dataService = dataService
        self.userSettings = userSettings
        // 実際のWebSocketServiceをデフォルトで使用
        self.webSocketService = webSocketService ?? WebSocketService()

        // 既存のメッセージを読み込み
        self.messages = dataService.fetchMessages(for: room)

        setupWebSocketCallbacks()
    }

    // MARK: - Setup

    private func setupWebSocketCallbacks() {
        webSocketService.onMessageReceived = { [weak self] message in
            Task { @MainActor in
                self?.handleReceivedMessage(message)
            }
        }

        webSocketService.onConnectionStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.connectionState = state
            }
        }
    }

    // MARK: - Connection

    /// ルームに接続
    func connect() async {
        // 未読をクリア
        dataService.markMessagesAsRead(in: room)

        // WebSocket接続
        guard let url = URL(string: userSettings.serverURL) else {
            errorMessage = "無効なサーバーURLです"
            return
        }

        do {
            try await webSocketService.connect(
                to: url,
                roomCode: room.roomCode,
                user: currentUser
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 再接続
    func reconnect() async {
        await connect()
    }

    /// 接続を切断
    func disconnect() {
        webSocketService.disconnect()
        onlineUsers = []
        typingUsers = []
    }

    // MARK: - Sending Messages

    /// メッセージを送信
    func sendMessage() async {
        guard canSend else { return }

        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""

        // ローカルにメッセージを保存
        let message = dataService.createMessage(
            content: content,
            senderName: currentUser.name,
            senderId: currentUser.id,
            isSentByMe: true,
            room: room
        )

        messages.append(message)

        // WebSocketで送信
        let wsMessage = WebSocketMessage.message(
            roomCode: room.roomCode,
            content: content,
            sender: currentUser
        )

        do {
            try await webSocketService.send(wsMessage)
            message.status = .sent
            dataService.save()
        } catch {
            message.status = .failed
            dataService.save()
            errorMessage = error.localizedDescription
        }

        // タイピング状態をリセット
        stopTypingIndicator()
    }

    /// タイピング状態を更新
    func updateTypingState() {
        guard userSettings.sendTypingIndicator,
              connectionState.isConnected else { return }

        // タイピング開始を送信
        if !isTyping {
            isTyping = true
            Task {
                try? await webSocketService.sendTypingIndicator(
                    isTyping: true,
                    user: currentUser
                )
            }
        }

        // タイマーをリセット（3秒後に停止）
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopTypingIndicator()
            }
        }
    }

    private func stopTypingIndicator() {
        guard isTyping else { return }

        isTyping = false
        typingTimer?.invalidate()
        typingTimer = nil

        Task {
            try? await webSocketService.sendTypingIndicator(
                isTyping: false,
                user: currentUser
            )
        }
    }

    // MARK: - Receiving Messages

    private func handleReceivedMessage(_ wsMessage: WebSocketMessage) {
        switch wsMessage.type {
        case .message:
            handleChatMessage(wsMessage)

        case .typing:
            handleTypingMessage(wsMessage)

        case .join:
            handleUserJoined(wsMessage)

        case .leave:
            handleUserLeft(wsMessage)

        case .userList:
            handleUserList(wsMessage)

        case .error:
            if let errorMsg = wsMessage.payload.errorMessage {
                errorMessage = errorMsg
            }

        default:
            break
        }
    }

    private func handleChatMessage(_ wsMessage: WebSocketMessage) {
        guard let content = wsMessage.payload.content,
              let senderId = wsMessage.payload.senderId,
              let senderName = wsMessage.payload.senderName else { return }

        // 自分のメッセージが返ってきた場合
        if senderId == currentUser.id {
            if isEchoServer {
                // エコーサーバー: "Echo 🔊" として表示
                let message = dataService.createMessage(
                    content: content,
                    senderName: "Echo 🔊",
                    senderId: "echo-server",
                    isSentByMe: false,
                    room: room
                )
                messages.append(message)
            }
            // 通常サーバー: スキップ（既にローカル保存済み）
            return
        }

        // 他のユーザーからのメッセージ
        let message = dataService.createMessage(
            content: content,
            senderName: senderName,
            senderId: senderId,
            isSentByMe: false,
            room: room
        )

        messages.append(message)

        // タイピング表示から削除
        typingUsers.removeAll { $0 == senderName }
    }

    private func handleTypingMessage(_ wsMessage: WebSocketMessage) {
        guard let userName = wsMessage.payload.userName,
              let isTyping = wsMessage.payload.isTyping,
              userName != currentUser.name else { return }

        if isTyping {
            if !typingUsers.contains(userName) {
                typingUsers.append(userName)
            }
        } else {
            typingUsers.removeAll { $0 == userName }
        }
    }

    private func handleUserJoined(_ wsMessage: WebSocketMessage) {
        guard let user = wsMessage.payload.user,
              user.id != currentUser.id else { return }

        if !onlineUsers.contains(where: { $0.id == user.id }) {
            onlineUsers.append(user)
        }
    }

    private func handleUserLeft(_ wsMessage: WebSocketMessage) {
        guard let userId = wsMessage.payload.userId else { return }
        onlineUsers.removeAll { $0.id == userId }
        let currentOnlineUsers = onlineUsers
        typingUsers.removeAll { typingName in
            !currentOnlineUsers.contains { user in user.name == typingName }
        }
    }

    private func handleUserList(_ wsMessage: WebSocketMessage) {
        if let users = wsMessage.payload.users {
            onlineUsers = users.filter { $0.id != currentUser.id }
        }
    }

    // MARK: - Error Handling

    /// エラーをクリア
    func clearError() {
        errorMessage = nil
    }
}
