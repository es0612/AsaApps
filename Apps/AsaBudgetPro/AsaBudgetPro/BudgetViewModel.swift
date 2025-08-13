//
//  BudgetViewModel.swift
//  AsaBudgetPro
//  
//  Created on 2025/08/03
//

import SwiftUI
import SwiftData
import Foundation

@Observable
class BudgetViewModel {
    var modelContext: ModelContext?
    
    // 取引入力フォーム用の状態
    var amount: String = ""
    var selectedCategory: Category?
    var selectedTransactionType: TransactionType = .expense
    var transactionDate: Date = Date()
    var memo: String = ""
    var amountError: String?
    
    // 予算設定用の状態
    var budgetAmount: String = ""
    var selectedBudgetCategory: Category?
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    
    // データ
    var transactions: [Transaction] = []
    var categories: [Category] = []
    var budgets: [Budget] = []
    
    // 初期化時にデフォルトカテゴリを設定
    func initializeDefaultCategories() {
        guard let modelContext = modelContext else { return }
        
        // 既存のカテゴリがあるかチェック
        let descriptor = FetchDescriptor<Category>()
        if let existingCategories = try? modelContext.fetch(descriptor), !existingCategories.isEmpty {
            return // 既にカテゴリが存在する場合は何もしない
        }
        
        // デフォルトカテゴリを追加
        let allDefaultCategories = Category.defaultIncomeCategories + Category.defaultExpenseCategories
        
        for category in allDefaultCategories {
            modelContext.insert(category)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("デフォルトカテゴリの保存に失敗しました: \(error)")
        }
    }
    
    // データ読み込み
    func loadData() {
        guard let modelContext = modelContext else { return }
        
        loadTransactions()
        loadCategories()
        loadBudgets()
    }
    
    private func loadTransactions() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            transactions = try modelContext.fetch(descriptor)
        } catch {
            print("取引データの読み込みに失敗しました: \(error)")
        }
    }
    
    private func loadCategories() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        do {
            categories = try modelContext.fetch(descriptor)
        } catch {
            print("カテゴリデータの読み込みに失敗しました: \(error)")
        }
    }
    
    private func loadBudgets() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Budget>()
        do {
            budgets = try modelContext.fetch(descriptor)
        } catch {
            print("予算データの読み込みに失敗しました: \(error)")
        }
    }
    
    // 取引追加
    func addTransaction() {
        guard let modelContext = modelContext,
              let amountDouble = Double(amount), amountDouble > 0,
              let category = selectedCategory else { return }
        
        let transaction = Transaction(
            amount: amountDouble,
            categoryName: category.name,
            transactionType: selectedTransactionType,
            date: transactionDate,
            memo: memo
        )
        
        modelContext.insert(transaction)
        
        do {
            try modelContext.save()
            loadTransactions()
            resetTransactionForm()
        } catch {
            print("取引の保存に失敗しました: \(error)")
        }
    }
    
    // 取引削除
    func deleteTransaction(_ transaction: Transaction) {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(transaction)
        
        do {
            try modelContext.save()
            loadTransactions()
        } catch {
            print("取引の削除に失敗しました: \(error)")
        }
    }
    
    // 予算設定
    func setBudget() {
        guard let modelContext = modelContext,
              let budgetDouble = Double(budgetAmount), budgetDouble > 0,
              let category = selectedBudgetCategory else { return }
        
        // 既存の予算をチェック
        let targetYear = selectedYear
        let targetMonth = selectedMonth
        let categoryName = category.name
        
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { budget in
                budget.categoryName == categoryName &&
                budget.year == targetYear &&
                budget.month == targetMonth
            }
        )
        
        do {
            let existingBudgets = try modelContext.fetch(descriptor)
            
            if let existingBudget = existingBudgets.first {
                // 既存の予算を更新
                existingBudget.monthlyBudget = budgetDouble
            } else {
                // 新しい予算を作成
                let budget = Budget(
                    categoryName: category.name,
                    monthlyBudget: budgetDouble,
                    year: selectedYear,
                    month: selectedMonth
                )
                modelContext.insert(budget)
            }
            
            try modelContext.save()
            loadBudgets()
            budgetAmount = ""
        } catch {
            print("予算の保存に失敗しました: \(error)")
        }
    }
    
    // フォームリセット
    private func resetTransactionForm() {
        amount = ""
        memo = ""
        transactionDate = Date()
        amountError = nil
    }
    
    // 金額バリデーション
    func validateAmount() {
        let filtered = amount.filter { "0123456789.".contains($0) }
        if filtered.isEmpty {
            amountError = "金額を入力してください"
            amount = ""
        } else if let value = Double(filtered), value > 0 {
            amountError = nil
            amount = filtered
        } else {
            amountError = "有効な正の金額を入力してください"
            amount = filtered
        }
    }
    
    // 統計情報計算
    func getTotalIncomeForMonth(year: Int, month: Int) -> Double {
        let filteredTransactions = transactions.filter { transaction in
            let calendar = Calendar.current
            let transactionComponents = calendar.dateComponents([.year, .month], from: transaction.date)
            return transactionComponents.year == year &&
                   transactionComponents.month == month &&
                   transaction.transactionType == .income
        }
        return filteredTransactions.reduce(0) { $0 + $1.amount }
    }
    
    func getTotalExpenseForMonth(year: Int, month: Int) -> Double {
        let filteredTransactions = transactions.filter { transaction in
            let calendar = Calendar.current
            let transactionComponents = calendar.dateComponents([.year, .month], from: transaction.date)
            return transactionComponents.year == year &&
                   transactionComponents.month == month &&
                   transaction.transactionType == .expense
        }
        return filteredTransactions.reduce(0) { $0 + $1.amount }
    }
    
    func getCategoryExpenseForMonth(categoryName: String, year: Int, month: Int) -> Double {
        let filteredTransactions = transactions.filter { transaction in
            let calendar = Calendar.current
            let transactionComponents = calendar.dateComponents([.year, .month], from: transaction.date)
            return transactionComponents.year == year &&
                   transactionComponents.month == month &&
                   transaction.categoryName == categoryName &&
                   transaction.transactionType == .expense
        }
        return filteredTransactions.reduce(0) { $0 + $1.amount }
    }
    
    func getBudgetForCategory(categoryName: String, year: Int, month: Int) -> Budget? {
        return budgets.first { budget in
            budget.categoryName == categoryName &&
            budget.year == year &&
            budget.month == month
        }
    }
    
    // カテゴリフィルタリング
    func getCategoriesForType(_ type: TransactionType) -> [Category] {
        return categories.filter { $0.transactionType == type }
    }
    
    // 最近の取引取得
    func getRecentTransactions(limit: Int = 5) -> [Transaction] {
        return Array(transactions.prefix(limit))
    }
}
