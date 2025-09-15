//
//  ExpenseChartView.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import Charts
import AsaUIKit

struct ExpenseChartView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @State private var selectedMonth: (month: String, amount: Double)?
    @State private var timeRange: TimeRange = .sixMonths

    enum TimeRange: String, CaseIterable {
        case threeMonths = "3ヶ月"
        case sixMonths = "6ヶ月"
        case oneYear = "1年"

        var monthCount: Int {
            switch self {
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - 期間選択
            Picker("期間", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // MARK: - 月次推移グラフ
            AsaCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("月次支出推移")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    if viewModel.monthlyTrendData().isEmpty {
                        Text("データがありません")
                            .foregroundColor(AsaColors.mutedSage)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                    } else {
                        monthlyTrendChart
                    }

                    // MARK: - サマリー
                    summarySection
                }
            }
            .padding(.horizontal)

            // MARK: - 予算vs実績
            budgetComparisonSection
        }
    }

    // MARK: - Monthly Trend Chart
    private var monthlyTrendChart: some View {
        Chart(viewModel.monthlyTrendData(), id: \.0) { item in
            BarMark(
                x: .value("月", item.0),
                y: .value("支出", item.1),
                width: .ratio(0.7)
            )
            .foregroundStyle(
                Gradient(colors: [
                    AsaColors.coffeeBrown,
                    AsaColors.mocha
                ])
            )
            .cornerRadius(5)
            .opacity(selectedMonth?.month == item.0 ? 1.0 : 0.8)

            // 予算ライン（仮に月30万円として）
            if let budget = viewModel.currentBudget {
                RuleMark(
                    y: .value("予算", budget.totalAmount / 12)
                )
                .foregroundStyle(Color.red.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("予算")
                        .font(.caption)
                        .foregroundColor(Color.red)
                }
            }
        }
        .frame(height: 250)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatCompactCurrency(amount))
                            .font(.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let month = value.as(String.self) {
                        Text(month)
                            .font(.caption)
                    }
                }
            }
        }
        .onTapGesture { location in
            // タップ位置から月を特定する簡易実装
            selectedMonth = nil
        }
    }

    // MARK: - Summary Section
    private var summarySection: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("平均支出")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                Text(formatCurrency(averageMonthlyExpense))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AsaColors.coffeeBrown)
            }

            Spacer()

            VStack(alignment: .center) {
                Text("最大支出")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                Text(formatCurrency(maxMonthlyExpense))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.red)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("最小支出")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                Text(formatCurrency(minMonthlyExpense))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.green)
            }
        }
    }

    // MARK: - Budget Comparison Section
    private var budgetComparisonSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("予算達成状況")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                if let budget = viewModel.currentBudget {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今月の予算")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                            Text(formatCurrency(budget.totalAmount))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AsaColors.coffeeBrown)
                        }

                        Spacer()

                        VStack(alignment: .center, spacing: 8) {
                            Text("使用済み")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                            Text("\(Int(budget.spentPercentage))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(progressColor(for: budget.spentPercentage))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            Text("1日あたり")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                            Text(formatCurrency(dailyBudget))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AsaColors.mocha)
                        }
                    }

                    // プログレスバー
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(AsaColors.softCream)
                                .frame(height: 10)

                            RoundedRectangle(cornerRadius: 5)
                                .fill(progressColor(for: budget.spentPercentage))
                                .frame(
                                    width: min(
                                        geometry.size.width * (budget.spentPercentage / 100),
                                        geometry.size.width
                                    ),
                                    height: 10
                                )
                                .animation(.easeInOut(duration: 0.3), value: budget.spentPercentage)
                        }
                    }
                    .frame(height: 10)
                } else {
                    Text("予算が設定されていません")
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Computed Properties
    private var averageMonthlyExpense: Double {
        let data = viewModel.monthlyTrendData()
        guard !data.isEmpty else { return 0 }
        let total = data.reduce(0) { $0 + $1.1 }
        return total / Double(data.count)
    }

    private var maxMonthlyExpense: Double {
        viewModel.monthlyTrendData().map { $0.1 }.max() ?? 0
    }

    private var minMonthlyExpense: Double {
        viewModel.monthlyTrendData().map { $0.1 }.min() ?? 0
    }

    private var dailyBudget: Double {
        guard let budget = viewModel.currentBudget,
              budget.daysRemaining > 0 else { return 0 }
        return budget.remainingAmount / Double(budget.daysRemaining)
    }

    // MARK: - Helper Methods
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }

    private func formatCompactCurrency(_ amount: Double) -> String {
        if amount >= 10000 {
            return String(format: "%.0f万", amount / 10000)
        } else {
            return String(format: "%.0f", amount)
        }
    }

    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 90 {
            return Color.red
        } else if percentage >= 70 {
            return Color.orange
        } else {
            return Color.green
        }
    }
}