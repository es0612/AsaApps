import SwiftUI
import AsaPapaHubKit

// MARK: - ドメインセクションヘッダー

/// ドメインのアイコンと名前を表示するセクションヘッダー
struct DomainSectionHeader: View {
    let domain: LifeDomain
    var showChevron: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: domain.icon)
                .font(.subheadline)
                .foregroundStyle(Color(hex: domain.accentColorHex))
                .frame(width: 24)

            Text(domain.displayName)
                .font(.headline)
                .foregroundStyle(Color(hex: domain.accentColorHex))

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
