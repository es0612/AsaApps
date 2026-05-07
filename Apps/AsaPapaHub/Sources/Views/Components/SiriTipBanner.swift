import SwiftUI
import AsaUIKit

// MARK: - Siri Tip バナー

/// Phase 6 で SiriTipView に差し替え予定のプレースホルダー
struct SiriTipBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.title3)
                .foregroundStyle(AsaColors.coffeeBrown)

            VStack(alignment: .leading, spacing: 2) {
                Text("Siri で朝活を始めよう")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\"朝活を始めて\" と話しかけてみましょう")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AsaColors.softCream.opacity(0.5))
        )
    }
}
