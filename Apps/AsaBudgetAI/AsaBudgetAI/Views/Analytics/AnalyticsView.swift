import SwiftUI
import Charts
import AsaUIKit

struct AnalyticsView: View {
    @Bindable var viewModel: BudgetAIViewModel
    @State private var analyticsVM: AnalyticsViewModel?
    @State private var selectedChart: ChartType = .trend

    enum ChartType: String, CaseIterable {
        case trend = "トレンド"
        case category = "カテゴリ"
        case heatmap = "ヒートマップ"
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = analyticsVM {
                    AnalyticsContent(viewModel: vm, selectedChart: $selectedChart)
                } else {
                    ProgressView()
                        .onAppear {
                            initializeAnalyticsVM()
                        }
                }
            }
            .navigationTitle("分析")
        }
    }

    private func initializeAnalyticsVM() {
        do {
            let container = try DataService.createContainer()
            let dataService = DataService(modelContainer: container)
            analyticsVM = AnalyticsViewModel(dataService: dataService)
            analyticsVM?.loadAnalytics()
        } catch {
            print("Failed to initialize AnalyticsViewModel: \(error)")
        }
    }
}

// MARK: - Analytics Content

struct AnalyticsContent: View {
    @Bindable var viewModel: AnalyticsViewModel
    @Binding var selectedChart: AnalyticsView.ChartType

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 期間選択
                TimeRangePicker(selection: $viewModel.selectedTimeRange) {
                    viewModel.loadAnalytics()
                }

                // チャート種類選択
                Picker("チャート", selection: $selectedChart) {
                    ForEach(AnalyticsView.ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // 選択されたチャートを表示
                switch selectedChart {
                case .trend:
                    TrendChartView(viewModel: viewModel)
                case .category:
                    CategoryChartView(viewModel: viewModel)
                case .heatmap:
                    HeatmapView(viewModel: viewModel)
                }

                // パターン分析
                if !viewModel.spendingPatterns.isEmpty {
                    PatternAnalysisCard(patterns: viewModel.spendingPatterns)
                }

                // 統計サマリー
                StatisticsSummaryCard(viewModel: viewModel)
            }
            .padding()
        }
        .refreshable {
            viewModel.loadAnalytics()
        }
    }
}

// MARK: - Time Range Picker

struct TimeRangePicker: View {
    @Binding var selection: TimeRange
    let onChange: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button {
                        selection = range
                        onChange()
                    } label: {
                        Text(range.displayName)
                            .font(.subheadline)
                            .fontWeight(selection == range ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selection == range ? AsaColors.coffeeBrown : Color(.systemGray6))
                            .foregroundColor(selection == range ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Trend Chart View

struct TrendChartView: View {
    @Bindable var viewModel: AnalyticsViewModel

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("月次支出推移")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    // トレンド表示
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.overallTrend.icon)
                        Text(viewModel.overallTrend.displayName)
                    }
                    .font(.caption)
                    .foregroundColor(trendColor)
                }

                if viewModel.monthlyTrends.isEmpty {
                    Text("データがありません")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    Chart(viewModel.monthlyTrends) { trend in
                        BarMark(
                            x: .value("月", trend.displayMonth),
                            y: .value("支出", trend.totalExpense)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AsaColors.coffeeBrown, AsaColors.mocha],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)

                        // 平均ライン
                        RuleMark(y: .value("平均", viewModel.averageMonthlyExpense))
                            .foregroundStyle(.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("平均")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(formatCompact(amount))
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                        }
                    }
                }

                // 平均支出
                HStack {
                    Text("月平均支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(viewModel.averageMonthlyExpense))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }

    private var trendColor: Color {
        switch viewModel.overallTrend {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .blue
        }
    }

    private func formatCompact(_ amount: Double) -> String {
        if amount >= 10000 {
            return String(format: "%.0f万", amount / 10000)
        }
        return String(format: "%.0f", amount)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

// MARK: - Category Chart View

struct CategoryChartView: View {
    @Bindable var viewModel: AnalyticsViewModel

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("カテゴリ別支出")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                if viewModel.categoryBreakdown.isEmpty {
                    Text("データがありません")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    // ドーナツチャート
                    Chart(viewModel.categoryBreakdown) { category in
                        SectorMark(
                            angle: .value("金額", category.amount),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.0
                        )
                        .foregroundStyle(by: .value("カテゴリ", category.categoryName))
                        .cornerRadius(4)
                    }
                    .frame(height: 200)

                    // 凡例
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(viewModel.categoryBreakdown.prefix(6)) { category in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(categoryColor(for: category.categoryName))
                                    .frame(width: 8, height: 8)
                                Text(category.categoryName)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(category.percentage))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func categoryColor(for name: String) -> Color {
        // カテゴリ名に基づいて色を返す（簡易実装）
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow, .teal]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Heatmap View

struct HeatmapView: View {
    @Bindable var viewModel: AnalyticsViewModel

    private let hours = Array(0..<24)
    private let weekdays = WeeklyHeatmapData.weekdayLabels

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("支出ヒートマップ")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Text("曜日×時間帯の支出パターン")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.weeklyHeatmap.totalTransactions == 0 {
                    Text("データがありません")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 2) {
                            // 時間ラベル
                            HStack(spacing: 2) {
                                Text("")
                                    .frame(width: 20)
                                ForEach([0, 6, 12, 18], id: \.self) { hour in
                                    Text("\(hour)時")
                                        .font(.caption2)
                                        .frame(width: 48)
                                }
                            }

                            // ヒートマップグリッド
                            ForEach(0..<7, id: \.self) { weekday in
                                HStack(spacing: 2) {
                                    Text(weekdays[weekday])
                                        .font(.caption2)
                                        .frame(width: 20)

                                    ForEach(hours, id: \.self) { hour in
                                        let value = viewModel.weeklyHeatmap.normalizedValue(
                                            weekday: weekday,
                                            hour: hour
                                        )
                                        Rectangle()
                                            .fill(heatmapColor(value: value))
                                            .frame(width: 10, height: 16)
                                            .cornerRadius(2)
                                    }
                                }
                            }
                        }
                    }

                    // 凡例
                    HStack {
                        Text("少")
                            .font(.caption2)
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 100, height: 10)
                        .cornerRadius(2)
                        Text("多")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private func heatmapColor(value: Double) -> Color {
        if value < 0.25 {
            return Color.green.opacity(0.2 + value * 2)
        } else if value < 0.5 {
            return Color.yellow.opacity(0.5 + value)
        } else if value < 0.75 {
            return Color.orange.opacity(0.5 + value * 0.5)
        } else {
            return Color.red.opacity(0.5 + value * 0.5)
        }
    }
}

// MARK: - Pattern Analysis Card

struct PatternAnalysisCard: View {
    let patterns: [SpendingPattern]

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("検出されたパターン")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                ForEach(patterns.prefix(3)) { pattern in
                    HStack {
                        Image(systemName: pattern.patternType.icon)
                            .foregroundColor(severityColor(pattern.patternType.severity))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pattern.patternType.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(pattern.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(Int(pattern.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func severityColor(_ severity: PatternSeverity) -> Color {
        switch severity {
        case .positive: return .green
        case .neutral: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Statistics Summary Card

struct StatisticsSummaryCard: View {
    @Bindable var viewModel: AnalyticsViewModel

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("統計サマリー")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItem(
                        title: "月平均支出",
                        value: formatCurrency(viewModel.averageMonthlyExpense)
                    )
                    StatItem(
                        title: "変動係数",
                        value: String(format: "%.1f%%", viewModel.expenseVolatility * 100)
                    )
                    StatItem(
                        title: "データ期間",
                        value: viewModel.selectedTimeRange.displayName
                    )
                    StatItem(
                        title: "トレンド",
                        value: viewModel.overallTrend.displayName
                    )
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    AnalyticsView(viewModel: BudgetAIViewModel(dataService: DataService(modelContainer: try! DataService.createContainer())))
}
