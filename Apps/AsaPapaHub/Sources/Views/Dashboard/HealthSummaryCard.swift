import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - 健康サマリーカード

/// ダッシュボードグリッドの健康ドメインサマリー
struct HealthSummaryCard: View {
    let snapshot: DomainSnapshot?
    let dashboard: HubDashboard?

    // MARK: - Body

    var body: some View {
        NavigationLink {
            HealthOverviewView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                DomainSectionHeader(domain: .health, showChevron: true)

                if let dashboard {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .font(.caption)
                        Text("\(dashboard.stepsCount)歩")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(AsaColors.darkSlate)

                    HStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .font(.caption)
                        Text(String(format: "%.1f時間", dashboard.sleepHours))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Text("--")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                if let snapshot {
                    TrendIndicator(trend: snapshot.trend)
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
