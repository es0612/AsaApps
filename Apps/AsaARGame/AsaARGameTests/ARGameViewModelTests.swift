import Testing
@testable import AsaARGame

// MARK: - ARGameViewModelTests
@Suite("ARGameViewModel Tests")
struct ARGameViewModelTests {

    // MARK: - 初期状態テスト

    @Test("初期状態が正しい")
    @MainActor
    func testInitialState() async {
        let viewModel = ARGameViewModel()

        #expect(viewModel.gameState == .idle)
        #expect(viewModel.score.currentScore == 0)
        #expect(viewModel.remainingTime == 60.0)
        #expect(!viewModel.isPlaneDetected)
        #expect(!viewModel.showingGameOver)
    }

    // MARK: - 状態遷移テスト

    @Test("平面検出でready状態に遷移")
    @MainActor
    func testPlaneDetectedTransition() async {
        let viewModel = ARGameViewModel()
        viewModel.gameState = .waitingForPlane

        viewModel.onPlaneDetected()

        #expect(viewModel.isPlaneDetected)
        #expect(viewModel.gameState == .ready)
    }

    @Test("ゲーム終了でgameOver状態に遷移")
    @MainActor
    func testEndGameTransition() async {
        let viewModel = ARGameViewModel()
        viewModel.gameState = .playing

        viewModel.endGame()

        #expect(viewModel.gameState == .gameOver)
        #expect(viewModel.showingGameOver)
    }

    // MARK: - ゲーム開始条件テスト

    @Test("ready状態でゲーム開始可能")
    @MainActor
    func testCanStartGameWhenReady() async {
        #expect(GameState.ready.canStartGame)
    }

    @Test("gameOver状態でゲーム開始可能")
    @MainActor
    func testCanStartGameWhenGameOver() async {
        #expect(GameState.gameOver.canStartGame)
    }

    @Test("playing状態ではゲーム開始不可")
    @MainActor
    func testCannotStartGameWhenPlaying() async {
        #expect(!GameState.playing.canStartGame)
    }

    @Test("waitingForPlane状態ではゲーム開始不可")
    @MainActor
    func testCannotStartGameWhenWaiting() async {
        #expect(!GameState.waitingForPlane.canStartGame)
    }

    // MARK: - スコア操作テスト

    @Test("スコアリセットが正しく動作")
    @MainActor
    func testScoreReset() async {
        let viewModel = ARGameViewModel()
        viewModel.score.addHit(points: 100)
        viewModel.score.addHit(points: 50)

        viewModel.score.reset()

        #expect(viewModel.score.currentScore == 0)
        #expect(viewModel.score.comboCount == 0)
    }

    // MARK: - エラーハンドリングテスト

    @Test("エラークリアが動作")
    @MainActor
    func testClearError() async {
        let viewModel = ARGameViewModel()
        viewModel.errorMessage = "テストエラー"

        viewModel.clearError()

        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - 一時停止テスト

    @Test("playing状態で一時停止可能")
    @MainActor
    func testPauseGame() async {
        let viewModel = ARGameViewModel()
        viewModel.gameState = .playing

        viewModel.pauseGame()

        #expect(viewModel.gameState == .paused)
        #expect(viewModel.showingPauseMenu)
    }

    @Test("paused状態で再開可能")
    @MainActor
    func testResumeGame() async {
        let viewModel = ARGameViewModel()
        viewModel.gameState = .paused
        viewModel.showingPauseMenu = true

        viewModel.resumeGame()

        #expect(viewModel.gameState == .playing)
        #expect(!viewModel.showingPauseMenu)
    }

    // MARK: - 統計情報テスト

    @Test("ゲーム統計が正しく取得できる")
    @MainActor
    func testGameStatistics() async {
        let viewModel = ARGameViewModel()
        viewModel.score.addHit(points: 10)
        viewModel.score.addHit(points: 25)
        viewModel.score.addMiss()

        let stats = viewModel.gameStatistics

        #expect(stats.targetsHit == 2)
        #expect(stats.targetsMissed == 1)
        #expect(stats.maxCombo == 2)
    }
}
