//
//  GameRoom.swift
//  AsaMultiplayerGame
//
//  ゲームルーム管理
//

import Foundation

/// ゲームルーム
struct GameRoom: Codable, Sendable, Identifiable, Equatable {
    // MARK: - Properties

    /// ルームID（ルームコード）
    let id: String

    /// ルームコード（6文字の英数字）
    var roomCode: String { id }

    /// ホストプレイヤーID
    let hostId: String

    /// 参加プレイヤー
    var players: [Player]

    /// ゲーム設定
    var settings: GameSettings

    /// 現在のゲームフェーズ
    var phase: GamePhase

    /// 現在のラウンド
    var currentRound: GameRound?

    /// 過去のラウンド結果
    var roundHistory: [GameRound]

    /// 作成日時
    let createdAt: Date

    // MARK: - Initialization

    init(
        id: String = GameRoom.generateRoomCode(),
        hostId: String,
        players: [Player] = [],
        settings: GameSettings = GameSettings(),
        phase: GamePhase = .waiting,
        currentRound: GameRound? = nil,
        roundHistory: [GameRound] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.hostId = hostId
        self.players = players
        self.settings = settings
        self.phase = phase
        self.currentRound = currentRound
        self.roundHistory = roundHistory
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// ホストプレイヤー
    var host: Player? {
        players.first { $0.id == hostId }
    }

    /// 全員がReady状態か
    var allPlayersReady: Bool {
        players.count >= 2 && players.allSatisfy { $0.isReady }
    }

    /// ゲーム開始可能か
    var canStartGame: Bool {
        players.count >= 2 && allPlayersReady
    }

    // MARK: - Static Methods

    /// ランダムなルームコードを生成（6文字の英数字）
    static func generateRoomCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}
