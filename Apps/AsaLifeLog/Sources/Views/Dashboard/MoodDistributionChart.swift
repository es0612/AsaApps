import SwiftUI
import Charts
import AsaLifeLogKit

// MARK: - MoodDistributionChart

/// 気分分布チャート（SectorMark）
struct MoodDistributionChart: View {
    let distribution: [MoodScore: Int]

    private var chartData: [(mood: MoodScore, count: Int)] {
        MoodScore.allCases.compactMap { mood in
            guard let count = distribution[mood], count > 0 else { return nil }
            return (mood: mood, count: count)
        }
    }

    var body: some View {
        AsaLifeLogCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("気分の分布")
                    .font(.subheadline.weight(.semibold))

                if chartData.isEmpty {
                    Text("データなし")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    Chart(chartData, id: \.mood) { item in
                        SectorMark(
                            angle: .value("回数", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 1
                        )
                        .foregroundStyle(by: .value("気分", item.mood.emoji + " " + item.mood.displayName))
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}
