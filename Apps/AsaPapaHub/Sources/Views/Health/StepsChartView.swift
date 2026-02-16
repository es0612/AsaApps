import SwiftUI
import Charts
import AsaPapaHubKit
import AsaUIKit

// MARK: - 歩数チャートビュー

/// 歩数の折れ線グラフ
struct StepsChartView: View {
    let dashboards: [HubDashboard]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("歩数")
                    .font(.headline)
                Spacer()
                Text("目標: 10,000歩")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dashboards.isEmpty {
                emptyChart
            } else {
                Chart {
                    // 目標ライン
                    RuleMark(y: .value("目標", 10000))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .foregroundStyle(.green.opacity(0.5))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("目標")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }

                    // 歩数データ
                    ForEach(dashboards, id: \.id) { dashboard in
                        LineMark(
                            x: .value("日付", dashboard.date, unit: .day),
                            y: .value("歩数", dashboard.stepsCount)
                        )
                        .foregroundStyle(AsaColors.coffeeBrown)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("日付", dashboard.date, unit: .day),
                            y: .value("歩数", dashboard.stepsCount)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [AsaColors.coffeeBrown.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        PointMark(
                            x: .value("日付", dashboard.date, unit: .day),
                            y: .value("歩数", dashboard.stepsCount)
                        )
                        .foregroundStyle(AsaColors.coffeeBrown)
                        .symbolSize(30)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
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

    private var emptyChart: some View {
        VStack {
            Image(systemName: "chart.xyaxis.line")
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
