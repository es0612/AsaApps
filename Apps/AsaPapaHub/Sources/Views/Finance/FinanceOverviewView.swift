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
            VStack(spacing: 20) {
                // スコアヘッダー
                if let snapshot {
                    financeScoreHeader(snapshot)
                }

                // 目標進捗カード
                GoalProgressCard()

                // 月次支出チャート
                MonthlySpendingChart()
            }
            .padding()
        }
        .navigationTitle("資産")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
    }

    // MARK: - スコアヘッダー

    private func financeScoreHeader(_ snapshot: DomainSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("資産スコア")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(snapshot.score)点")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.darkSlate)
                TrendIndicator(trend: snapshot.trend)

                Text(snapshot.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            Spacer()

            ScoreRing(
                progress: Double(snapshot.score) / 100.0,
                lineWidth: 8,
                size: 72,
                gradientColors: [.green, .mint]
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
        let financeRaw = LifeDomain.finance.rawValue
        let descriptor = FetchDescriptor<DomainSnapshot>(
            predicate: #Predicate {
                $0.date >= today && $0.date < tomorrow && $0.domainRawValue == financeRaw
            }
        )
        snapshot = try? modelContext.fetch(descriptor).first
    }
}
