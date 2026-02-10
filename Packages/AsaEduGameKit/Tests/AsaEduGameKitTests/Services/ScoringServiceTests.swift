import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - ScoringService テスト

@Suite("ScoringService テスト")
struct ScoringServiceTests {

    let service = ScoringService()

    @Test("基本星数 - easy")
    func testBaseStarsEasy() {
        // easy: 倍率1.0 → round(1.0 * 1.0) = 1星（コンボなし）
        let stars = service.starsForCorrectAnswer(difficulty: .easy, currentCombo: 0)
        #expect(stars == 1)
    }

    @Test("基本星数 - normal")
    func testBaseStarsNormal() {
        // normal: 倍率1.5 → round(1.0 * 1.5) = 2星（コンボなし）
        let stars = service.starsForCorrectAnswer(difficulty: .normal, currentCombo: 0)
        #expect(stars == 2)
    }

    @Test("基本星数 - hard")
    func testBaseStarsHard() {
        // hard: 倍率2.0 → round(1.0 * 2.0) = 2星（コンボなし）
        let stars = service.starsForCorrectAnswer(difficulty: .hard, currentCombo: 0)
        #expect(stars == 2)
    }

    @Test("コンボボーナス - 3連続")
    func testComboBonus3() {
        // コンボ3: +1星
        let stars = service.starsForCorrectAnswer(difficulty: .easy, currentCombo: 3)
        let baseStars = 1 // easy基本星
        #expect(stars == baseStars + 1)
    }

    @Test("コンボボーナス - 5連続")
    func testComboBonus5() {
        // コンボ5: +2星
        let stars = service.starsForCorrectAnswer(difficulty: .easy, currentCombo: 5)
        let baseStars = 1
        #expect(stars == baseStars + 2)
    }

    @Test("コンボボーナス - 10連続")
    func testComboBonus10() {
        // コンボ10: +5星
        let stars = service.starsForCorrectAnswer(difficulty: .easy, currentCombo: 10)
        let baseStars = 1
        #expect(stars == baseStars + 5)
    }

    @Test("コンボなし")
    func testNoComboBonus() {
        // コンボ0: ボーナスなし
        let stars = service.starsForCorrectAnswer(difficulty: .easy, currentCombo: 0)
        #expect(stars == 1)

        // コンボ2: まだボーナスなし
        let stars2 = service.starsForCorrectAnswer(difficulty: .easy, currentCombo: 2)
        #expect(stars2 == 1)
    }

    @Test("セッションスコア計算 - easy全問正解")
    func testSessionScoreEasyAllCorrect() {
        let result = service.calculateSessionScore(
            correctAnswers: 5,
            totalQuestions: 5,
            maxCombo: 5,
            difficulty: .easy
        )
        // 基本星: round(5 * 1.0) = 5
        #expect(result.earnedStars == 5)
        // コンボボーナス: 5連続 → +2
        #expect(result.comboBonus == 2)
        // パーフェクトボーナス: 全問正解 → +3
        #expect(result.perfectBonus == 3)
        // 合計: 5 + 2 + 3 = 10
        #expect(result.totalStars == 10)
    }

    @Test("セッションスコア計算 - パーフェクトボーナス")
    func testSessionScorePerfectBonus() {
        let result = service.calculateSessionScore(
            correctAnswers: 8,
            totalQuestions: 8,
            maxCombo: 3,
            difficulty: .normal
        )
        // パーフェクト（全問正解）でボーナス+3
        #expect(result.perfectBonus == 3)
        #expect(result.earnedStars == 12) // round(8 * 1.5) = 12
    }

    @Test("セッションスコア計算 - normal+コンボ")
    func testSessionScoreNormalWithCombo() {
        let result = service.calculateSessionScore(
            correctAnswers: 6,
            totalQuestions: 8,
            maxCombo: 4,
            difficulty: .normal
        )
        // 基本星: round(6 * 1.5) = 9
        #expect(result.earnedStars == 9)
        // コンボボーナス: 4連続 → +1
        #expect(result.comboBonus == 1)
        // パーフェクトでないのでボーナスなし
        #expect(result.perfectBonus == 0)
        // 合計: 9 + 1 + 0 = 10
        #expect(result.totalStars == 10)
    }
}
