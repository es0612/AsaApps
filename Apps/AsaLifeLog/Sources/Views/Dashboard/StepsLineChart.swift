import SwiftUI
import Charts

// MARK: - StepsLineChart

/// 歩数推移チャート（LineMark）
struct StepsLineChart: View {
    let data: [Date: Int]

    private var sortedData: [(date: Date, steps: Int)] {
        data.map { (date: $0.key, steps: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        AsaLifeLogCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("歩数の推移")
                    .font(.subheadline.weight(.semibold))

                if sortedData.isEmpty {
                    Text("データなし")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    Chart(sortedData, id: \.date) { item in
                        LineMark(
                            x: .value("日付", item.date, unit: .day),
                            y: .value("歩数", item.steps)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("日付", item.date, unit: .day),
                            y: .value("歩数", item.steps)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                        .interpolationMethod(.catmullRom)

                        // 目標ライン
                        RuleMark(y: .value("目標", 10000))
                            .foregroundStyle(.orange.opacity(0.5))
                            .lineStyle(StrokeStyle(dash: [5, 3]))
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
            }
        }
    }
}
