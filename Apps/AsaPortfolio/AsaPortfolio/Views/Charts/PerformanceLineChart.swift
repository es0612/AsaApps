import SwiftUI
import Charts
import AsaUIKit

/// 資産推移折れ線グラフ
struct PerformanceLineChart: View {
    let data: [ChartDataPoint]
    let title: String
    var showArea: Bool = true
    var color: Color = AsaColors.coffeeBrown

    @State private var selectedPoint: ChartDataPoint?
    @State private var selectedTimeRange: TimeRange = .month

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // タイトルと期間選択
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AsaColors.darkSlate)

                Spacer()

                timeRangePicker
            }

            if data.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var timeRangePicker: some View {
        Menu {
            ForEach([TimeRange.week, .month, .threeMonths, .year], id: \.self) { range in
                Button(range.displayName) {
                    selectedTimeRange = range
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedTimeRange.displayName)
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(AsaColors.coffeeBrown)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AsaColors.coffeeBrown.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(AsaColors.mutedSage)

            Text("データがありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    private var filteredData: [ChartDataPoint] {
        let startDate = selectedTimeRange.startDate
        return data.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
    }

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 選択中のポイント情報
            if let selected = selectedPoint {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(selected.value.formattedCurrency)
                            .font(.title3.bold())
                            .foregroundStyle(color)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
            }

            // チャート
            Chart(filteredData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", NSDecimalNumber(decimal: point.value).doubleValue)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))

                if showArea {
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", NSDecimalNumber(decimal: point.value).doubleValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                if let selected = selectedPoint, selected.id == point.id {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", NSDecimalNumber(decimal: point.value).doubleValue)
                    )
                    .foregroundStyle(color)
                    .symbolSize(100)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(CurrencyFormatter.formatCompact(Decimal(doubleValue)))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let x = value.location.x - geometry[plotFrame].origin.x
                                    guard let date: Date = proxy.value(atX: x) else { return }

                                    if let closestPoint = filteredData.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    }) {
                                        selectedPoint = closestPoint
                                    }
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
            .frame(height: 200)

            // 期間サマリー
            if let first = filteredData.first, let last = filteredData.last {
                let change = last.value - first.value
                let changePercent = first.value > 0 ?
                    NSDecimalNumber(decimal: change / first.value).doubleValue * 100 : 0

                HStack {
                    Text("期間変動")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(change.formattedCurrency)
                            .font(.caption.bold())
                        Text("(\(changePercent.formattedPercentage))")
                            .font(.caption)
                    }
                    .foregroundStyle(change >= 0 ? .green : .red)
                }
            }
        }
    }

    private var xAxisStride: Int {
        switch selectedTimeRange {
        case .day: return 4
        case .week: return 1
        case .month: return 5
        case .threeMonths: return 14
        case .sixMonths: return 30
        case .year: return 60
        default: return 30
        }
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Decimal
}

// MARK: - Gain/Loss Bar Chart

struct GainLossBarChart: View {
    let holdings: [Holding]
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if holdings.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundStyle(AsaColors.mutedSage)

            Text("データがありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }

    private var sortedHoldings: [Holding] {
        holdings.sorted { $0.gainPercentage > $1.gainPercentage }.prefix(8).map { $0 }
    }

    private var chartContent: some View {
        Chart(sortedHoldings, id: \.id) { holding in
            BarMark(
                x: .value("Symbol", holding.symbol),
                y: .value("Gain %", holding.gainPercentage)
            )
            .foregroundStyle(holding.isProfit ? Color.green.gradient : Color.red.gradient)
            .annotation(position: holding.isProfit ? .top : .bottom) {
                Text(holding.gainPercentage.formattedPercentage)
                    .font(.caption2)
                    .foregroundStyle(holding.isProfit ? .green : .red)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let percent = value.as(Double.self) {
                        Text("\(Int(percent))%")
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 200)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // サンプルデータ
            let sampleData: [ChartDataPoint] = {
                var data: [ChartDataPoint] = []
                var value: Decimal = 10000
                for i in 0..<30 {
                    let date = Calendar.current.date(byAdding: .day, value: -29 + i, to: Date())!
                    value += Decimal(Double.random(in: -200...300))
                    data.append(ChartDataPoint(date: date, value: value))
                }
                return data
            }()

            PerformanceLineChart(
                data: sampleData,
                title: "資産推移"
            )

            PerformanceLineChart(
                data: [],
                title: "空のチャート"
            )
        }
        .padding()
    }
    .background(AsaColors.darkSlate.opacity(0.05))
}
