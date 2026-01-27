import Foundation
#if FIREBASE_ENABLED
@preconcurrency import FirebaseFirestore
#endif

// MARK: - TransactionType

enum TransactionType: String, Codable, CaseIterable, Sendable {
    case income = "収入"
    case expense = "支出"

    var symbol: String {
        switch self {
        case .income: return "+"
        case .expense: return "-"
        }
    }

    var iconName: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
}

// MARK: - ExpenseTransaction

struct ExpenseTransaction: Codable, Identifiable, Sendable, Hashable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    #else
    var id: String?
    var createdAt: Date?
    var updatedAt: Date?
    #endif

    // MARK: - Core Properties

    var amount: Double
    var typeRawValue: String
    var title: String
    var note: String?
    var date: Date
    var categoryId: String?

    // MARK: - Sync Properties

    var userId: String
    var deviceId: String
    var syncVersion: Int
    var isDeleted: Bool
    var localModifiedAt: Date?

    // MARK: - Computed Properties

    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }

    var transactionId: String {
        id ?? UUID().uuidString
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        let value = formatter.string(from: NSNumber(value: amount)) ?? "¥0"
        return "\(type.symbol)\(value)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Initialization

    init(
        id: String? = nil,
        amount: Double,
        type: TransactionType,
        title: String,
        note: String? = nil,
        date: Date = Date(),
        categoryId: String? = nil,
        userId: String,
        deviceId: String,
        syncVersion: Int = 1,
        isDeleted: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        localModifiedAt: Date? = nil
    ) {
        self.id = id
        self.amount = amount
        self.typeRawValue = type.rawValue
        self.title = title
        self.note = note
        self.date = date
        self.categoryId = categoryId
        self.userId = userId
        self.deviceId = deviceId
        self.syncVersion = syncVersion
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.localModifiedAt = localModifiedAt
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ExpenseTransaction, rhs: ExpenseTransaction) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data

extension ExpenseTransaction {
    static var sampleTransactions: [ExpenseTransaction] {
        let userId = "sample-user"
        let deviceId = "sample-device"

        return [
            ExpenseTransaction(
                id: "1",
                amount: 250000,
                type: .income,
                title: "給与",
                date: Date(),
                categoryId: "salary",
                userId: userId,
                deviceId: deviceId
            ),
            ExpenseTransaction(
                id: "2",
                amount: 5800,
                type: .expense,
                title: "スーパーで買い物",
                note: "週末の食材",
                date: Date().addingTimeInterval(-86400),
                categoryId: "food",
                userId: userId,
                deviceId: deviceId
            ),
            ExpenseTransaction(
                id: "3",
                amount: 1200,
                type: .expense,
                title: "電車代",
                date: Date().addingTimeInterval(-172800),
                categoryId: "transport",
                userId: userId,
                deviceId: deviceId
            ),
            ExpenseTransaction(
                id: "4",
                amount: 15000,
                type: .expense,
                title: "映画とディナー",
                note: "家族でお出かけ",
                date: Date().addingTimeInterval(-259200),
                categoryId: "entertainment",
                userId: userId,
                deviceId: deviceId
            )
        ]
    }
}
