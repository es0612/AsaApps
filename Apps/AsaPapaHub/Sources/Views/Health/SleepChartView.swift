import SwiftUI
import Charts
import AsaPapaHubKit
import AsaUIKit

// MARK: - 睡眠チャートビュー

/// 睡眠時間の棒グラフ
struct SleepChartView: View {
    let dashboards: [HubDashboard]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("睡眠")
                    .font(.headline)
                Spacer()
                Text("目標: 7時間")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dashboards.isEmpty {
                emptyChart
            } else {
                Chart {
                    // 目標ライン
                    RuleMark(y: .value("目標", 7.0))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .foregroundStyle(.blue.opacity(0.5))

                    ForEach(dashboards, id: \.id) { dashboard in
                        BarMark(
                            x: .value("日付", dashboard.date, unit: .day),
                            y: .value("時間", dashboard.sleepHours)
                        )
                        .foregroundStyle(barColor(for: dashboard.sleepHours))
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text(String(format: "%.0fh", hours))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - Private

    private func barColor(for hours: Double) -> Color {
        switch hours {
        case 7...: .blue
        case 6..<7: .blue.opacity(0.6)
        default: .red.opacity(0.6)
        }
    }

    private var emptyChart: some View {
        VStack {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("データがありません")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}
