import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - 家族サマリーカード

/// ダッシュボードグリッドの家族ドメインサマリー
struct FamilySummaryCard: View {
    let snapshot: DomainSnapshot?

    // MARK: - Body

    var body: some View {
        NavigationLink {
            FamilyHubView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                DomainSectionHeader(domain: .family, showChevron: true)

                if let snapshot {
                    Text("\(snapshot.score)点")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AsaColors.darkSlate)

                    Text(snapshot.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    TrendIndicator(trend: snapshot.trend)
                } else {
                    Text("--")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
