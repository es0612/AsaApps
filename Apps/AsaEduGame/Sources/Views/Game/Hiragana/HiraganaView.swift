import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - ひらがなビュー

/// ひらがなモード固有UI
/// 選択式と手書きキャンバスの2モードをサポート
struct HiraganaView: View {

    // MARK: - Properties

    @Bindable var gameVM: GameViewModel
    @State private var hiraganaVM: HiraganaViewModel

    // MARK: - State

    @State private var selectedOption: String?
    @State private var showResult: Bool = false
    @State private var currentStroke: [CGPoint] = []

    // MARK: - Init

    init(gameVM: GameViewModel, handwritingService: HandwritingRecognizing? = nil) {
        self.gameVM = gameVM
        self._hiraganaVM = State(initialValue: HiraganaViewModel(handwritingService: handwritingService))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // ひらがな文字/問題表示
            characterDisplaySection

            if hiraganaVM.isWritingMode {
                // 手書きモード
                writingSection
            } else {
                // 選択式モード
                selectionSection
            }

            // モード切り替えボタン
            modeToggleButton

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: gameVM.currentQuestion) { _, newQuestion in
            if let question = newQuestion {
                hiraganaVM.setupForQuestion(question)
                resetState()
            }
        }
        .onAppear {
            if let question = gameVM.currentQuestion {
                hiraganaVM.setupForQuestion(question)
            }
        }
    }

    // MARK: - 文字表示セクション

    private var characterDisplaySection: some View {
        VStack(spacing: 12) {
            // 問題テキスト
            if let question = gameVM.currentQuestion {
                Text(question.questionText)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)
                    .multilineTextAlignment(.center)
            }

            // 大きなひらがな文字（手書きモード時はお手本として表示）
            if hiraganaVM.isWritingMode {
                Text(hiraganaVM.currentCharacter)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.coffeeBrown.opacity(0.3))
                    .padding(8)
            }
        }
    }

    // MARK: - 手書きセクション

    private var writingSection: some View {
        VStack(spacing: 16) {
            // 手書きキャンバス
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                // 描画されたストローク
                Canvas { context, size in
                    for stroke in hiraganaVM.drawingPoints {
                        guard stroke.count > 1 else { continue }
                        var path = Path()
                        path.move(to: stroke[0])
                        for point in stroke.dropFirst() {
                            path.addLine(to: point)
                        }
                        context.stroke(path,
                                       with: .color(AsaColors.darkSlate),
                                       lineWidth: 4)
                    }
                    // 現在描画中のストローク
                    if currentStroke.count > 1 {
                        var path = Path()
                        path.move(to: currentStroke[0])
                        for point in currentStroke.dropFirst() {
                            path.addLine(to: point)
                        }
                        context.stroke(path,
                                       with: .color(AsaColors.coffeeBrown),
                                       lineWidth: 4)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            currentStroke.append(value.location)
                        }
                        .onEnded { _ in
                            hiraganaVM.drawingPoints.append(currentStroke)
                            currentStroke = []
                        }
                )
            }
            .frame(height: 200)

            // 手書きアクションボタン
            HStack(spacing: 16) {
                ChildFriendlyButton(
                    title: "けす",
                    color: AsaColors.mutedSage
                ) {
                    hiraganaVM.clearDrawing()
                    currentStroke = []
                }

                ChildFriendlyButton(
                    title: "できた！",
                    color: AsaColors.coffeeBrown
                ) {
                    Task {
                        await hiraganaVM.submitDrawing()
                        if let result = hiraganaVM.recognitionResult {
                            gameVM.submitAnswer(result.recognizedCharacter)
                        }
                    }
                }
            }

            // 認識中インジケーター
            if hiraganaVM.isRecognizing {
                ProgressView("にんしきちゅう...")
                    .font(.system(size: 14, design: .rounded))
            }
        }
    }

    // MARK: - 選択式セクション

    private var selectionSection: some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(gameVM.currentQuestion?.options.enumerated() ?? [].enumerated()),
                    id: \.offset) { _, option in
                optionButton(option: option)
            }
        }
    }

    /// 選択肢ボタン
    private func optionButton(option: String) -> some View {
        Button {
            selectOption(option)
        } label: {
            Text(option)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(optionTextColor(option))
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(optionBackgroundColor(option))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .disabled(showResult)
        .accessibilityLabel("こたえ \(option)")
    }

    /// 選択肢テキスト色
    private func optionTextColor(_ option: String) -> Color {
        guard showResult else { return AsaColors.darkSlate }
        if option == gameVM.currentQuestion?.correctAnswer { return .white }
        if option == selectedOption { return .white }
        return AsaColors.darkSlate.opacity(0.5)
    }

    /// 選択肢背景色
    private func optionBackgroundColor(_ option: String) -> Color {
        guard showResult else { return Color.white }
        if option == gameVM.currentQuestion?.correctAnswer { return .green }
        if option == selectedOption { return .red.opacity(0.8) }
        return Color.white.opacity(0.5)
    }

    // MARK: - モード切り替えボタン

    private var modeToggleButton: some View {
        Button {
            hiraganaVM.isWritingMode.toggle()
            hiraganaVM.clearDrawing()
            currentStroke = []
        } label: {
            HStack(spacing: 8) {
                Image(systemName: hiraganaVM.isWritingMode ? "list.bullet" : "pencil")
                Text(hiraganaVM.isWritingMode ? "えらぶモード" : "かくモード")
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(AsaColors.coffeeBrown)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AsaColors.softCream)
            .clipShape(Capsule())
        }
    }

    // MARK: - アクション

    /// 選択肢をタップ
    private func selectOption(_ option: String) {
        guard !showResult else { return }
        selectedOption = option
        showResult = true
        gameVM.submitAnswer(option)
    }

    /// 状態リセット
    private func resetState() {
        selectedOption = nil
        showResult = false
        currentStroke = []
    }
}

// MARK: - Preview

#Preview {
    HiraganaView(
        gameVM: GameViewModel(
            dataService: EduGameDataService(inMemory: true),
            questionGenerator: QuestionGeneratorService(),
            scoringService: ScoringService(),
            difficultyService: AdaptiveDifficultyService()
        )
    )
}
