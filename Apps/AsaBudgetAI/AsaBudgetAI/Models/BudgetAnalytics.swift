import Foundation

// MARK: - BudgetAnalytics

/// 日次分析データの集計
struct BudgetAnalytics: Codable, Sendable, Identifiable {
    let id: UUID
    let date: Date
    let totalIncome: Double
    let totalExpense: Double
    let transactionCount: Int
    let categoryBreakdown: [CategoryBreakdown]
    let dailyAverage: Double
    let comparedToAverage: Double   // 平均比 (-1.0 to +1.0)

    var netAmount: Double {
        totalIncome - totalExpense
    }

    var isPositive: Bool {
        netAmount >= 0
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        totalIncome: Double = 0,
        totalExpense: Double = 0,
        transactionCount: Int = 0,
        categoryBreakdown: [CategoryBreakdown] = [],
        dailyAverage: Double = 0,
        comparedToAverage: Double = 0
    ) {
        self.id = id
        self.date = date
        self.totalIncome = totalIncome
        self.totalExpense = totalExpense
        self.transactionCount = transactionCount
        self.categoryBreakdown = categoryBreakdown
        self.dailyAverage = dailyAverage
        self.comparedToAverage = comparedToAverage
    }
}

// MARK: - CategoryBreakdown

struct CategoryBreakdown: Codable, Sendable, Identifiable {
    var id: UUID { categoryId }
    let categoryId: UUID
    let categoryName: String
    let amount: Double
    let percentage: Double
    let transactionCount: Int

    init(
        categoryId: UUID,
        categoryName: String,
        amount: Double,
        percentage: Double,
        transactionCount: Int
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.amount = amount
        self.percentage = percentage
        self.transactionCount = transactionCount
    }
}

// MARK: - MonthlyTrend

/// 月次トレンドデータ
struct MonthlyTrend: Codable, Sendable, Identifiable {
    let id: UUID
    let month: String               // "2024-01" 形式
    let year: Int
    let monthNumber: Int            // 1-12
    let totalExpense: Double
    let totalIncome: Double
    let transactionCount: Int
    let categoryTotals: [UUID: Double]
    let trend: TrendDirection

    var netAmount: Double {
        totalIncome - totalExpense
    }

    var displayMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: month) {
            formatter.dateFormat = "M月"
            return formatter.string(from: date)
        }
        return month
    }

    enum TrendDirection: String, Codable, Sendable {
        case up = "up"
        case down = "down"
        case stable = "stable"
    }

    init(
        id: UUID = UUID(),
        month: String,
        year: Int,
        monthNumber: Int,
        totalExpense: Double,
        totalIncome: Double,
        transactionCount: Int,
        categoryTotals: [UUID: Double] = [:],
        trend: TrendDirection = .stable
    ) {
        self.id = id
        self.month = month
        self.year = year
        self.monthNumber = monthNumber
        self.totalExpense = totalExpense
        self.totalIncome = totalIncome
        self.transactionCount = transactionCount
        self.categoryTotals = categoryTotals
        self.trend = trend
    }
}

// MARK: - WeeklyHeatmapData

/// 曜日×時間帯のヒートマップデータ
struct WeeklyHeatmapData: Codable, Sendable {
    let data: [[Double]]            // 7×24の2次元配列 [曜日][時間]
    let maxValue: Double
    let totalTransactions: Int

    static let empty = WeeklyHeatmapData(
        data: Array(repeating: Array(repeating: 0, count: 24), count: 7),
        maxValue: 0,
        totalTransactions: 0
    )

    func value(weekday: Int, hour: Int) -> Double {
        guard weekday >= 0, weekday < 7, hour >= 0, hour < 24 else { return 0 }
        return data[weekday][hour]
    }

    func normalizedValue(weekday: Int, hour: Int) -> Double {
        guard maxValue > 0 else { return 0 }
        return value(weekday: weekday, hour: hour) / maxValue
    }

    static let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    init(data: [[Double]], maxValue: Double, totalTransactions: Int) {
        self.data = data
        self.maxValue = maxValue
        self.totalTransactions = totalTransactions
    }
}

// MARK: - BudgetProgress

/// 予算進捗データ
struct BudgetProgress: Codable, Sendable, Identifiable {
    let id: UUID
    let budgetId: UUID
    let date: Date
    let spent: Double
    let budget: Double
    let percentage: Double
    let dailyTarget: Double
    let actualDaily: Double
    let onTrack: Bool

    var remaining: Double {
        max(budget - spent, 0)
    }

    var isOverBudget: Bool {
        spent > budget
    }

    init(
        id: UUID = UUID(),
        budgetId: UUID,
        date: Date = Date(),
        spent: Double,
        budget: Double,
        dailyTarget: Double,
        actualDaily: Double
    ) {
        self.id = id
        self.budgetId = budgetId
        self.date = date
        self.spent = spent
        self.budget = budget
        self.percentage = budget > 0 ? min((spent / budget) * 100, 100) : 0
        self.dailyTarget = dailyTarget
        self.actualDaily = actualDaily
        self.onTrack = actualDaily <= dailyTarget
    }
}

// MARK: - DashboardSummary

/// ダッシュボード用サマリーデータ
struct DashboardSummary: Codable, Sendable {
    let totalExpenseThisMonth: Double
    let totalIncomeThisMonth: Double
    let budgetRemaining: Double
    let budgetPercentage: Double
    let topCategories: [CategoryBreakdown]
    let recentAnomalies: Int
    let activeAlertLevel: AlertLevel
    let daysUntilBudgetEnd: Int
    let dailyBudgetRemaining: Double
    let comparedToLastMonth: Double     // 前月比 (-1.0 to +1.0)

    var netAmount: Double {
        totalIncomeThisMonth - totalExpenseThisMonth
    }

    var isPositive: Bool {
        netAmount >= 0
    }

    static let empty = DashboardSummary(
        totalExpenseThisMonth: 0,
        totalIncomeThisMonth: 0,
        budgetRemaining: 0,
        budgetPercentage: 0,
        topCategories: [],
        recentAnomalies: 0,
        activeAlertLevel: .normal,
        daysUntilBudgetEnd: 0,
        dailyBudgetRemaining: 0,
        comparedToLastMonth: 0
    )

    init(
        totalExpenseThisMonth: Double,
        totalIncomeThisMonth: Double,
        budgetRemaining: Double,
        budgetPercentage: Double,
        topCategories: [CategoryBreakdown],
        recentAnomalies: Int,
        activeAlertLevel: AlertLevel,
        daysUntilBudgetEnd: Int,
        dailyBudgetRemaining: Double,
        comparedToLastMonth: Double
    ) {
        self.totalExpenseThisMonth = totalExpenseThisMonth
        self.totalIncomeThisMonth = totalIncomeThisMonth
        self.budgetRemaining = budgetRemaining
        self.budgetPercentage = budgetPercentage
        self.topCategories = topCategories
        self.recentAnomalies = recentAnomalies
        self.activeAlertLevel = activeAlertLevel
        self.daysUntilBudgetEnd = daysUntilBudgetEnd
        self.dailyBudgetRemaining = dailyBudgetRemaining
        self.comparedToLastMonth = comparedToLastMonth
    }
}
