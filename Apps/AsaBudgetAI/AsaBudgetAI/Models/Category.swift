import Foundation
import SwiftData
import SwiftUI

// MARK: - Category Model

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var sortOrder: Int
    var isDefault: Bool
    var createdAt: Date

    // リレーションシップ
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]?

    // MARK: - Computed Properties

    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    var transactionCount: Int {
        transactions?.count ?? 0
    }

    var totalAmount: Double {
        transactions?.reduce(0) { $0 + $1.amount } ?? 0
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorHex: String,
        sortOrder: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}

// MARK: - Default Categories

extension Category {
    static func defaultCategories() -> [Category] {
        [
            Category(name: "食費", iconName: "fork.knife", colorHex: "#FF6B6B", sortOrder: 0, isDefault: true),
            Category(name: "交通費", iconName: "car.fill", colorHex: "#4ECDC4", sortOrder: 1, isDefault: true),
            Category(name: "日用品", iconName: "cart.fill", colorHex: "#45B7D1", sortOrder: 2, isDefault: true),
            Category(name: "娯楽", iconName: "gamecontroller.fill", colorHex: "#96CEB4", sortOrder: 3, isDefault: true),
            Category(name: "医療費", iconName: "cross.case.fill", colorHex: "#FFEAA7", sortOrder: 4, isDefault: true),
            Category(name: "教育", iconName: "book.fill", colorHex: "#DDA0DD", sortOrder: 5, isDefault: true),
            Category(name: "光熱費", iconName: "bolt.fill", colorHex: "#FFB347", sortOrder: 6, isDefault: true),
            Category(name: "通信費", iconName: "antenna.radiowaves.left.and.right", colorHex: "#87CEEB", sortOrder: 7, isDefault: true),
            Category(name: "住居費", iconName: "house.fill", colorHex: "#C68C53", sortOrder: 8, isDefault: true),
            Category(name: "その他", iconName: "ellipsis.circle.fill", colorHex: "#B8B8B8", sortOrder: 9, isDefault: true)
        ]
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }

        guard hexString.count == 6 else { return nil }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0
        )
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#808080"
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
