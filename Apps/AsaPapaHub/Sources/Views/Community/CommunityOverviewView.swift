import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - 地域オーバービュー

/// 地域ドメインの詳細ビュー
struct CommunityOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var snapshot: DomainSnapshot?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // スコアヘッダー
                if let snapshot {
                    communityScoreHeader(snapshot)
                }

                // 地域イベントカード
                LocalEventCard()

                // 安全ステータスカード
                SafetyStatusCard()
            }
            .padding()
        }
        .navigationTitle("地域")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
    }

    // MARK: - スコアヘッダー

    private func communityScoreHeader(_ snapshot: DomainSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("地域スコア")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(snapshot.score)点")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.darkSlate)
                TrendIndicator(trend: snapshot.trend)
            }

            Spacer()

            ScoreRing(
                progress: Double(snapshot.score) / 100.0,
                lineWidth: 8,
                size: 72,
                gradientColors: [.blue, .cyan]
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - Private

    private func loadData() async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let communityRaw = LifeDomain.community.rawValue
        let descriptor = FetchDescriptor<DomainSnapshot>(
            predicate: #Predicate {
                $0.date >= today && $0.date < tomorrow && $0.domainRawValue == communityRaw
            }
        )
        snapshot = try? modelContext.fetch(descriptor).first
    }
}
