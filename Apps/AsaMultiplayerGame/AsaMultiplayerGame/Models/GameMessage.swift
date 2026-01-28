//
//  GameMessage.swift
//  AsaMultiplayerGame
//
//  WebSocket通信メッセージ
//

import Foundation

/// ゲームメッセージタイプ
enum GameMessageType: String, Codable, Sendable {
    // MARK: - 接続管理

    /// ルーム参加
    case join = "join"

    /// ルーム退出
    case leave = "leave"

    /// Ready状態変更
    case ready = "ready"

    /// プレイヤーリスト更新
    case playerList = "playerList"

    // MARK: - ゲーム進行

    /// ゲーム開始
    case gameStart = "gameStart"

    /// ラウンド開始
    case roundStart = "roundStart"

    /// ラウンド終了
    case roundEnd = "roundEnd"

    /// ゲーム終了
    case gameEnd = "gameEnd"

    // MARK: - 描画同期

    /// 描画ストローク
    case drawingStroke = "drawingStroke"

    /// 描画クリア
    case drawingClear = "drawingClear"

    /// 描画Undo
    case drawingUndo = "drawingUndo"

    // MARK: - 回答

    /// 回答送信
    case answer = "answer"

    /// 回答結果
    case answerResult = "answerResult"

    // MARK: - システム

    /// 接続確認（Ping）
    case ping = "ping"

    /// 接続応答（Pong）
    case pong = "pong"

    /// エラー
    case error = "error"

    /// 状態同期
    case sync = "sync"
}

/// ゲームメッセージ
struct GameMessage: Codable, Sendable {
    // MARK: - Properties

    /// メッセージタイプ
    let type: GameMessageType

    /// ルームコード
    let roomCode: String

    /// ペイロード
    let payload: GamePayload

    /// タイムスタンプ
    let timestamp: Date

    // MARK: - Initialization

    init(
        type: GameMessageType,
        roomCode: String,
        payload: GamePayload = GamePayload(),
        timestamp: Date = Date()
    ) {
        self.type = type
        self.roomCode = roomCode
        self.payload = payload
        self.timestamp = timestamp
    }

    // MARK: - Factory Methods

    /// 参加メッセージ
    static func join(roomCode: String, player: Player) -> GameMessage {
        GameMessage(
            type: .join,
            roomCode: roomCode,
            payload: GamePayload(player: player)
        )
    }

    /// 退出メッセージ
    static func leave(roomCode: String, playerId: String) -> GameMessage {
        GameMessage(
            type: .leave,
            roomCode: roomCode,
            payload: GamePayload(playerId: playerId)
        )
    }

    /// Ready状態変更メッセージ
    static func ready(roomCode: String, playerId: String, isReady: Bool) -> GameMessage {
        GameMessage(
            type: .ready,
            roomCode: roomCode,
            payload: GamePayload(playerId: playerId, isReady: isReady)
        )
    }

    /// ゲーム開始メッセージ
    static func gameStart(roomCode: String, settings: GameSettings) -> GameMessage {
        GameMessage(
            type: .gameStart,
            roomCode: roomCode,
            payload: GamePayload(settings: settings)
        )
    }

    /// ラウンド開始メッセージ
    static func roundStart(roomCode: String, round: GameRound) -> GameMessage {
        GameMessage(
            type: .roundStart,
            roomCode: roomCode,
            payload: GamePayload(round: round)
        )
    }

    /// 描画ストロークメッセージ
    static func drawingStroke(roomCode: String, stroke: DrawingStroke) -> GameMessage {
        GameMessage(
            type: .drawingStroke,
            roomCode: roomCode,
            payload: GamePayload(stroke: stroke)
        )
    }

    /// 描画クリアメッセージ
    static func drawingClear(roomCode: String) -> GameMessage {
        GameMessage(
            type: .drawingClear,
            roomCode: roomCode
        )
    }

    /// 描画Undoメッセージ
    static func drawingUndo(roomCode: String) -> GameMessage {
        GameMessage(
            type: .drawingUndo,
            roomCode: roomCode
        )
    }

    /// 回答メッセージ
    static func answer(roomCode: String, playerId: String, answer: String) -> GameMessage {
        GameMessage(
            type: .answer,
            roomCode: roomCode,
            payload: GamePayload(playerId: playerId, answer: answer)
        )
    }

    /// 回答結果メッセージ
    static func answerResult(roomCode: String, result: RoundResult) -> GameMessage {
        GameMessage(
            type: .answerResult,
            roomCode: roomCode,
            payload: GamePayload(roundResult: result)
        )
    }

    /// ゲーム終了メッセージ
    static func gameEnd(roomCode: String, result: GameResult) -> GameMessage {
        GameMessage(
            type: .gameEnd,
            roomCode: roomCode,
            payload: GamePayload(gameResult: result)
        )
    }

    /// エラーメッセージ
    static func error(roomCode: String, message: String, code: String? = nil) -> GameMessage {
        GameMessage(
            type: .error,
            roomCode: roomCode,
            payload: GamePayload(errorMessage: message, errorCode: code)
        )
    }
}

/// ゲームメッセージのペイロード
struct GamePayload: Codable, Sendable {
    // MARK: - Player Fields

    var player: Player?
    var playerId: String?
    var players: [Player]?
    var isReady: Bool?

    // MARK: - Game Fields

    var settings: GameSettings?
    var round: GameRound?
    var roundResult: RoundResult?
    var gameResult: GameResult?

    // MARK: - Drawing Fields

    var stroke: DrawingStroke?
    var canvas: DrawingCanvas?

    // MARK: - Answer Fields

    var answer: String?

    // MARK: - Error Fields

    var errorMessage: String?
    var errorCode: String?

    // MARK: - Initialization

    init(
        player: Player? = nil,
        playerId: String? = nil,
        players: [Player]? = nil,
        isReady: Bool? = nil,
        settings: GameSettings? = nil,
        round: GameRound? = nil,
        roundResult: RoundResult? = nil,
        gameResult: GameResult? = nil,
        stroke: DrawingStroke? = nil,
        canvas: DrawingCanvas? = nil,
        answer: String? = nil,
        errorMessage: String? = nil,
        errorCode: String? = nil
    ) {
        self.player = player
        self.playerId = playerId
        self.players = players
        self.isReady = isReady
        self.settings = settings
        self.round = round
        self.roundResult = roundResult
        self.gameResult = gameResult
        self.stroke = stroke
        self.canvas = canvas
        self.answer = answer
        self.errorMessage = errorMessage
        self.errorCode = errorCode
    }
}

// MARK: - JSON Encoding/Decoding

extension GameMessage {
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
            throw GameError.encodingFailed
        }
        return string
    }

    /// JSONデータからデコード
    static func from(data: Data) throws -> GameMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(GameMessage.self, from: data)
    }

    /// JSON文字列からデコード
    static func from(string: String) throws -> GameMessage {
        guard let data = string.data(using: .utf8) else {
            throw GameError.decodingFailed
        }
        return try from(data: data)
    }
}

// MARK: - GameError

/// ゲームエラー
enum GameError: Error, LocalizedError, Sendable {
    case connectionFailed(String)
    case disconnected
    case sendFailed(String)
    case receiveFailed(String)
    case encodingFailed
    case decodingFailed
    case invalidMessage
    case timeout
    case serverError(String)
    case roomNotFound
    case roomFull
    case gameAlreadyStarted
    case notYourTurn
    case invalidAnswer

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
        case .roomNotFound:
            return "ルームが見つかりません"
        case .roomFull:
            return "ルームが満員です"
        case .gameAlreadyStarted:
            return "ゲームはすでに開始しています"
        case .notYourTurn:
            return "あなたのターンではありません"
        case .invalidAnswer:
            return "無効な回答です"
        }
    }
}
