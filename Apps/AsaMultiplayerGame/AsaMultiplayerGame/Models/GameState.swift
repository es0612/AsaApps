//
//  GameState.swift
//  AsaMultiplayerGame
//
//  ゲーム状態管理
//

import Foundation

/// 現在表示している画面
enum GameScreen: Equatable, Sendable {
    case mainMenu
    case lobby
    case playing
    case result
}

/// ゲームの状態
enum GamePhase: String, Codable, Sendable, Equatable {
    /// 待機中（ロビー）
    case waiting = "waiting"

    /// ラウンド開始前のカウントダウン
    case countdown = "countdown"

    /// 描画中
    case drawing = "drawing"

    /// 回答受付中
    case answering = "answering"

    /// ラウンド結果表示
    case roundResult = "roundResult"

    /// ゲーム終了
    case finished = "finished"
}

/// ラウンド情報
struct GameRound: Codable, Sendable, Equatable {
    /// 現在のラウンド番号（1から開始）
    let roundNumber: Int

    /// 総ラウンド数
    let totalRounds: Int

    /// 描く側のプレイヤーID
    let drawerId: String

    /// 当てる側のプレイヤーID
    let guesserId: String

    /// お題
    let word: String

    /// ラウンド開始時刻
    let startTime: Date

    /// 制限時間（秒）
    let timeLimit: Int

    /// ラウンド結果
    var result: RoundResult?
}

/// ラウンド結果
struct RoundResult: Codable, Sendable, Equatable {
    /// 正解したかどうか
    let isCorrect: Bool

    /// 回答に要した時間（秒）
    let answerTime: TimeInterval?

    /// 獲得ポイント
    let earnedPoints: Int

    /// 正解/不正解の回答
    let answer: String?
}

/// ゲーム設定
struct GameSettings: Codable, Sendable, Equatable {
    /// ラウンド数
    var roundCount: Int = 5

    /// 各ラウンドの制限時間（秒）
    var roundTimeLimit: Int = 30

    /// カウントダウン時間（秒）
    var countdownDuration: Int = 3

    /// 結果表示時間（秒）
    var resultDisplayDuration: Int = 5

    /// ローカル対戦モード
    var isLocalMode: Bool = false
}
