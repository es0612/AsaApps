//
//  Budget.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import Foundation
import SwiftData

enum BudgetPeriod: String, Codable, CaseIterable {
    case monthly = "月次"
    case yearly = "年次"
    case custom = "カスタム"

    var calendarComponent: Calendar.Component {
        switch self {
        case .monthly: return .month
        case .yearly: return .year
        case .custom: return .day
        }
    }
}

@Model
final class Budget {
    // MARK: - Properties
    var id: UUID
    var name: String
    var totalAmount: Double
    var periodRawValue: String
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships
    var categories: [Category]?
    var transactions: [Transaction]?

    // MARK: - Computed Properties
    var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRawValue) ?? .monthly }
        set { periodRawValue = newValue.rawValue }
    }

    var remainingAmount: Double {
        let spentAmount = transactions?.reduce(0) { total, transaction in
            transaction.type == .expense ? total + transaction.amount : total
        } ?? 0
        return totalAmount - spentAmount
    }

    var spentPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        let spentAmount = totalAmount - remainingAmount
        return (spentAmount / totalAmount) * 100
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }

    var periodLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        switch period {
        case .monthly:
            formatter.dateFormat = "yyyy年MM月"
            return formatter.string(from: startDate)
        case .yearly:
            formatter.dateFormat = "yyyy年"
            return formatter.string(from: startDate)
        case .custom:
            formatter.dateFormat = "MM/dd"
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            return "\(start) - \(end)"
        }
    }

    var statusColor: String {
        let percentage = spentPercentage
        if percentage >= 90 {
            return "#FF0000" // 赤
        } else if percentage >= 70 {
            return "#FFA500" // オレンジ
        } else {
            return "#00FF00" // 緑
        }
    }

    // MARK: - Initialization
    init(
        name: String,
        totalAmount: Double,
        period: BudgetPeriod = .monthly,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.totalAmount = totalAmount
        self.periodRawValue = period.rawValue

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        self.startDate = startOfDay

        if let endDate = endDate {
            self.endDate = endDate
        } else {
            switch period {
            case .monthly:
                self.endDate = calendar.date(byAdding: .month, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? startOfDay
            case .yearly:
                self.endDate = calendar.date(byAdding: .year, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? startOfDay
            case .custom:
                self.endDate = calendar.date(byAdding: .month, value: 1, to: startOfDay) ?? startOfDay
            }
        }

        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods
    func addCategory(_ category: Category) {
        if categories == nil {
            categories = []
        }
        categories?.append(category)
        updatedAt = Date()
    }

    func removeCategory(_ category: Category) {
        categories?.removeAll { $0.id == category.id }
        updatedAt = Date()
    }

    func addTransaction(_ transaction: Transaction) {
        if transactions == nil {
            transactions = []
        }
        transactions?.append(transaction)
        updatedAt = Date()
    }

    func updateBudget(name: String? = nil, totalAmount: Double? = nil, isActive: Bool? = nil) {
        if let name = name { self.name = name }
        if let totalAmount = totalAmount { self.totalAmount = totalAmount }
        if let isActive = isActive { self.isActive = isActive }
        self.updatedAt = Date()
    }

    // MARK: - Static Methods
    static func currentMonthBudget() -> Budget {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

        return Budget(
            name: "今月の予算",
            totalAmount: 300000,
            period: .monthly,
            startDate: startOfMonth
        )
    }

    static func sampleBudgets() -> [Budget] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now

        return [
            Budget(
                name: "今月の家計",
                totalAmount: 300000,
                period: .monthly,
                startDate: startOfMonth
            ),
            Budget(
                name: "年間予算",
                totalAmount: 4000000,
                period: .yearly,
                startDate: startOfYear
            ),
            Budget(
                name: "夏休み旅行",
                totalAmount: 200000,
                period: .custom,
                startDate: calendar.date(byAdding: .month, value: 2, to: now) ?? now,
                endDate: calendar.date(byAdding: .month, value: 3, to: now)
            )
        ]
    }
}