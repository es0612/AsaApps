//
//  GameWebSocketService.swift
//  AsaMultiplayerGame
//
//  URLSessionWebSocketTaskを使用したWebSocket通信サービス
//

import Foundation

/// WebSocket通信サービスの実装
///
/// URLSessionWebSocketTaskを使用してリアルタイム通信を行います。
///
/// ## 機能
/// - 接続/切断管理
/// - 自動再接続（指数バックオフ）
/// - メッセージ送受信
/// - ハートビート（Ping/Pong）
final class GameWebSocketService: GameWebSocketServiceProtocol, @unchecked Sendable {
    // MARK: - Properties

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var pingTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5

    private var serverURL: URL?
    private var currentPlayer: Player?

    private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            Task { @MainActor in
                onConnectionStateChanged?(connectionState)
            }
        }
    }

    private(set) var currentRoomCode: String?

    var onMessageReceived: (@Sendable (GameMessage) -> Void)?
    var onConnectionStateChanged: (@Sendable (ConnectionState) -> Void)?

    // MARK: - Initialization

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: configuration)
    }

    // MARK: - Connection

    func connect(to url: URL, roomCode: String, player: Player) async throws {
        // 既存の接続があれば切断
        if connectionState.isConnected {
            disconnect()
        }

        self.serverURL = url
        self.currentRoomCode = roomCode
        self.currentPlayer = player
        self.reconnectAttempts = 0

        connectionState = .connecting

        do {
            // WebSocket接続を開始
            let task = urlSession.webSocketTask(with: url)
            self.webSocketTask = task
            task.resume()

            // 接続成功
            connectionState = .connected

            // 参加メッセージを送信
            let joinMessage = GameMessage.join(roomCode: roomCode, player: player)
            try await send(joinMessage)

            // メッセージ受信ループを開始
            startReceiving()

            // ハートビートを開始
            startHeartbeat()

        } catch {
            connectionState = .failed(error.localizedDescription)
            throw GameError.connectionFailed(error.localizedDescription)
        }
    }

    func disconnect() {
        // 退出メッセージを送信（同期的に試行）
        if let roomCode = currentRoomCode, let playerId = currentPlayer?.id {
            let leaveMessage = GameMessage.leave(roomCode: roomCode, playerId: playerId)
            if let data = try? leaveMessage.toJSONString() {
                webSocketTask?.send(.string(data)) { _ in }
            }
        }

        // タイマー停止
        pingTimer?.invalidate()
        pingTimer = nil

        // WebSocket切断
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        // 状態リセット
        currentRoomCode = nil
        currentPlayer = nil
        connectionState = .disconnected
    }

    // MARK: - Sending

    func send(_ message: GameMessage) async throws {
        guard connectionState.isConnected, let task = webSocketTask else {
            throw GameError.disconnected
        }

        do {
            let jsonString = try message.toJSONString()
            try await task.send(.string(jsonString))
        } catch {
            throw GameError.sendFailed(error.localizedDescription)
        }
    }

    // MARK: - Receiving

    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleReceivedMessage(message)
                // 次のメッセージを待つ
                self.startReceiving()

            case .failure(let error):
                print("受信エラー: \(error)")
                self.handleDisconnection()
            }
        }
    }

    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            do {
                let gameMessage = try GameMessage.from(string: text)
                Task { @MainActor in
                    self.onMessageReceived?(gameMessage)
                }
            } catch {
                print("メッセージのデコードに失敗: \(error)")
            }

        case .data(let data):
            do {
                let gameMessage = try GameMessage.from(data: data)
                Task { @MainActor in
                    self.onMessageReceived?(gameMessage)
                }
            } catch {
                print("メッセージのデコードに失敗: \(error)")
            }

        @unknown default:
            break
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("Pingエラー: \(error)")
                self?.handleDisconnection()
            }
        }
    }

    // MARK: - Reconnection

    private func handleDisconnection() {
        guard connectionState.isConnected || connectionState == .connecting else { return }

        connectionState = .disconnected
        attemptReconnect()
    }

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts,
              let url = serverURL,
              let roomCode = currentRoomCode,
              let player = currentPlayer else {
            connectionState = .failed("再接続の上限に達しました")
            return
        }

        reconnectAttempts += 1
        connectionState = .reconnecting(attempt: reconnectAttempts)

        // 指数バックオフで再接続
        let delay = Double(min(pow(2.0, Double(reconnectAttempts)), 30))

        Task {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            try await connect(to: url, roomCode: roomCode, player: player)
        }
    }
}
