import SwiftUI
import AsaUIKit

/// 統計カードコンポーネント
struct StatCard: View {
    let title: String
    let value: String
    let iconName: String
    var iconColor: Color = AsaColors.coffeeBrown

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AsaColors.darkSlate)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
