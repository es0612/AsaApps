import SwiftUI
import SpriteKit
import AsaEduGameKit
import AsaUIKit

// MARK: - ゲームコンテナビュー

/// SpriteViewラッパー。メインゲーム画面。
/// ゲーム状態に応じてSpriteKitシーンまたは結果画面を切り替え表示する
struct GameContainerView: View {

    // MARK: - Properties

    let gameMode: GameMode
    let difficulty: DifficultyLevel
    let profile: UserProfile

    /// サービスDI
    let dataService: EduGameDataServiceProtocol
    let questionGenerator: QuestionGenerating
    let scoringService: GameScoring
    let difficultyService: DifficultyAdjusting

    // MARK: - State

    @State private var gameVM: GameViewModel
    @State private var scene: BaseGameScene

    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(
        gameMode: GameMode,
        difficulty: DifficultyLevel,
        profile: UserProfile,
        dataService: EduGameDataServiceProtocol,
        questionGenerator: QuestionGenerating,
        scoringService: GameScoring,
        difficultyService: DifficultyAdjusting
    ) {
        self.gameMode = gameMode
        self.difficulty = difficulty
        self.profile = profile
        self.dataService = dataService
        self.questionGenerator = questionGenerator
        self.scoringService = scoringService
        self.difficultyService = difficultyService

        // GameViewModel初期化
        let vm = GameViewModel(
            dataService: dataService,
            questionGenerator: questionGenerator,
            scoringService: scoringService,
            difficultyService: difficultyService
        )
        self._gameVM = State(initialValue: vm)

        // ゲームモードに応じたSpriteKitシーンを生成
        let sceneSize = CGSize(width: 400, height: 600)
        let gameScene: BaseGameScene
        switch gameMode {
        case .mathQuiz:
            gameScene = MathQuizScene(size: sceneSize)
        case .hiraganaPractice:
            gameScene = HiraganaScene(size: sceneSize)
        case .shapePuzzle:
            gameScene = ShapePuzzleScene(size: sceneSize)
        case .logicGame:
            gameScene = LogicGameScene(size: sceneSize)
        }
        gameScene.scaleMode = .aspectFill
        self._scene = State(initialValue: gameScene)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景色
            AsaColors.softCream.opacity(0.3)
                .ignoresSafeArea()

            if gameVM.gameState == .sessionComplete {
                // セッション完了 → 結果画面
                GameResultView(
                    gameVM: gameVM,
                    gameMode: gameMode,
                    onPlayAgain: {
                        restartGame()
                    },
                    onGoHome: {
                        dismiss()
                    }
                )
            } else {
                // ゲームプレイ中
                VStack(spacing: 0) {
                    // スコアバー
                    scoreBarSection

                    // SpriteKitシーン
                    SpriteView(scene: scene)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if gameVM.gameState != .sessionComplete {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("やめる")
                        }
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
        }
        .onAppear {
            setupGame()
        }
        .onChange(of: gameVM.gameState) { _, newState in
            handleGameStateChange(newState)
        }
        .onChange(of: gameVM.currentQuestionIndex) { _, _ in
            presentCurrentQuestion()
        }
    }

    // MARK: - スコアバー

    private var scoreBarSection: some View {
        HStack(spacing: 16) {
            // 星数
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(gameVM.score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)
            }

            // コンボ表示
            if gameVM.currentCombo >= 2 {
                ComboCounterView(combo: gameVM.currentCombo)
            }

            Spacer()

            // 残り問題数
            Text("\(gameVM.currentQuestionIndex + 1)/\(gameVM.questions.count)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AsaColors.mutedSage)

            // タイマー
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundColor(timerColor)
                Text("\(Int(gameVM.remainingTime))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(timerColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9))
    }

    /// タイマーの色（残り時間が少ないと赤くなる）
    private var timerColor: Color {
        if gameVM.remainingTime <= 5 {
            return .red
        } else if gameVM.remainingTime <= 10 {
            return .orange
        } else {
            return AsaColors.mutedSage
        }
    }

    // MARK: - ゲーム制御

    /// ゲームを初期セットアップする
    private func setupGame() {
        scene.gameDelegate = gameVM
        gameVM.startGame(mode: gameMode, difficulty: difficulty, profile: profile)

        // 最初の問題を表示
        if let question = gameVM.currentQuestion {
            scene.presentQuestion(question)
        }
    }

    /// ゲームを再スタートする
    private func restartGame() {
        gameVM.startGame(mode: gameMode, difficulty: difficulty, profile: profile)

        // 最初の問題を表示
        if let question = gameVM.currentQuestion {
            scene.presentQuestion(question)
        }
    }

    /// 現在の問題をシーンに表示する
    private func presentCurrentQuestion() {
        if let question = gameVM.currentQuestion {
            scene.presentQuestion(question)
        }
    }

    /// ゲーム状態の変化に応じた処理
    private func handleGameStateChange(_ state: EduGameState) {
        switch state {
        case .showingResult:
            if let isCorrect = gameVM.isAnswerCorrect {
                if isCorrect {
                    scene.showCorrectEffect()
                    scene.updateScore(gameVM.score)
                    scene.updateCombo(gameVM.currentCombo)
                    if gameVM.currentCombo >= 3 {
                        scene.showComboEffect(combo: gameVM.currentCombo)
                    }
                } else {
                    scene.showIncorrectEffect()
                    scene.updateCombo(0)
                }
            }
        default:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GameContainerView(
            gameMode: .mathQuiz,
            difficulty: .easy,
            profile: UserProfile(name: "テスト", avatarEmoji: "🐱", age: 5),
            dataService: EduGameDataService(inMemory: true),
            questionGenerator: QuestionGeneratorService(),
            scoringService: ScoringService(),
            difficultyService: AdaptiveDifficultyService()
        )
    }
}
