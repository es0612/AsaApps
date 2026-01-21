import SwiftUI
import AsaUIKit

// MARK: - GameOverView
/// ゲーム終了画面（結果表示、リプレイボタン）
struct GameOverView: View {
    let statistics: GameScore.Statistics
    let onRestart: () -> Void
    let onClose: () -> Void

    @State private var showAnimation = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // タイトル
                titleSection

                // スコア表示
                scoreSection
                    .scaleEffect(showAnimation ? 1 : 0.5)
                    .opacity(showAnimation ? 1 : 0)

                // 統計情報
                statisticsSection
                    .offset(y: showAnimation ? 0 : 30)
                    .opacity(showAnimation ? 1 : 0)

                // ボタン
                buttonSection
                    .offset(y: showAnimation ? 0 : 50)
                    .opacity(showAnimation ? 1 : 0)
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showAnimation = true
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("ゲーム終了")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if statistics.isNewHighScore {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("ハイスコア更新！")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.2), in: Capsule())
            }
        }
    }

    private var scoreSection: some View {
        VStack(spacing: 8) {
            Text("スコア")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Text("\(statistics.finalScore)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("ハイスコア: \(statistics.highScore)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var statisticsSection: some View {
        AsaCard {
            VStack(spacing: 16) {
                Text("統計")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                HStack(spacing: 24) {
                    statisticItem(
                        icon: "target",
                        label: "命中",
                        value: "\(statistics.targetsHit)"
                    )
                    statisticItem(
                        icon: "xmark.circle",
                        label: "ミス",
                        value: "\(statistics.targetsMissed)"
                    )
                    statisticItem(
                        icon: "percent",
                        label: "命中率",
                        value: "\(statistics.accuracy)%"
                    )
                    statisticItem(
                        icon: "flame.fill",
                        label: "最大コンボ",
                        value: "\(statistics.maxCombo)"
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func statisticItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AsaColors.coffeeBrown)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.darkSlate)
            Text(label)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
    }

    private var buttonSection: some View {
        HStack(spacing: 16) {
            // ホームに戻る
            Button(action: onClose) {
                HStack {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AsaColors.mutedSage, in: RoundedRectangle(cornerRadius: 12))
            }

            // リプレイ
            Button(action: onRestart) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("もう一度")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AsaColors.coffeeBrown, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GameOverView(
        statistics: GameScore.Statistics(
            finalScore: 1250,
            highScore: 1250,
            isNewHighScore: true,
            accuracy: 78,
            maxCombo: 8,
            targetsHit: 25,
            targetsMissed: 7
        ),
        onRestart: {},
        onClose: {}
    )
}
