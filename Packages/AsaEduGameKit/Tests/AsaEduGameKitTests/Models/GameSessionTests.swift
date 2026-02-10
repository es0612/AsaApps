import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - GameSession テスト

@Suite("GameSession テスト")
struct GameSessionTests {

    @Test("デフォルト初期化")
    func testDefaultInit() {
        let session = GameSession()
        #expect(session.gameMode == .mathQuiz)
        #expect(session.difficulty == .easy)
        #expect(session.totalQuestions == 0)
        #expect(session.correctAnswers == 0)
        #expect(session.earnedStars == 0)
        #expect(session.maxCombo == 0)
        #expect(session.endedAt == nil)
    }

    @Test("ゲームモード設定と取得")
    func testGameModeComputedProperty() {
        let session = GameSession(gameMode: .hiraganaPractice)
        #expect(session.gameMode == .hiraganaPractice)
        #expect(session.gameModeRawValue == "hiraganaPractice")

        // setter テスト
        session.gameMode = .shapePuzzle
        #expect(session.gameMode == .shapePuzzle)
        #expect(session.gameModeRawValue == "shapePuzzle")
    }

    @Test("難易度設定と取得")
    func testDifficultyComputedProperty() {
        let session = GameSession(difficulty: .hard)
        #expect(session.difficulty == .hard)
        #expect(session.difficultyRawValue == "hard")

        // setter テスト
        session.difficulty = .normal
        #expect(session.difficulty == .normal)
        #expect(session.difficultyRawValue == "normal")
    }

    @Test("正答率計算 - 正常")
    func testAccuracyNormal() {
        let session = GameSession(totalQuestions: 8)
        session.totalQuestions = 8
        session.correctAnswers = 6
        #expect(session.accuracy == 0.75)
    }

    @Test("正答率計算 - ゼロ問題")
    func testAccuracyZeroQuestions() {
        let session = GameSession()
        session.totalQuestions = 0
        #expect(session.accuracy == 0.0)
    }

    @Test("正答率パーセンテージ")
    func testAccuracyPercentage() {
        let session = GameSession(totalQuestions: 10)
        session.totalQuestions = 10
        session.correctAnswers = 8
        #expect(session.accuracyPercentage == 80)
    }

    @Test("パーフェクト判定 - true")
    func testIsPerfectTrue() {
        let session = GameSession(totalQuestions: 5)
        session.totalQuestions = 5
        session.correctAnswers = 5
        #expect(session.isPerfect == true)
    }

    @Test("パーフェクト判定 - false")
    func testIsPerfectFalse() {
        let session = GameSession(totalQuestions: 5)
        session.totalQuestions = 5
        session.correctAnswers = 4
        #expect(session.isPerfect == false)
    }

    @Test("セッション完了")
    func testComplete() {
        let session = GameSession()
        // startedAt は init 時に設定済み
        session.complete()
        #expect(session.endedAt != nil)
        #expect(session.durationSeconds >= 0)
    }

    @Test("複数モードのセッション")
    func testMultipleModes() {
        for mode in GameMode.allCases {
            let session = GameSession(gameMode: mode)
            #expect(session.gameMode == mode)
        }
    }
}
