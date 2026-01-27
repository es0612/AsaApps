import Foundation

// MARK: - MockExpenseDataService

final class MockExpenseDataService: ExpenseDataServiceProtocol, @unchecked Sendable {
    // MARK: - Properties

    private var transactions: [String: [ExpenseTransaction]] = [:] // userId -> transactions
    private var categories: [String: [ExpenseCategory]] = [:]
    private var budgets: [String: [Budget]] = [:]
    private var syncTimestamps: [String: Date] = [:]

    private var transactionObservers: [String: ([ExpenseTransaction]) -> Void] = [:]
    private var categoryObservers: [String: ([ExpenseCategory]) -> Void] = [:]

    // MARK: - Initialization

    init() {
        // Pre-populate with sample data for demo user
        let demoUserId = "demo-user-id"
        transactions[demoUserId] = ExpenseTransaction.sampleTransactions
        categories[demoUserId] = ExpenseCategory.allDefaultCategories
    }

    // MARK: - Transactions

    func fetchTransactions(userId: String) async throws -> [ExpenseTransaction] {
        try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
        return transactions[userId]?.filter { !$0.isDeleted } ?? []
    }

    func createTransaction(_ transaction: ExpenseTransaction) async throws -> ExpenseTransaction {
        try await Task.sleep(nanoseconds: 200_000_000)

        var newTransaction = transaction
        newTransaction.id = UUID().uuidString
        newTransaction.createdAt = Date()
        newTransaction.updatedAt = Date()
        newTransaction.syncVersion = 1

        if transactions[transaction.userId] == nil {
            transactions[transaction.userId] = []
        }
        transactions[transaction.userId]?.append(newTransaction)

        // Notify observers
        notifyTransactionObservers(userId: transaction.userId)

        print("MockExpenseDataService: Transaction created - \(newTransaction.title)")
        return newTransaction
    }

    func updateTransaction(_ transaction: ExpenseTransaction) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let index = transactions[transaction.userId]?.firstIndex(where: { $0.id == transaction.id }) else {
            throw ExpenseDataError.notFound
        }

        var updatedTransaction = transaction
        updatedTransaction.updatedAt = Date()
        updatedTransaction.syncVersion += 1

        transactions[transaction.userId]?[index] = updatedTransaction

        // Notify observers
        notifyTransactionObservers(userId: transaction.userId)

        print("MockExpenseDataService: Transaction updated - \(transaction.title)")
    }

    func deleteTransaction(_ transactionId: String, userId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let index = transactions[userId]?.firstIndex(where: { $0.id == transactionId }) else {
            throw ExpenseDataError.notFound
        }

        // Soft delete
        transactions[userId]?[index].isDeleted = true
        transactions[userId]?[index].updatedAt = Date()

        // Notify observers
        notifyTransactionObservers(userId: userId)

        print("MockExpenseDataService: Transaction deleted - \(transactionId)")
    }

    // MARK: - Categories

    func fetchCategories(userId: String) async throws -> [ExpenseCategory] {
        try await Task.sleep(nanoseconds: 200_000_000)

        // Return default categories if none exist for user
        if categories[userId] == nil || categories[userId]?.isEmpty == true {
            categories[userId] = ExpenseCategory.allDefaultCategories
        }

        return categories[userId] ?? []
    }

    func createCategory(_ category: ExpenseCategory) async throws -> ExpenseCategory {
        try await Task.sleep(nanoseconds: 200_000_000)

        var newCategory = category
        newCategory.id = UUID().uuidString

        if categories[category.userId ?? ""] == nil {
            categories[category.userId ?? ""] = []
        }
        categories[category.userId ?? ""]?.append(newCategory)

        // Notify observers
        if let userId = category.userId {
            notifyCategoryObservers(userId: userId)
        }

        return newCategory
    }

    func updateCategory(_ category: ExpenseCategory) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let userId = category.userId,
              let index = categories[userId]?.firstIndex(where: { $0.id == category.id }) else {
            throw ExpenseDataError.notFound
        }

        categories[userId]?[index] = category

        // Notify observers
        notifyCategoryObservers(userId: userId)
    }

    func deleteCategory(_ categoryId: String, userId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        categories[userId]?.removeAll { $0.id == categoryId }

        // Notify observers
        notifyCategoryObservers(userId: userId)
    }

    // MARK: - Budgets

    func fetchBudgets(userId: String) async throws -> [Budget] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return budgets[userId] ?? []
    }

    func createBudget(_ budget: Budget) async throws -> Budget {
        try await Task.sleep(nanoseconds: 200_000_000)

        var newBudget = budget
        newBudget.id = UUID().uuidString
        newBudget.createdAt = Date()
        newBudget.updatedAt = Date()

        if budgets[budget.userId] == nil {
            budgets[budget.userId] = []
        }
        budgets[budget.userId]?.append(newBudget)

        return newBudget
    }

    func updateBudget(_ budget: Budget) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let index = budgets[budget.userId]?.firstIndex(where: { $0.id == budget.id }) else {
            throw ExpenseDataError.notFound
        }

        var updatedBudget = budget
        updatedBudget.updatedAt = Date()
        budgets[budget.userId]?[index] = updatedBudget
    }

    func deleteBudget(_ budgetId: String, userId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        budgets[userId]?.removeAll { $0.id == budgetId }
    }

    // MARK: - Real-time Observation

    func observeTransactions(userId: String, handler: @escaping ([ExpenseTransaction]) -> Void) -> Any {
        let observerId = UUID().uuidString
        transactionObservers[observerId] = { transactions in
            let filtered = transactions.filter { $0.userId == userId && !$0.isDeleted }
            handler(filtered)
        }

        // Initial callback
        let currentTransactions = transactions[userId]?.filter { !$0.isDeleted } ?? []
        handler(currentTransactions)

        return observerId
    }

    func observeCategories(userId: String, handler: @escaping ([ExpenseCategory]) -> Void) -> Any {
        let observerId = UUID().uuidString
        categoryObservers[observerId] = { categories in
            let filtered = categories.filter { $0.userId == userId || $0.isDefault }
            handler(filtered)
        }

        // Initial callback
        let currentCategories = categories[userId] ?? ExpenseCategory.allDefaultCategories
        handler(currentCategories)

        return observerId
    }

    func removeListener(_ listener: Any) {
        guard let observerId = listener as? String else { return }
        transactionObservers.removeValue(forKey: observerId)
        categoryObservers.removeValue(forKey: observerId)
    }

    // MARK: - Sync

    func getLastSyncTimestamp(userId: String) async throws -> Date? {
        return syncTimestamps[userId]
    }

    func updateLastSyncTimestamp(userId: String, timestamp: Date) async throws {
        syncTimestamps[userId] = timestamp
    }

    // MARK: - Private Helpers

    private func notifyTransactionObservers(userId: String) {
        let allTransactions = transactions[userId] ?? []
        for (_, handler) in transactionObservers {
            handler(allTransactions)
        }
    }

    private func notifyCategoryObservers(userId: String) {
        let allCategories = categories[userId] ?? []
        for (_, handler) in categoryObservers {
            handler(allCategories)
        }
    }
}
