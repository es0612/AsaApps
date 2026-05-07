import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - 家族ハブビュー

/// 家族ドメインの詳細ビュー
struct FamilyHubView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var snapshot: DomainSnapshot?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let snapshot {
                    DomainScoreHeader(
                        domain: .family,
                        snapshot: snapshot,
                        gradientColors: [.purple, .indigo]
                    )
                }

                FamilyEventCard()
                KidsLearningCard()
                PhotoHighlightView()
            }
            .padding()
        }
        .navigationTitle("家族")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
    }

    // MARK: - Private

    private func loadData() async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let familyRaw = LifeDomain.family.rawValue
        let descriptor = FetchDescriptor<DomainSnapshot>(
            predicate: #Predicate {
                $0.date >= today && $0.date < tomorrow && $0.domainRawValue == familyRaw
            }
        )
        snapshot = try? modelContext.fetch(descriptor).first
    }
}
