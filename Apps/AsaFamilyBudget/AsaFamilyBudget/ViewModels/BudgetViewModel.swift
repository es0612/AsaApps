//
//  BudgetViewModel.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class BudgetViewModel: ObservableObject {
    // MARK: - Properties
    var budgets: [Budget] = []
    var transactions: [Transaction] = []
    var categories: [Category] = []
    var familyMembers: [FamilyMember] = []
    var currentBudget: Budget?
    var selectedTransaction: Transaction?
    var isLoading = false
    var errorMessage: String?
    var searchText = ""

    // MARK: - Computed Properties
    var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return transactions
        }
        return transactions.filter { transaction in
            transaction.title.localizedCaseInsensitiveContains(searchText) ||
            transaction.note?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var totalIncome: Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    var balance: Double {
        totalIncome - totalExpense
    }

    var expensesByCategory: [(category: Category, amount: Double)] {
        var result: [(Category, Double)] = []
        for category in categories {
            let amount = transactions
                .filter { $0.type == .expense && $0.category?.id == category.id }
                .reduce(0) { $0 + $1.amount }
            if amount > 0 {
                result.append((category, amount))
            }
        }
        return result.sorted(by: { $0.1 > $1.1 })
    }

    var recentTransactions: [Transaction] {
        transactions
            .sorted { $0.date > $1.date }
            .prefix(10)
            .map { $0 }
    }

    var activeBudget: Budget? {
        budgets.first { $0.isActive && $0.startDate <= Date() && $0.endDate >= Date() }
    }

    // MARK: - Initialization
    init() {
        Task {
            await loadInitialData()
        }
    }

    // MARK: - Public Methods
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }

        // デモデータの初期化
        if categories.isEmpty {
            categories = Category.defaultCategories()
        }

        if familyMembers.isEmpty {
            familyMembers = FamilyMember.sampleMembers()
        }

        if budgets.isEmpty {
            budgets = Budget.sampleBudgets()
            currentBudget = budgets.first
        }

        if transactions.isEmpty {
            let sampleTransactions = Transaction.sampleTransactions()
            // カテゴリとメンバーを関連付け
            for (index, transaction) in sampleTransactions.enumerated() {
                transaction.category = categories[index % categories.count]
                transaction.member = familyMembers[index % familyMembers.count]
                transaction.budget = currentBudget
            }
            transactions = sampleTransactions
        }
    }

    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        if let budget = currentBudget {
            budget.addTransaction(transaction)
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
    }

    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
        }
    }

    func addCategory(_ category: Category) {
        categories.append(category)
    }

    func deleteCategory(_ category: Category) {
        // デフォルトカテゴリは削除不可
        guard !category.isDefault else { return }
        categories.removeAll { $0.id == category.id }
    }

    func addFamilyMember(_ member: FamilyMember) {
        familyMembers.append(member)
    }

    func deleteFamilyMember(_ member: FamilyMember) {
        familyMembers.removeAll { $0.id == member.id }
    }

    func createBudget(name: String, amount: Double, period: BudgetPeriod) {
        let budget = Budget(name: name, totalAmount: amount, period: period)
        budgets.append(budget)
        currentBudget = budget
    }

    func updateBudget(_ budget: Budget, name: String? = nil, amount: Double? = nil) {
        budget.updateBudget(name: name, totalAmount: amount)
    }

    func deleteBudget(_ budget: Budget) {
        budgets.removeAll { $0.id == budget.id }
        if currentBudget?.id == budget.id {
            currentBudget = budgets.first
        }
    }

    func switchBudget(to budget: Budget) {
        currentBudget = budget
    }

    // MARK: - Chart Data Methods
    func categoryChartData() -> [(String, Double)] {
        expensesByCategory.map { ($0.category.name, $0.amount) }
    }

    func monthlyTrendData() -> [(String, Double)] {
        let calendar = Calendar.current
        let now = Date()
        var result: [(String, Double)] = []

        for monthOffset in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月"
            let monthLabel = formatter.string(from: monthDate)

            let monthKey = DateFormatter().apply {
                $0.dateFormat = "yyyy-MM"
            }.string(from: monthDate)

            let monthTotal = transactions
                .filter { $0.type == .expense && $0.monthYearKey == monthKey }
                .reduce(0) { $0 + $1.amount }

            result.append((monthLabel, monthTotal))
        }

        return result
    }

    func memberSpendingData() -> [(String, Double)] {
        var result: [(String, Double)] = []
        for member in familyMembers {
            let amount = transactions
                .filter { $0.type == .expense && $0.member?.id == member.id }
                .reduce(0) { $0 + $1.amount }
            if amount > 0 {
                result.append((member.name, amount))
            }
        }
        return result.sorted(by: { $0.1 > $1.1 })
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}