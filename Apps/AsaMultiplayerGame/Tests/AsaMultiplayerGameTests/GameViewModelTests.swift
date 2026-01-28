//
//  GameViewModelTests.swift
//  AsaMultiplayerGameTests
//
//  GameViewModelのユニットテスト
//

import Testing
import Foundation
@testable import AsaMultiplayerGame

@Suite("GameViewModel Tests")
struct GameViewModelTests {

    // MARK: - Room Management Tests

    @Test("ルーム作成が成功する")
    @MainActor
    func testCreateRoom() async {
        // Given
        let mockService = MockGameWebSocketService()
        let viewModel = GameViewModel(webSocketService: mockService)

        // When
        await viewModel.createRoom(playerName: "テストプレイヤー", avatarEmoji: "🎨")

        // Then
        #expect(viewModel.roomCode != nil)
        #expect(viewModel.roomCode?.count == 6)
        #expect(viewModel.localPlayer != nil)
        #expect(viewModel.localPlayer?.name == "テストプレイヤー")
        #expect(viewModel.localPlayer?.isHost == true)
        #expect(viewModel.currentScreen == .lobby)
    }

    @Test("プレイヤー名でルーム作成")
    @MainActor
    func testCreateRoomWithCustomName() async {
        // Given
        let viewModel = GameViewModel(webSocketService: MockGameWebSocketService())

        // When
        await viewModel.createRoom(playerName: "朝活パパ", avatarEmoji: "☕️")

        // Then
        #expect(viewModel.localPlayer?.name == "朝活パパ")
        #expect(viewModel.localPlayer?.avatarEmoji == "☕️")
    }

    @Test("ルームコードは6文字の英数字")
    @MainActor
    func testRoomCodeFormat() async {
        // Given
        let viewModel = GameViewModel(webSocketService: MockGameWebSocketService())

        // When
        await viewModel.createRoom(playerName: "テスト", avatarEmoji: "🎨")

        // Then
        let code = viewModel.roomCode ?? ""
        #expect(code.count == 6)
        #expect(code.allSatisfy { $0.isLetter || $0.isNumber })
        #expect(code == code.uppercased())
    }

    @Test("ルーム退出でリセットされる")
    @MainActor
    func testLeaveRoom() async {
        // Given
        let viewModel = GameViewModel(webSocketService: MockGameWebSocketService())
        await viewModel.createRoom(playerName: "テスト", avatarEmoji: "🎨")

        // When
        viewModel.leaveRoom()

        // Then
        #expect(viewModel.roomCode == nil)
        #expect(viewModel.localPlayer == nil)
        #expect(viewModel.players.isEmpty)
        #expect(viewModel.currentScreen == .mainMenu)
    }

    // MARK: - Ready State Tests

    @Test("Ready状態のトグル")
    @MainActor
    func testToggleReady() async {
        // Given
        let viewModel = GameViewModel(webSocketService: MockGameWebSocketService())
        await viewModel.createRoom(playerName: "テスト", avatarEmoji: "🎨")
        let initialReady = viewModel.localPlayer?.isReady ?? false

        // When
        await viewModel.toggleReady()

        // Then
        #expect(viewModel.localPlayer?.isReady == !initialReady)
    }

    // MARK: - Game Start Tests

    @Test("2人揃ってReadyでゲーム開始可能")
    @MainActor
    func testCanStartGame() async {
        // Given
        let viewModel = GameViewModel(webSocketService: MockGameWebSocketService())
        viewModel.players = [
            Player(name: "Player1", isReady: true, isHost: true),
            Player(name: "Player2", isReady: true, isHost: false)
        ]

        // Then
        #expect(viewModel.canStartGame == true)
    }

    @Test("1人だけではゲーム開始不可")
    @MainActor
    func testCannotStartWithOnePlayer() async {
        // Given
        let viewModel = GameViewModel(webSocketService: MockGameWebSocketService())
        viewModel.players = [
            Player(name: "Player1", isReady: true, isHost: true)
        ]

        // Then
        #expect(viewModel.canStartGame == false)
    }

    @Test("Ready状態でない人がいるとゲーム開始不可")
    @MainActor
    func testCannotStartWithNotReady() async {
        // Given
        let viewModel = GameViewModel(webSocketService: MockGameWebSocketService())
        viewModel.players = [
            Player(name: "Player1", isReady: true, isHost: true),
            Player(name: "Player2", isReady: false, isHost: false)
        ]

        // Then
        #expect(viewModel.canStartGame == false)
    }
}

// MARK: - Score Calculator Tests

@Suite("GameScoreCalculator Tests")
struct GameScoreCalculatorTests {

    @Test("正解時の基本スコア")
    func testCorrectAnswerBaseScore() {
        // When
        let score = GameScoreCalculator.calculateGuesserScore(
            isCorrect: true,
            answerTimeSeconds: 30,
            roundTimeLimit: 30
        )

        // Then
        #expect(score == 100) // 基本100点、時間ボーナス0
    }

    @Test("不正解時は0点")
    func testIncorrectAnswerZeroScore() {
        // When
        let score = GameScoreCalculator.calculateGuesserScore(
            isCorrect: false,
            answerTimeSeconds: 10,
            roundTimeLimit: 30
        )

        // Then
        #expect(score == 0)
    }

    @Test("早く答えると時間ボーナス")
    func testTimeBonus() {
        // When
        let score = GameScoreCalculator.calculateGuesserScore(
            isCorrect: true,
            answerTimeSeconds: 10,
            roundTimeLimit: 30
        )

        // Then
        // 基本100点 + 残り20秒 × 3点 = 100 + 50(上限) = 150点
        #expect(score == 150)
    }

    @Test("描画者のボーナススコア")
    func testDrawerBonus() {
        // When
        let scoreCorrect = GameScoreCalculator.calculateDrawerScore(guesserGotCorrect: true)
        let scoreIncorrect = GameScoreCalculator.calculateDrawerScore(guesserGotCorrect: false)

        // Then
        #expect(scoreCorrect == 50)
        #expect(scoreIncorrect == 0)
    }

    @Test("勝者判定")
    func testDetermineWinner() {
        // Given
        let players = [
            Player(id: "1", name: "Player1", score: 100),
            Player(id: "2", name: "Player2", score: 150),
            Player(id: "3", name: "Player3", score: 120)
        ]

        // When
        let winners = GameScoreCalculator.determineWinners(from: players)

        // Then
        #expect(winners.count == 1)
        #expect(winners.first?.id == "2")
    }

    @Test("引き分け判定")
    func testDetermineDraw() {
        // Given
        let players = [
            Player(id: "1", name: "Player1", score: 150),
            Player(id: "2", name: "Player2", score: 150)
        ]

        // When
        let winners = GameScoreCalculator.determineWinners(from: players)

        // Then
        #expect(winners.count == 2)
    }
}

// MARK: - Word Provider Tests

@Suite("WordProvider Tests")
struct WordProviderTests {

    @Test("ランダムなお題を取得")
    func testRandomWord() {
        // When
        let word = WordProvider.randomWord()

        // Then
        #expect(!word.isEmpty)
    }

    @Test("除外リストを考慮したお題取得")
    func testRandomWordWithExclusion() {
        // Given
        let usedWords: Set<String> = ["りんご", "バナナ", "いぬ"]

        // When
        let word = WordProvider.randomWord(excluding: usedWords)

        // Then
        #expect(!usedWords.contains(word))
    }

    @Test("正解判定 - 完全一致")
    func testCorrectAnswerExactMatch() {
        #expect(WordProvider.isCorrectAnswer("りんご", correctWord: "りんご"))
    }

    @Test("正解判定 - カタカナとひらがな")
    func testCorrectAnswerKatakanaHiragana() {
        #expect(WordProvider.isCorrectAnswer("リンゴ", correctWord: "りんご"))
        #expect(WordProvider.isCorrectAnswer("りんご", correctWord: "リンゴ"))
    }

    @Test("正解判定 - 空白を含む")
    func testCorrectAnswerWithWhitespace() {
        #expect(WordProvider.isCorrectAnswer("  りんご  ", correctWord: "りんご"))
    }

    @Test("不正解判定")
    func testIncorrectAnswer() {
        #expect(!WordProvider.isCorrectAnswer("みかん", correctWord: "りんご"))
    }
}

// MARK: - Drawing Data Tests

@Suite("DrawingData Tests")
struct DrawingDataTests {

    @Test("ストロークに点を追加")
    func testAddPointToStroke() {
        // Given
        var stroke = DrawingStroke(color: .black, lineWidth: 4)

        // When
        stroke.addPoint(CGPoint(x: 10, y: 20))
        stroke.addPoint(CGPoint(x: 30, y: 40))

        // Then
        #expect(stroke.points.count == 2)
        #expect(stroke.points[0].x == 10)
        #expect(stroke.points[0].y == 20)
    }

    @Test("キャンバスにストロークを追加")
    func testAddStrokeToCanvas() {
        // Given
        var canvas = DrawingCanvas()
        let stroke = DrawingStroke(
            points: [StrokePoint(x: 10, y: 20)],
            color: .red,
            lineWidth: 8
        )

        // When
        canvas.addStroke(stroke)

        // Then
        #expect(canvas.strokes.count == 1)
        #expect(canvas.strokes.first?.color == .red)
    }

    @Test("キャンバスのUndo")
    func testCanvasUndo() {
        // Given
        var canvas = DrawingCanvas()
        canvas.addStroke(DrawingStroke(color: .black, lineWidth: 4))
        canvas.addStroke(DrawingStroke(color: .red, lineWidth: 8))

        // When
        canvas.undoLastStroke()

        // Then
        #expect(canvas.strokes.count == 1)
        #expect(canvas.strokes.first?.color == .black)
    }

    @Test("キャンバスのクリア")
    func testCanvasClear() {
        // Given
        var canvas = DrawingCanvas()
        canvas.addStroke(DrawingStroke(color: .black, lineWidth: 4))
        canvas.addStroke(DrawingStroke(color: .red, lineWidth: 8))

        // When
        canvas.clear()

        // Then
        #expect(canvas.strokes.isEmpty)
    }
}

// MARK: - Game Message Tests

@Suite("GameMessage Tests")
struct GameMessageTests {

    @Test("参加メッセージのエンコード/デコード")
    func testJoinMessageCoding() throws {
        // Given
        let player = Player(name: "テストプレイヤー", avatarEmoji: "🎨")
        let message = GameMessage.join(roomCode: "ABC123", player: player)

        // When
        let jsonString = try message.toJSONString()
        let decoded = try GameMessage.from(string: jsonString)

        // Then
        #expect(decoded.type == .join)
        #expect(decoded.roomCode == "ABC123")
        #expect(decoded.payload.player?.name == "テストプレイヤー")
    }

    @Test("描画ストロークメッセージのエンコード/デコード")
    func testDrawingStrokeMessageCoding() throws {
        // Given
        let stroke = DrawingStroke(
            points: [StrokePoint(x: 10, y: 20), StrokePoint(x: 30, y: 40)],
            color: .blue,
            lineWidth: 6
        )
        let message = GameMessage.drawingStroke(roomCode: "XYZ789", stroke: stroke)

        // When
        let jsonString = try message.toJSONString()
        let decoded = try GameMessage.from(string: jsonString)

        // Then
        #expect(decoded.type == .drawingStroke)
        #expect(decoded.payload.stroke?.color == .blue)
        #expect(decoded.payload.stroke?.points.count == 2)
    }
}
