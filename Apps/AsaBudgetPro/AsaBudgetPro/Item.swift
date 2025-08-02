//
//  Transaction.swift
//  AsaBudgetPro
//  
//  Created on 2025/08/03
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var categoryName: String
    var transactionType: TransactionType
    var date: Date
    var memo: String
    var createdAt: Date
    
    init(amount: Double, categoryName: String, transactionType: TransactionType, date: Date, memo: String = "") {
        self.id = UUID()
        self.amount = amount
        self.categoryName = categoryName
        self.transactionType = transactionType
        self.date = date
        self.memo = memo
        self.createdAt = Date()
    }
}

enum TransactionType: String, CaseIterable, Codable {
    case income = "収入"
    case expense = "支出"
    
    var icon: String {
        switch self {
        case .income:
            return "plus.circle.fill"
        case .expense:
            return "minus.circle.fill"
        }
    }
}

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var transactionType: TransactionType
    var isDefault: Bool
    var createdAt: Date
    
    init(name: String, icon: String, colorHex: String, transactionType: TransactionType, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.transactionType = transactionType
        self.isDefault = isDefault
        self.createdAt = Date()
    }
    
    static let defaultIncomeCategories = [
        Category(name: "給与", icon: "banknote", colorHex: "#4CAF50", transactionType: .income, isDefault: true),
        Category(name: "副業", icon: "briefcase", colorHex: "#2196F3", transactionType: .income, isDefault: true),
        Category(name: "投資", icon: "chart.line.uptrend.xyaxis", colorHex: "#FF9800", transactionType: .income, isDefault: true),
        Category(name: "その他収入", icon: "plus", colorHex: "#9C27B0", transactionType: .income, isDefault: true)
    ]
    
    static let defaultExpenseCategories = [
        Category(name: "食費", icon: "fork.knife", colorHex: "#F44336", transactionType: .expense, isDefault: true),
        Category(name: "交通費", icon: "car", colorHex: "#3F51B5", transactionType: .expense, isDefault: true),
        Category(name: "娯楽", icon: "gamecontroller", colorHex: "#E91E63", transactionType: .expense, isDefault: true),
        Category(name: "生活費", icon: "house", colorHex: "#607D8B", transactionType: .expense, isDefault: true),
        Category(name: "医療費", icon: "heart", colorHex: "#FF5722", transactionType: .expense, isDefault: true),
        Category(name: "教育費", icon: "book", colorHex: "#795548", transactionType: .expense, isDefault: true),
        Category(name: "その他支出", icon: "minus", colorHex: "#9E9E9E", transactionType: .expense, isDefault: true)
    ]
}

@Model
final class Budget {
    var id: UUID
    var categoryName: String
    var monthlyBudget: Double
    var year: Int
    var month: Int
    var createdAt: Date
    
    init(categoryName: String, monthlyBudget: Double, year: Int, month: Int) {
        self.id = UUID()
        self.categoryName = categoryName
        self.monthlyBudget = monthlyBudget
        self.year = year
        self.month = month
        self.createdAt = Date()
    }
}
