import SwiftUI
import AsaPapaHubKit

// MARK: - トレンドインジケーター

/// トレンド方向を矢印アイコンとテキストで表示
struct TrendIndicator: View {
    let trend: TrendDirection
    var value: String?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.caption2)
                .fontWeight(.bold)

            if let value {
                Text(value)
                    .font(.caption2)
                    .fontWeight(.medium)
            } else {
                Text(trend.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(trendColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(trendColor.opacity(0.12), in: Capsule())
    }

    // MARK: - Private

    private var trendColor: Color {
        switch trend {
        case .up: .green
        case .down: .red
        case .stable: .gray
        }
    }
}
