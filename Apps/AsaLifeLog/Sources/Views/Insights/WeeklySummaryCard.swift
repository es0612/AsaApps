import SwiftUI
import AsaLifeLogKit

// MARK: - WeeklySummaryCard

/// 週次サマリーカード
struct WeeklySummaryCard: View {
    let insight: WeeklyInsightResult?

    var body: some View {
        AsaLifeLogCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text("今週のまとめ")
                        .font(.headline)
                    Spacer()
                }

                if let insight {
                    Text(insight.summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !insight.moodTrend.isEmpty {
                        Label(insight.moodTrend, systemImage: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }

                    if let comparison = insight.comparisonText {
                        Label(comparison, systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !insight.topTags.isEmpty {
                        HStack {
                            ForEach(insight.topTags.prefix(5), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                } else {
                    Text("1週間分のデータが蓄積されると、週次インサイトが表示されます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
