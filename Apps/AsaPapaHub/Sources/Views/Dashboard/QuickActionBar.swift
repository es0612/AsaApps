import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - クイックアクションバー

/// ダッシュボード下部のクイックアクション横スクロールバー
struct QuickActionBar: View {
    let actions: [QuickAction]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("クイックアクション")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(actions, id: \.id) { action in
                        quickActionButton(action)
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func quickActionButton(_ action: QuickAction) -> some View {
        VStack(spacing: 6) {
            Image(systemName: action.iconName)
                .font(.title3)
                .foregroundStyle(Color(hex: action.domain.accentColorHex))
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Color(hex: action.domain.accentColorHex).opacity(0.12))
                )

            Text(action.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 72)
    }
}
