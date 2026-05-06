import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - モード別統計コンポーネント

/// ゲームモードごとの統計カード
/// モード名、emoji、正答率プログレスバー、プレイ回数を表示
struct GameModeStatsView: View {

    // MARK: - Properties

    let mode: GameMode
    let stats: ProgressViewModel.ModeStatistics?

    // MARK: - Body

    var body: some View {
        AsaCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(mode.themeColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(mode.themeColor)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(mode.themeColor)

                    if let stats, stats.totalSessions > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("せいとうりつ")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(AsaColors.mutedSage)
                                Spacer()
                                Text("\(Int(stats.averageAccuracy * 100))%")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(mode.themeColor)
                            }

                            ProgressView(value: stats.averageAccuracy)
                                .tint(mode.themeColor)
                        }

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(AsaColors.mutedSage)
                                Text("\(stats.totalSessions)かい")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(AsaColors.mutedSage)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(AsaColors.coffeeBrown)
                                Text("\(stats.totalCorrect)もん")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(AsaColors.mutedSage)
                            }

                            if stats.bestCombo >= 2 {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(AsaColors.mocha)
                                    Text("\(stats.bestCombo)")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(AsaColors.mocha)
                                }
                            }
                        }
                    } else {
                        Text("まだプレイしていません")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        GameModeStatsView(
            mode: .mathQuiz,
            stats: ProgressViewModel.ModeStatistics(
                totalSessions: 15,
                totalCorrect: 60,
                totalQuestions: 75,
                averageAccuracy: 0.8,
                bestCombo: 7
            )
        )

        GameModeStatsView(
            mode: .hiraganaPractice,
            stats: nil
        )
    }
    .padding()
}
