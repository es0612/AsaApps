import Testing
import Foundation
@testable import AsaExpenseSync

@MainActor
struct ExpenseViewModelTests {
    // MARK: - Setup

    private func createTestViewModel() -> (ExpenseViewModel, MockExpenseDataService) {
        let mockService = MockExpenseDataService()
        let viewModel = ExpenseViewModel(dataService: mockService)
        return (viewModel, mockService)
    }

    // MARK: - Transaction Tests

    @Test("取引追加が正しく動作する")
    func testAddTransaction() async {
        let (viewModel, _) = createTestViewModel()

        await viewModel.addTransaction(
            amount: 1000,
            type: .expense,
            title: "テスト支出",
            note: "テストメモ",
            date: Date(),
            categoryId: "food",
            userId: "test-user",
            deviceId: "test-device"
        )

        #expect(viewModel.transactions.count == 1)
        #expect(viewModel.transactions.first?.title == "テスト支出")
        #expect(viewModel.transactions.first?.amount == 1000)
    }

    @Test("収支バランスが正しく計算される")
    func testBalanceCalculation() async {
        let (viewModel, _) = createTestViewModel()

        // Add income
        await viewModel.addTransaction(
            amount: 10000,
            type: .income,
            title: "給与",
            categoryId: "salary",
            userId: "test-user",
            deviceId: "test-device"
        )

        // Add expenses
        await viewModel.addTransaction(
            amount: 3000,
            type: .expense,
            title: "食費",
            categoryId: "food",
            userId: "test-user",
            deviceId: "test-device"
        )

        await viewModel.addTransaction(
            amount: 2000,
            type: .expense,
            title: "交通費",
            categoryId: "transport",
            userId: "test-user",
            deviceId: "test-device"
        )

        #expect(viewModel.totalIncome == 10000)
        #expect(viewModel.totalExpense == 5000)
        #expect(viewModel.balance == 5000)
    }

    @Test("取引削除が正しく動作する")
    func testDeleteTransaction() async {
        let (viewModel, _) = createTestViewModel()

        await viewModel.addTransaction(
            amount: 1000,
            type: .expense,
            title: "削除対象",
            categoryId: "food",
            userId: "test-user",
            deviceId: "test-device"
        )

        #expect(viewModel.transactions.count == 1)

        if let transaction = viewModel.transactions.first {
            await viewModel.deleteTransaction(transaction)
        }

        #expect(viewModel.transactions.count == 0)
    }

    // MARK: - Filter Tests

    @Test("取引タイプでフィルタリングできる")
    func testFilterByType() async {
        let (viewModel, _) = createTestViewModel()

        await viewModel.addTransaction(
            amount: 10000, type: .income, title: "収入1",
            categoryId: "salary", userId: "test-user", deviceId: "test-device"
        )
        await viewModel.addTransaction(
            amount: 5000, type: .expense, title: "支出1",
            categoryId: "food", userId: "test-user", deviceId: "test-device"
        )
        await viewModel.addTransaction(
            amount: 3000, type: .expense, title: "支出2",
            categoryId: "transport", userId: "test-user", deviceId: "test-device"
        )

        // Filter by expense
        viewModel.selectedTransactionType = .expense
        #expect(viewModel.filteredTransactions.count == 2)

        // Filter by income
        viewModel.selectedTransactionType = .income
        #expect(viewModel.filteredTransactions.count == 1)

        // Clear filter
        viewModel.clearFilters()
        #expect(viewModel.filteredTransactions.count == 3)
    }

    @Test("検索テキストでフィルタリングできる")
    func testFilterBySearchText() async {
        let (viewModel, _) = createTestViewModel()

        await viewModel.addTransaction(
            amount: 1000, type: .expense, title: "スーパーで買い物",
            note: "野菜と果物", categoryId: "food", userId: "test-user", deviceId: "test-device"
        )
        await viewModel.addTransaction(
            amount: 2000, type: .expense, title: "レストラン",
            categoryId: "food", userId: "test-user", deviceId: "test-device"
        )

        // Search by title
        viewModel.searchText = "スーパー"
        #expect(viewModel.filteredTransactions.count == 1)

        // Search by note
        viewModel.searchText = "野菜"
        #expect(viewModel.filteredTransactions.count == 1)

        // No match
        viewModel.searchText = "存在しない"
        #expect(viewModel.filteredTransactions.count == 0)
    }

    // MARK: - Category Tests

    @Test("カテゴリ別支出が正しく集計される")
    func testExpensesByCategory() async {
        let (viewModel, mockService) = createTestViewModel()

        // Load categories first
        await viewModel.loadData(userId: "demo-user-id")

        await viewModel.addTransaction(
            amount: 1000, type: .expense, title: "食費1",
            categoryId: "food", userId: "demo-user-id", deviceId: "test-device"
        )
        await viewModel.addTransaction(
            amount: 2000, type: .expense, title: "食費2",
            categoryId: "food", userId: "demo-user-id", deviceId: "test-device"
        )
        await viewModel.addTransaction(
            amount: 500, type: .expense, title: "交通費",
            categoryId: "transport", userId: "demo-user-id", deviceId: "test-device"
        )

        // Reload to update categories
        await viewModel.loadData(userId: "demo-user-id")

        let foodExpense = viewModel.expensesByCategory.first { $0.category.id == "food" }
        #expect(foodExpense?.amount == 3000)
    }

    // MARK: - Sync Status Tests

    @Test("同期ステータスが正しく更新される")
    func testSyncStatus() async {
        let (viewModel, _) = createTestViewModel()

        #expect(viewModel.syncMetadata.syncStatus == .synced)

        await viewModel.addTransaction(
            amount: 1000, type: .expense, title: "テスト",
            categoryId: "food", userId: "test-user", deviceId: "test-device"
        )

        // After successful add, status should be synced
        #expect(viewModel.syncMetadata.syncStatus == .synced)
        #expect(viewModel.syncMetadata.lastSyncTimestamp != nil)
    }
}
