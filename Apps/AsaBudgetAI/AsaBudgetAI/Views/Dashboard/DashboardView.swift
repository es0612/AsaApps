import SwiftUI
import AsaUIKit

struct DashboardView: View {
    @Bindable var viewModel: BudgetAIViewModel
    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 予算サマリーカード
                    BudgetSummaryCard(summary: viewModel.dashboardSummary, budget: viewModel.currentBudget)

                    // アラートセクション
                    if viewModel.dashboardSummary.activeAlertLevel != .normal {
                        AlertBannerView(
                            alertLevel: viewModel.dashboardSummary.activeAlertLevel,
                            message: alertMessage
                        )
                    }

                    // クイックアクション
                    QuickActionsView(
                        onAddExpense: { showAddTransaction = true },
                        onAddIncome: { showAddTransaction = true }
                    )

                    // カテゴリ別支出
                    if !viewModel.dashboardSummary.topCategories.isEmpty {
                        CategoryBreakdownCard(
                            categories: viewModel.dashboardSummary.topCategories
                        )
                    }

                    // 最近の取引
                    RecentTransactionsCard(
                        transactions: viewModel.recentTransactions
                    )

                    // AI分析サマリー
                    if viewModel.anomalyTransactions.count > 0 {
                        AnomalySummaryCard(
                            anomalyCount: viewModel.anomalyTransactions.count
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("AsaBudgetAI")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView(viewModel: viewModel)
            }
        }
    }

    private var alertMessage: String {
        switch viewModel.dashboardSummary.activeAlertLevel {
        case .critical:
            return "予算を超過しました！支出を見直してください。"
        case .warning:
            return "予算の90%以上を使用しています。"
        case .caution:
            return "予算の70%を使用しました。"
        case .normal:
            return ""
        }
    }
}

// MARK: - Budget Summary Card

struct BudgetSummaryCard: View {
    let summary: DashboardSummary
    let budget: Budget?

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("今月の予算")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    if let budget = budget {
                        Text("残り\(budget.daysRemaining)日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let budget = budget {
                    // 予算プログレスバー
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(budget.formattedSpentAmount)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AsaColors.coffeeBrown)

                            Text("/ \(budget.formattedTotalAmount)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("\(Int(summary.budgetPercentage))%")
                                .font(.headline)
                                .foregroundColor(progressColor)
                        }

                        ProgressView(value: min(summary.budgetPercentage / 100, 1.0))
                            .tint(progressColor)
                    }

                    // 日次予算
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(AsaColors.mutedSage)
                        Text("1日あたり \(budget.formattedRemainingAmount) / \(budget.daysRemaining)日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // 予算未設定時
                    VStack(spacing: 8) {
                        Text("予算が設定されていません")
                            .foregroundColor(.secondary)

                        Text("設定タブから予算を作成してください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                // 収支サマリー
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("支出")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(summary.totalExpenseThisMonth))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }

                    VStack(alignment: .leading) {
                        Text("収入")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(summary.totalIncomeThisMonth))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    // 前月比
                    if summary.comparedToLastMonth != 0 {
                        VStack(alignment: .trailing) {
                            Text("前月比")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 2) {
                                Image(systemName: summary.comparedToLastMonth > 0 ? "arrow.up" : "arrow.down")
                                Text("\(abs(Int(summary.comparedToLastMonth * 100)))%")
                            }
                            .font(.subheadline)
                            .foregroundColor(summary.comparedToLastMonth > 0 ? .red : .green)
                        }
                    }
                }
            }
        }
    }

    private var progressColor: Color {
        if summary.budgetPercentage >= 100 {
            return .red
        } else if summary.budgetPercentage >= 90 {
            return .orange
        } else if summary.budgetPercentage >= 70 {
            return .yellow
        } else {
            return AsaColors.coffeeBrown
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

// MARK: - Alert Banner

struct AlertBannerView: View {
    let alertLevel: AlertLevel
    let message: String

    var body: some View {
        HStack {
            Image(systemName: alertLevel.icon)
                .foregroundColor(alertColor)

            Text(message)
                .font(.subheadline)
                .foregroundColor(alertColor)

            Spacer()
        }
        .padding()
        .background(alertColor.opacity(0.1))
        .cornerRadius(10)
    }

    private var alertColor: Color {
        switch alertLevel {
        case .critical: return .red
        case .warning: return .orange
        case .caution: return .yellow
        case .normal: return .green
        }
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    let onAddExpense: () -> Void
    let onAddIncome: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onAddExpense) {
                HStack {
                    Image(systemName: "minus.circle.fill")
                    Text("支出を追加")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(10)
            }

            Button(action: onAddIncome) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("収入を追加")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - Category Breakdown Card

struct CategoryBreakdownCard: View {
    let categories: [CategoryBreakdown]

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("カテゴリ別支出")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                ForEach(categories.prefix(5)) { category in
                    HStack {
                        Text(category.categoryName)
                            .font(.subheadline)

                        Spacer()

                        Text(formatCurrency(category.amount))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("(\(Int(category.percentage))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
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

// MARK: - Recent Transactions Card

struct RecentTransactionsCard: View {
    let transactions: [Transaction]

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("最近の取引")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    NavigationLink("すべて表示") {
                        // TransactionListView
                    }
                    .font(.caption)
                    .foregroundColor(AsaColors.coffeeBrown)
                }

                if transactions.isEmpty {
                    Text("取引がありません")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                } else {
                    ForEach(transactions.prefix(5)) { transaction in
                        TransactionRowView(transaction: transaction)
                    }
                }
            }
        }
    }
}

// MARK: - Transaction Row

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            // カテゴリアイコン
            ZStack {
                Circle()
                    .fill(transaction.category?.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: transaction.category?.iconName ?? "questionmark")
                    .foregroundColor(transaction.category?.color ?? .gray)
                    .font(.system(size: 14))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(transaction.category?.name ?? "未分類")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.type == .expense ? "-" : "+")
                    + Text(transaction.formattedAmount)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(transaction.type == .expense ? .red : .green)

                Text(formatDate(transaction.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // 異常フラグ
            if transaction.isAnomaly {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Anomaly Summary Card

struct AnomalySummaryCard: View {
    let anomalyCount: Int

    var body: some View {
        AsaCard {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text("異常な支出を検出")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Text("\(anomalyCount)件の取引が通常パターンから外れています")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    DashboardView(viewModel: BudgetAIViewModel(dataService: DataService(modelContainer: try! DataService.createContainer())))
}
