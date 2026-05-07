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
            VStack(spacing: 16) {
                if let snapshot {
                    DomainScoreHeader(
                        domain: .community,
                        snapshot: snapshot,
                        gradientColors: [.blue, .cyan]
                    )
                }

                LocalEventCard()
                SafetyStatusCard()
            }
            .padding()
        }
        .navigationTitle("地域")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
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
