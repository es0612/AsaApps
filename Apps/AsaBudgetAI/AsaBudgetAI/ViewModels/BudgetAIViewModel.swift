import Foundation
import SwiftData
import Combine

// MARK: - BudgetAIViewModel

/// メインのViewModel
@Observable
@MainActor
final class BudgetAIViewModel {

    // MARK: - Published Properties

    var transactions: [Transaction] = []
    var categories: [Category] = []
    var currentBudget: Budget?
    var settings: UserSettings
    var dashboardSummary: DashboardSummary = .empty
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let dataService: DataService
    private let analyzer: EnhancedSpendingAnalyzer
    private let notificationService: NotificationService

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
        self.analyzer = EnhancedSpendingAnalyzer()
        self.notificationService = NotificationService.shared
        self.settings = dataService.fetchUserSettings()

        // 初期データをロード
        loadInitialData()
    }

    // MARK: - Data Loading

    func loadInitialData() {
        isLoading = true

        // カテゴリを初期化
        dataService.initializeDefaultCategories()
        categories = dataService.fetchCategories()

        // 取引を取得
        transactions = dataService.fetchTransactions()

        // 現在の予算を取得
        currentBudget = dataService.fetchCurrentBudget()

        // ダッシュボードサマリーを更新
        updateDashboardSummary()

        isLoading = false
    }

    func refreshData() {
        transactions = dataService.fetchTransactions()
        categories = dataService.fetchCategories()
        currentBudget = dataService.fetchCurrentBudget()
        settings = dataService.fetchUserSettings()
        updateDashboardSummary()
    }

    // MARK: - Dashboard Summary

    private func updateDashboardSummary() {
        let calendar = Calendar.current
        let now = Date()

        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return
        }

        let thisMonthTransactions = transactions.filter { $0.date >= monthStart }

        let totalExpense = thisMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        let totalIncome = thisMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        // 前月比を計算
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart)!
        let lastMonthEnd = monthStart

        let lastMonthExpense = transactions
            .filter { $0.type == .expense && $0.date >= lastMonthStart && $0.date < lastMonthEnd }
            .reduce(0) { $0 + $1.amount }

        let comparedToLastMonth = lastMonthExpense > 0
            ? (totalExpense - lastMonthExpense) / lastMonthExpense
            : 0

        // カテゴリ別内訳
        let breakdown = dataService.fetchCategoryBreakdown(
            startDate: monthStart,
            endDate: now
        )

        // 異常検知数
        let anomalyCount = thisMonthTransactions.filter { $0.isAnomaly }.count

        // 予算情報
        let budgetRemaining = currentBudget?.remainingAmount ?? 0
        let budgetPercentage = currentBudget?.spentPercentage ?? 0
        let daysRemaining = currentBudget?.daysRemaining ?? 0
        let dailyBudget = currentBudget?.dailyBudget ?? 0

        // アラートレベルを判定
        let alertLevel: AlertLevel
        if budgetPercentage >= 100 {
            alertLevel = .critical
        } else if budgetPercentage >= 90 {
            alertLevel = .warning
        } else if budgetPercentage >= 70 {
            alertLevel = .caution
        } else {
            alertLevel = .normal
        }

        dashboardSummary = DashboardSummary(
            totalExpenseThisMonth: totalExpense,
            totalIncomeThisMonth: totalIncome,
            budgetRemaining: budgetRemaining,
            budgetPercentage: budgetPercentage,
            topCategories: Array(breakdown.prefix(5)),
            recentAnomalies: anomalyCount,
            activeAlertLevel: alertLevel,
            daysUntilBudgetEnd: daysRemaining,
            dailyBudgetRemaining: dailyBudget,
            comparedToLastMonth: comparedToLastMonth
        )

        // 予算警告をチェック
        checkBudgetWarnings()
    }

    // MARK: - Transaction Operations

    func addTransaction(
        amount: Double,
        title: String,
        note: String?,
        date: Date,
        type: TransactionType,
        category: Category?
    ) async {
        let transaction = Transaction(
            amount: amount,
            title: title,
            note: note,
            date: date,
            type: type,
            category: category,
            budget: currentBudget
        )

        // 異常検知を実行
        if type == .expense && settings.autoAnomalyDetection {
            let quickResult = await analyzer.quickAnalysis(
                transaction: transaction,
                recentTransactions: transactions,
                settings: settings
            )

            if quickResult.isAnomaly {
                transaction.markAsAnomaly(
                    score: quickResult.anomalyScore,
                    reasons: quickResult.alerts
                )

                // 異常通知を送信
                if settings.anomalyNotificationEnabled {
                    notificationService.sendAnomalyNotification(
                        transactionId: transaction.id,
                        title: title,
                        amount: amount,
                        reasons: quickResult.alerts
                    )
                }
            }
        }

        dataService.addTransaction(transaction)
        refreshData()
    }

    func updateTransaction(_ transaction: Transaction) {
        dataService.updateTransaction(transaction)
        refreshData()
    }

    func deleteTransaction(_ transaction: Transaction) {
        dataService.deleteTransaction(transaction)
        refreshData()
    }

    // MARK: - Budget Operations

    func createBudget(name: String, amount: Double, period: BudgetPeriod) {
        // 既存のアクティブな予算を非アクティブに
        if let existing = currentBudget {
            existing.isActive = false
            dataService.updateBudget(existing)
        }

        let budget = Budget(name: name, totalAmount: amount, period: period)
        dataService.addBudget(budget)
        currentBudget = budget
        refreshData()
    }

    func updateBudget(_ budget: Budget) {
        dataService.updateBudget(budget)
        refreshData()
    }

    // MARK: - Budget Warnings

    private func checkBudgetWarnings() {
        guard let budget = currentBudget else { return }

        let percentage = budget.spentPercentage

        if percentage >= 100 && settings.budgetWarningAt100 {
            let overage = budget.spentAmount - budget.totalAmount
            notificationService.sendBudgetExceededNotification(
                budgetId: budget.id,
                budgetName: budget.name,
                overage: overage
            )
        } else if percentage >= 90 && settings.budgetWarningAt90 {
            notificationService.scheduleBudgetWarning(
                budgetId: budget.id,
                percentage: 90,
                budgetName: budget.name,
                remaining: budget.remainingAmount
            )
        } else if percentage >= 70 && settings.budgetWarningAt70 {
            notificationService.scheduleBudgetWarning(
                budgetId: budget.id,
                percentage: 70,
                budgetName: budget.name,
                remaining: budget.remainingAmount
            )
        }
    }

    // MARK: - Settings

    func updateSettings(_ settings: UserSettings) {
        self.settings = settings
        dataService.updateUserSettings(settings)

        // 日次レポート通知を更新
        if settings.dailyReportEnabled {
            notificationService.scheduleDailyReport(hour: settings.dailyReportHour)
        } else {
            notificationService.cancelDailyReport()
        }
    }

    // MARK: - Category Operations

    func addCategory(name: String, iconName: String, colorHex: String) {
        let category = Category(
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            sortOrder: categories.count
        )
        dataService.addCategory(category)
        categories = dataService.fetchCategories()
    }

    func deleteCategory(_ category: Category) {
        dataService.deleteCategory(category)
        categories = dataService.fetchCategories()
    }
}

// MARK: - Computed Properties

extension BudgetAIViewModel {
    var recentTransactions: [Transaction] {
        Array(transactions.prefix(10))
    }

    var thisMonthExpenses: Double {
        dashboardSummary.totalExpenseThisMonth
    }

    var thisMonthIncome: Double {
        dashboardSummary.totalIncomeThisMonth
    }

    var budgetProgress: Double {
        dashboardSummary.budgetPercentage / 100
    }

    var hasActiveBudget: Bool {
        currentBudget != nil && currentBudget!.isActive
    }

    var anomalyTransactions: [Transaction] {
        transactions.filter { $0.isAnomaly }
    }
}
