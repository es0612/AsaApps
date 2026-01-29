import Foundation
import SwiftData

// MARK: - BudgetPeriod

enum BudgetPeriod: String, Codable, CaseIterable, Sendable {
    case monthly = "monthly"
    case weekly = "weekly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .monthly: return "月次"
        case .weekly: return "週次"
        case .yearly: return "年次"
        }
    }
}

// MARK: - Budget Model

@Model
final class Budget {
    @Attribute(.unique) var id: UUID
    var name: String
    var totalAmount: Double
    var periodRawValue: String
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    // リレーションシップ
    @Relationship(deleteRule: .nullify, inverse: \Transaction.budget)
    var transactions: [Transaction]?

    // カテゴリ別予算（JSON形式で保存）
    var categoryBudgetsData: Data?

    // MARK: - Computed Properties

    var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRawValue) ?? .monthly }
        set { periodRawValue = newValue.rawValue }
    }

    var spentAmount: Double {
        transactions?
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount } ?? 0
    }

    var remainingAmount: Double {
        totalAmount - spentAmount
    }

    var spentPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return min((spentAmount / totalAmount) * 100, 100)
    }

    var isOverBudget: Bool {
        spentAmount > totalAmount
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: endDate)
        return calendar.dateComponents([.day], from: today, to: end).day ?? 0
    }

    var dailyBudget: Double {
        guard daysRemaining > 0 else { return 0 }
        return remainingAmount / Double(daysRemaining)
    }

    var formattedTotalAmount: String {
        formatCurrency(totalAmount)
    }

    var formattedSpentAmount: String {
        formatCurrency(spentAmount)
    }

    var formattedRemainingAmount: String {
        formatCurrency(remainingAmount)
    }

    // カテゴリ別予算の取得・設定
    var categoryBudgets: [UUID: Double] {
        get {
            guard let data = categoryBudgetsData else { return [:] }
            return (try? JSONDecoder().decode([String: Double].self, from: data))
                .map { dict in
                    Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
                        UUID(uuidString: key).map { ($0, value) }
                    })
                } ?? [:]
        }
        set {
            let stringDict = Dictionary(uniqueKeysWithValues: newValue.map { ($0.key.uuidString, $0.value) })
            categoryBudgetsData = try? JSONEncoder().encode(stringDict)
        }
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        name: String,
        totalAmount: Double,
        period: BudgetPeriod = .monthly,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.totalAmount = totalAmount
        self.periodRawValue = period.rawValue
        self.startDate = startDate
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()

        // 終了日を期間に基づいて計算
        if let endDate = endDate {
            self.endDate = endDate
        } else {
            let calendar = Calendar.current
            switch period {
            case .monthly:
                self.endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
            case .weekly:
                self.endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
            case .yearly:
                self.endDate = calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
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

    func setCategoryBudget(categoryId: UUID, amount: Double) {
        var budgets = categoryBudgets
        budgets[categoryId] = amount
        categoryBudgets = budgets
        updatedAt = Date()
    }

    func getCategoryBudget(categoryId: UUID) -> Double {
        categoryBudgets[categoryId] ?? 0
    }

    func getCategorySpent(categoryId: UUID) -> Double {
        transactions?
            .filter { $0.type == .expense && $0.category?.id == categoryId }
            .reduce(0) { $0 + $1.amount } ?? 0
    }
}

// MARK: - Budget Extensions

extension Budget {
    static func createMonthlyBudget(amount: Double) -> Budget {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        return Budget(
            name: "月次予算",
            totalAmount: amount,
            period: .monthly,
            startDate: startOfMonth,
            endDate: endOfMonth
        )
    }
}
