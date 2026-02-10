import SwiftUI
import Charts
import AsaUIKit
import AsaFinancePlannerKit

struct GrowthProjectionChart: View {
    let points: [ProjectionPoint]
    @State private var selectedYear: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("資産成長予測")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if points.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
    }

    private var chartContent: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(points) { point in
                    // 名目値（エリア）
                    AreaMark(
                        x: .value("年", point.year),
                        y: .value("名目値", NSDecimalNumber(decimal: point.nominalValue).doubleValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AsaColors.coffeeBrown.opacity(0.3), AsaColors.coffeeBrown.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // 名目値ライン
                    LineMark(
                        x: .value("年", point.year),
                        y: .value("名目値", NSDecimalNumber(decimal: point.nominalValue).doubleValue)
                    )
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    // 実質値ライン
                    LineMark(
                        x: .value("年", point.year),
                        y: .value("実質値", NSDecimalNumber(decimal: point.realValue).doubleValue)
                    )
                    .foregroundStyle(AsaColors.mutedSage)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))

                    // 積立累計ライン
                    LineMark(
                        x: .value("年", point.year),
                        y: .value("積立累計", NSDecimalNumber(decimal: point.contributionTotal).doubleValue)
                    )
                    .foregroundStyle(AsaColors.mocha.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }

                if let selected = selectedYear,
                   let point = points.first(where: { $0.year == selected }) {
                    RuleMark(x: .value("年", selected))
                        .foregroundStyle(AsaColors.darkSlate.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .annotation(position: .top) {
                            annotationView(for: point)
                        }
                }
            }
            .chartXSelection(value: $selectedYear)
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
            .frame(height: 250)
            .accessibilityLabel("資産成長予測チャート、\(points.count)年分のデータ")

            legendRow
        }
    }

    private var legendRow: some View {
        HStack(spacing: 16) {
            legendItem(color: AsaColors.coffeeBrown, label: "名目値", isDashed: false)
            legendItem(color: AsaColors.mutedSage, label: "実質値", isDashed: true)
            legendItem(color: AsaColors.mocha.opacity(0.5), label: "積立累計", isDashed: true)
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, label: String, isDashed: Bool) -> some View {
        HStack(spacing: 4) {
            if isDashed {
                Rectangle()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                    .frame(width: 16, height: 2)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 2)
            }
            Text(label)
                .foregroundStyle(AsaColors.darkSlate)
        }
    }

    private func annotationView(for point: ProjectionPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(point.year)年後")
                .font(.caption2)
                .fontWeight(.bold)
            Text("名目: \(formatAmount(point.nominalValue))")
                .font(.caption2)
            Text("実質: \(formatAmount(point.realValue))")
                .font(.caption2)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(AsaColors.mutedSage.opacity(0.5))
            Text("予測データがありません")
                .font(.caption)
                .foregroundStyle(AsaColors.mutedSage)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }

    private func formatAmount(_ value: Decimal) -> String {
        let intValue = NSDecimalNumber(decimal: value).intValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: intValue)) ?? "\(intValue)") + "円"
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
