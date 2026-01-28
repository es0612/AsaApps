//
//  MockGameWebSocketService.swift
//  AsaMultiplayerGame
//
//  テスト・開発用のモックWebSocketサービス
//

import Foundation

/// テスト・開発用のモックWebSocketサービス
///
/// 実際のサーバー接続なしでゲーム機能をテストできます。
/// ローカル対戦モードで使用します。
final class MockGameWebSocketService: GameWebSocketServiceProtocol, @unchecked Sendable {
    // MARK: - Properties

    private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            Task { @MainActor in
                onConnectionStateChanged?(connectionState)
            }
        }
    }

    private(set) var currentRoomCode: String?
    private var currentPlayer: Player?

    var onMessageReceived: (@Sendable (GameMessage) -> Void)?
    var onConnectionStateChanged: (@Sendable (ConnectionState) -> Void)?

    /// 接続遅延（シミュレート用）
    var connectionDelay: TimeInterval = 0.5

    /// 送信されたメッセージの履歴（テスト用）
    private(set) var sentMessages: [GameMessage] = []

    /// シミュレートする対戦相手
    private var opponent: Player?

    // MARK: - Connection

    func connect(to url: URL, roomCode: String, player: Player) async throws {
        currentRoomCode = roomCode
        currentPlayer = player

        connectionState = .connecting

        // 接続をシミュレート
        try await Task.sleep(nanoseconds: UInt64(connectionDelay * 1_000_000_000))

        connectionState = .connected

        // 参加通知をシミュレート
        let joinMessage = GameMessage(
            type: .join,
            roomCode: roomCode,
            payload: GamePayload(player: player)
        )

        Task { @MainActor in
            self.onMessageReceived?(joinMessage)
        }

        // 対戦相手を自動生成（ローカルモード用）
        await simulateOpponentJoin(roomCode: roomCode)
    }

    func disconnect() {
        currentRoomCode = nil
        currentPlayer = nil
        opponent = nil
        connectionState = .disconnected
    }

    func send(_ message: GameMessage) async throws {
        guard connectionState.isConnected else {
            throw GameError.disconnected
        }

        // 送信履歴に追加
        sentMessages.append(message)

        // 送信メッセージをエコー（自分のメッセージとして受信）
        Task { @MainActor in
            self.onMessageReceived?(message)
        }

        // メッセージタイプに応じた応答をシミュレート
        await simulateResponse(to: message)
    }

    // MARK: - Simulation

    /// 対戦相手の参加をシミュレート
    private func simulateOpponentJoin(roomCode: String) async {
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

        opponent = Player(
            id: "opponent-\(UUID().uuidString.prefix(8))",
            name: "AIプレイヤー",
            avatarEmoji: "🤖",
            isReady: false,
            isHost: false
        )

        guard let opponent = opponent else { return }

        // 対戦相手の参加メッセージ
        let opponentJoinMessage = GameMessage(
            type: .join,
            roomCode: roomCode,
            payload: GamePayload(player: opponent)
        )

        Task { @MainActor in
            self.onMessageReceived?(opponentJoinMessage)
        }

        // 対戦相手のReady状態をシミュレート
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

        let readyMessage = GameMessage(
            type: .ready,
            roomCode: roomCode,
            payload: GamePayload(playerId: opponent.id, isReady: true)
        )

        Task { @MainActor in
            self.onMessageReceived?(readyMessage)
        }
    }

    /// メッセージへの応答をシミュレート
    private func simulateResponse(to message: GameMessage) async {
        guard currentRoomCode != nil else { return }

        switch message.type {
        case .drawingStroke, .drawingClear, .drawingUndo:
            // 描画メッセージはそのまま相手に届く（エコーのみ）
            break

        case .answer:
            // 回答メッセージの処理はGameViewModelで行う
            break

        case .ready:
            // 自分のReady状態変更は処理済み
            break

        case .gameStart:
            // ゲーム開始はホストが制御
            break

        default:
            break
        }
    }

    // MARK: - Test Helpers

    /// 送信履歴をクリア
    func clearSentMessages() {
        sentMessages.removeAll()
    }

    /// 特定のメッセージを直接受信させる（テスト用）
    func injectMessage(_ message: GameMessage) {
        Task { @MainActor in
            self.onMessageReceived?(message)
        }
    }

    /// 対戦相手の回答をシミュレート
    func simulateOpponentAnswer(answer: String, isCorrect: Bool, delay: TimeInterval = 2.0) async {
        guard let roomCode = currentRoomCode, let opponent = opponent else { return }

        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        let answerMessage = GameMessage.answer(
            roomCode: roomCode,
            playerId: opponent.id,
            answer: answer
        )

        Task { @MainActor in
            self.onMessageReceived?(answerMessage)
        }
    }
}
