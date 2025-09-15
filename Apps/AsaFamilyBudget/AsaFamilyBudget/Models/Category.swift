//
//  Category.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    // MARK: - Properties
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var budgetLimit: Double
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships
    var transactions: [Transaction]?
    var budgets: [Budget]?

    // MARK: - Computed Properties
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    var icon: String {
        iconName.isEmpty ? "folder.fill" : iconName
    }

    // MARK: - Initialization
    init(
        name: String,
        iconName: String = "folder.fill",
        colorHex: String = "#8B5A2B",
        budgetLimit: Double = 0,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.budgetLimit = budgetLimit
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Static Methods
    static func defaultCategories() -> [Category] {
        return [
            Category(name: "食費", iconName: "cart.fill", colorHex: "#C68C53", budgetLimit: 50000, isDefault: true),
            Category(name: "住居費", iconName: "house.fill", colorHex: "#8B5A2B", budgetLimit: 100000, isDefault: true),
            Category(name: "光熱費", iconName: "bolt.fill", colorHex: "#7A918D", budgetLimit: 20000, isDefault: true),
            Category(name: "交通費", iconName: "car.fill", colorHex: "#2F3E46", budgetLimit: 15000, isDefault: true),
            Category(name: "通信費", iconName: "wifi", colorHex: "#E8D5B9", budgetLimit: 10000, isDefault: true),
            Category(name: "教育費", iconName: "book.fill", colorHex: "#C68C53", budgetLimit: 30000, isDefault: true),
            Category(name: "娯楽費", iconName: "gamecontroller.fill", colorHex: "#8B5A2B", budgetLimit: 20000, isDefault: true),
            Category(name: "医療費", iconName: "cross.fill", colorHex: "#7A918D", budgetLimit: 15000, isDefault: true),
            Category(name: "衣服費", iconName: "tshirt.fill", colorHex: "#2F3E46", budgetLimit: 20000, isDefault: true),
            Category(name: "その他", iconName: "ellipsis.circle.fill", colorHex: "#E8D5B9", budgetLimit: 10000, isDefault: true)
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
}