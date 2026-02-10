import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - ゲーム結果画面

/// セッション終了後のスコア・バッジ結果を表示する画面
struct GameResultView: View {

    // MARK: - Properties

    @Bindable var gameVM: GameViewModel
    let gameMode: GameMode
    let onPlayAgain: () -> Void
    let onGoHome: () -> Void

    // MARK: - State

    @State private var showStarAnimation: Bool = false
    @State private var showDetails: Bool = false
    @State private var showBadges: Bool = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer()
                    .frame(height: 20)

                // パーフェクト表示
                if isPerfect {
                    perfectBanner
                }

                // メイン星アニメーション
                starSection

                // 正答率
                accuracySection

                // スコア内訳
                scoreBreakdownSection

                // 新規バッジ表示
                if !gameVM.newBadges.isEmpty {
                    newBadgesSection
                }

                // アクションボタン
                actionButtonsSection

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(AsaColors.softCream.opacity(0.3))
        .onAppear {
            // アニメーション順序
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                showStarAnimation = true
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.8)) {
                showDetails = true
            }
            withAnimation(.easeInOut(duration: 0.4).delay(1.2)) {
                showBadges = true
            }
        }
    }

    // MARK: - パーフェクトかどうか

    private var isPerfect: Bool {
        gameVM.correctCount == gameVM.questions.count && gameVM.questions.count > 0
    }

    // MARK: - パーフェクトバナー

    private var perfectBanner: some View {
        HStack(spacing: 8) {
            Text("💯")
                .font(.system(size: 36))
            Text("パーフェクト!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.coffeeBrown)
            Text("💯")
                .font(.system(size: 36))
        }
        .scaleEffect(showStarAnimation ? 1.0 : 0.5)
        .opacity(showStarAnimation ? 1.0 : 0.0)
    }

    // MARK: - 星セクション

    private var starSection: some View {
        VStack(spacing: 12) {
            // 大きな星
            ZStack {
                // 背景のキラキラ
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow.opacity(0.5))
                        .offset(
                            x: CGFloat.random(in: -40...40),
                            y: CGFloat.random(in: -40...40)
                        )
                        .scaleEffect(showStarAnimation ? 1.0 : 0.0)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .delay(Double(index) * 0.1 + 0.3),
                            value: showStarAnimation
                        )
                }

                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange.opacity(0.4), radius: 10)
            }
            .scaleEffect(showStarAnimation ? 1.0 : 0.3)

            // 獲得星数
            if let result = gameVM.sessionResult {
                Text("+\(result.totalStars)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.coffeeBrown)
                    .opacity(showStarAnimation ? 1.0 : 0.0)
            }
        }
    }

    // MARK: - 正答率セクション

    private var accuracySection: some View {
        VStack(spacing: 8) {
            // 正答率の大きな数字
            let accuracy = gameVM.questions.count > 0
                ? Int(Double(gameVM.correctCount) / Double(gameVM.questions.count) * 100)
                : 0

            Text("\(accuracy)%")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(accuracyColor(accuracy))

            Text("\(gameVM.correctCount)/\(gameVM.questions.count) もんせいかい")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AsaColors.mutedSage)
        }
        .opacity(showDetails ? 1.0 : 0.0)
    }

    /// 正答率に応じた色
    private func accuracyColor(_ accuracy: Int) -> Color {
        if accuracy >= 80 {
            return .green
        } else if accuracy >= 50 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - スコア内訳セクション

    private var scoreBreakdownSection: some View {
        AsaCard {
            VStack(spacing: 12) {
                Text("スコアないやく")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)

                if let result = gameVM.sessionResult {
                    scoreRow(label: "きほんのほし", value: result.earnedStars, emoji: "⭐")
                    scoreRow(label: "コンボボーナス", value: result.comboBonus, emoji: "🔥")
                    scoreRow(label: "パーフェクトボーナス", value: result.perfectBonus, emoji: "💯")

                    Divider()

                    HStack {
                        Text("ごうけい")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AsaColors.darkSlate)
                        Spacer()
                        Text("\(result.totalStars)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }

                // 最大コンボ
                if gameVM.maxCombo >= 2 {
                    HStack {
                        Text("さいだいコンボ")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)
                        Spacer()
                        Text("\(gameVM.maxCombo)コンボ 🔥")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .opacity(showDetails ? 1.0 : 0.0)
    }

    /// スコア行コンポーネント
    private func scoreRow(label: String, value: Int, emoji: String) -> some View {
        HStack {
            Text("\(emoji) \(label)")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AsaColors.darkSlate)
            Spacer()
            Text("+\(value)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(value > 0 ? AsaColors.coffeeBrown : AsaColors.mutedSage)
        }
    }

    // MARK: - 新規バッジセクション

    private var newBadgesSection: some View {
        VStack(spacing: 12) {
            Text("🎉 あたらしいバッジ!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.coffeeBrown)

            ForEach(gameVM.newBadges, id: \.rawValue) { badge in
                AsaCard {
                    HStack(spacing: 12) {
                        Text(badge.emoji)
                            .font(.system(size: 36))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(badge.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AsaColors.darkSlate)

                            Text(badge.badgeDescription)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(AsaColors.mutedSage)
                        }

                        Spacer()
                    }
                }
            }
        }
        .opacity(showBadges ? 1.0 : 0.0)
    }

    // MARK: - アクションボタン

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            ChildFriendlyButton(
                title: "もういっかい",
                color: Color(gameMode.themeColorName)
            ) {
                onPlayAgain()
            }

            ChildFriendlyButton(
                title: "ホームにもどる",
                color: AsaColors.mutedSage
            ) {
                onGoHome()
            }
        }
        .opacity(showDetails ? 1.0 : 0.0)
    }
}

// MARK: - Preview

#Preview {
    GameResultView(
        gameVM: {
            let vm = GameViewModel(
                dataService: EduGameDataService(inMemory: true),
                questionGenerator: QuestionGeneratorService(),
                scoringService: ScoringService(),
                difficultyService: AdaptiveDifficultyService()
            )
            return vm
        }(),
        gameMode: .mathQuiz,
        onPlayAgain: {},
        onGoHome: {}
    )
}
