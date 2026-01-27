import SwiftUI
import Charts
import AsaUIKit

// MARK: - ReportsView

struct ReportsView: View {
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel

    @State private var selectedPeriod: ReportPeriod = .month

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    periodSelector

                    // Summary Cards
                    summaryCardsSection

                    // Expense Pie Chart
                    expensePieChartSection

                    // Monthly Trend Chart
                    monthlyTrendSection
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("レポート")
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("期間", selection: $selectedPeriod) {
            ForEach(ReportPeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary Cards

    private var summaryCardsSection: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "収入",
                amount: expenseViewModel.totalIncome,
                icon: "arrow.down.circle.fill",
                color: .green
            )

            SummaryCard(
                title: "支出",
                amount: expenseViewModel.totalExpense,
                icon: "arrow.up.circle.fill",
                color: .red
            )
        }
    }

    // MARK: - Expense Pie Chart

    private var expensePieChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別支出")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            AsaCard {
                if expenseViewModel.expensesByCategory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.pie")
                            .font(.largeTitle)
                            .foregroundColor(AsaColors.mutedSage)

                        Text("データがありません")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        // Pie Chart
                        Chart(expenseViewModel.expensesByCategory, id: \.category.id) { item in
                            SectorMark(
                                angle: .value("金額", item.amount),
                                innerRadius: .ratio(0.5),
                                angularInset: 1
                            )
                            .foregroundStyle(item.category.color)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)

                        // Legend
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(expenseViewModel.expensesByCategory.prefix(6), id: \.category.id) { item in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(item.category.color)
                                        .frame(width: 10, height: 10)

                                    Text(item.category.name)
                                        .font(.caption)
                                        .foregroundColor(AsaColors.darkSlate)

                                    Spacer()

                                    Text(formatPercentage(item.amount))
                                        .font(.caption)
                                        .foregroundColor(AsaColors.mutedSage)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Monthly Trend

    private var monthlyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月別推移")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            AsaCard {
                if monthlyData.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar")
                            .font(.largeTitle)
                            .foregroundColor(AsaColors.mutedSage)

                        Text("データがありません")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    Chart(monthlyData) { data in
                        BarMark(
                            x: .value("月", data.month),
                            y: .value("金額", data.amount)
                        )
                        .foregroundStyle(data.type == .income ? Color.green : Color.red)
                    }
                    .frame(height: 200)
                    .padding()
                }
            }
        }
    }

    // MARK: - Helpers

    private var monthlyData: [MonthlyData] {
        let calendar = Calendar.current
        var result: [MonthlyData] = []

        // Group transactions by month
        let grouped = Dictionary(grouping: expenseViewModel.transactions) { transaction -> String in
            let components = calendar.dateComponents([.year, .month], from: transaction.date)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }

        // Calculate income and expense for each month
        for (key, transactions) in grouped {
            let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

            let components = key.split(separator: "-")
            if let month = components.last {
                result.append(MonthlyData(month: "\(month)月", amount: income, type: .income))
                result.append(MonthlyData(month: "\(month)月", amount: expense, type: .expense))
            }
        }

        return result.sorted { $0.month < $1.month }
    }

    private func formatPercentage(_ amount: Double) -> String {
        let total = expenseViewModel.totalExpense
        guard total > 0 else { return "0%" }
        let percentage = (amount / total) * 100
        return String(format: "%.0f%%", percentage)
    }
}

// MARK: - ReportPeriod

enum ReportPeriod: String, CaseIterable {
    case week = "週"
    case month = "月"
    case year = "年"

    var displayName: String { rawValue }
}

// MARK: - MonthlyData

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
    let type: TransactionType
}

// MARK: - SummaryCard

struct SummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)

                    Text(title)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Text(formatCurrency(amount))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.darkSlate)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
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
    ReportsView()
        .environmentObject(ExpenseViewModel(dataService: MockExpenseDataService()))
}
