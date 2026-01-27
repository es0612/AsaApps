import SwiftUI
import AsaUIKit

// MARK: - DashboardView

struct DashboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel

    @State private var showingAddTransaction = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Sync Status
                    syncStatusSection

                    // Balance Card
                    balanceCard

                    // Quick Actions
                    quickActionsSection

                    // Recent Transactions
                    recentTransactionsSection

                    // Category Summary
                    categorySummarySection
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .refreshable {
                await refreshData()
            }
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        HStack {
            SyncStatusBadge(status: expenseViewModel.syncMetadata.syncStatus)

            Spacer()

            if let lastSync = expenseViewModel.syncMetadata.lastSyncTimestamp {
                Text("最終同期: \(lastSync.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        AsaCard {
            VStack(spacing: 16) {
                Text("今月の収支")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)

                Text(expenseViewModel.formattedBalance)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(expenseViewModel.balance >= 0 ? .green : .red)

                HStack(spacing: 24) {
                    // Income
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                            Text("収入")
                                .foregroundColor(AsaColors.mutedSage)
                        }
                        .font(.caption)

                        Text(formatCurrency(expenseViewModel.totalIncome))
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                    }

                    Spacer()

                    // Expense
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("支出")
                                .foregroundColor(AsaColors.mutedSage)
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.red)
                        }
                        .font(.caption)

                        Text(formatCurrency(expenseViewModel.totalExpense))
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "arrow.up.circle.fill",
                title: "支出",
                color: .red
            ) {
                showingAddTransaction = true
            }

            QuickActionButton(
                icon: "arrow.down.circle.fill",
                title: "収入",
                color: .green
            ) {
                showingAddTransaction = true
            }
        }
    }

    // MARK: - Recent Transactions Section

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近の取引")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                NavigationLink(destination: TransactionListView()) {
                    Text("すべて見る")
                        .font(.caption)
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }

            if expenseViewModel.recentTransactions.isEmpty {
                AsaCard {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundColor(AsaColors.mutedSage)

                        Text("取引がありません")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                AsaCard {
                    VStack(spacing: 0) {
                        ForEach(expenseViewModel.recentTransactions) { transaction in
                            TransactionRowView(
                                transaction: transaction,
                                category: expenseViewModel.category(for: transaction.categoryId)
                            )

                            if transaction.id != expenseViewModel.recentTransactions.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Category Summary Section

    private var categorySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別支出")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            if expenseViewModel.expensesByCategory.isEmpty {
                AsaCard {
                    Text("データがありません")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            } else {
                AsaCard {
                    VStack(spacing: 12) {
                        ForEach(expenseViewModel.expensesByCategory.prefix(5), id: \.category.id) { item in
                            CategoryProgressRow(
                                category: item.category,
                                amount: item.amount,
                                total: expenseViewModel.totalExpense
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }

    private func refreshData() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        await expenseViewModel.loadData(userId: userId)
    }
}

// MARK: - QuickActionButton

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(AsaColors.darkSlate)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - CategoryProgressRow

struct CategoryProgressRow: View {
    let category: ExpenseCategory
    let amount: Double
    let total: Double

    var percentage: Double {
        guard total > 0 else { return 0 }
        return (amount / total) * 100
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)

                Text(category.name)
                    .font(.subheadline)
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text(formatCurrency(amount))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AsaColors.darkSlate)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AsaColors.softCream)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(category.color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel(authService: MockAuthService()))
        .environmentObject(ExpenseViewModel(dataService: MockExpenseDataService()))
}
