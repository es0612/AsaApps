import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - 資産オーバービュー

/// 資産ドメインの詳細ビュー
struct FinanceOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var snapshot: DomainSnapshot?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let snapshot {
                    DomainScoreHeader(
                        domain: .finance,
                        snapshot: snapshot,
                        gradientColors: [.green, .mint]
                    )
                }

                GoalProgressCard()
                MonthlySpendingChart()
            }
            .padding()
        }
        .navigationTitle("資産")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
    }

    // MARK: - Private

    private func loadData() async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let financeRaw = LifeDomain.finance.rawValue
        let descriptor = FetchDescriptor<DomainSnapshot>(
            predicate: #Predicate {
                $0.date >= today && $0.date < tomorrow && $0.domainRawValue == financeRaw
            }
        )
        snapshot = try? modelContext.fetch(descriptor).first
    }
}
