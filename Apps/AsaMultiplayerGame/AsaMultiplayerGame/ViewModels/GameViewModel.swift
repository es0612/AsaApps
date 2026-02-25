//
//  GameViewModel.swift
//  AsaMultiplayerGame
//
//  メインゲームロジックのViewModel
//

import Foundation
import SwiftUI

/// メインゲームロジックを管理するViewModel
///
/// ゲームの状態管理、通信処理、スコア計算などを担当します。
@MainActor
@Observable
final class GameViewModel {
    // MARK: - Properties

    /// 現在表示している画面
    var currentScreen: GameScreen = .mainMenu

    /// 接続状態
    var connectionState: ConnectionState = .disconnected

    /// 現在のルーム
    var room: GameRoom?

    /// ルームコード（表示用）
    var roomCode: String?

    /// 現在のプレイヤー（自分）
    var localPlayer: Player?

    /// プレイヤーリスト
    var players: [Player] = []

    /// 現在のゲームフェーズ
    var gamePhase: GamePhase = .waiting

    /// 現在のラウンド情報
    var currentRound: GameRound?

    /// 自分の役割
    var myRole: PlayerRole = .spectator

    /// 描画キャンバス
    var canvas: DrawingCanvas = DrawingCanvas()

    /// 残り時間
    var remainingTime: Int = 0

    /// カウントダウン中の数字
    var countdownNumber: Int = 3

    /// 回答入力テキスト
    var answerInput: String = ""

    /// 前回のラウンド結果
    var lastRoundResult: RoundResult?

    /// 最終結果
    var gameResult: GameResult?

    /// 使用済みのお題
    var usedWords: Set<String> = []

    /// エラーメッセージ
    var errorMessage: String?

    /// ローディング状態
    var isLoading = false

    /// ゲーム設定
    var settings: GameSettings = GameSettings()

    // MARK: - Private Properties

    private var webSocketService: any GameWebSocketServiceProtocol
    private var gameTimer: Timer?
    private var aiActionTask: Task<Void, Never>?

    // MARK: - Initialization

    init(webSocketService: any GameWebSocketServiceProtocol = MockGameWebSocketService()) {
        self.webSocketService = webSocketService
        setupWebSocketCallbacks()
    }

    // MARK: - Setup

    private func setupWebSocketCallbacks() {
        webSocketService.onConnectionStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.connectionState = state
            }
        }

        webSocketService.onMessageReceived = { [weak self] message in
            Task { @MainActor in
                self?.handleMessage(message)
            }
        }
    }

    // MARK: - Room Management

    /// ルームを作成
    func createRoom(playerName: String, avatarEmoji: String = "🎨") async {
        isLoading = true
        errorMessage = nil

        let player = Player.localPlayer(name: playerName, avatarEmoji: avatarEmoji)
        self.localPlayer = player

        let newRoomCode = GameRoom.generateRoomCode()
        self.roomCode = newRoomCode

        var newPlayer = player
        newPlayer.isHost = true
        newPlayer.isReady = true

        self.players = [newPlayer]
        self.localPlayer = newPlayer

        // ローカルモードではMockServiceを使用
        if settings.isLocalMode {
            // MockServiceの場合は即座に接続
            do {
                let url = URL(string: "wss://localhost/game")!
                try await webSocketService.connect(to: url, roomCode: newRoomCode, player: newPlayer)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
        currentScreen = .lobby
    }

    /// ルームに参加
    func joinRoom(roomCode: String, playerName: String, avatarEmoji: String = "🎨") async {
        isLoading = true
        errorMessage = nil

        let player = Player(name: playerName, avatarEmoji: avatarEmoji)
        self.localPlayer = player
        self.roomCode = roomCode.uppercased()

        // ローカルモードではMockServiceを使用
        if settings.isLocalMode {
            do {
                let url = URL(string: "wss://localhost/game")!
                try await webSocketService.connect(to: url, roomCode: roomCode.uppercased(), player: player)
                self.players.append(player)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
        currentScreen = .lobby
    }

    /// ルームから退出
    func leaveRoom() {
        webSocketService.disconnect()
        resetGameState()
        currentScreen = .mainMenu
    }

    // MARK: - Ready State

    /// Ready状態をトグル
    func toggleReady() async {
        guard var player = localPlayer, let roomCode = roomCode else { return }

        player.isReady.toggle()
        self.localPlayer = player

        // プレイヤーリストを更新
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index] = player
        }

        // Ready状態変更を送信
        let message = GameMessage.ready(roomCode: roomCode, playerId: player.id, isReady: player.isReady)
        try? await webSocketService.send(message)
    }

    /// ゲームを開始
    func startGame() async {
        guard let roomCode = roomCode,
              localPlayer?.isHost == true,
              canStartGame else { return }

        gamePhase = .countdown
        currentScreen = .playing

        // ゲーム開始メッセージを送信
        let message = GameMessage.gameStart(roomCode: roomCode, settings: settings)
        try? await webSocketService.send(message)

        // カウントダウン開始
        await startCountdown()
    }

    /// ゲーム開始可能かどうか
    var canStartGame: Bool {
        players.count >= 2 && players.allSatisfy { $0.isReady }
    }

    // MARK: - Game Flow

    /// カウントダウン開始
    private func startCountdown() async {
        countdownNumber = settings.countdownDuration

        for i in (1...settings.countdownDuration).reversed() {
            countdownNumber = i
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        // カウントダウン終了後、最初のラウンドを開始
        await startNextRound()
    }

    /// 次のラウンドを開始
    private func startNextRound() async {
        let roundNumber = (currentRound?.roundNumber ?? 0) + 1

        guard roundNumber <= settings.roundCount else {
            // ゲーム終了
            await endGame()
            return
        }

        // 描く側と当てる側を決定（交互に）
        let drawerIndex = (roundNumber - 1) % players.count
        let guesserIndex = (drawerIndex + 1) % players.count

        let drawerId = players[drawerIndex].id
        let guesserId = players[guesserIndex].id

        // お題を選択
        let word = WordProvider.randomWord(excluding: usedWords)
        usedWords.insert(word)

        // 自分の役割を設定
        if localPlayer?.id == drawerId {
            myRole = .drawer
        } else if localPlayer?.id == guesserId {
            myRole = .guesser
        } else {
            myRole = .spectator
        }

        // ラウンド情報を設定
        let round = GameRound(
            roundNumber: roundNumber,
            totalRounds: settings.roundCount,
            drawerId: drawerId,
            guesserId: guesserId,
            word: word,
            startTime: Date(),
            timeLimit: settings.roundTimeLimit
        )

        currentRound = round
        gamePhase = .drawing
        remainingTime = settings.roundTimeLimit
        canvas = DrawingCanvas()
        answerInput = ""
        lastRoundResult = nil

        // ラウンド開始メッセージを送信
        if let roomCode = roomCode {
            let message = GameMessage.roundStart(roomCode: roomCode, round: round)
            try? await webSocketService.send(message)
        }

        // タイマー開始
        startRoundTimer()

        // AIプレイヤーの行動をスケジュール
        scheduleAIAction()
    }

    /// ラウンドタイマー開始
    private func startRoundTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.handleTimerTick()
            }
        }
    }

    /// タイマーのTick処理
    private func handleTimerTick() {
        guard remainingTime > 0 else {
            // 時間切れ
            Task {
                await handleTimeUp()
            }
            return
        }
        remainingTime -= 1
    }

    /// 時間切れ処理
    private func handleTimeUp() async {
        // 既にラウンド結果処理済み（AIが先に回答した場合など）なら無視
        guard gamePhase == .drawing else { return }

        gameTimer?.invalidate()
        gameTimer = nil

        // 時間切れの結果を生成
        let result = RoundResult(
            isCorrect: false,
            answerTime: nil,
            earnedPoints: 0,
            answer: nil
        )

        await processRoundResult(result)
    }

    /// 回答を送信
    func submitAnswer() async {
        guard myRole == .guesser,
              !answerInput.isEmpty,
              let round = currentRound,
              let roomCode = roomCode,
              let playerId = localPlayer?.id else { return }

        // 正解判定
        let isCorrect = WordProvider.isCorrectAnswer(answerInput, correctWord: round.word)
        let answerTime = Date().timeIntervalSince(round.startTime)

        // スコア計算
        let guesserPoints = GameScoreCalculator.calculateGuesserScore(
            isCorrect: isCorrect,
            answerTimeSeconds: answerTime,
            roundTimeLimit: round.timeLimit
        )

        let result = RoundResult(
            isCorrect: isCorrect,
            answerTime: answerTime,
            earnedPoints: guesserPoints,
            answer: answerInput
        )

        // 回答を送信
        let message = GameMessage.answer(roomCode: roomCode, playerId: playerId, answer: answerInput)
        try? await webSocketService.send(message)

        // ラウンド結果を処理
        await processRoundResult(result)
    }

    /// ラウンド結果を処理
    private func processRoundResult(_ result: RoundResult) async {
        gameTimer?.invalidate()
        gameTimer = nil
        aiActionTask?.cancel()
        aiActionTask = nil

        lastRoundResult = result
        gamePhase = .roundResult

        // スコアを更新
        if result.isCorrect {
            // 回答者にポイント追加
            if let guesserIndex = players.firstIndex(where: { $0.id == currentRound?.guesserId }) {
                players[guesserIndex].score += result.earnedPoints
            }

            // 描画者にボーナスポイント追加
            let drawerBonus = GameScoreCalculator.calculateDrawerScore(guesserGotCorrect: true)
            if let drawerIndex = players.firstIndex(where: { $0.id == currentRound?.drawerId }) {
                players[drawerIndex].score += drawerBonus
            }
        }

        // 現在のラウンドに結果を設定
        if var round = currentRound {
            round.result = result
            currentRound = round
        }

        // 結果表示時間後に次のラウンドへ
        try? await Task.sleep(nanoseconds: UInt64(settings.resultDisplayDuration) * 1_000_000_000)

        await startNextRound()
    }

    /// ゲーム終了
    private func endGame() async {
        gameTimer?.invalidate()
        gameTimer = nil

        gamePhase = .finished

        // 最終結果を生成
        let result = GameResult.from(players: players, rounds: [])
        self.gameResult = result

        // ゲーム終了メッセージを送信
        if let roomCode = roomCode {
            let message = GameMessage.gameEnd(roomCode: roomCode, result: result)
            try? await webSocketService.send(message)
        }

        currentScreen = .result
    }

    // MARK: - Drawing

    /// ストロークを追加
    func addStroke(_ stroke: DrawingStroke) async {
        guard myRole == .drawer else { return }

        canvas.addStroke(stroke)

        // ストロークを送信
        if let roomCode = roomCode {
            let message = GameMessage.drawingStroke(roomCode: roomCode, stroke: stroke)
            try? await webSocketService.send(message)
        }
    }

    /// 描画をクリア
    func clearDrawing() async {
        guard myRole == .drawer else { return }

        canvas.clear()

        // クリアを送信
        if let roomCode = roomCode {
            let message = GameMessage.drawingClear(roomCode: roomCode)
            try? await webSocketService.send(message)
        }
    }

    /// 描画をUndo
    func undoDrawing() async {
        guard myRole == .drawer else { return }

        canvas.undoLastStroke()

        // Undoを送信
        if let roomCode = roomCode {
            let message = GameMessage.drawingUndo(roomCode: roomCode)
            try? await webSocketService.send(message)
        }
    }

    // MARK: - Message Handling

    private func handleMessage(_ message: GameMessage) {
        switch message.type {
        case .join:
            handlePlayerJoin(message)

        case .leave:
            handlePlayerLeave(message)

        case .ready:
            handleReady(message)

        case .playerList:
            handlePlayerList(message)

        case .gameStart:
            handleGameStart(message)

        case .roundStart:
            handleRoundStart(message)

        case .drawingStroke:
            handleDrawingStroke(message)

        case .drawingClear:
            handleDrawingClear()

        case .drawingUndo:
            handleDrawingUndo()

        case .answer:
            handleAnswer(message)

        case .answerResult:
            handleAnswerResult(message)

        case .roundEnd:
            break // 現在は使用していない

        case .gameEnd:
            handleGameEnd(message)

        case .error:
            handleError(message)

        case .ping, .pong, .sync:
            break
        }
    }

    private func handlePlayerJoin(_ message: GameMessage) {
        guard let player = message.payload.player else { return }

        // 自分自身でなければプレイヤーリストに追加
        if player.id != localPlayer?.id {
            if !players.contains(where: { $0.id == player.id }) {
                players.append(player)
            }
        }
    }

    private func handlePlayerLeave(_ message: GameMessage) {
        guard let playerId = message.payload.playerId else { return }
        players.removeAll { $0.id == playerId }
    }

    private func handleReady(_ message: GameMessage) {
        guard let playerId = message.payload.playerId,
              let isReady = message.payload.isReady else { return }

        if let index = players.firstIndex(where: { $0.id == playerId }) {
            players[index].isReady = isReady
        }
    }

    private func handlePlayerList(_ message: GameMessage) {
        guard let newPlayers = message.payload.players else { return }
        players = newPlayers
    }

    private func handleGameStart(_ message: GameMessage) {
        if let newSettings = message.payload.settings {
            settings = newSettings
        }
        gamePhase = .countdown
        currentScreen = .playing
    }

    private func handleRoundStart(_ message: GameMessage) {
        guard let round = message.payload.round else { return }
        currentRound = round
        gamePhase = .drawing
        remainingTime = round.timeLimit
        canvas = DrawingCanvas()

        // 自分の役割を設定
        if localPlayer?.id == round.drawerId {
            myRole = .drawer
        } else if localPlayer?.id == round.guesserId {
            myRole = .guesser
        } else {
            myRole = .spectator
        }
    }

    private func handleDrawingStroke(_ message: GameMessage) {
        // 自分が描画者でない場合のみ受信ストロークを反映
        guard myRole != .drawer,
              let stroke = message.payload.stroke else { return }
        canvas.addStroke(stroke)
    }

    private func handleDrawingClear() {
        guard myRole != .drawer else { return }
        canvas.clear()
    }

    private func handleDrawingUndo() {
        guard myRole != .drawer else { return }
        canvas.undoLastStroke()
    }

    private func handleAnswer(_ message: GameMessage) {
        // 回答処理はホストが行う
        // 現在の実装ではローカルで処理
    }

    private func handleAnswerResult(_ message: GameMessage) {
        guard let result = message.payload.roundResult else { return }
        lastRoundResult = result
        gamePhase = .roundResult
    }

    private func handleGameEnd(_ message: GameMessage) {
        guard let result = message.payload.gameResult else { return }
        gameResult = result
        gamePhase = .finished
        currentScreen = .result
    }

    private func handleError(_ message: GameMessage) {
        errorMessage = message.payload.errorMessage
    }

    // MARK: - Reset

    /// ゲーム状態をリセット
    private func resetGameState() {
        room = nil
        roomCode = nil
        localPlayer = nil
        players = []
        gamePhase = .waiting
        currentRound = nil
        myRole = .spectator
        canvas = DrawingCanvas()
        remainingTime = 0
        answerInput = ""
        lastRoundResult = nil
        gameResult = nil
        usedWords = []
        errorMessage = nil
        gameTimer?.invalidate()
        gameTimer = nil
        aiActionTask?.cancel()
        aiActionTask = nil
    }

    // MARK: - AI Player Actions

    /// AIプレイヤーのIDを取得（"opponent-"プレフィックスで判別）
    private var aiPlayerId: String? {
        players.first { $0.id.hasPrefix("opponent-") }?.id
    }

    /// ラウンド開始時にAIの役割に応じた行動をスケジュール
    private func scheduleAIAction() {
        guard settings.isLocalMode, let aiId = aiPlayerId, let round = currentRound else { return }

        aiActionTask?.cancel()
        aiActionTask = Task { [weak self] in
            guard let self else { return }

            if round.guesserId == aiId {
                // AIが当てる側
                await self.performAIGuessing()
            } else if round.drawerId == aiId {
                // AIが描く側
                await self.performAIDrawing()
            }
        }
    }

    /// AIの回答行動（5-15秒後にランダム回答、正解率40%）
    private func performAIGuessing() async {
        guard let round = currentRound else { return }

        // 5-15秒のランダム待機
        let delay = Double.random(in: 5...15)
        do {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        } catch {
            return // キャンセルされた
        }

        // 既にラウンドが終了している場合は何もしない
        guard gamePhase == .drawing else { return }

        // 40%の確率で正解
        let isCorrect = Double.random(in: 0...1) < 0.4
        let answer: String
        if isCorrect {
            answer = round.word
        } else {
            // 別の単語をランダムに選択
            var wrongWord = WordProvider.randomWord(excluding: usedWords)
            // 偶然正解と一致した場合は別の単語を選び直す
            if WordProvider.isCorrectAnswer(wrongWord, correctWord: round.word) {
                wrongWord = WordProvider.randomWord()
            }
            answer = wrongWord
        }

        await processAIAnswer(answer: answer)
    }

    /// AIの描画行動（2秒後から0.8-1.5秒間隔で段階的ストローク追加）
    private func performAIDrawing() async {
        guard let round = currentRound else { return }

        // 2秒の初期待機
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
        } catch {
            return
        }

        // パターンからストロークを取得
        let strokes = AIDrawingPatterns.generateStrokes(for: round.word)

        // ストロークを段階的に追加
        for stroke in strokes {
            guard gamePhase == .drawing else { break }

            canvas.addStroke(stroke)

            // ストロークを送信（相手側にも表示させるため）
            if let roomCode = roomCode {
                let message = GameMessage.drawingStroke(roomCode: roomCode, stroke: stroke)
                try? await webSocketService.send(message)
            }

            // 0.8-1.5秒のランダム間隔
            let interval = Double.random(in: 0.8...1.5)
            do {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            } catch {
                return
            }
        }
    }

    /// AIの回答を処理してスコア更新
    private func processAIAnswer(answer: String) async {
        guard let round = currentRound else { return }

        // 正解判定
        let isCorrect = WordProvider.isCorrectAnswer(answer, correctWord: round.word)
        let answerTime = Date().timeIntervalSince(round.startTime)

        // スコア計算
        let guesserPoints = GameScoreCalculator.calculateGuesserScore(
            isCorrect: isCorrect,
            answerTimeSeconds: answerTime,
            roundTimeLimit: round.timeLimit
        )

        let result = RoundResult(
            isCorrect: isCorrect,
            answerTime: answerTime,
            earnedPoints: guesserPoints,
            answer: answer
        )

        await processRoundResult(result)
    }

    /// 新しいゲームを開始（同じルームで）
    func playAgain() async {
        // スコアをリセット
        for i in 0..<players.count {
            players[i].score = 0
            players[i].isReady = false
        }

        usedWords = []
        currentRound = nil
        lastRoundResult = nil
        gameResult = nil
        gamePhase = .waiting
        currentScreen = .lobby
    }

    /// メインメニューに戻る
    func returnToMainMenu() {
        webSocketService.disconnect()
        resetGameState()
        currentScreen = .mainMenu
    }
}
