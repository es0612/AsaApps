import SwiftUI
import AsaUIKit

// MARK: - アクティビティリング

/// 個別のアクティビティリング（歩数、睡眠、朝活）
struct ActivityRingView: View {
    let progress: Double
    var color: Color = .green
    var label: String
    var value: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)

                Text(value)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            .frame(width: 64, height: 64)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
}
