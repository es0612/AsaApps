import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - AdaptiveDifficulty テスト

@Suite("AdaptiveDifficulty テスト")
struct AdaptiveDifficultyTests {

    let service = AdaptiveDifficultyService()

    @Test("高正答率で難易度UP")
    func testHighAccuracyUpgrade() {
        let result = service.recommendedDifficulty(
            currentDifficulty: .easy,
            recentAccuracy: 0.95,
            consecutiveCorrect: 0,
            consecutiveWrong: 0
        )
        #expect(result == .normal)
    }

    @Test("低正答率で難易度DOWN")
    func testLowAccuracyDowngrade() {
        let result = service.recommendedDifficulty(
            currentDifficulty: .normal,
            recentAccuracy: 0.3,
            consecutiveCorrect: 0,
            consecutiveWrong: 0
        )
        #expect(result == .easy)
    }

    @Test("中間正答率で維持")
    func testMidAccuracyMaintain() {
        let result = service.recommendedDifficulty(
            currentDifficulty: .normal,
            recentAccuracy: 0.6,
            consecutiveCorrect: 0,
            consecutiveWrong: 0
        )
        #expect(result == .normal)
    }

    @Test("連続正解5で難易度UP")
    func testConsecutiveCorrectUpgrade() {
        let result = service.recommendedDifficulty(
            currentDifficulty: .easy,
            recentAccuracy: 0.5,
            consecutiveCorrect: 5,
            consecutiveWrong: 0
        )
        #expect(result == .normal)
    }

    @Test("連続不正解3で難易度DOWN")
    func testConsecutiveWrongDowngrade() {
        let result = service.recommendedDifficulty(
            currentDifficulty: .normal,
            recentAccuracy: 0.5,
            consecutiveCorrect: 0,
            consecutiveWrong: 3
        )
        #expect(result == .easy)
    }

    @Test("最高難易度で上限")
    func testMaxDifficultyCap() {
        let result = service.recommendedDifficulty(
            currentDifficulty: .hard,
            recentAccuracy: 0.95,
            consecutiveCorrect: 10,
            consecutiveWrong: 0
        )
        #expect(result == .hard)
    }

    @Test("最低難易度で下限")
    func testMinDifficultyFloor() {
        let result = service.recommendedDifficulty(
            currentDifficulty: .easy,
            recentAccuracy: 0.1,
            consecutiveCorrect: 0,
            consecutiveWrong: 10
        )
        #expect(result == .easy)
    }

    @Test("セッション後調整 - UP")
    func testAdjustAfterSessionUpgrade() {
        let result = service.adjustAfterSession(
            currentDifficulty: .easy,
            sessionAccuracy: 0.95
        )
        #expect(result == .normal)
    }

    @Test("セッション後調整 - DOWN")
    func testAdjustAfterSessionDowngrade() {
        let result = service.adjustAfterSession(
            currentDifficulty: .hard,
            sessionAccuracy: 0.3
        )
        #expect(result == .normal)
    }

    @Test("セッション後調整 - 維持")
    func testAdjustAfterSessionMaintain() {
        let result = service.adjustAfterSession(
            currentDifficulty: .normal,
            sessionAccuracy: 0.6
        )
        #expect(result == .normal)
    }

    @Test("境界値 - 正答率90%ちょうど")
    func testBoundaryUpgrade90() {
        // 90%ちょうどは >= 0.9 なので難易度UP
        let result = service.recommendedDifficulty(
            currentDifficulty: .easy,
            recentAccuracy: 0.9,
            consecutiveCorrect: 0,
            consecutiveWrong: 0
        )
        #expect(result == .normal)
    }

    @Test("境界値 - 正答率40%ちょうど")
    func testBoundaryDowngrade40() {
        // 40%ちょうどは <= 0.4 なので難易度DOWN
        let result = service.recommendedDifficulty(
            currentDifficulty: .normal,
            recentAccuracy: 0.4,
            consecutiveCorrect: 0,
            consecutiveWrong: 0
        )
        #expect(result == .easy)
    }
}
