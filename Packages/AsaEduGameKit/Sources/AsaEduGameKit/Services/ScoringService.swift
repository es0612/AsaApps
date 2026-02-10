import Foundation

// MARK: - スコアリングサービス

/// 星/ポイント計算サービス
/// - 正解1問 = 1星 x 難易度倍率 (easy:1.0, normal:1.5, hard:2.0)
/// - コンボ3: +1星, コンボ5: +2星, コンボ10: +5星
/// - パーフェクト（全問正解）: +3星
public final class ScoringService: GameScoring {

    // MARK: - 定数

    /// パーフェクトボーナスの星数
    private static let perfectBonusStars: Int = 3

    /// コンボボーナスのしきい値と星数
    private static let comboBonuses: [(threshold: Int, bonus: Int)] = [
        (10, 5),
        (5, 2),
        (3, 1),
    ]

    // MARK: - Init

    public init() {}

    // MARK: - GameScoring

    /// 1問の正解に対する星数を計算
    public func starsForCorrectAnswer(
        difficulty: DifficultyLevel,
        currentCombo: Int
    ) -> Int {
        // 基本星数 = 1 x 難易度倍率（四捨五入）
        let baseStars = Int(round(1.0 * difficulty.starMultiplier))

        // コンボボーナス
        let comboBonus = calculateComboBonus(combo: currentCombo)

        return baseStars + comboBonus
    }

    /// セッション全体のスコアを計算
    public func calculateSessionScore(
        correctAnswers: Int,
        totalQuestions: Int,
        maxCombo: Int,
        difficulty: DifficultyLevel
    ) -> ScoreResult {
        // 基本星数 = 正解数 x 難易度倍率（四捨五入）
        let earnedStars = Int(round(Double(correctAnswers) * difficulty.starMultiplier))

        // コンボボーナス
        let comboBonus = calculateComboBonus(combo: maxCombo)

        // パーフェクトボーナス
        let isPerfect = totalQuestions > 0 && correctAnswers == totalQuestions
        let perfectBonus = isPerfect ? Self.perfectBonusStars : 0

        return ScoreResult(
            earnedStars: earnedStars,
            comboBonus: comboBonus,
            perfectBonus: perfectBonus
        )
    }

    // MARK: - ヘルパー

    /// コンボ数に応じたボーナス星数を計算
    private func calculateComboBonus(combo: Int) -> Int {
        for (threshold, bonus) in Self.comboBonuses {
            if combo >= threshold {
                return bonus
            }
        }
        return 0
    }
}
