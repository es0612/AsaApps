//
//  BudgetSettingsView.swift
//  AsaBudgetPro
//  
//  Created on 2025/08/03
//

import SwiftUI

struct BudgetSettingsView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    
    private let months = [
        1: "1月", 2: "2月", 3: "3月", 4: "4月",
        5: "5月", 6: "6月", 7: "7月", 8: "8月",
        9: "9月", 10: "10月", 11: "11月", 12: "12月"
    ]
    
    private let years = Array(2020...2030)
    
    var expenseCategories: [Category] {
        viewModel.getCategoriesForType(.expense)
    }
    
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
                    
                    periodSelector
                    
                    budgetListView
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.selectedYear = selectedYear
                viewModel.selectedMonth = selectedMonth
            }
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
            
            Text("予算設定")
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
    
    private var periodSelector: some View {
        AsaCard {
            VStack(spacing: 16) {
                Text("予算期間")
                    .font(.headline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
                        .onChange(of: selectedYear) { _, newValue in
                            viewModel.selectedYear = newValue
                        }
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
                        .onChange(of: selectedMonth) { _, newValue in
                            viewModel.selectedMonth = newValue
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var budgetListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if expenseCategories.isEmpty {
                    emptyStateView
                } else {
                    ForEach(expenseCategories, id: \.id) { category in
                        BudgetCategoryRow(
                            category: category,
                            viewModel: viewModel,
                            year: selectedYear,
                            month: selectedMonth
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("支出カテゴリがありません")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text("まずカテゴリを作成してください")
                .font(.body)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .padding()
    }
}

struct BudgetCategoryRow: View {
    let category: Category
    @ObservedObject var viewModel: BudgetViewModel
    let year: Int
    let month: Int
    @State private var budgetText: String = ""
    @State private var isEditing: Bool = false
    
    private var currentBudget: Budget? {
        viewModel.getBudgetForCategory(categoryName: category.name, year: year, month: month)
    }
    
    private var currentExpense: Double {
        viewModel.getCategoryExpenseForMonth(categoryName: category.name, year: year, month: month)
    }
    
    private var budgetProgress: Double {
        guard let budget = currentBudget, budget.monthlyBudget > 0 else { return 0 }
        return min(currentExpense / budget.monthlyBudget, 1.0)
    }
    
    var body: some View {
        AsaCard {
            VStack(spacing: 12) {
                HStack {
                    // カテゴリ情報
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.title3)
                            .foregroundColor(Color(hex: category.colorHex))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.body.weight(.medium))
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Text("今月の支出: ¥\(Int(currentExpense))")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                    
                    Spacer()
                    
                    // 予算入力/表示
                    budgetInputSection
                }
                
                // 進捗バー（予算が設定されている場合のみ）
                if let budget = currentBudget {
                    progressBarSection(budget: budget)
                }
            }
        }
        .onAppear {
            if let budget = currentBudget {
                budgetText = String(Int(budget.monthlyBudget))
            } else {
                budgetText = ""
            }
        }
        .onChange(of: year) { _, _ in updateBudgetText() }
        .onChange(of: month) { _, _ in updateBudgetText() }
    }
    
    private var budgetInputSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isEditing {
                HStack(spacing: 8) {
                    TextField("予算", text: $budgetText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    
                    Button("保存") {
                        saveBudget()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("AsaCoffeeBrown"))
                    .cornerRadius(6)
                    
                    Button("キャンセル") {
                        cancelEditing()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color("AsaMutedSage"))
                }
            } else {
                Button {
                    isEditing = true
                } label: {
                    if let budget = currentBudget {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("¥\(Int(budget.monthlyBudget))")
                                .font(.headline.weight(.bold))
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Text("予算")
                                .font(.caption2)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    } else {
                        Text("予算を設定")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color("AsaMutedSage"))
                            .cornerRadius(6)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func progressBarSection(budget: Budget) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("進捗")
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
                
                Spacer()
                
                Text("\(Int(budgetProgress * 100))%")
                    .font(.caption.weight(.medium))
                    .foregroundColor(budgetProgress > 0.9 ? .red : Color("AsaCoffeeBrown"))
            }
            
            ProgressView(value: budgetProgress)
                .progressViewStyle(LinearProgressViewStyle(
                    tint: budgetProgress > 1.0 ? .red : 
                          budgetProgress > 0.8 ? .orange : .green
                ))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("¥\(Int(currentExpense))")
                    .font(.caption2)
                    .foregroundColor(Color("AsaMutedSage"))
                
                Spacer()
                
                Text("残り: ¥\(Int(max(0, budget.monthlyBudget - currentExpense)))")
                    .font(.caption2)
                    .foregroundColor(budget.monthlyBudget - currentExpense >= 0 ? .green : .red)
            }
        }
    }
    
    private func updateBudgetText() {
        if let budget = currentBudget {
            budgetText = String(Int(budget.monthlyBudget))
        } else {
            budgetText = ""
        }
    }
    
    private func saveBudget() {
        guard let amount = Double(budgetText), amount > 0 else {
            cancelEditing()
            return
        }
        
        viewModel.selectedBudgetCategory = category
        viewModel.budgetAmount = budgetText
        viewModel.selectedYear = year
        viewModel.selectedMonth = month
        viewModel.setBudget()
        
        isEditing = false
    }
    
    private func cancelEditing() {
        updateBudgetText()
        isEditing = false
    }
}

#Preview {
    BudgetSettingsView(viewModel: BudgetViewModel())
}