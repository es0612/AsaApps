import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - 朝活スコア詳細ビュー

/// 朝活スコアの詳細・履歴ビュー
struct MorningScoreDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var routines: [MorningRoutine] = []

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 直近の朝活スコアグラフ
                scoreChartSection

                // 履歴リスト
                historySection
            }
            .padding()
        }
        .navigationTitle("朝活スコア詳細")
        .background(Color(.systemGroupedBackground))
        .task { await loadData() }
    }

    // MARK: - スコアチャート

    private var scoreChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近7日間の朝活スコア")
                .font(.headline)

            // 簡易棒グラフ
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(routines.prefix(7), id: \.id) { routine in
                    VStack(spacing: 4) {
                        Text("\(routine.totalScore)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(for: routine.totalScore))
                            .frame(width: 32, height: barHeight(for: routine.totalScore))

                        Text(dayLabel(for: routine.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - 履歴セクション

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("履歴")
                .font(.headline)

            if routines.isEmpty {
                EmptyDomainView(domain: .morning, message: "まだ朝活の記録がありません")
            } else {
                ForEach(routines, id: \.id) { routine in
                    historyRow(routine)
                }
            }
        }
    }

    private func historyRow(_ routine: MorningRoutine) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(routine.completedItemsCount)/\(routine.items.count) アイテム完了")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ScoreRing(
                progress: Double(routine.totalScore) / 100.0,
                lineWidth: 4,
                size: 40
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        )
    }

    // MARK: - Private Methods

    private func loadData() async {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<MorningRoutine>(
            predicate: #Predicate { $0.date >= weekAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        routines = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func barColor(for score: Int) -> Color {
        switch score {
        case 80...100: .green
        case 60..<80: AsaColors.coffeeBrown
        case 40..<60: .orange
        default: .red.opacity(0.6)
        }
    }

    private func barHeight(for score: Int) -> CGFloat {
        max(CGFloat(score) / 100.0 * 120.0, 8)
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
