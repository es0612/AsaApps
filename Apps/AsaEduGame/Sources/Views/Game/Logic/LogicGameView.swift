import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - 論理ゲームビュー

/// 論理ゲームモード固有UI
/// なかまはずれ、じゅんばん、パターン完成の3タイプに対応
struct LogicGameView: View {

    // MARK: - Properties

    @Bindable var gameVM: GameViewModel
    @State private var logicVM = LogicGameViewModel()

    // MARK: - State

    @State private var selectedOption: String?
    @State private var showResult: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 問題表示
            questionSection

            // 問題タイプに応じたUI
            switch logicVM.questionSubtype {
            case .sequenceOrder:
                reorderSection
            default:
                selectionSection
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: gameVM.currentQuestion) { _, newQuestion in
            if let question = newQuestion {
                logicVM.setupForQuestion(question)
                resetState()
            }
        }
        .onAppear {
            if let question = gameVM.currentQuestion {
                logicVM.setupForQuestion(question)
            }
        }
    }

    // MARK: - 問題表示セクション

    private var questionSection: some View {
        VStack(spacing: 12) {
            // サブタイプラベル
            Text(logicVM.questionSubtype.displayName)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(AsaColors.darkSlate)
                .clipShape(Capsule())

            // 問題テキスト
            if let question = gameVM.currentQuestion {
                Text(question.questionText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 選択式セクション（なかまはずれ/パターン完成）

    private var selectionSection: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(logicVM.items.enumerated()), id: \.offset) { _, item in
                itemButton(item: item)
            }
        }
    }

    /// アイテムボタン
    private func itemButton(item: String) -> some View {
        Button {
            selectItem(item)
        } label: {
            Text(item)
                .font(.system(size: 32))
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(itemBackgroundColor(item))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(itemBorderColor(item), lineWidth: selectedOption == item ? 3 : 0)
                )
        }
        .disabled(showResult)
        .accessibilityLabel("こたえ \(item)")
    }

    /// アイテム背景色
    private func itemBackgroundColor(_ item: String) -> Color {
        guard showResult else { return Color.white }
        if item == gameVM.currentQuestion?.correctAnswer { return .green.opacity(0.3) }
        if item == selectedOption { return .red.opacity(0.2) }
        return Color.white.opacity(0.5)
    }

    /// アイテムボーダー色
    private func itemBorderColor(_ item: String) -> Color {
        guard showResult else {
            return selectedOption == item ? AsaColors.coffeeBrown : .clear
        }
        if item == gameVM.currentQuestion?.correctAnswer { return .green }
        if item == selectedOption { return .red }
        return .clear
    }

    // MARK: - 並べ替えセクション（じゅんばん）

    private var reorderSection: some View {
        VStack(spacing: 12) {
            Text("ただしいじゅんばんにならべよう")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AsaColors.mutedSage)

            // 並べ替えリスト
            ForEach(Array(logicVM.orderedItems.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(width: 30)

                    Text(item)
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(AsaColors.darkSlate)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                        .draggable(item)
                }
            }
            .dropDestination(for: String.self) { items, location in
                // ドロップ時の並べ替え処理
                guard let droppedItem = items.first,
                      let fromIndex = logicVM.orderedItems.firstIndex(of: droppedItem) else {
                    return false
                }
                let toIndex = min(logicVM.orderedItems.count - 1, Int(location.y / 62))
                logicVM.reorderItem(from: fromIndex, to: toIndex)
                return true
            }

            // 並べ替え完了後の送信ボタン
            ChildFriendlyButton(
                title: "けってい！",
                color: AsaColors.darkSlate
            ) {
                // 並べた順序を文字列にして送信
                let orderedAnswer = logicVM.orderedItems.joined(separator: ",")
                gameVM.submitAnswer(orderedAnswer)
                showResult = true
            }
            .disabled(showResult)
        }
    }

    // MARK: - アクション

    private func selectItem(_ item: String) {
        guard !showResult else { return }
        selectedOption = item
        showResult = true
        gameVM.submitAnswer(item)
    }

    private func resetState() {
        selectedOption = nil
        showResult = false
    }
}

// MARK: - Preview

#Preview {
    LogicGameView(
        gameVM: GameViewModel(
            dataService: EduGameDataService(inMemory: true),
            questionGenerator: QuestionGeneratorService(),
            scoringService: ScoringService(),
            difficultyService: AdaptiveDifficultyService()
        )
    )
}
