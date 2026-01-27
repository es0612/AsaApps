import SwiftUI
import AsaUIKit

// MARK: - TransactionListView

struct TransactionListView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel

    @State private var showingAddTransaction = false
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Filter Chips
                if hasActiveFilters {
                    filterChipsSection
                }

                // Transaction List
                if expenseViewModel.filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    transactionList
                }
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("取引一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingFilters = true }) {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundColor(AsaColors.coffeeBrown)
                        }

                        Button(action: { showingAddTransaction = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AsaColors.coffeeBrown)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $showingFilters) {
                FilterView()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AsaColors.mutedSage)

            TextField("取引を検索", text: $expenseViewModel.searchText)
                .textFieldStyle(.plain)

            if !expenseViewModel.searchText.isEmpty {
                Button(action: { expenseViewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Filter Chips

    private var hasActiveFilters: Bool {
        expenseViewModel.selectedTransactionType != nil ||
        expenseViewModel.selectedCategoryId != nil ||
        expenseViewModel.dateRange != nil
    }

    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let type = expenseViewModel.selectedTransactionType {
                    FilterChip(title: type.rawValue, icon: type.iconName) {
                        expenseViewModel.selectedTransactionType = nil
                    }
                }

                if let categoryId = expenseViewModel.selectedCategoryId,
                   let category = expenseViewModel.category(for: categoryId) {
                    FilterChip(title: category.name, icon: category.iconName) {
                        expenseViewModel.selectedCategoryId = nil
                    }
                }

                if expenseViewModel.dateRange != nil {
                    FilterChip(title: "期間指定", icon: "calendar") {
                        expenseViewModel.dateRange = nil
                    }
                }

                Button(action: { expenseViewModel.clearFilters() }) {
                    Text("すべてクリア")
                        .font(.caption)
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(AsaColors.mutedSage)

            Text("取引が見つかりません")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            Text("検索条件を変更するか、\n新しい取引を追加してください")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
                .multilineTextAlignment(.center)

            AsaButton(title: "取引を追加", action: { showingAddTransaction = true })
                .padding(.horizontal, 60)

            Spacer()
        }
        .padding()
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        List {
            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                Section(header: sectionHeader(for: date)) {
                    ForEach(groupedTransactions[date] ?? []) { transaction in
                        TransactionRowView(
                            transaction: transaction,
                            category: expenseViewModel.category(for: transaction.categoryId)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await expenseViewModel.deleteTransaction(transaction)
                                }
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedTransactions: [Date: [ExpenseTransaction]] {
        let calendar = Calendar.current
        return Dictionary(grouping: expenseViewModel.filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
    }

    private func sectionHeader(for date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"

        return Text(formatter.string(from: date))
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(AsaColors.darkSlate)
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let title: String
    let icon: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)

            Text(title)
                .font(.caption)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AsaColors.coffeeBrown.opacity(0.1))
        .foregroundColor(AsaColors.coffeeBrown)
        .cornerRadius(16)
    }
}

// MARK: - TransactionRowView

struct TransactionRowView: View {
    let transaction: ExpenseTransaction
    let category: ExpenseCategory?

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill((category?.color ?? .gray).opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: category?.iconName ?? "questionmark.circle")
                    .font(.title3)
                    .foregroundColor(category?.color ?? .gray)
            }

            // Transaction Info
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AsaColors.darkSlate)

                HStack(spacing: 4) {
                    Text(category?.name ?? "未分類")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    if let note = transaction.note, !note.isEmpty {
                        Text("・\(note)")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Amount
            Text(transaction.formattedAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - FilterView

struct FilterView: View {
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Transaction Type
                Section("取引タイプ") {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Button(action: {
                            expenseViewModel.selectedTransactionType = expenseViewModel.selectedTransactionType == type ? nil : type
                        }) {
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type == .income ? .green : .red)

                                Text(type.rawValue)
                                    .foregroundColor(AsaColors.darkSlate)

                                Spacer()

                                if expenseViewModel.selectedTransactionType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AsaColors.coffeeBrown)
                                }
                            }
                        }
                    }
                }

                // Categories
                Section("カテゴリ") {
                    ForEach(expenseViewModel.categories) { category in
                        Button(action: {
                            expenseViewModel.selectedCategoryId = expenseViewModel.selectedCategoryId == category.id ? nil : category.id
                        }) {
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundColor(category.color)

                                Text(category.name)
                                    .foregroundColor(AsaColors.darkSlate)

                                Spacer()

                                if expenseViewModel.selectedCategoryId == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AsaColors.coffeeBrown)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("リセット") {
                        expenseViewModel.clearFilters()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TransactionListView()
        .environmentObject(AuthViewModel(authService: MockAuthService()))
        .environmentObject(ExpenseViewModel(dataService: MockExpenseDataService()))
}
