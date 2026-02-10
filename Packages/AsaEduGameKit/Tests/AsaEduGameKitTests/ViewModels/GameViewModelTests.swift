import Testing
import Foundation
import SwiftData
@testable import AsaEduGameKit

// MARK: - GameViewModel テスト用Mock

/// テスト用の問題生成Mock
private struct MockQuestionGenerator: QuestionGenerating {
    func generateQuestions(mode: GameMode, difficulty: DifficultyLevel, count: Int) -> [GameQuestion] {
        (0 ..< count).map { i in
            GameQuestion(
                questionType: .addition,
                questionText: "\(i) + 1 = ?",
                options: ["0", "1", "\(i + 1)", "\(i + 2)"],
                correctAnswer: "\(i + 1)"
            )
        }
    }

    func generateQuestion(type: QuestionType, difficulty: DifficultyLevel) -> GameQuestion {
        GameQuestion(
            questionType: type,
            questionText: "1 + 1 = ?",
            options: ["1", "2", "3", "4"],
            correctAnswer: "2"
        )
    }
}

/// テスト用のスコアリングMock
private struct MockScoringService: GameScoring {
    func starsForCorrectAnswer(difficulty: DifficultyLevel, currentCombo: Int) -> Int {
        return 1
    }

    func calculateSessionScore(
        correctAnswers: Int,
        totalQuestions: Int,
        maxCombo: Int,
        difficulty: DifficultyLevel
    ) -> ScoreResult {
        ScoreResult(
            earnedStars: correctAnswers,
            comboBonus: maxCombo >= 3 ? 1 : 0,
            perfectBonus: correctAnswers == totalQuestions ? 3 : 0
        )
    }
}

/// テスト用の難易度調整Mock
private struct MockDifficultyService: DifficultyAdjusting {
    func recommendedDifficulty(
        currentDifficulty: DifficultyLevel,
        recentAccuracy: Double,
        consecutiveCorrect: Int,
        consecutiveWrong: Int
    ) -> DifficultyLevel {
        return currentDifficulty
    }

    func adjustAfterSession(
        currentDifficulty: DifficultyLevel,
        sessionAccuracy: Double
    ) -> DifficultyLevel {
        return currentDifficulty
    }
}

// MARK: - GameViewModel テスト

@Suite("GameViewModel テスト")
struct GameViewModelTests {

    /// テスト用のViewModelを作成するヘルパー
    @MainActor
    private func makeViewModel() -> (GameViewModel, EduGameDataService) {
        let dataService = EduGameDataService(inMemory: true)
        let vm = GameViewModel(
            dataService: dataService,
            questionGenerator: MockQuestionGenerator(),
            scoringService: MockScoringService(),
            difficultyService: MockDifficultyService()
        )
        return (vm, dataService)
    }

    @Test("初期状態")
    @MainActor
    func testInitialState() {
        let (vm, _) = makeViewModel()
        #expect(vm.gameState == .idle)
        #expect(vm.currentQuestion == nil)
        #expect(vm.score == 0)
        #expect(vm.currentCombo == 0)
        #expect(vm.maxCombo == 0)
        #expect(vm.correctCount == 0)
    }

    @Test("ゲーム開始")
    @MainActor
    func testStartGame() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)
        #expect(vm.gameState == .playing)
        #expect(vm.currentQuestion != nil)
        #expect(vm.questions.count == 5) // easy: 5問
        #expect(vm.gameMode == .mathQuiz)
        #expect(vm.difficulty == .easy)
    }

    @Test("正解提出")
    @MainActor
    func testSubmitCorrectAnswer() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)
        let correctAnswer = vm.currentQuestion!.correctAnswer

        vm.submitAnswer(correctAnswer)
        #expect(vm.correctCount == 1)
        #expect(vm.isAnswerCorrect == true)
    }

    @Test("不正解提出")
    @MainActor
    func testSubmitWrongAnswer() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)

        vm.submitAnswer("wrong_answer")
        #expect(vm.correctCount == 0)
        #expect(vm.isAnswerCorrect == false)
    }

    @Test("コンボ増加")
    @MainActor
    func testComboIncrease() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)

        // 1問目正解
        let answer1 = vm.currentQuestion!.correctAnswer
        vm.submitAnswer(answer1)
        #expect(vm.currentCombo == 1)

        // 次の問題に進む
        vm.moveToNextQuestion()

        // 2問目正解
        let answer2 = vm.currentQuestion!.correctAnswer
        vm.submitAnswer(answer2)
        #expect(vm.currentCombo == 2)
    }

    @Test("コンボリセット")
    @MainActor
    func testComboReset() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)

        // 1問目正解
        let answer1 = vm.currentQuestion!.correctAnswer
        vm.submitAnswer(answer1)
        #expect(vm.currentCombo == 1)

        // 次の問題に進む
        vm.moveToNextQuestion()

        // 2問目不正解
        vm.submitAnswer("wrong")
        #expect(vm.currentCombo == 0)
    }

    @Test("最大コンボ記録")
    @MainActor
    func testMaxComboTracking() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)

        // 2問連続正解
        vm.submitAnswer(vm.currentQuestion!.correctAnswer)
        vm.moveToNextQuestion()
        vm.submitAnswer(vm.currentQuestion!.correctAnswer)
        #expect(vm.maxCombo == 2)

        // 不正解でコンボリセット
        vm.moveToNextQuestion()
        vm.submitAnswer("wrong")
        #expect(vm.currentCombo == 0)
        // maxCombo は維持
        #expect(vm.maxCombo == 2)
    }

    @Test("スコア加算")
    @MainActor
    func testScoreIncrease() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)

        let answer = vm.currentQuestion!.correctAnswer
        vm.submitAnswer(answer)
        // MockScoringService は1星を返す
        #expect(vm.score == 1)
    }

    @Test("問題進行")
    @MainActor
    func testQuestionProgression() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)
        #expect(vm.currentQuestionIndex == 0)

        vm.submitAnswer(vm.currentQuestion!.correctAnswer)
        vm.moveToNextQuestion()
        #expect(vm.currentQuestionIndex == 1)
    }

    @Test("セッション完了")
    @MainActor
    func testSessionComplete() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)

        // 全問回答
        for _ in 0 ..< 5 {
            vm.submitAnswer(vm.currentQuestion!.correctAnswer)
            if vm.gameState != .sessionComplete {
                vm.moveToNextQuestion()
            }
        }

        #expect(vm.gameState == .sessionComplete)
    }

    @Test("ゲームリセット")
    @MainActor
    func testResetGame() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)
        vm.submitAnswer(vm.currentQuestion!.correctAnswer)

        vm.resetGame()
        #expect(vm.gameState == .idle)
        #expect(vm.currentQuestion == nil)
        #expect(vm.score == 0)
        #expect(vm.currentCombo == 0)
        #expect(vm.maxCombo == 0)
        #expect(vm.correctCount == 0)
        #expect(vm.questions.isEmpty)
        #expect(vm.sessionResult == nil)
        #expect(vm.newBadges.isEmpty)
    }

    @Test("セッション結果計算")
    @MainActor
    func testSessionResult() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)

        // 全問正解して完了
        for _ in 0 ..< 5 {
            vm.submitAnswer(vm.currentQuestion!.correctAnswer)
            if vm.gameState != .sessionComplete {
                vm.moveToNextQuestion()
            }
        }

        #expect(vm.sessionResult != nil)
        #expect(vm.sessionResult!.earnedStars > 0)
    }

    @Test("難易度easy問題数")
    @MainActor
    func testEasyQuestionCount() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .easy, profile: profile)
        #expect(vm.questions.count == 5)
    }

    @Test("難易度normal問題数")
    @MainActor
    func testNormalQuestionCount() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .normal, profile: profile)
        #expect(vm.questions.count == 8)
    }

    @Test("難易度hard問題数")
    @MainActor
    func testHardQuestionCount() throws {
        let (vm, dataService) = makeViewModel()
        let profile = try dataService.getOrCreateProfile()

        vm.startGame(mode: .mathQuiz, difficulty: .hard, profile: profile)
        #expect(vm.questions.count == 10)
    }
}
