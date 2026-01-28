//
//  GameScore.swift
//  AsaMultiplayerGame
//
//  スコア管理
//

import Foundation

/// ゲームスコア計算
struct GameScoreCalculator: Sendable {
    // MARK: - Constants

    /// 正解時の基本ポイント
    static let baseCorrectPoints = 100

    /// 描画者への正解ボーナス
    static let drawerBonus = 50

    /// 時間ボーナスの係数（残り時間1秒あたり）
    static let timeBonus = 3

    /// 最大時間ボーナス
    static let maxTimeBonus = 50

    // MARK: - Score Calculation

    /// 回答者のスコアを計算
    /// - Parameters:
    ///   - isCorrect: 正解したかどうか
    ///   - answerTimeSeconds: 回答にかかった時間（秒）
    ///   - roundTimeLimit: ラウンドの制限時間（秒）
    /// - Returns: 獲得ポイント
    static func calculateGuesserScore(
        isCorrect: Bool,
        answerTimeSeconds: TimeInterval,
        roundTimeLimit: Int
    ) -> Int {
        guard isCorrect else { return 0 }

        let basePoints = baseCorrectPoints
        let remainingTime = max(0, TimeInterval(roundTimeLimit) - answerTimeSeconds)
        let timeBonusPoints = min(Int(remainingTime) * timeBonus, maxTimeBonus)

        return basePoints + timeBonusPoints
    }

    /// 描画者のスコアを計算（回答者が正解した場合のボーナス）
    static func calculateDrawerScore(guesserGotCorrect: Bool) -> Int {
        guesserGotCorrect ? drawerBonus : 0
    }

    /// 総合勝者を判定
    /// - Parameter players: プレイヤー配列
    /// - Returns: 勝者（引き分けの場合は複数）
    static func determineWinners(from players: [Player]) -> [Player] {
        guard !players.isEmpty else { return [] }

        let maxScore = players.map(\.score).max() ?? 0
        return players.filter { $0.score == maxScore }
    }
}

/// 最終結果
struct GameResult: Codable, Sendable, Equatable {
    /// 勝者のプレイヤーID
    let winnerIds: [String]

    /// 各プレイヤーの最終スコア
    let finalScores: [String: Int]

    /// 引き分けかどうか
    let isDraw: Bool

    /// ゲーム終了時刻
    let endedAt: Date

    /// ラウンド履歴
    let rounds: [GameRound]

    init(
        winnerIds: [String],
        finalScores: [String: Int],
        isDraw: Bool = false,
        endedAt: Date = Date(),
        rounds: [GameRound] = []
    ) {
        self.winnerIds = winnerIds
        self.finalScores = finalScores
        self.isDraw = isDraw
        self.endedAt = endedAt
        self.rounds = rounds
    }

    /// プレイヤー配列から結果を生成
    static func from(players: [Player], rounds: [GameRound]) -> GameResult {
        let winners = GameScoreCalculator.determineWinners(from: players)
        let finalScores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.score) })

        return GameResult(
            winnerIds: winners.map(\.id),
            finalScores: finalScores,
            isDraw: winners.count > 1,
            rounds: rounds
        )
    }
}
