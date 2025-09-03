import Foundation
import SwiftData

// MARK: - Ingredient Model
@Model
final class Ingredient {
    var id: UUID
    var name: String
    var amount: Double
    var unit: String
    var category: IngredientCategory
    var createdAt: Date
    
    // Relationship
    var meal: Meal?
    
    init(
        name: String,
        amount: Double = 1.0,
        unit: String = "個",
        category: IngredientCategory = .other
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.unit = unit
        self.category = category
        self.createdAt = Date()
    }
}

// MARK: - Ingredient Category
enum IngredientCategory: String, CaseIterable, Codable {
    case vegetable = "野菜"
    case meat = "肉・魚"
    case grain = "穀物"
    case dairy = "乳製品"
    case seasoning = "調味料"
    case fruit = "果物"
    case other = "その他"
    
    var displayName: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .vegetable: return "🥬"
        case .meat: return "🥩"
        case .grain: return "🌾"
        case .dairy: return "🥛"
        case .seasoning: return "🧂"
        case .fruit: return "🍎"
        case .other: return "📦"
        }
    }
}

// MARK: - Ingredient Extensions
extension Ingredient {
    static let sampleData: [Ingredient] = [
        Ingredient(name: "玉ねぎ", amount: 1, unit: "個", category: .vegetable),
        Ingredient(name: "牛肉", amount: 200, unit: "g", category: .meat),
        Ingredient(name: "米", amount: 2, unit: "合", category: .grain),
        Ingredient(name: "醤油", amount: 1, unit: "大さじ", category: .seasoning)
    ]
}