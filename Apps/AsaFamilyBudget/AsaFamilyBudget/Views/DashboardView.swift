//
//  DashboardView.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import Charts
import AsaUIKit

struct DashboardView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @State private var showingAddTransaction = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 予算サマリー
                    budgetSummarySection

                    // MARK: - 支出カテゴリ
                    categoryBreakdownSection

                    // MARK: - 最近の取引
                    recentTransactionsSection
                }
                .padding()
            }
            .navigationTitle("ダッシュボード")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
                    .environmentObject(viewModel)
            }
        }
    }

    // MARK: - Budget Summary Section
    private var budgetSummarySection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("今月の予算")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    if let budget = viewModel.activeBudget {
                        Text("\(budget.daysRemaining)日残り")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                if let budget = viewModel.activeBudget {
                    VStack(spacing: 12) {
                        // 予算額と使用額
                        HStack {
                            VStack(alignment: .leading) {
                                Text("予算額")
                                    .font(.caption)
                                    .foregroundColor(AsaColors.mutedSage)
                                Text(formatCurrency(budget.totalAmount))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AsaColors.coffeeBrown)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("使用額")
                                    .font(.caption)
                                    .foregroundColor(AsaColors.mutedSage)
                                Text(formatCurrency(budget.totalAmount - budget.remainingAmount))
                                    .font(.title2)
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
                            }
                        }
                        .frame(height: 10)

                        // 残額
                        HStack {
                            Text("残額")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                            Spacer()
                            Text(formatCurrency(budget.remainingAmount))
                                .font(.headline)
                                .foregroundColor(progressColor(for: budget.spentPercentage))
                        }
                    }
                } else {
                    Text("アクティブな予算がありません")
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
    }

    // MARK: - Category Breakdown Section
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別支出")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            AsaCard {
                if viewModel.expensesByCategory.isEmpty {
                    Text("まだ支出データがありません")
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.expensesByCategory.prefix(5), id: \.category.id) { item in
                            HStack {
                                Image(systemName: item.category.icon)
                                    .foregroundColor(item.category.color)
                                    .frame(width: 24)
                                Text(item.category.name)
                                    .font(.subheadline)
                                    .foregroundColor(AsaColors.darkSlate)
                                Spacer()
                                Text(formatCurrency(item.amount))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AsaColors.mocha)
                            }
                        }
                    }
                }
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
                NavigationLink(destination: TransactionListView().environmentObject(viewModel)) {
                    Text("すべて見る")
                        .font(.caption)
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }

            AsaCard {
                if viewModel.recentTransactions.isEmpty {
                    Text("取引履歴がありません")
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.recentTransactions.prefix(5)) { transaction in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(transaction.title)
                                        .font(.subheadline)
                                        .foregroundColor(AsaColors.darkSlate)
                                    HStack(spacing: 8) {
                                        if let category = transaction.category {
                                            Label(category.name, systemImage: category.icon)
                                                .font(.caption)
                                                .foregroundColor(AsaColors.mutedSage)
                                        }
                                        if let member = transaction.member {
                                            Text(member.name)
                                                .font(.caption)
                                                .foregroundColor(AsaColors.mutedSage)
                                        }
                                    }
                                }
                                Spacer()
                                Text(transaction.formattedAmount)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(
                                        transaction.type == .income ?
                                        Color.green : AsaColors.mocha
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
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