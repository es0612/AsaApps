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
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(AsaColors.coffeeBrown)
            Text("パーフェクト!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.coffeeBrown)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(AsaColors.coffeeBrown)
        }
        .scaleEffect(showStarAnimation ? 1.0 : 0.5)
        .opacity(showStarAnimation ? 1.0 : 0.0)
    }

    // MARK: - 星セクション

    private var starSection: some View {
        VStack(spacing: 12) {
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 18))
                        .foregroundColor(AsaColors.softCream)
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
                    .font(.system(size: 80, weight: .semibold))
                    .foregroundColor(AsaColors.coffeeBrown)
                    .shadow(color: AsaColors.coffeeBrown.opacity(0.3), radius: 10)
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

    /// 正答率に応じた色（ブランドカラー基調）
    private func accuracyColor(_ accuracy: Int) -> Color {
        if accuracy >= 80 {
            return AsaColors.coffeeBrown
        } else if accuracy >= 50 {
            return AsaColors.mocha
        } else {
            return AsaColors.mutedSage
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
                    scoreRow(
                        label: "きほんのほし",
                        value: result.earnedStars,
                        systemImage: "star.fill",
                        iconColor: AsaColors.coffeeBrown
                    )
                    scoreRow(
                        label: "コンボボーナス",
                        value: result.comboBonus,
                        systemImage: "flame.fill",
                        iconColor: AsaColors.mocha
                    )
                    scoreRow(
                        label: "パーフェクトボーナス",
                        value: result.perfectBonus,
                        systemImage: "checkmark.seal.fill",
                        iconColor: AsaColors.mutedSage
                    )

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

                if gameVM.maxCombo >= 2 {
                    HStack {
                        Text("さいだいコンボ")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("\(gameVM.maxCombo)コンボ")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AsaColors.mocha)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AsaColors.mocha)
                        }
                    }
                }
            }
        }
        .opacity(showDetails ? 1.0 : 0.0)
    }

    /// スコア行コンポーネント
    private func scoreRow(label: String, value: Int, systemImage: String, iconColor: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 18)
            Text(label)
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
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AsaColors.coffeeBrown)
                Text("あたらしいバッジ!")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.coffeeBrown)
            }

            ForEach(gameVM.newBadges, id: \.rawValue) { badge in
                AsaCard {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(badge.iconColor.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: badge.systemImage)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(badge.iconColor)
                        }

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
                color: gameMode.themeColor
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
