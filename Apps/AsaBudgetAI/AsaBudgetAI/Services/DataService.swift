import Foundation
import SwiftData

// MARK: - DataService

/// データ永続化サービス
@MainActor
final class DataService: Sendable {

    // MARK: - Properties

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }

    static func createContainer() throws -> ModelContainer {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Budget.self,
            UserSettings.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }

    // MARK: - Transaction Operations

    func fetchTransactions(
        startDate: Date? = nil,
        endDate: Date? = nil,
        type: TransactionType? = nil,
        categoryId: UUID? = nil,
        sortBy: TransactionSortOption = .dateDescending
    ) -> [Transaction] {
        var descriptor = FetchDescriptor<Transaction>()

        // フィルタを構築
        var predicates: [Predicate<Transaction>] = []

        if let startDate = startDate {
            predicates.append(#Predicate<Transaction> { $0.date >= startDate })
        }

        if let endDate = endDate {
            predicates.append(#Predicate<Transaction> { $0.date <= endDate })
        }

        if let type = type {
            let typeRaw = type.rawValue
            predicates.append(#Predicate<Transaction> { $0.typeRawValue == typeRaw })
        }

        // 複合プレディケートを作成
        if !predicates.isEmpty {
            // 簡易実装：startDateのみのフィルタ
            if let startDate = startDate, let endDate = endDate {
                descriptor.predicate = #Predicate<Transaction> {
                    $0.date >= startDate && $0.date <= endDate
                }
            } else if let startDate = startDate {
                descriptor.predicate = #Predicate<Transaction> { $0.date >= startDate }
            } else if let endDate = endDate {
                descriptor.predicate = #Predicate<Transaction> { $0.date <= endDate }
            }
        }

        // ソート
        switch sortBy {
        case .dateDescending:
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        case .dateAscending:
            descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        case .amountDescending:
            descriptor.sortBy = [SortDescriptor(\.amount, order: .reverse)]
        case .amountAscending:
            descriptor.sortBy = [SortDescriptor(\.amount, order: .forward)]
        }

        do {
            var transactions = try modelContext.fetch(descriptor)

            // 追加フィルタリング（SwiftDataのPredicate制限を回避）
            if let type = type {
                transactions = transactions.filter { $0.type == type }
            }

            if let categoryId = categoryId {
                transactions = transactions.filter { $0.category?.id == categoryId }
            }

            return transactions
        } catch {
            print("Error fetching transactions: \(error)")
            return []
        }
    }

    func addTransaction(_ transaction: Transaction) {
        modelContext.insert(transaction)
        saveContext()
    }

    func updateTransaction(_ transaction: Transaction) {
        transaction.updatedAt = Date()
        saveContext()
    }

    func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)
        saveContext()
    }

    // MARK: - Category Operations

    func fetchCategories() -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }

    func addCategory(_ category: Category) {
        modelContext.insert(category)
        saveContext()
    }

    func deleteCategory(_ category: Category) {
        modelContext.delete(category)
        saveContext()
    }

    func initializeDefaultCategories() {
        let existingCategories = fetchCategories()
        guard existingCategories.isEmpty else { return }

        let defaults = Category.defaultCategories()
        for category in defaults {
            modelContext.insert(category)
        }
        saveContext()
    }

    // MARK: - Budget Operations

    func fetchBudgets(activeOnly: Bool = false) -> [Budget] {
        var descriptor = FetchDescriptor<Budget>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        if activeOnly {
            descriptor.predicate = #Predicate<Budget> { $0.isActive == true }
        }

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching budgets: \(error)")
            return []
        }
    }

    func fetchCurrentBudget() -> Budget? {
        let now = Date()
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> {
                $0.isActive == true && $0.startDate <= now && $0.endDate >= now
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching current budget: \(error)")
            return nil
        }
    }

    func addBudget(_ budget: Budget) {
        modelContext.insert(budget)
        saveContext()
    }

    func updateBudget(_ budget: Budget) {
        budget.updatedAt = Date()
        saveContext()
    }

    func deleteBudget(_ budget: Budget) {
        modelContext.delete(budget)
        saveContext()
    }

    // MARK: - UserSettings Operations

    func fetchUserSettings() -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            if let settings = try modelContext.fetch(descriptor).first {
                return settings
            }
        } catch {
            print("Error fetching user settings: \(error)")
        }

        // 設定が存在しない場合は新規作成
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        saveContext()
        return newSettings
    }

    func updateUserSettings(_ settings: UserSettings) {
        settings.updatedAt = Date()
        saveContext()
    }

    // MARK: - Analytics

    func fetchMonthlyExpenses(months: Int = 6) -> [MonthlyTrend] {
        let calendar = Calendar.current
        let now = Date()

        var trends: [MonthlyTrend] = []

        for monthOffset in 0..<months {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                continue
            }

            let transactions = fetchTransactions(startDate: monthStart, endDate: monthEnd)

            let totalExpense = transactions
                .filter { $0.type == .expense }
                .reduce(0) { $0 + $1.amount }

            let totalIncome = transactions
                .filter { $0.type == .income }
                .reduce(0) { $0 + $1.amount }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            let monthKey = formatter.string(from: monthStart)

            let year = calendar.component(.year, from: monthStart)
            let monthNumber = calendar.component(.month, from: monthStart)

            trends.append(MonthlyTrend(
                month: monthKey,
                year: year,
                monthNumber: monthNumber,
                totalExpense: totalExpense,
                totalIncome: totalIncome,
                transactionCount: transactions.count
            ))
        }

        return trends.reversed()
    }

    func fetchCategoryBreakdown(startDate: Date, endDate: Date) -> [CategoryBreakdown] {
        let transactions = fetchTransactions(
            startDate: startDate,
            endDate: endDate,
            type: .expense
        )

        let totalAmount = transactions.reduce(0) { $0 + $1.amount }
        guard totalAmount > 0 else { return [] }

        // カテゴリ別に集計
        var categoryTotals: [UUID: (name: String, amount: Double, count: Int)] = [:]

        for transaction in transactions {
            guard let category = transaction.category else { continue }
            var current = categoryTotals[category.id] ?? (category.name, 0, 0)
            current.amount += transaction.amount
            current.count += 1
            categoryTotals[category.id] = current
        }

        return categoryTotals.map { (categoryId, data) in
            CategoryBreakdown(
                categoryId: categoryId,
                categoryName: data.name,
                amount: data.amount,
                percentage: (data.amount / totalAmount) * 100,
                transactionCount: data.count
            )
        }.sorted { $0.amount > $1.amount }
    }

    // MARK: - Helper Methods

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - TransactionSortOption

enum TransactionSortOption: String, CaseIterable, Sendable {
    case dateDescending = "date_desc"
    case dateAscending = "date_asc"
    case amountDescending = "amount_desc"
    case amountAscending = "amount_asc"

    var displayName: String {
        switch self {
        case .dateDescending: return "日付（新しい順）"
        case .dateAscending: return "日付（古い順）"
        case .amountDescending: return "金額（高い順）"
        case .amountAscending: return "金額（低い順）"
        }
    }
}
