import Foundation

// MARK: - GameScore
/// スコア管理（Codable, Sendable準拠）
struct GameScore: Codable, Sendable, Equatable {
    // MARK: - Properties

    /// 現在のスコア
    var currentScore: Int = 0

    /// 現在のコンボ数
    var comboCount: Int = 0

    /// 最大コンボ数
    var maxCombo: Int = 0

    /// ヒットしたターゲット数
    var targetsHit: Int = 0

    /// 逃したターゲット数
    var targetsMissed: Int = 0

    // MARK: - Computed Properties

    /// コンボボーナス（最大+25点）
    var comboBonus: Int {
        min(comboCount * 5, 25)
    }

    /// 命中率（0.0〜1.0）
    var accuracy: Double {
        let total = targetsHit + targetsMissed
        guard total > 0 else { return 0 }
        return Double(targetsHit) / Double(total)
    }

    /// 命中率（パーセンテージ表示用）
    var accuracyPercentage: Int {
        Int(accuracy * 100)
    }

    // MARK: - Methods

    /// ヒット時の処理
    /// - Parameter points: 基本得点
    mutating func addHit(points: Int) {
        comboCount += 1
        maxCombo = max(maxCombo, comboCount)
        let totalPoints = points + comboBonus
        currentScore += totalPoints
        targetsHit += 1
    }

    /// ミス時の処理（ターゲット消失）
    mutating func addMiss() {
        comboCount = 0
        targetsMissed += 1
    }

    /// スコアをリセット
    mutating func reset() {
        currentScore = 0
        comboCount = 0
        maxCombo = 0
        targetsHit = 0
        targetsMissed = 0
    }

    // MARK: - High Score Persistence

    private static let highScoreKey = "AsaARGame_HighScore"

    /// ハイスコアを読み込み
    static func loadHighScore() -> Int {
        UserDefaults.standard.integer(forKey: highScoreKey)
    }

    /// ハイスコアを保存
    static func saveHighScore(_ score: Int) {
        let currentHigh = loadHighScore()
        if score > currentHigh {
            UserDefaults.standard.set(score, forKey: highScoreKey)
        }
    }

    /// 現在のスコアがハイスコアを更新したか
    func isNewHighScore() -> Bool {
        currentScore > Self.loadHighScore()
    }
}

// MARK: - GameScore Statistics
extension GameScore {
    /// ゲーム結果の統計情報
    struct Statistics: Sendable {
        let finalScore: Int
        let highScore: Int
        let isNewHighScore: Bool
        let accuracy: Int
        let maxCombo: Int
        let targetsHit: Int
        let targetsMissed: Int
    }

    /// 統計情報を生成
    func generateStatistics() -> Statistics {
        Statistics(
            finalScore: currentScore,
            highScore: max(currentScore, Self.loadHighScore()),
            isNewHighScore: isNewHighScore(),
            accuracy: accuracyPercentage,
            maxCombo: maxCombo,
            targetsHit: targetsHit,
            targetsMissed: targetsMissed
        )
    }
}
