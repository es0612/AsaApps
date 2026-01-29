import Foundation
import SwiftData

// MARK: - TransactionType

enum TransactionType: String, Codable, CaseIterable, Sendable {
    case income = "income"
    case expense = "expense"

    var displayName: String {
        switch self {
        case .income: return "収入"
        case .expense: return "支出"
        }
    }

    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
}

// MARK: - Transaction Model

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var title: String
    var note: String?
    var date: Date
    var typeRawValue: String
    var createdAt: Date
    var updatedAt: Date

    // AI分析フィールド
    var isAnomaly: Bool
    var anomalyScore: Double?
    var anomalyReasons: [String]?

    // リレーションシップ
    var category: Category?
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
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }

    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: date)
    }

    var hourOfDay: Int {
        Calendar.current.component(.hour, from: date)
    }

    var monthKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    var weekKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-'W'ww"
        return formatter.string(from: date)
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        amount: Double,
        title: String,
        note: String? = nil,
        date: Date = Date(),
        type: TransactionType = .expense,
        category: Category? = nil,
        budget: Budget? = nil
    ) {
        self.id = id
        self.amount = amount
        self.title = title
        self.note = note
        self.date = date
        self.typeRawValue = type.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isAnomaly = false
        self.anomalyScore = nil
        self.anomalyReasons = nil
        self.category = category
        self.budget = budget
    }

    // MARK: - Methods

    func markAsAnomaly(score: Double, reasons: [String]) {
        self.isAnomaly = true
        self.anomalyScore = score
        self.anomalyReasons = reasons
        self.updatedAt = Date()
    }

    func clearAnomalyFlag() {
        self.isAnomaly = false
        self.anomalyScore = nil
        self.anomalyReasons = nil
        self.updatedAt = Date()
    }
}

// MARK: - Transaction Extensions

extension Transaction {
    static func sampleTransactions() -> [Transaction] {
        let categories = Category.defaultCategories()

        return [
            Transaction(amount: 1500, title: "コーヒー", type: .expense, category: categories[0]),
            Transaction(amount: 8500, title: "ランチ会食", type: .expense, category: categories[0]),
            Transaction(amount: 3200, title: "電車代", type: .expense, category: categories[1]),
            Transaction(amount: 250000, title: "給与", type: .income),
            Transaction(amount: 15000, title: "書籍購入", type: .expense, category: categories[3])
        ]
    }
}
