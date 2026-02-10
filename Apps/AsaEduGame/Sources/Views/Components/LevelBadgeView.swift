import SwiftUI
import AsaUIKit

// MARK: - レベルバッジ表示

/// 現在レベル数、レベル名、次レベルまでのプログレスを表示
struct LevelBadgeView: View {

    // MARK: - Properties

    /// 現在のレベル（1-7）
    let level: Int

    /// レベル名
    let levelName: String

    /// 次のレベルまでに必要な星数
    let starsToNextLevel: Int

    /// 現在の総星数
    let totalStars: Int

    // MARK: - Constants

    /// レベルごとの星数しきい値
    private let thresholds = [0, 50, 150, 300, 500, 750, 1000]

    // MARK: - Computed

    /// 現在のレベルの進捗（0.0-1.0）
    private var progress: Double {
        guard level < 7 else { return 1.0 }
        let currentThreshold = thresholds[level - 1]
        let nextThreshold = thresholds[level]
        let range = nextThreshold - currentThreshold
        guard range > 0 else { return 0 }
        let current = totalStars - currentThreshold
        return min(1.0, max(0.0, Double(current) / Double(range)))
    }

    /// レベルに応じた色
    private var levelColor: Color {
        switch level {
        case 1: return AsaColors.mutedSage
        case 2: return .green
        case 3: return .blue
        case 4: return .purple
        case 5: return .orange
        case 6: return .red
        case 7: return .yellow
        default: return AsaColors.coffeeBrown
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // レベルバッジ
            HStack(spacing: 12) {
                // レベル数のサークル
                ZStack {
                    Circle()
                        .fill(levelColor.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Circle()
                        .stroke(levelColor, lineWidth: 3)
                        .frame(width: 60, height: 60)

                    Text("Lv.\(level)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(levelColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // レベル名
                    Text(levelName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AsaColors.darkSlate)

                    // 星数表示
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                        Text("\(totalStars)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                Spacer()
            }

            // プログレスバー
            if level < 7 {
                VStack(spacing: 6) {
                    ProgressView(value: progress)
                        .tint(levelColor)

                    HStack {
                        Text("つぎのレベルまで")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)

                        Spacer()

                        Text("あと\(starsToNextLevel)⭐")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(levelColor)
                    }
                }
            } else {
                // 最大レベル
                Text("さいこうレベルたっせい! 🎉")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        LevelBadgeView(
            level: 1,
            levelName: "ビギナー",
            starsToNextLevel: 35,
            totalStars: 15
        )

        LevelBadgeView(
            level: 4,
            levelName: "エキスパート",
            starsToNextLevel: 120,
            totalStars: 380
        )

        LevelBadgeView(
            level: 7,
            levelName: "レジェンド",
            starsToNextLevel: 0,
            totalStars: 1200
        )
    }
    .padding()
}
