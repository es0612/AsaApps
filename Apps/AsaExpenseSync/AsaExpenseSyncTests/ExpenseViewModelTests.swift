import Testing
import Foundation
@testable import AsaExpenseSync

// MARK: - ExpenseViewModelTests

@MainActor
struct ExpenseViewModelTests {
    // MARK: - Setup

    private func createViewModel() -> ExpenseViewModel {
        let mockService = MockExpenseDataService()
        return ExpenseViewModel(dataService: mockService)
    }

    // MARK: - Transaction Tests

    @Test("取引追加が正しく動作する")
    func testAddTransaction() async {
        let viewModel = createViewModel()
        let userId = "test-user"
        let deviceId = "test-device"

        await viewModel.addTransaction(
            amount: 1000,
            type: .expense,
            title: "テスト支出",
            note: "テストメモ",
            date: Date(),
            categoryId: "food",
            userId: userId,
            deviceId: deviceId
        )

        #expect(viewModel.transactions.count == 1)
        #expect(viewModel.transactions.first?.title == "テスト支出")
        #expect(viewModel.transactions.first?.amount == 1000)
        #expect(viewModel.transactions.first?.type == .expense)
    }

    @Test("収支バランス計算が正しい")
    func testBalanceCalculation() async {
        let viewModel = createViewModel()
        let userId = "test-user"
        let deviceId = "test-device"

        // 収入を追加
        await viewModel.addTransaction(
            amount: 10000,
            type: .income,
            title: "給与",
            categoryId: "salary",
            userId: userId,
            deviceId: deviceId
        )

        // 支出を追加
        await viewModel.addTransaction(
            amount: 3000,
            type: .expense,
            title: "食費",
            categoryId: "food",
            userId: userId,
            deviceId: deviceId
        )

        await viewModel.addTransaction(
            amount: 2000,
            type: .expense,
            title: "交通費",
            categoryId: "transport",
            userId: userId,
            deviceId: deviceId
        )

        #expect(viewModel.totalIncome == 10000)
        #expect(viewModel.totalExpense == 5000)
        #expect(viewModel.balance == 5000)
    }

    @Test("取引フィルタリングが正しく動作する")
    func testTransactionFiltering() async {
        let viewModel = createViewModel()
        let userId = "test-user"
        let deviceId = "test-device"

        await viewModel.addTransaction(
            amount: 5000,
            type: .income,
            title: "収入1",
            categoryId: "salary",
            userId: userId,
            deviceId: deviceId
        )

        await viewModel.addTransaction(
            amount: 1000,
            type: .expense,
            title: "支出1",
            categoryId: "food",
            userId: userId,
            deviceId: deviceId
        )

        // 支出のみフィルタ
        viewModel.selectedTransactionType = .expense

        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.type == .expense)
    }

    @Test("検索フィルタリングが正しく動作する")
    func testSearchFiltering() async {
        let viewModel = createViewModel()
        let userId = "test-user"
        let deviceId = "test-device"

        await viewModel.addTransaction(
            amount: 1000,
            type: .expense,
            title: "スーパーで買い物",
            userId: userId,
            deviceId: deviceId
        )

        await viewModel.addTransaction(
            amount: 2000,
            type: .expense,
            title: "コンビニ",
            userId: userId,
            deviceId: deviceId
        )

        // 検索
        viewModel.searchText = "スーパー"

        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.title == "スーパーで買い物")
    }

    @Test("フィルタクリアが正しく動作する")
    func testClearFilters() async {
        let viewModel = createViewModel()

        viewModel.selectedTransactionType = .expense
        viewModel.selectedCategoryId = "food"
        viewModel.searchText = "test"

        viewModel.clearFilters()

        #expect(viewModel.selectedTransactionType == nil)
        #expect(viewModel.selectedCategoryId == nil)
        #expect(viewModel.searchText == "")
    }
}

// MARK: - ConflictResolverTests

struct ConflictResolverTests {
    @Test("Last-Write-Wins戦略が正しく動作する")
    func testLastWriteWinsStrategy() {
        let resolver = ConflictResolver.shared

        let localTransaction = ExpenseTransaction(
            id: "tx1",
            amount: 1000,
            type: .expense,
            title: "ローカル更新",
            userId: "user1",
            deviceId: "device1",
            syncVersion: 1,
            updatedAt: Date()
        )

        let remoteTransaction = ExpenseTransaction(
            id: "tx1",
            amount: 2000,
            type: .expense,
            title: "リモート更新",
            userId: "user1",
            deviceId: "device2",
            syncVersion: 1,
            updatedAt: Date().addingTimeInterval(-60) // 1分前
        )

        let conflict = ConflictInfo(
            transactionId: "tx1",
            localVersion: localTransaction,
            remoteVersion: remoteTransaction,
            conflictType: .updateUpdate
        )

        let resolved = resolver.resolve(conflict: conflict, strategy: .lastWriteWins)

        #expect(resolved.title == "ローカル更新")
        #expect(resolved.amount == 1000)
    }

    @Test("Local-Wins戦略が正しく動作する")
    func testLocalWinsStrategy() {
        let resolver = ConflictResolver.shared

        let localTransaction = ExpenseTransaction(
            id: "tx1",
            amount: 1000,
            type: .expense,
            title: "ローカル",
            userId: "user1",
            deviceId: "device1"
        )

        let remoteTransaction = ExpenseTransaction(
            id: "tx1",
            amount: 2000,
            type: .expense,
            title: "リモート",
            userId: "user1",
            deviceId: "device2"
        )

        let conflict = ConflictInfo(
            transactionId: "tx1",
            localVersion: localTransaction,
            remoteVersion: remoteTransaction,
            conflictType: .updateUpdate
        )

        let resolved = resolver.resolve(conflict: conflict, strategy: .localWins)

        #expect(resolved.title == "ローカル")
    }

    @Test("Remote-Wins戦略が正しく動作する")
    func testRemoteWinsStrategy() {
        let resolver = ConflictResolver.shared

        let localTransaction = ExpenseTransaction(
            id: "tx1",
            amount: 1000,
            type: .expense,
            title: "ローカル",
            userId: "user1",
            deviceId: "device1"
        )

        let remoteTransaction = ExpenseTransaction(
            id: "tx1",
            amount: 2000,
            type: .expense,
            title: "リモート",
            userId: "user1",
            deviceId: "device2"
        )

        let conflict = ConflictInfo(
            transactionId: "tx1",
            localVersion: localTransaction,
            remoteVersion: remoteTransaction,
            conflictType: .updateUpdate
        )

        let resolved = resolver.resolve(conflict: conflict, strategy: .remoteWins)

        #expect(resolved.title == "リモート")
    }
}

// MARK: - ExpenseTransactionTests

struct ExpenseTransactionTests {
    @Test("金額フォーマットが正しい")
    func testFormattedAmount() {
        let income = ExpenseTransaction(
            amount: 10000,
            type: .income,
            title: "給与",
            userId: "user1",
            deviceId: "device1"
        )

        let expense = ExpenseTransaction(
            amount: 5000,
            type: .expense,
            title: "食費",
            userId: "user1",
            deviceId: "device1"
        )

        #expect(income.formattedAmount.contains("+"))
        #expect(expense.formattedAmount.contains("-"))
    }

    @Test("TransactionTypeのシンボルが正しい")
    func testTransactionTypeSymbol() {
        #expect(TransactionType.income.symbol == "+")
        #expect(TransactionType.expense.symbol == "-")
    }

    @Test("サンプルデータが正しく生成される")
    func testSampleTransactions() {
        let samples = ExpenseTransaction.sampleTransactions

        #expect(samples.count == 4)
        #expect(samples.contains { $0.type == .income })
        #expect(samples.contains { $0.type == .expense })
    }
}

// MARK: - ExpenseCategoryTests

struct ExpenseCategoryTests {
    @Test("デフォルトカテゴリが正しく定義されている")
    func testDefaultCategories() {
        let expenseCategories = ExpenseCategory.defaultExpenseCategories
        let incomeCategories = ExpenseCategory.defaultIncomeCategories

        #expect(expenseCategories.count == 8)
        #expect(incomeCategories.count == 5)
        #expect(expenseCategories.allSatisfy { $0.transactionType == .expense })
        #expect(incomeCategories.allSatisfy { $0.transactionType == .income })
    }

    @Test("カテゴリの色が正しく変換される")
    func testCategoryColor() {
        let category = ExpenseCategory(
            id: "test",
            name: "テスト",
            iconName: "star",
            colorHex: "#FF6B6B",
            transactionType: .expense
        )

        #expect(category.color != nil)
    }
}
