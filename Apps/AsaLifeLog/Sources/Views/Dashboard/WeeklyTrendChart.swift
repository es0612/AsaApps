import SwiftUI
import Charts

// MARK: - WeeklyTrendChart

/// 週間トレンドチャート（AreaMark）
struct WeeklyTrendChart: View {
    let stepsData: [Date: Int]
    let sleepData: [Date: Double]

    private var sortedSteps: [(date: Date, value: Double)] {
        stepsData.map { (date: $0.key, value: Double($0.value) / 10000.0) }
            .sorted { $0.date < $1.date }
    }

    private var sortedSleep: [(date: Date, value: Double)] {
        sleepData.map { (date: $0.key, value: $0.value / 8.0) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        AsaLifeLogCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("週間トレンド（正規化）")
                    .font(.subheadline.weight(.semibold))

                if sortedSteps.isEmpty && sortedSleep.isEmpty {
                    Text("データなし")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    Chart {
                        ForEach(sortedSteps, id: \.date) { item in
                            AreaMark(
                                x: .value("日付", item.date, unit: .day),
                                y: .value("達成率", item.value)
                            )
                            .foregroundStyle(.blue.opacity(0.3))
                            .interpolationMethod(.catmullRom)
                        }
                        ForEach(sortedSleep, id: \.date) { item in
                            AreaMark(
                                x: .value("日付", item.date, unit: .day),
                                y: .value("達成率", item.value)
                            )
                            .foregroundStyle(.purple.opacity(0.3))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .frame(height: 200)
                    .chartLegend(.visible)
                }
            }
        }
    }
}
