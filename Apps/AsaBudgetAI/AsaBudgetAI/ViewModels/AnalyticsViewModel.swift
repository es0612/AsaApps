import Foundation

// MARK: - AnalyticsViewModel

/// 分析画面のViewModel
@Observable
@MainActor
final class AnalyticsViewModel {

    // MARK: - Properties

    var monthlyTrends: [MonthlyTrend] = []
    var categoryBreakdown: [CategoryBreakdown] = []
    var weeklyHeatmap: WeeklyHeatmapData = .empty
    var spendingPatterns: [SpendingPattern] = []
    var selectedTimeRange: TimeRange = .threeMonths
    var isLoading = false

    // MARK: - Dependencies

    private let dataService: DataService
    private let patternAnalyzer: SpendingPatternAnalyzer

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
        self.patternAnalyzer = SpendingPatternAnalyzer()
    }

    // MARK: - Data Loading

    func loadAnalytics() {
        isLoading = true

        let calendar = Calendar.current
        let now = Date()

        // 選択された期間に基づいてデータを取得
        let startDate: Date
        switch selectedTimeRange {
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        // 月次トレンドを取得
        monthlyTrends = dataService.fetchMonthlyExpenses(months: selectedTimeRange.months)

        // カテゴリ別内訳を取得
        categoryBreakdown = dataService.fetchCategoryBreakdown(
            startDate: startDate,
            endDate: now
        )

        // ヒートマップデータを生成
        let transactions = dataService.fetchTransactions(
            startDate: startDate,
            endDate: now
        )
        weeklyHeatmap = patternAnalyzer.generateWeeklyHeatmap(transactions: transactions)

        // パターン分析
        spendingPatterns = patternAnalyzer.analyzePatterns(transactions: transactions)

        isLoading = false
    }

    func updateTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        loadAnalytics()
    }

    // MARK: - Chart Data

    /// 月次支出チャート用データ
    var monthlyExpenseChartData: [(label: String, value: Double)] {
        monthlyTrends.map { ($0.displayMonth, $0.totalExpense) }
    }

    /// 月次収入チャート用データ
    var monthlyIncomeChartData: [(label: String, value: Double)] {
        monthlyTrends.map { ($0.displayMonth, $0.totalIncome) }
    }

    /// カテゴリ別円グラフ用データ
    var categoryPieChartData: [(name: String, value: Double, percentage: Double)] {
        categoryBreakdown.map { ($0.categoryName, $0.amount, $0.percentage) }
    }

    /// 平均月次支出
    var averageMonthlyExpense: Double {
        guard !monthlyTrends.isEmpty else { return 0 }
        return monthlyTrends.map { $0.totalExpense }.reduce(0, +) / Double(monthlyTrends.count)
    }

    /// 支出の変動係数
    var expenseVolatility: Double {
        guard monthlyTrends.count > 1 else { return 0 }

        let amounts = monthlyTrends.map { $0.totalExpense }
        let mean = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)

        guard mean > 0 else { return 0 }
        return sqrt(variance) / mean
    }

    /// トレンドの方向
    var overallTrend: TrendDirection {
        guard monthlyTrends.count >= 2 else { return .stable }

        let recent = monthlyTrends.suffix(3)
        let older = monthlyTrends.prefix(3)

        let recentAvg = recent.map { $0.totalExpense }.reduce(0, +) / Double(recent.count)
        let olderAvg = older.map { $0.totalExpense }.reduce(0, +) / Double(older.count)

        guard olderAvg > 0 else { return .stable }

        let change = (recentAvg - olderAvg) / olderAvg

        if change > 0.1 {
            return .increasing
        } else if change < -0.1 {
            return .decreasing
        } else {
            return .stable
        }
    }

    enum TrendDirection: String {
        case increasing = "increasing"
        case decreasing = "decreasing"
        case stable = "stable"

        var displayName: String {
            switch self {
            case .increasing: return "増加傾向"
            case .decreasing: return "減少傾向"
            case .stable: return "安定"
            }
        }

        var icon: String {
            switch self {
            case .increasing: return "arrow.up.right"
            case .decreasing: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
    }
}

// MARK: - TimeRange

enum TimeRange: String, CaseIterable, Sendable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"

    var displayName: String {
        switch self {
        case .oneMonth: return "1ヶ月"
        case .threeMonths: return "3ヶ月"
        case .sixMonths: return "6ヶ月"
        case .oneYear: return "1年"
        }
    }

    var months: Int {
        switch self {
        case .oneMonth: return 1
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        }
    }
}
