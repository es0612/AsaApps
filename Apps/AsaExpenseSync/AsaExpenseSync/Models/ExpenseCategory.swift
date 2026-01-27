import Foundation
import SwiftUI
#if FIREBASE_ENABLED
@preconcurrency import FirebaseFirestore
#endif

// MARK: - ExpenseCategory

struct ExpenseCategory: Codable, Identifiable, Sendable, Hashable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?
    #else
    var id: String?
    #endif

    var name: String
    var iconName: String
    var colorHex: String
    var transactionType: TransactionType
    var isDefault: Bool
    var sortOrder: Int
    var userId: String?

    // MARK: - Computed Properties

    var categoryId: String {
        id ?? UUID().uuidString
    }

    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    // MARK: - Initialization

    init(
        id: String? = nil,
        name: String,
        iconName: String,
        colorHex: String,
        transactionType: TransactionType,
        isDefault: Bool = false,
        sortOrder: Int = 0,
        userId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.transactionType = transactionType
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.userId = userId
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ExpenseCategory, rhs: ExpenseCategory) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Default Categories

extension ExpenseCategory {
    static var defaultExpenseCategories: [ExpenseCategory] {
        [
            ExpenseCategory(id: "food", name: "食費", iconName: "fork.knife", colorHex: "#FF6B6B", transactionType: .expense, isDefault: true, sortOrder: 0),
            ExpenseCategory(id: "transport", name: "交通費", iconName: "car.fill", colorHex: "#4ECDC4", transactionType: .expense, isDefault: true, sortOrder: 1),
            ExpenseCategory(id: "entertainment", name: "娯楽", iconName: "gamecontroller.fill", colorHex: "#45B7D1", transactionType: .expense, isDefault: true, sortOrder: 2),
            ExpenseCategory(id: "shopping", name: "買い物", iconName: "bag.fill", colorHex: "#96CEB4", transactionType: .expense, isDefault: true, sortOrder: 3),
            ExpenseCategory(id: "utilities", name: "光熱費", iconName: "bolt.fill", colorHex: "#FFEAA7", transactionType: .expense, isDefault: true, sortOrder: 4),
            ExpenseCategory(id: "healthcare", name: "医療費", iconName: "heart.fill", colorHex: "#DDA0DD", transactionType: .expense, isDefault: true, sortOrder: 5),
            ExpenseCategory(id: "education", name: "教育費", iconName: "book.fill", colorHex: "#98D8C8", transactionType: .expense, isDefault: true, sortOrder: 6),
            ExpenseCategory(id: "other_expense", name: "その他", iconName: "ellipsis.circle.fill", colorHex: "#BDC3C7", transactionType: .expense, isDefault: true, sortOrder: 7)
        ]
    }

    static var defaultIncomeCategories: [ExpenseCategory] {
        [
            ExpenseCategory(id: "salary", name: "給与", iconName: "yensign.circle.fill", colorHex: "#2ECC71", transactionType: .income, isDefault: true, sortOrder: 0),
            ExpenseCategory(id: "bonus", name: "ボーナス", iconName: "star.fill", colorHex: "#F1C40F", transactionType: .income, isDefault: true, sortOrder: 1),
            ExpenseCategory(id: "investment", name: "投資収益", iconName: "chart.line.uptrend.xyaxis", colorHex: "#3498DB", transactionType: .income, isDefault: true, sortOrder: 2),
            ExpenseCategory(id: "side_job", name: "副業", iconName: "briefcase.fill", colorHex: "#9B59B6", transactionType: .income, isDefault: true, sortOrder: 3),
            ExpenseCategory(id: "other_income", name: "その他", iconName: "ellipsis.circle.fill", colorHex: "#95A5A6", transactionType: .income, isDefault: true, sortOrder: 4)
        ]
    }

    static var allDefaultCategories: [ExpenseCategory] {
        defaultExpenseCategories + defaultIncomeCategories
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
