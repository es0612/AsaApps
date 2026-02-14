import SwiftUI
import Charts
import AsaLifeLogKit

// MARK: - ActivityBreakdownChart

/// アクティビティ内訳チャート（SectorMark）
struct ActivityBreakdownChart: View {
    let breakdown: [ActivityType: Int]

    private var chartData: [(type: ActivityType, count: Int)] {
        ActivityType.allCases.compactMap { type in
            guard let count = breakdown[type], count > 0 else { return nil }
            return (type: type, count: count)
        }
    }

    var body: some View {
        AsaLifeLogCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("アクティビティの内訳")
                    .font(.subheadline.weight(.semibold))

                if chartData.isEmpty {
                    Text("データなし")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    Chart(chartData, id: \.type) { item in
                        SectorMark(
                            angle: .value("回数", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 1
                        )
                        .foregroundStyle(by: .value("活動", item.type.displayName))
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}
