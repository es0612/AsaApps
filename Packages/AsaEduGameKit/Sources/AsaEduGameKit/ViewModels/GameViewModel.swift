import Foundation
import SpriteKit

// MARK: - メインゲーム制御ViewModel

/// ゲームプレイ全体のフロー制御、スコア管理、SpriteKit連携を担当
/// GameSceneDelegateに準拠し、SpriteKitシーンからのイベントを受け取る
@Observable
@MainActor
public final class GameViewModel: GameSceneDelegate {

    // MARK: - Dependencies

    /// データサービス（セッション・記録の永続化）
    private let dataService: EduGameDataServiceProtocol

    /// 問題生成サービス
    private let questionGenerator: QuestionGenerating

    /// スコア計算サービス
    private let scoringService: GameScoring

    /// 難易度調整サービス
    private let difficultyService: DifficultyAdjusting

    // MARK: - Game State

    /// 現在のゲーム状態
    public var gameState: EduGameState = .idle

    /// 現在表示中の問題
    public var currentQuestion: GameQuestion?

    /// セッションの全問題リスト
    public var questions: [GameQuestion] = []

    /// 現在の問題インデックス
    public var currentQuestionIndex: Int = 0

    /// ユーザーが選択した回答
    public var selectedAnswer: String?

    /// 回答が正解かどうか
    public var isAnswerCorrect: Bool?

    // MARK: - Score State

    /// 現在のスコア（星の数）
    public var score: Int = 0

    /// 現在の連続正解コンボ数
    public var currentCombo: Int = 0

    /// セッション中の最大コンボ数
    public var maxCombo: Int = 0

    /// 正解数
    public var correctCount: Int = 0

    /// 連続正解数（難易度調整用）
    public var consecutiveCorrect: Int = 0

    /// 連続不正解数（難易度調整用）
    public var consecutiveWrong: Int = 0

    // MARK: - Session State

    /// 現在のゲームモード
    public var gameMode: GameMode = .mathQuiz

    /// 現在の難易度
    public var difficulty: DifficultyLevel = .easy

    /// 現在のゲームセッション（SwiftData永続化用）
    public var currentSession: GameSession?

    /// セッション完了時のスコア結果
    public var sessionResult: ScoreResult?

    /// セッション中に新たに解除されたバッジ一覧
    public var newBadges: [BadgeDefinition] = []

    // MARK: - Timer

    /// 残り時間（秒）
    public var remainingTime: TimeInterval = 0

    /// タイマー（CLAUDE.mdルール#2: nonisolated(unsafe)を使用）
    nonisolated(unsafe) var timer: Timer?

    // MARK: - Private

    /// 問題の回答開始時刻（回答時間計測用）
    private var questionStartTime: Date?

    /// 現在のプロフィール
    private var currentProfile: UserProfile?

    // MARK: - Init

    public init(
        dataService: EduGameDataServiceProtocol,
        questionGenerator: QuestionGenerating,
        scoringService: GameScoring,
        difficultyService: DifficultyAdjusting
    ) {
        self.dataService = dataService
        self.questionGenerator = questionGenerator
        self.scoringService = scoringService
        self.difficultyService = difficultyService
    }

    // MARK: - Deinit

    deinit {
        timer?.invalidate()
    }

    // MARK: - Game Flow

    /// ゲームを開始する
    /// - Parameters:
    ///   - mode: ゲームモード
    ///   - difficulty: 難易度レベル
    ///   - profile: プレイするユーザープロフィール
    public func startGame(mode: GameMode, difficulty: DifficultyLevel, profile: UserProfile) {
        // 状態をリセット
        resetGame()

        self.gameMode = mode
        self.difficulty = difficulty
        self.currentProfile = profile

        // 問題を生成
        let questionCount = difficulty.questionsPerSession
        questions = questionGenerator.generateQuestions(
            mode: mode,
            difficulty: difficulty,
            count: questionCount
        )

        // セッションを作成
        do {
            currentSession = try dataService.createSession(
                profile: profile,
                gameMode: mode,
                difficulty: difficulty,
                totalQuestions: questionCount
            )
        } catch {
            // セッション作成失敗時もゲームは続行
            currentSession = nil
        }

        // 最初の問題を表示
        if !questions.isEmpty {
            currentQuestionIndex = 0
            currentQuestion = questions[0]
            gameState = .playing
            questionStartTime = Date()
            startTimer()
        }
    }

    /// 回答を提出する
    /// - Parameter answer: ユーザーの回答文字列
    public func submitAnswer(_ answer: String) {
        guard gameState == .playing || gameState == .answering else { return }
        guard let question = currentQuestion else { return }

        selectedAnswer = answer
        gameState = .answering

        // タイマー停止
        stopTimer()

        // 回答を処理
        processAnswer(answer, for: question)
    }

    /// 回答を処理（正解/不正解の判定、スコア計算、記録保存）
    func processAnswer(_ answer: String, for question: GameQuestion) {
        let isCorrect = answer == question.correctAnswer
        isAnswerCorrect = isCorrect

        // 回答時間の計算
        let responseTime: Double
        if let startTime = questionStartTime {
            responseTime = Date().timeIntervalSince(startTime)
        } else {
            responseTime = 0
        }

        if isCorrect {
            // 正解処理
            correctCount += 1
            currentCombo += 1
            consecutiveCorrect += 1
            consecutiveWrong = 0

            // 最大コンボ更新
            if currentCombo > maxCombo {
                maxCombo = currentCombo
            }

            // スコア加算
            let stars = scoringService.starsForCorrectAnswer(
                difficulty: difficulty,
                currentCombo: currentCombo
            )
            score += stars
        } else {
            // 不正解処理
            currentCombo = 0
            consecutiveWrong += 1
            consecutiveCorrect = 0
        }

        // 学習記録を保存
        if let session = currentSession {
            do {
                _ = try dataService.addLearningRecord(
                    to: session,
                    questionType: question.questionType,
                    questionContent: question.questionText,
                    userAnswer: answer,
                    correctAnswer: question.correctAnswer,
                    isCorrect: isCorrect,
                    responseTimeSeconds: responseTime
                )
            } catch {
                // 記録保存失敗は無視してゲームを続行
            }
        }

        // 結果表示状態に遷移
        gameState = .showingResult
    }

    /// 次の問題に移動する
    func moveToNextQuestion() {
        let nextIndex = currentQuestionIndex + 1

        if nextIndex < questions.count {
            // 次の問題へ
            currentQuestionIndex = nextIndex
            currentQuestion = questions[nextIndex]
            selectedAnswer = nil
            isAnswerCorrect = nil
            gameState = .playing
            questionStartTime = Date()
            startTimer()
        } else {
            // 全問題終了 → セッション完了
            completeSession()
        }
    }

    /// セッションを完了する（スコア集計、バッジ判定、データ保存）
    func completeSession() {
        stopTimer()
        gameState = .sessionComplete

        // セッションスコアを計算
        let result = scoringService.calculateSessionScore(
            correctAnswers: correctCount,
            totalQuestions: questions.count,
            maxCombo: maxCombo,
            difficulty: difficulty
        )
        sessionResult = result

        // セッションを完了状態にする
        if let session = currentSession {
            session.correctAnswers = correctCount
            session.earnedStars = result.totalStars
            session.maxCombo = maxCombo

            do {
                try dataService.completeSession(session)
            } catch {
                // 完了保存失敗は無視
            }
        }

        // プロフィールの星を更新
        if let profile = currentProfile {
            profile.totalStars += result.totalStars
            profile.updateLevel()

            do {
                try dataService.updateProfile(profile)
            } catch {
                // プロフィール更新失敗は無視
            }

            // バッジ判定
            checkAndUnlockBadges(profile: profile)
        }
    }

    /// ゲーム状態を完全にリセットする
    public func resetGame() {
        stopTimer()

        gameState = .idle
        currentQuestion = nil
        questions = []
        currentQuestionIndex = 0
        selectedAnswer = nil
        isAnswerCorrect = nil

        score = 0
        currentCombo = 0
        maxCombo = 0
        correctCount = 0
        consecutiveCorrect = 0
        consecutiveWrong = 0

        currentSession = nil
        sessionResult = nil
        newBadges = []
        questionStartTime = nil
    }

    // MARK: - Timer

    /// 制限時間タイマーを開始する
    func startTimer() {
        stopTimer()
        remainingTime = difficulty.timeLimitSeconds

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.remainingTime -= 1.0

                if self.remainingTime <= 0 {
                    self.remainingTime = 0
                    self.stopTimer()

                    // 時間切れ → 不正解として処理
                    if let question = self.currentQuestion,
                       self.gameState == .playing || self.gameState == .answering {
                        self.submitAnswer("")
                    }
                }
            }
        }
    }

    /// タイマーを停止する
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Badge Check

    /// バッジ解除条件をチェックして新バッジを解除する
    private func checkAndUnlockBadges(profile: UserProfile) {
        newBadges = []

        do {
            let unlockedIds = try dataService.unlockedBadgeIds(for: profile)

            // はじめてのほし
            if !unlockedIds.contains(BadgeDefinition.firstStar.rawValue) && profile.totalStars > 0 {
                unlockBadge(.firstStar, for: profile)
            }

            // ほしあつめ100
            if !unlockedIds.contains(BadgeDefinition.starCollector100.rawValue) && profile.totalStars >= 100 {
                unlockBadge(.starCollector100, for: profile)
            }

            // ほしあつめ500
            if !unlockedIds.contains(BadgeDefinition.starCollector500.rawValue) && profile.totalStars >= 500 {
                unlockBadge(.starCollector500, for: profile)
            }

            // レベル3たっせい
            if !unlockedIds.contains(BadgeDefinition.levelThree.rawValue) && profile.currentLevel >= 3 {
                unlockBadge(.levelThree, for: profile)
            }

            // コンボ5!
            if !unlockedIds.contains(BadgeDefinition.combo5.rawValue) && maxCombo >= 5 {
                unlockBadge(.combo5, for: profile)
            }

            // スーパーコンボ
            if !unlockedIds.contains(BadgeDefinition.superCombo.rawValue) && maxCombo >= 10 {
                unlockBadge(.superCombo, for: profile)
            }

            // パーフェクト
            if !unlockedIds.contains(BadgeDefinition.perfect.rawValue)
                && correctCount == questions.count && questions.count > 0 {
                unlockBadge(.perfect, for: profile)
            }

            // さんすうマスター（50問正解）
            if !unlockedIds.contains(BadgeDefinition.mathMaster.rawValue) {
                let mathCorrect = try dataService.correctAnswerCount(for: profile, mode: .mathQuiz)
                if mathCorrect >= 50 {
                    unlockBadge(.mathMaster, for: profile)
                }
            }

            // ひらがなヒーロー（50問正解）
            if !unlockedIds.contains(BadgeDefinition.hiraganaHero.rawValue) {
                let hiraganaCorrect = try dataService.correctAnswerCount(for: profile, mode: .hiraganaPractice)
                if hiraganaCorrect >= 50 {
                    unlockBadge(.hiraganaHero, for: profile)
                }
            }

            // かたちはかせ（50問正解）
            if !unlockedIds.contains(BadgeDefinition.shapeExpert.rawValue) {
                let shapeCorrect = try dataService.correctAnswerCount(for: profile, mode: .shapePuzzle)
                if shapeCorrect >= 50 {
                    unlockBadge(.shapeExpert, for: profile)
                }
            }

            // ろんりてんさい（50問正解）
            if !unlockedIds.contains(BadgeDefinition.logicGenius.rawValue) {
                let logicCorrect = try dataService.correctAnswerCount(for: profile, mode: .logicGame)
                if logicCorrect >= 50 {
                    unlockBadge(.logicGenius, for: profile)
                }
            }

            // まいにちがんばる（3日連続）
            if !unlockedIds.contains(BadgeDefinition.dailyPlayer.rawValue) {
                let consecutiveDays = try dataService.consecutivePlayDays(for: profile)
                if consecutiveDays >= 3 {
                    unlockBadge(.dailyPlayer, for: profile)
                }
            }

            // ぜんぶやったよ（4モード全プレイ）
            if !unlockedIds.contains(BadgeDefinition.allModes.rawValue) {
                let playedModeSet = try dataService.playedModes(for: profile)
                if playedModeSet.count >= GameMode.allCases.count {
                    unlockBadge(.allModes, for: profile)
                }
            }
        } catch {
            // バッジチェック失敗は無視
        }
    }

    /// バッジを解除して新バッジリストに追加
    private func unlockBadge(_ badge: BadgeDefinition, for profile: UserProfile) {
        do {
            _ = try dataService.unlockAchievement(for: profile, badge: badge)
            newBadges.append(badge)
        } catch {
            // 解除失敗は無視
        }
    }

    // MARK: - GameSceneDelegate

    /// SpriteKitシーンで選択肢がタップされた（nonisolated + MainActor.run）
    nonisolated public func sceneDidSelectAnswer(_ scene: BaseGameScene, answer: String) {
        Task { @MainActor [weak self] in
            self?.submitAnswer(answer)
        }
    }

    /// SpriteKitシーンが次の問題を要求した（nonisolated + MainActor.run）
    nonisolated public func sceneDidRequestNextQuestion(_ scene: BaseGameScene) {
        Task { @MainActor [weak self] in
            self?.moveToNextQuestion()
        }
    }

    /// SpriteKitシーンのお祝いアニメーションが完了した（nonisolated + MainActor.run）
    nonisolated public func sceneDidFinishCelebration(_ scene: BaseGameScene) {
        Task { @MainActor [weak self] in
            self?.moveToNextQuestion()
        }
    }
}
