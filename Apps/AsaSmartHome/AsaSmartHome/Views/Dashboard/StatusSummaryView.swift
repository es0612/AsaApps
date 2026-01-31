import SwiftUI

// MARK: - StatusSummaryView

/// ステータスサマリー表示ビュー
struct StatusSummaryView: View {
    // MARK: - Properties

    let totalDevices: Int
    let onlineDevices: Int
    let activeDevices: Int
    let isConnected: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 接続状態
            HStack {
                Circle()
                    .fill(isConnected ? Color.deviceOnline : Color.deviceOffline)
                    .frame(width: 10, height: 10)

                Text(isConnected ? "スマートホームに接続中" : "接続が切断されています")
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Spacer()
            }

            // 統計カード
            HStack(spacing: 12) {
                StatCard(
                    title: "デバイス",
                    value: "\(totalDevices)",
                    icon: "square.stack.3d.up.fill",
                    color: .asaCoffeeBrown
                )

                StatCard(
                    title: "オンライン",
                    value: "\(onlineDevices)",
                    icon: "wifi",
                    color: .deviceOnline
                )

                StatCard(
                    title: "動作中",
                    value: "\(activeDevices)",
                    icon: "bolt.fill",
                    color: .deviceActive
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - StatCard

/// 統計カード
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview("Status Summary") {
    StatusSummaryView(
        totalDevices: 12,
        onlineDevices: 11,
        activeDevices: 5,
        isConnected: true
    )
    .padding()
    .background(Color.asaDarkSlate)
}
