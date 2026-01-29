import SwiftUI
import AsaUIKit

struct TransactionListView: View {
    @Bindable var viewModel: BudgetAIViewModel
    @State private var transactionVM: TransactionViewModel?
    @State private var showAddTransaction = false
    @State private var showFilterSheet = false
    @State private var selectedTransaction: Transaction?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = transactionVM {
                    TransactionListContent(
                        viewModel: vm,
                        onSelect: { selectedTransaction = $0 }
                    )
                } else {
                    ProgressView()
                        .onAppear {
                            initializeTransactionVM()
                        }
                }
            }
            .navigationTitle("取引一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: transactionVM?.hasActiveFilters == true
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView(viewModel: viewModel)
            }
            .sheet(isPresented: $showFilterSheet) {
                if let vm = transactionVM {
                    FilterSheetView(viewModel: vm)
                }
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction, viewModel: viewModel)
            }
        }
    }

    private func initializeTransactionVM() {
        if transactionVM == nil {
            do {
                let container = try DataService.createContainer()
                let dataService = DataService(modelContainer: container)
                transactionVM = TransactionViewModel(dataService: dataService)
            } catch {
                print("Failed to initialize TransactionViewModel: \(error)")
            }
        }
    }
}

// MARK: - Transaction List Content

struct TransactionListContent: View {
    @Bindable var viewModel: TransactionViewModel
    let onSelect: (Transaction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 検索バー
            SearchBar(text: $viewModel.searchText) {
                viewModel.applyFilters()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // サマリー
            TransactionSummaryBar(
                expense: viewModel.totalExpense,
                income: viewModel.totalIncome,
                count: viewModel.transactionCount
            )

            // 取引リスト
            if viewModel.filteredTransactions.isEmpty {
                EmptyTransactionView(hasFilters: viewModel.hasActiveFilters) {
                    viewModel.clearFilters()
                }
            } else {
                List {
                    ForEach(viewModel.groupedTransactions, id: \.date) { group in
                        Section(header: Text(formatSectionDate(group.date))) {
                            ForEach(group.transactions) { transaction in
                                TransactionRowView(transaction: transaction)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onSelect(transaction)
                                    }
                            }
                            .onDelete { offsets in
                                deleteTransactions(in: group.transactions, at: offsets)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func deleteTransactions(in transactions: [Transaction], at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteTransaction(transactions[index])
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let onSearch: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("取引を検索...", text: $text)
                .textFieldStyle(.plain)
                .onChange(of: text) { _, _ in
                    onSearch()
                }

            if !text.isEmpty {
                Button {
                    text = ""
                    onSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Transaction Summary Bar

struct TransactionSummaryBar: View {
    let expense: Double
    let income: Double
    let count: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("支出")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(expense))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            Spacer()

            VStack(alignment: .center, spacing: 2) {
                Text("収入")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(income))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("件数")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(count)件")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

// MARK: - Empty View

struct EmptyTransactionView: View {
    let hasFilters: Bool
    let onClearFilters: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(hasFilters ? "条件に一致する取引がありません" : "取引がありません")
                .font(.headline)
                .foregroundColor(.secondary)

            if hasFilters {
                Button("フィルターをクリア") {
                    onClearFilters()
                }
                .foregroundColor(AsaColors.coffeeBrown)
            } else {
                Text("右上の+ボタンから取引を追加してください")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Sheet

struct FilterSheetView: View {
    @Bindable var viewModel: TransactionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // 種類フィルター
                Section("種類") {
                    Picker("取引種類", selection: $viewModel.selectedType) {
                        Text("すべて").tag(nil as TransactionType?)
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type as TransactionType?)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // カテゴリフィルター
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $viewModel.selectedCategory) {
                        Text("すべて").tag(nil as Category?)
                        ForEach(viewModel.categories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category as Category?)
                        }
                    }
                }

                // 期間フィルター
                Section("期間") {
                    ForEach(DateRangeFilter.quickFilters, id: \.displayName) { filter in
                        Button {
                            viewModel.selectedDateRange = filter
                        } label: {
                            HStack {
                                Text(filter.displayName)
                                Spacer()
                                if viewModel.selectedDateRange == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AsaColors.coffeeBrown)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                // ソート
                Section("並び順") {
                    Picker("並び順", selection: $viewModel.sortOption) {
                        ForEach(TransactionSortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }

                // クリアボタン
                Section {
                    Button("フィルターをクリア", role: .destructive) {
                        viewModel.clearFilters()
                    }
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("適用") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.sortOption) { _, _ in
                viewModel.updateSortOption(viewModel.sortOption)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    TransactionListView(viewModel: BudgetAIViewModel(dataService: DataService(modelContainer: try! DataService.createContainer())))
}
