import AsaUIKit
import SwiftUI

// MARK: - 空状態ビュー

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
                .foregroundStyle(AsaColors.mutedSage)
        } description: {
            Text(description)
                .foregroundStyle(.secondary)
        }
    }
}
