//
//  Player.swift
//  AsaMultiplayerGame
//
//  プレイヤーモデル
//

import Foundation

/// ゲームプレイヤー
struct Player: Codable, Sendable, Identifiable, Equatable {
    // MARK: - Properties

    /// 一意のID
    let id: String

    /// プレイヤー名
    var name: String

    /// アバター絵文字
    var avatarEmoji: String

    /// Ready状態
    var isReady: Bool

    /// ホストかどうか
    var isHost: Bool

    /// 現在のスコア
    var score: Int

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        name: String,
        avatarEmoji: String = "🎨",
        isReady: Bool = false,
        isHost: Bool = false,
        score: Int = 0
    ) {
        self.id = id
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.isReady = isReady
        self.isHost = isHost
        self.score = score
    }

    // MARK: - Factory Methods

    /// ローカルプレイヤーを作成
    static func localPlayer(name: String, avatarEmoji: String = "🎨") -> Player {
        Player(name: name, avatarEmoji: avatarEmoji, isHost: true)
    }
}

// MARK: - Player Role

/// プレイヤーの役割（描く側/当てる側）
enum PlayerRole: String, Codable, Sendable {
    case drawer = "drawer"
    case guesser = "guesser"
    case spectator = "spectator"
}
