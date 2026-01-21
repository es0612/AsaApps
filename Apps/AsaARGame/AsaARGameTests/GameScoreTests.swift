import Testing
@testable import AsaARGame

// MARK: - GameScoreTests
@Suite("GameScore Tests")
struct GameScoreTests {

    // MARK: - 初期状態テスト

    @Test("初期スコアは0")
    func testInitialScore() {
        let score = GameScore()

        #expect(score.currentScore == 0)
        #expect(score.comboCount == 0)
        #expect(score.maxCombo == 0)
        #expect(score.targetsHit == 0)
        #expect(score.targetsMissed == 0)
    }

    // MARK: - ヒット処理テスト

    @Test("ヒット時にスコアが加算される")
    func testAddHitAddsScore() {
        var score = GameScore()

        score.addHit(points: 10)

        #expect(score.currentScore == 10)
        #expect(score.targetsHit == 1)
    }

    @Test("連続ヒットでコンボが増加する")
    func testComboIncreases() {
        var score = GameScore()

        score.addHit(points: 10)
        #expect(score.comboCount == 1)

        score.addHit(points: 10)
        #expect(score.comboCount == 2)

        score.addHit(points: 10)
        #expect(score.comboCount == 3)
    }

    @Test("コンボボーナスが正しく計算される")
    func testComboBonus() {
        var score = GameScore()

        // 1ヒット目: コンボ1、ボーナス5点、合計10+5=15点
        score.addHit(points: 10)
        #expect(score.currentScore == 15)  // 10 + 5(コンボ1)

        // 2ヒット目: コンボ2、ボーナス10点、合計15+10+10=35点
        score.addHit(points: 10)
        #expect(score.currentScore == 35)  // 15 + 10 + 10(コンボ2)
    }

    @Test("コンボボーナスの上限は25点")
    func testComboBonusMaximum() {
        var score = GameScore()

        // 10回連続ヒット
        for _ in 0..<10 {
            score.addHit(points: 10)
        }

        #expect(score.comboBonus == 25)  // 上限確認
    }

    // MARK: - ミス処理テスト

    @Test("ミス時にコンボがリセットされる")
    func testMissResetsCombo() {
        var score = GameScore()

        score.addHit(points: 10)
        score.addHit(points: 10)
        #expect(score.comboCount == 2)

        score.addMiss()
        #expect(score.comboCount == 0)
        #expect(score.targetsMissed == 1)
    }

    @Test("ミスしても最大コンボは保持される")
    func testMaxComboPreserved() {
        var score = GameScore()

        // 5連続ヒット
        for _ in 0..<5 {
            score.addHit(points: 10)
        }
        #expect(score.maxCombo == 5)

        // ミス
        score.addMiss()
        #expect(score.comboCount == 0)
        #expect(score.maxCombo == 5)  // 最大コンボは保持

        // 3連続ヒット
        for _ in 0..<3 {
            score.addHit(points: 10)
        }
        #expect(score.maxCombo == 5)  // まだ5が最大
    }

    // MARK: - 命中率テスト

    @Test("命中率が正しく計算される")
    func testAccuracy() {
        var score = GameScore()

        // 3ヒット、1ミス = 75%
        score.addHit(points: 10)
        score.addHit(points: 10)
        score.addHit(points: 10)
        score.addMiss()

        #expect(score.accuracy == 0.75)
        #expect(score.accuracyPercentage == 75)
    }

    @Test("ヒットもミスもない場合の命中率は0")
    func testAccuracyWithNoAttempts() {
        let score = GameScore()

        #expect(score.accuracy == 0)
        #expect(score.accuracyPercentage == 0)
    }

    // MARK: - リセットテスト

    @Test("リセットで全ての値が初期化される")
    func testReset() {
        var score = GameScore()

        score.addHit(points: 10)
        score.addHit(points: 25)
        score.addMiss()

        score.reset()

        #expect(score.currentScore == 0)
        #expect(score.comboCount == 0)
        #expect(score.maxCombo == 0)
        #expect(score.targetsHit == 0)
        #expect(score.targetsMissed == 0)
    }

    // MARK: - 統計情報テスト

    @Test("統計情報が正しく生成される")
    func testGenerateStatistics() {
        var score = GameScore()

        // 5ヒット、2ミス
        for _ in 0..<3 {
            score.addHit(points: 10)
        }
        score.addMiss()
        for _ in 0..<2 {
            score.addHit(points: 25)
        }
        score.addMiss()

        let stats = score.generateStatistics()

        #expect(stats.finalScore == score.currentScore)
        #expect(stats.targetsHit == 5)
        #expect(stats.targetsMissed == 2)
        #expect(stats.maxCombo == 3)
    }
}
