import Foundation
#if FIREBASE_ENABLED
@preconcurrency import FirebaseFirestore
#endif

// MARK: - BudgetPeriod

enum BudgetPeriod: String, Codable, CaseIterable, Sendable {
    case monthly = "月次"
    case yearly = "年次"
    case custom = "カスタム"

    var displayName: String { rawValue }
}

// MARK: - Budget

struct Budget: Codable, Identifiable, Sendable, Hashable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    #else
    var id: String?
    var createdAt: Date?
    var updatedAt: Date?
    #endif

    var name: String
    var totalAmount: Double
    var periodRawValue: String
    var startDate: Date
    var endDate: Date
    var categoryId: String?
    var userId: String
    var isActive: Bool

    // MARK: - Computed Properties

    var budgetId: String {
        id ?? UUID().uuidString
    }

    var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRawValue) ?? .monthly }
        set { periodRawValue = newValue.rawValue }
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "¥0"
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }

    var periodLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"

        switch period {
        case .monthly:
            return formatter.string(from: startDate)
        case .yearly:
            formatter.dateFormat = "yyyy年"
            return formatter.string(from: startDate)
        case .custom:
            formatter.dateFormat = "M/d"
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }

    // MARK: - Initialization

    init(
        id: String? = nil,
        name: String,
        totalAmount: Double,
        period: BudgetPeriod = .monthly,
        startDate: Date,
        endDate: Date,
        categoryId: String? = nil,
        userId: String,
        isActive: Bool = true,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.totalAmount = totalAmount
        self.periodRawValue = period.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.categoryId = categoryId
        self.userId = userId
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Budget, rhs: Budget) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Budget Helpers

extension Budget {
    static func createMonthlyBudget(
        name: String,
        amount: Double,
        categoryId: String? = nil,
        userId: String
    ) -> Budget {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        return Budget(
            name: name,
            totalAmount: amount,
            period: .monthly,
            startDate: startOfMonth,
            endDate: endOfMonth,
            categoryId: categoryId,
            userId: userId
        )
    }
}
