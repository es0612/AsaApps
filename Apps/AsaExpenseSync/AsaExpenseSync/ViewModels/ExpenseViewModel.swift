import Foundation
import SwiftUI

// MARK: - ExpenseViewModel

@MainActor
@Observable
final class ExpenseViewModel: ObservableObject {
    // MARK: - Properties

    var transactions: [ExpenseTransaction] = []
    var categories: [ExpenseCategory] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // Filters
    var selectedTransactionType: TransactionType? = nil
    var selectedCategoryId: String? = nil
    var searchText: String = ""
    var dateRange: ClosedRange<Date>?

    // Sync Status
    var syncMetadata: SyncMetadata = SyncMetadata()

    private let dataService: ExpenseDataServiceProtocol
    private var transactionListener: Any?
    private var categoryListener: Any?

    // MARK: - Initialization

    init(dataService: ExpenseDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Computed Properties

    var filteredTransactions: [ExpenseTransaction] {
        var result = transactions

        // Filter by transaction type
        if let type = selectedTransactionType {
            result = result.filter { $0.type == type }
        }

        // Filter by category
        if let categoryId = selectedCategoryId {
            result = result.filter { $0.categoryId == categoryId }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.note?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by date range
        if let range = dateRange {
            result = result.filter { range.contains($0.date) }
        }

        return result.sorted { $0.date > $1.date }
    }

    var totalIncome: Double {
        filteredTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        filteredTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    var balance: Double {
        totalIncome - totalExpense
    }

    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: balance)) ?? "¥0"
    }

    var expenseCategories: [ExpenseCategory] {
        categories.filter { $0.transactionType == .expense }
    }

    var incomeCategories: [ExpenseCategory] {
        categories.filter { $0.transactionType == .income }
    }

    var recentTransactions: [ExpenseTransaction] {
        Array(filteredTransactions.prefix(5))
    }

    var expensesByCategory: [(category: ExpenseCategory, amount: Double)] {
        let expenses = filteredTransactions.filter { $0.type == .expense }

        var categoryAmounts: [String: Double] = [:]
        for transaction in expenses {
            let categoryId = transaction.categoryId ?? "other_expense"
            categoryAmounts[categoryId, default: 0] += transaction.amount
        }

        return categoryAmounts.compactMap { categoryId, amount in
            guard let category = categories.first(where: { $0.id == categoryId }) else {
                return nil
            }
            return (category, amount)
        }.sorted { $0.amount > $1.amount }
    }

    // MARK: - Data Loading

    func loadData(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            async let transactionsTask = dataService.fetchTransactions(userId: userId)
            async let categoriesTask = dataService.fetchCategories(userId: userId)

            transactions = try await transactionsTask
            categories = try await categoriesTask

            syncMetadata.syncStatus = .synced
            syncMetadata.lastSyncTimestamp = Date()
        } catch let error as ExpenseDataError {
            errorMessage = error.localizedDescription
            syncMetadata.syncStatus = .error
        } catch {
            errorMessage = "データの読み込みに失敗しました"
            syncMetadata.syncStatus = .error
        }

        isLoading = false
    }

    func startObserving(userId: String) {
        // Observe transactions
        transactionListener = dataService.observeTransactions(userId: userId) { [weak self] transactions in
            Task { @MainActor in
                self?.transactions = transactions
                self?.syncMetadata.lastSyncTimestamp = Date()
                self?.syncMetadata.syncStatus = .synced
            }
        }

        // Observe categories
        categoryListener = dataService.observeCategories(userId: userId) { [weak self] categories in
            Task { @MainActor in
                self?.categories = categories
            }
        }
    }

    func stopObserving() {
        if let listener = transactionListener {
            dataService.removeListener(listener)
            transactionListener = nil
        }
        if let listener = categoryListener {
            dataService.removeListener(listener)
            categoryListener = nil
        }
    }

    // MARK: - Transaction CRUD

    func addTransaction(
        amount: Double,
        type: TransactionType,
        title: String,
        note: String? = nil,
        date: Date = Date(),
        categoryId: String?,
        userId: String,
        deviceId: String
    ) async {
        let transaction = ExpenseTransaction(
            amount: amount,
            type: type,
            title: title,
            note: note,
            date: date,
            categoryId: categoryId,
            userId: userId,
            deviceId: deviceId
        )

        syncMetadata.syncStatus = .syncing

        do {
            let created = try await dataService.createTransaction(transaction)
            transactions.append(created)
            transactions.sort { $0.date > $1.date }
            syncMetadata.syncStatus = .synced
            syncMetadata.lastSyncTimestamp = Date()
        } catch let error as ExpenseDataError {
            errorMessage = error.localizedDescription
            syncMetadata.syncStatus = .error
        } catch {
            errorMessage = "取引の追加に失敗しました"
            syncMetadata.syncStatus = .error
        }
    }

    func updateTransaction(_ transaction: ExpenseTransaction) async {
        syncMetadata.syncStatus = .syncing

        do {
            try await dataService.updateTransaction(transaction)

            if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
                transactions[index] = transaction
            }

            syncMetadata.syncStatus = .synced
            syncMetadata.lastSyncTimestamp = Date()
        } catch let error as ExpenseDataError {
            errorMessage = error.localizedDescription
            syncMetadata.syncStatus = .error
        } catch {
            errorMessage = "取引の更新に失敗しました"
            syncMetadata.syncStatus = .error
        }
    }

    func deleteTransaction(_ transaction: ExpenseTransaction) async {
        guard let id = transaction.id else { return }

        syncMetadata.syncStatus = .syncing

        do {
            try await dataService.deleteTransaction(id, userId: transaction.userId)
            transactions.removeAll { $0.id == id }
            syncMetadata.syncStatus = .synced
            syncMetadata.lastSyncTimestamp = Date()
        } catch let error as ExpenseDataError {
            errorMessage = error.localizedDescription
            syncMetadata.syncStatus = .error
        } catch {
            errorMessage = "取引の削除に失敗しました"
            syncMetadata.syncStatus = .error
        }
    }

    // MARK: - Filters

    func clearFilters() {
        selectedTransactionType = nil
        selectedCategoryId = nil
        searchText = ""
        dateRange = nil
    }

    func setMonthFilter(year: Int, month: Int) {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let startDate = calendar.date(from: components),
              let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
            return
        }

        dateRange = startDate...endDate
    }

    // MARK: - Helpers

    func category(for id: String?) -> ExpenseCategory? {
        guard let id = id else { return nil }
        return categories.first { $0.id == id }
    }
}
