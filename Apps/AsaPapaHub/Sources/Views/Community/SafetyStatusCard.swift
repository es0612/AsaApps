import SwiftUI
import AsaUIKit

// MARK: - 安全ステータスカード

/// 地域の安全情報を表示するカード
struct SafetyStatusCard: View {
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundStyle(.green)
                Text("安全ステータス")
                    .font(.headline)
            }

            // ステータスインジケーター
            HStack(spacing: 16) {
                statusItem(title: "気象", status: "晴れ", icon: "sun.max.fill", color: .orange)
                statusItem(title: "防災", status: "安全", icon: "exclamationmark.triangle", color: .green)
                statusItem(title: "交通", status: "通常", icon: "car.fill", color: .blue)
            }
            .frame(maxWidth: .infinity)

            // 最新のお知らせ
            VStack(alignment: .leading, spacing: 4) {
                Text("最新のお知らせ")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("本日の天気は晴れ。最高気温12度の予報です。")
                    .font(.caption)
                    .foregroundStyle(AsaColors.darkSlate)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - Private

    private func statusItem(title: String, status: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(status)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}
