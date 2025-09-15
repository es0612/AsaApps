//
//  Transaction.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case income = "収入"
    case expense = "支出"

    var symbol: String {
        switch self {
        case .income: return "+"
        case .expense: return "-"
        }
    }
}

@Model
final class Transaction {
    // MARK: - Properties
    var id: UUID
    var amount: Double
    var typeRawValue: String
    var title: String
    var note: String?
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships
    var category: Category?
    var member: FamilyMember?
    var budget: Budget?

    // MARK: - Computed Properties
    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        let formattedString = formatter.string(from: NSNumber(value: amount)) ?? "¥0"
        return "\(type.symbol)\(formattedString)"
    }

    var monthYearKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    // MARK: - Initialization
    init(
        amount: Double,
        type: TransactionType,
        title: String,
        note: String? = nil,
        date: Date = Date(),
        category: Category? = nil,
        member: FamilyMember? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.typeRawValue = type.rawValue
        self.title = title
        self.note = note
        self.date = date
        self.category = category
        self.member = member
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods
    func update(
        amount: Double? = nil,
        type: TransactionType? = nil,
        title: String? = nil,
        note: String? = nil,
        date: Date? = nil,
        category: Category? = nil,
        member: FamilyMember? = nil
    ) {
        if let amount = amount { self.amount = amount }
        if let type = type { self.type = type }
        if let title = title { self.title = title }
        if let note = note { self.note = note }
        if let date = date { self.date = date }
        if let category = category { self.category = category }
        if let member = member { self.member = member }
        self.updatedAt = Date()
    }

    // MARK: - Static Methods
    static func sampleTransactions() -> [Transaction] {
        let calendar = Calendar.current
        let today = Date()

        return [
            Transaction(
                amount: 5000,
                type: .expense,
                title: "スーパーで買い物",
                note: "週末の食材",
                date: calendar.date(byAdding: .day, value: -1, to: today) ?? today
            ),
            Transaction(
                amount: 1200,
                type: .expense,
                title: "ランチ",
                date: calendar.date(byAdding: .day, value: -2, to: today) ?? today
            ),
            Transaction(
                amount: 300000,
                type: .income,
                title: "給料",
                date: calendar.date(byAdding: .day, value: -5, to: today) ?? today
            ),
            Transaction(
                amount: 10000,
                type: .expense,
                title: "電気代",
                date: calendar.date(byAdding: .day, value: -7, to: today) ?? today
            ),
            Transaction(
                amount: 3000,
                type: .expense,
                title: "書籍購入",
                note: "プログラミング参考書",
                date: calendar.date(byAdding: .day, value: -10, to: today) ?? today
            )
        ]
    }
}