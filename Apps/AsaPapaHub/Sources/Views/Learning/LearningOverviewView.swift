import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - 学習オーバービュー

/// 学習ドメインの詳細ビュー
struct LearningOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var snapshot: DomainSnapshot?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // スコアヘッダー
                if let snapshot {
                    learningScoreHeader(snapshot)
                }

                // 学習ストリーク
                StudyStreakView()

                // 最近の学習
                RecentLearningCard()
            }
            .padding()
        }
        .navigationTitle("学習")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
    }

    // MARK: - スコアヘッダー

    private func learningScoreHeader(_ snapshot: DomainSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("学習スコア")
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
                gradientColors: [.purple, .pink]
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
        let learningRaw = LifeDomain.learning.rawValue
        let descriptor = FetchDescriptor<DomainSnapshot>(
            predicate: #Predicate {
                $0.date >= today && $0.date < tomorrow && $0.domainRawValue == learningRaw
            }
        )
        snapshot = try? modelContext.fetch(descriptor).first
    }
}
