import SwiftUI
import AsaUIKit

// MARK: - スコアリング

/// 円形プログレス表示コンポーネント
struct ScoreRing: View {
    let progress: Double
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var gradientColors: [Color] = [AsaColors.coffeeBrown, AsaColors.mocha]
    var label: String?

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景リング
            Circle()
                .stroke(
                    AsaColors.softCream.opacity(0.3),
                    lineWidth: lineWidth
                )

            // プログレスリング
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        colors: gradientColors,
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * clampedProgress)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)

            // 中央テキスト
            VStack(spacing: 2) {
                Text("\(Int(clampedProgress * 100))")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundStyle(AsaColors.darkSlate)

                if let label {
                    Text(label)
                        .font(.system(size: size * 0.1))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Private

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
}
