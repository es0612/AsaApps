//
//  BudgetChartView.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import Charts
import AsaUIKit

struct BudgetChartView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @State private var selectedCategory: (category: Category, amount: Double)?
    @State private var chartType: ChartType = .pie

    enum ChartType: String, CaseIterable {
        case pie = "円グラフ"
        case bar = "棒グラフ"
        case donut = "ドーナツ"
    }

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - チャートタイプ選択
            Picker("グラフタイプ", selection: $chartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // MARK: - チャート表示
            AsaCard {
                VStack {
                    Text("カテゴリ別支出")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                        .padding(.bottom, 10)

                    if viewModel.expensesByCategory.isEmpty {
                        Text("データがありません")
                            .foregroundColor(AsaColors.mutedSage)
                            .frame(height: 300)
                    } else {
                        switch chartType {
                        case .pie:
                            pieChart
                        case .bar:
                            barChart
                        case .donut:
                            donutChart
                        }
                    }

                    // MARK: - 凡例
                    legendView
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Pie Chart
    private var pieChart: some View {
        Chart(viewModel.expensesByCategory, id: \.category.id) { item in
            SectorMark(
                angle: .value("金額", item.amount),
                innerRadius: .ratio(0.0),
                angularInset: 2
            )
            .foregroundStyle(item.category.color)
            .opacity(selectedCategory?.category.id == item.category.id ? 1.0 : 0.8)
        }
        .frame(height: 300)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                if let selected = selectedCategory {
                    VStack {
                        Text(selected.category.name)
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                        Text(formatCurrency(selected.amount))
                            .font(.subheadline)
                            .foregroundColor(AsaColors.mocha)
                        Text(formatPercentage(selected.amount))
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
        .chartAngleSelection(value: .constant(0))
    }

    // MARK: - Bar Chart
    private var barChart: some View {
        Chart(viewModel.expensesByCategory, id: \.category.id) { item in
            BarMark(
                x: .value("カテゴリ", item.category.name),
                y: .value("金額", item.amount)
            )
            .foregroundStyle(item.category.color)
            .annotation(position: .top) {
                Text(formatCompactCurrency(item.amount))
                    .font(.caption)
                    .foregroundColor(AsaColors.darkSlate)
            }
        }
        .frame(height: 300)
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
                    if let category = value.as(String.self) {
                        Text(String(category.prefix(3)))
                            .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - Donut Chart
    private var donutChart: some View {
        Chart(viewModel.expensesByCategory, id: \.category.id) { item in
            SectorMark(
                angle: .value("金額", item.amount),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(item.category.color)
            .opacity(selectedCategory?.category.id == item.category.id ? 1.0 : 0.8)
        }
        .frame(height: 300)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                VStack {
                    Text("合計")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                    Text(formatCurrency(viewModel.totalExpense))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.coffeeBrown)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }

    // MARK: - Legend View
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.expensesByCategory.prefix(5), id: \.category.id) { item in
                HStack {
                    Circle()
                        .fill(item.category.color)
                        .frame(width: 12, height: 12)
                    Text(item.category.name)
                        .font(.caption)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    Text(formatCurrency(item.amount))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AsaColors.mocha)
                    Text(formatPercentage(item.amount))
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if selectedCategory?.category.id == item.category.id {
                            selectedCategory = nil
                        } else {
                            selectedCategory = item
                        }
                    }
                }
            }
        }
        .padding(.top, 10)
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
            return String(format: "%.1f万", amount / 10000)
        } else {
            return String(format: "%.0f", amount)
        }
    }

    private func formatPercentage(_ amount: Double) -> String {
        let percentage = (amount / viewModel.totalExpense) * 100
        return String(format: "%.1f%%", percentage)
    }
}