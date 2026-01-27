import Foundation

// MARK: - ExpenseDataError

enum ExpenseDataError: Error, LocalizedError {
    case fetchFailed(String)
    case createFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case syncFailed(String)
    case conflictDetected(ConflictInfo)
    case notAuthenticated
    case notFound
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message): return "取得失敗: \(message)"
        case .createFailed(let message): return "作成失敗: \(message)"
        case .updateFailed(let message): return "更新失敗: \(message)"
        case .deleteFailed(let message): return "削除失敗: \(message)"
        case .syncFailed(let message): return "同期失敗: \(message)"
        case .conflictDetected: return "データ競合が検出されました"
        case .notAuthenticated: return "認証が必要です"
        case .notFound: return "データが見つかりません"
        case .unknown(let error): return "エラー: \(error.localizedDescription)"
        }
    }
}

// MARK: - ExpenseDataServiceProtocol

protocol ExpenseDataServiceProtocol: AnyObject, Sendable {
    // MARK: - Transactions

    func fetchTransactions(userId: String) async throws -> [ExpenseTransaction]
    func fetchTransaction(id: String, userId: String) async throws -> ExpenseTransaction?
    func createTransaction(_ transaction: ExpenseTransaction) async throws -> ExpenseTransaction
    func updateTransaction(_ transaction: ExpenseTransaction) async throws
    func deleteTransaction(_ transactionId: String, userId: String) async throws

    // MARK: - Categories

    func fetchCategories(userId: String) async throws -> [ExpenseCategory]
    func createCategory(_ category: ExpenseCategory) async throws -> ExpenseCategory
    func updateCategory(_ category: ExpenseCategory) async throws
    func deleteCategory(_ categoryId: String, userId: String) async throws

    // MARK: - Budgets

    func fetchBudgets(userId: String) async throws -> [Budget]
    func createBudget(_ budget: Budget) async throws -> Budget
    func updateBudget(_ budget: Budget) async throws
    func deleteBudget(_ budgetId: String, userId: String) async throws

    // MARK: - Real-time Observation

    func observeTransactions(userId: String, handler: @escaping ([ExpenseTransaction]) -> Void) -> Any
    func observeCategories(userId: String, handler: @escaping ([ExpenseCategory]) -> Void) -> Any
    func removeListener(_ listener: Any)

    // MARK: - Sync

    func getLastSyncTimestamp(userId: String) async throws -> Date?
    func updateLastSyncTimestamp(userId: String, timestamp: Date) async throws

    // MARK: - Batch Operations

    func batchCreateTransactions(_ transactions: [ExpenseTransaction]) async throws -> [ExpenseTransaction]
    func batchDeleteTransactions(_ transactionIds: [String], userId: String) async throws
}

// MARK: - Default Implementation

extension ExpenseDataServiceProtocol {
    func fetchTransaction(id: String, userId: String) async throws -> ExpenseTransaction? {
        let transactions = try await fetchTransactions(userId: userId)
        return transactions.first { $0.id == id }
    }

    func batchCreateTransactions(_ transactions: [ExpenseTransaction]) async throws -> [ExpenseTransaction] {
        var results: [ExpenseTransaction] = []
        for transaction in transactions {
            let created = try await createTransaction(transaction)
            results.append(created)
        }
        return results
    }

    func batchDeleteTransactions(_ transactionIds: [String], userId: String) async throws {
        for id in transactionIds {
            try await deleteTransaction(id, userId: userId)
        }
    }

    func getLastSyncTimestamp(userId: String) async throws -> Date? {
        return nil
    }

    func updateLastSyncTimestamp(userId: String, timestamp: Date) async throws {
        // Default implementation does nothing
    }
}
