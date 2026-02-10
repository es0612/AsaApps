import Foundation

// MARK: - スコアリングプロトコル

/// スコア計算結果
public struct ScoreResult: Sendable {
    /// 獲得した星の数
    public let earnedStars: Int
    /// コンボボーナス
    public let comboBonus: Int
    /// パーフェクトボーナス
    public let perfectBonus: Int
    /// 合計星数
    public let totalStars: Int

    public init(earnedStars: Int, comboBonus: Int, perfectBonus: Int) {
        self.earnedStars = earnedStars
        self.comboBonus = comboBonus
        self.perfectBonus = perfectBonus
        self.totalStars = earnedStars + comboBonus + perfectBonus
    }
}

/// ゲームスコア計算サービスのインターフェース
public protocol GameScoring: Sendable {
    /// 1問の正解に対する星数を計算
    func starsForCorrectAnswer(
        difficulty: DifficultyLevel,
        currentCombo: Int
    ) -> Int

    /// セッション全体のスコアを計算
    func calculateSessionScore(
        correctAnswers: Int,
        totalQuestions: Int,
        maxCombo: Int,
        difficulty: DifficultyLevel
    ) -> ScoreResult
}
