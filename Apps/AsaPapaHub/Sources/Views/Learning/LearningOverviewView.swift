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
            VStack(spacing: 16) {
                if let snapshot {
                    DomainScoreHeader(
                        domain: .learning,
                        snapshot: snapshot,
                        gradientColors: [.purple, .pink]
                    )
                }

                StudyStreakView()
                RecentLearningCard()
            }
            .padding()
        }
        .navigationTitle("学習")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
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
