import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - 空ドメインビュー

/// データがない時の空状態表示
struct EmptyDomainView: View {
    let domain: LifeDomain
    var message: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: domain.icon)
                .font(.system(size: 48))
                .foregroundStyle(AsaColors.mutedSage.opacity(0.5))

            Text(message ?? "\(domain.displayName)のデータがありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}
