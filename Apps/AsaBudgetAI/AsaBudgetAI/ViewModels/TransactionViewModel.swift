import Foundation

// MARK: - TransactionViewModel

/// 取引管理画面のViewModel
@Observable
@MainActor
final class TransactionViewModel {

    // MARK: - Properties

    var transactions: [Transaction] = []
    var filteredTransactions: [Transaction] = []
    var categories: [Category] = []
    var isLoading = false

    // フィルター状態
    var searchText = ""
    var selectedType: TransactionType?
    var selectedCategory: Category?
    var selectedDateRange: DateRangeFilter = .all
    var sortOption: TransactionSortOption = .dateDescending

    // フォーム状態
    var isShowingAddForm = false
    var editingTransaction: Transaction?

    // MARK: - Dependencies

    private let dataService: DataService

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        transactions = dataService.fetchTransactions(sortBy: sortOption)
        categories = dataService.fetchCategories()
        applyFilters()
        isLoading = false
    }

    // MARK: - Filtering

    func applyFilters() {
        var result = transactions

        // テキスト検索
        if !searchText.isEmpty {
            result = result.filter { transaction in
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                (transaction.note?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                transaction.category?.name.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        // 種類フィルター
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }

        // カテゴリフィルター
        if let category = selectedCategory {
            result = result.filter { $0.category?.id == category.id }
        }

        // 日付範囲フィルター
        let calendar = Calendar.current
        let now = Date()

        switch selectedDateRange {
        case .all:
            break
        case .today:
            result = result.filter { calendar.isDateInToday($0.date) }
        case .thisWeek:
            result = result.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        case .thisMonth:
            result = result.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .lastMonth:
            if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) {
                result = result.filter { calendar.isDate($0.date, equalTo: lastMonth, toGranularity: .month) }
            }
        case .custom(let start, let end):
            result = result.filter { $0.date >= start && $0.date <= end }
        }

        filteredTransactions = result
    }

    func clearFilters() {
        searchText = ""
        selectedType = nil
        selectedCategory = nil
        selectedDateRange = .all
        applyFilters()
    }

    // MARK: - Sorting

    func updateSortOption(_ option: TransactionSortOption) {
        sortOption = option
        transactions = dataService.fetchTransactions(sortBy: option)
        applyFilters()
    }

    // MARK: - CRUD Operations

    func deleteTransaction(_ transaction: Transaction) {
        dataService.deleteTransaction(transaction)
        loadData()
    }

    func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let transaction = filteredTransactions[index]
            dataService.deleteTransaction(transaction)
        }
        loadData()
    }

    // MARK: - Computed Properties

    var totalExpense: Double {
        filteredTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    var totalIncome: Double {
        filteredTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    var netAmount: Double {
        totalIncome - totalExpense
    }

    var transactionCount: Int {
        filteredTransactions.count
    }

    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        selectedType != nil ||
        selectedCategory != nil ||
        selectedDateRange != .all
    }

    // グループ化された取引（日付別）
    var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }

        return grouped
            .map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - DateRangeFilter

enum DateRangeFilter: Equatable {
    case all
    case today
    case thisWeek
    case thisMonth
    case lastMonth
    case custom(start: Date, end: Date)

    var displayName: String {
        switch self {
        case .all: return "すべて"
        case .today: return "今日"
        case .thisWeek: return "今週"
        case .thisMonth: return "今月"
        case .lastMonth: return "先月"
        case .custom: return "カスタム"
        }
    }

    static func == (lhs: DateRangeFilter, rhs: DateRangeFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all),
             (.today, .today),
             (.thisWeek, .thisWeek),
             (.thisMonth, .thisMonth),
             (.lastMonth, .lastMonth):
            return true
        case (.custom(let lStart, let lEnd), .custom(let rStart, let rEnd)):
            return lStart == rStart && lEnd == rEnd
        default:
            return false
        }
    }

    static var quickFilters: [DateRangeFilter] {
        [.all, .today, .thisWeek, .thisMonth, .lastMonth]
    }
}
