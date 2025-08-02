//
//  AnalyticsView.swift
//  AsaBudgetPro
//  
//  Created on 2025/08/03
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var analysisType: AnalysisType = .category
    
    enum AnalysisType: String, CaseIterable {
        case category = "カテゴリ別"
        case monthly = "月次推移"
        case budget = "予算比較"
    }
    
    private let months = [
        1: "1月", 2: "2月", 3: "3月", 4: "4月",
        5: "5月", 6: "6月", 7: "7月", 8: "8月",
        9: "9月", 10: "10月", 11: "11月", 12: "12月"
    ]
    
    private let years = Array(2020...2030)
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color("AsaSoftCream"), Color("AsaMocha")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    controlsView
                    
                    analyticsContentView
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("閉じる") {
                dismiss()
            }
            .font(.body.weight(.medium))
            .foregroundColor(Color("AsaMutedSage"))
            
            Spacer()
            
            Text("分析")
                .font(.title2.weight(.bold))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Spacer()
            
            // 空のスペース（対称性のため）
            Text("")
                .frame(width: 40)
        }
        .padding()
        .background(Color.white.opacity(0.1))
    }
    
    private var controlsView: some View {
        VStack(spacing: 12) {
            AsaCard {
                VStack(spacing: 16) {
                    Text("分析タイプ")
                        .font(.headline.weight(.medium))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Picker("分析タイプ", selection: $analysisType) {
                        ForEach(AnalysisType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            if analysisType != .monthly {
                AsaCard {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("年")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            Picker("年", selection: $selectedYear) {
                                ForEach(years, id: \.self) { year in
                                    Text("\(year)年").tag(year)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("月")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            Picker("月", selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text(months[month] ?? "").tag(month)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var analyticsContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch analysisType {
                case .category:
                    categoryAnalysisView
                case .monthly:
                    monthlyTrendView
                case .budget:
                    budgetComparisonView
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var categoryAnalysisView: some View {
        VStack(spacing: 16) {
            // 支出カテゴリ分析
            categoryBreakdownView
            
            // 収入カテゴリ分析
            incomeBreakdownView
        }
    }
    
    private var categoryBreakdownView: some View {
        let expenseCategories = viewModel.getCategoriesForType(.expense)
        let categoryData = expenseCategories.compactMap { category -> CategoryAnalysisData? in
            let amount = viewModel.getCategoryExpenseForMonth(
                categoryName: category.name,
                year: selectedYear,
                month: selectedMonth
            )
            guard amount > 0 else { return nil }
            return CategoryAnalysisData(
                name: category.name,
                amount: amount,
                color: Color(hex: category.colorHex),
                icon: category.icon
            )
        }.sorted { $0.amount > $1.amount }
        
        return AsaCard {
            VStack(spacing: 16) {
                Text("\(selectedMonth)月の支出カテゴリ別内訳")
                    .font(.headline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if categoryData.isEmpty {
                    Text("データがありません")
                        .font(.body)
                        .foregroundColor(Color("AsaMutedSage"))
                        .padding()
                } else {
                    ForEach(categoryData, id: \.name) { data in
                        CategoryAnalysisRow(data: data, total: categoryData.reduce(0) { $0 + $1.amount })
                    }
                }
            }
        }
    }
    
    private var incomeBreakdownView: some View {
        let incomeCategories = viewModel.getCategoriesForType(.income)
        let categoryData = incomeCategories.compactMap { category -> CategoryAnalysisData? in
            let amount = viewModel.transactions
                .filter { transaction in
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.year, .month], from: transaction.date)
                    return components.year == selectedYear &&
                           components.month == selectedMonth &&
                           transaction.categoryName == category.name &&
                           transaction.transactionType == .income
                }
                .reduce(0) { $0 + $1.amount }
            
            guard amount > 0 else { return nil }
            return CategoryAnalysisData(
                name: category.name,
                amount: amount,
                color: Color(hex: category.colorHex),
                icon: category.icon
            )
        }.sorted { $0.amount > $1.amount }
        
        return AsaCard {
            VStack(spacing: 16) {
                Text("\(selectedMonth)月の収入カテゴリ別内訳")
                    .font(.headline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if categoryData.isEmpty {
                    Text("データがありません")
                        .font(.body)
                        .foregroundColor(Color("AsaMutedSage"))
                        .padding()
                } else {
                    ForEach(categoryData, id: \.name) { data in
                        CategoryAnalysisRow(data: data, total: categoryData.reduce(0) { $0 + $1.amount })
                    }
                }
            }
        }
    }
    
    private var monthlyTrendView: some View {
        let monthlyData = (1...12).map { month -> MonthlyData in
            let income = viewModel.getTotalIncomeForMonth(year: selectedYear, month: month)
            let expense = viewModel.getTotalExpenseForMonth(year: selectedYear, month: month)
            return MonthlyData(
                month: month,
                monthName: months[month] ?? "",
                income: income,
                expense: expense,
                balance: income - expense
            )
        }.filter { $0.income > 0 || $0.expense > 0 }
        
        return AsaCard {
            VStack(spacing: 16) {
                Text("\(selectedYear)年の月次推移")
                    .font(.headline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if monthlyData.isEmpty {
                    Text("データがありません")
                        .font(.body)
                        .foregroundColor(Color("AsaMutedSage"))
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(monthlyData, id: \.month) { data in
                            MonthlyAnalysisRow(data: data)
                        }
                    }
                }
            }
        }
    }
    
    private var budgetComparisonView: some View {
        let expenseCategories = viewModel.getCategoriesForType(.expense)
        let budgetData = expenseCategories.compactMap { category -> BudgetAnalysisData? in
            guard let budget = viewModel.getBudgetForCategory(
                categoryName: category.name,
                year: selectedYear,
                month: selectedMonth
            ) else { return nil }
            
            let actualExpense = viewModel.getCategoryExpenseForMonth(
                categoryName: category.name,
                year: selectedYear,
                month: selectedMonth
            )
            
            return BudgetAnalysisData(
                categoryName: category.name,
                budgetAmount: budget.monthlyBudget,
                actualAmount: actualExpense,
                color: Color(hex: category.colorHex),
                icon: category.icon
            )
        }
        
        return AsaCard {
            VStack(spacing: 16) {
                Text("\(selectedMonth)月の予算と実績比較")
                    .font(.headline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if budgetData.isEmpty {
                    Text("予算データがありません")
                        .font(.body)
                        .foregroundColor(Color("AsaMutedSage"))
                        .padding()
                } else {
                    ForEach(budgetData, id: \.categoryName) { data in
                        BudgetAnalysisRow(data: data)
                    }
                }
            }
        }
    }
}

struct CategoryAnalysisData {
    let name: String
    let amount: Double
    let color: Color
    let icon: String
}

struct CategoryAnalysisRow: View {
    let data: CategoryAnalysisData
    let total: Double
    
    private var percentage: Double {
        total > 0 ? (data.amount / total) * 100 : 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: data.icon)
                .font(.title3)
                .foregroundColor(data.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(data.name)
                    .font(.body.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                ProgressView(value: percentage / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: data.color))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("¥\(Int(data.amount))")
                    .font(.body.weight(.bold))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("\(Int(percentage))%")
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
            }
        }
    }
}

struct MonthlyData {
    let month: Int
    let monthName: String
    let income: Double
    let expense: Double
    let balance: Double
}

struct MonthlyAnalysisRow: View {
    let data: MonthlyData
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(data.monthName)
                    .font(.body.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Spacer()
                
                Text("残高: ¥\(Int(data.balance))")
                    .font(.body.weight(.bold))
                    .foregroundColor(data.balance >= 0 ? .green : .red)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("収入")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                    Text("¥\(Int(data.income))")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("支出")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                    Text("¥\(Int(data.expense))")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.red)
                }
            }
            
            Divider()
        }
    }
}

struct BudgetAnalysisData {
    let categoryName: String
    let budgetAmount: Double
    let actualAmount: Double
    let color: Color
    let icon: String
}

struct BudgetAnalysisRow: View {
    let data: BudgetAnalysisData
    
    private var progress: Double {
        data.budgetAmount > 0 ? min(data.actualAmount / data.budgetAmount, 1.0) : 0
    }
    
    private var isOverBudget: Bool {
        data.actualAmount > data.budgetAmount
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: data.icon)
                    .font(.title3)
                    .foregroundColor(data.color)
                    .frame(width: 30)
                
                Text(data.categoryName)
                    .font(.body.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("¥\(Int(data.actualAmount)) / ¥\(Int(data.budgetAmount))")
                        .font(.caption.weight(.medium))
                        .foregroundColor(isOverBudget ? .red : Color("AsaCoffeeBrown"))
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(
                    tint: isOverBudget ? .red : 
                          progress > 0.8 ? .orange : .green
                ))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
            
            if isOverBudget {
                Text("予算を¥\(Int(data.actualAmount - data.budgetAmount))超過")
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

#Preview {
    AnalyticsView(viewModel: BudgetViewModel())
}