import SwiftUI
import Charts
import AsaUIKit
import AsaFinancePlannerKit

struct ScenarioLineChart: View {
    let scenarios: [ScenarioProjection]
    @State private var selectedYear: Int?

    private let colors: [Color] = [
        AsaColors.coffeeBrown,
        .blue,
        .green,
        .orange,
        .purple,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("シナリオ比較")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if scenarios.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
    }

    private var chartContent: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(Array(scenarios.enumerated()), id: \.element.id) { index, scenario in
                    let color = colors[index % colors.count]
                    ForEach(scenario.points) { point in
                        LineMark(
                            x: .value("年", point.year),
                            y: .value("金額", NSDecimalNumber(decimal: point.nominalValue).doubleValue)
                        )
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    .foregroundStyle(by: .value("シナリオ", scenario.scenarioName))
                }

                if let selected = selectedYear {
                    RuleMark(x: .value("年", selected))
                        .foregroundStyle(AsaColors.darkSlate.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }
            .chartXSelection(value: $selectedYear)
            .chartForegroundStyleScale(range: colors.prefix(scenarios.count).map { $0 })
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatCompact(amount))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text("\(year)年")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartLegend(position: .bottom)
            .frame(height: 250)
            .accessibilityLabel("シナリオ比較チャート、\(scenarios.count)シナリオ")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.largeTitle)
                .foregroundStyle(AsaColors.mutedSage.opacity(0.5))
            Text("シナリオデータがありません")
                .font(.caption)
                .foregroundStyle(AsaColors.mutedSage)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }

    private func formatCompact(_ amount: Double) -> String {
        if amount >= 100_000_000 {
            return String(format: "%.1f億", amount / 100_000_000)
        } else if amount >= 10_000 {
            return String(format: "%.0f万", amount / 10_000)
        }
        return String(format: "%.0f", amount)
    }
}
