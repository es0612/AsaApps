import SwiftUI

// MARK: - StatRing

/// 円形プログレスリング
struct StatRing: View {
    let value: Double
    let maxValue: Double
    let label: String
    let valueText: String
    var ringColor: Color = .accentColor
    var size: CGFloat = 80

    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(ringColor.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(valueText)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.5)
            }
            .frame(width: size, height: size)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
