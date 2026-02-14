import SwiftUI
import Charts

// MARK: - SleepBarChart

/// 睡眠時間チャート（BarMark）
struct SleepBarChart: View {
    let data: [Date: Double]

    private var sortedData: [(date: Date, hours: Double)] {
        data.map { (date: $0.key, hours: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        AsaLifeLogCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("睡眠時間の推移")
                    .font(.subheadline.weight(.semibold))

                if sortedData.isEmpty {
                    Text("データなし")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    Chart(sortedData, id: \.date) { item in
                        BarMark(
                            x: .value("日付", item.date, unit: .day),
                            y: .value("時間", item.hours)
                        )
                        .foregroundStyle(item.hours >= 7 ? .purple : .orange)
                        .cornerRadius(4)

                        // 推奨睡眠ライン
                        RuleMark(y: .value("推奨", 7))
                            .foregroundStyle(.green.opacity(0.5))
                            .lineStyle(StrokeStyle(dash: [5, 3]))
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}
