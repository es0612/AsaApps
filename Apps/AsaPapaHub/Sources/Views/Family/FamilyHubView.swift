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
            VStack(spacing: 20) {
                // スコアヘッダー
                if let snapshot {
                    scoreHeader(snapshot)
                }

                // 家族イベントカード
                FamilyEventCard()

                // 子供の学習カード
                KidsLearningCard()

                // フォトハイライト
                PhotoHighlightView()
            }
            .padding()
        }
        .navigationTitle("家族")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
    }

    // MARK: - スコアヘッダー

    private func scoreHeader(_ snapshot: DomainSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("家族スコア")
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
                gradientColors: [.purple, .indigo]
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
        let familyRaw = LifeDomain.family.rawValue
        let descriptor = FetchDescriptor<DomainSnapshot>(
            predicate: #Predicate {
                $0.date >= today && $0.date < tomorrow && $0.domainRawValue == familyRaw
            }
        )
        snapshot = try? modelContext.fetch(descriptor).first
    }
}
