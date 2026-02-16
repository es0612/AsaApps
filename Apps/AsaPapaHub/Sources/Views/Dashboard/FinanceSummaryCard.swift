import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - 資産サマリーカード

/// ダッシュボードグリッドの資産ドメインサマリー
struct FinanceSummaryCard: View {
    let snapshot: DomainSnapshot?

    // MARK: - Body

    var body: some View {
        NavigationLink {
            FinanceOverviewView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                DomainSectionHeader(domain: .finance, showChevron: true)

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
