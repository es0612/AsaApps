import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - 算数クイズビュー

/// 算数モード固有のSwiftUI版UI
/// SpriteKitを使わないシンプルなアニメーション版
struct MathQuizView: View {

    // MARK: - Properties

    @Bindable var gameVM: GameViewModel
    @State private var mathVM = MathQuizViewModel()

    // MARK: - State

    @State private var selectedOption: String?
    @State private var showResult: Bool = false
    @State private var buttonScales: [Int: CGFloat] = [:]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 数式表示
            expressionSection

            // 選択肢ボタン
            optionsSection

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: gameVM.currentQuestion) { _, newQuestion in
            if let question = newQuestion {
                mathVM.setupForQuestion(question)
                resetState()
            }
        }
        .onAppear {
            if let question = gameVM.currentQuestion {
                mathVM.setupForQuestion(question)
            }
        }
    }

    // MARK: - 数式表示セクション

    private var expressionSection: some View {
        VStack(spacing: 16) {
            // 問題タイプアイコン
            Text(mathVM.operationType == "+" ? "たしざん" :
                    mathVM.operationType == "-" ? "ひきざん" :
                    mathVM.operationType == ">" ? "くらべっこ" : "あなうめ")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AsaColors.coffeeBrown)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(AsaColors.softCream)
                .clipShape(Capsule())

            // メイン数式
            Text(mathVM.currentExpression)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.darkSlate)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
        }
    }

    // MARK: - 選択肢セクション

    private var optionsSection: some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(gameVM.currentQuestion?.options.enumerated() ?? [].enumerated()),
                    id: \.offset) { index, option in
                optionButton(option: option, index: index)
            }
        }
    }

    /// 選択肢ボタン
    private func optionButton(option: String, index: Int) -> some View {
        Button {
            selectOption(option)
        } label: {
            Text(option)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(optionTextColor(option))
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(optionBackgroundColor(option))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .scaleEffect(buttonScales[index] ?? 1.0)
        .disabled(showResult)
        .accessibilityLabel("こたえ \(option)")
    }

    /// 選択肢のテキスト色
    private func optionTextColor(_ option: String) -> Color {
        guard showResult else { return AsaColors.darkSlate }

        if option == gameVM.currentQuestion?.correctAnswer {
            return .white
        } else if option == selectedOption {
            return .white
        }
        return AsaColors.darkSlate.opacity(0.5)
    }

    /// 選択肢の背景色
    private func optionBackgroundColor(_ option: String) -> Color {
        guard showResult else { return Color.white }

        if option == gameVM.currentQuestion?.correctAnswer {
            return .green
        } else if option == selectedOption {
            return .red.opacity(0.8)
        }
        return Color.white.opacity(0.5)
    }

    // MARK: - アクション

    /// 選択肢をタップ
    private func selectOption(_ option: String) {
        guard !showResult else { return }

        selectedOption = option
        showResult = true

        // タップアニメーション
        if let index = gameVM.currentQuestion?.options.firstIndex(of: option) {
            withAnimation(.easeInOut(duration: 0.1)) {
                buttonScales[index] = 0.95
            }
            withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                buttonScales[index] = 1.0
            }
        }

        // 回答を送信
        gameVM.submitAnswer(option)
    }

    /// 状態リセット
    private func resetState() {
        selectedOption = nil
        showResult = false
        buttonScales = [:]
    }
}

// MARK: - Preview

#Preview {
    MathQuizView(
        gameVM: GameViewModel(
            dataService: EduGameDataService(inMemory: true),
            questionGenerator: QuestionGeneratorService(),
            scoringService: ScoringService(),
            difficultyService: AdaptiveDifficultyService()
        )
    )
}
