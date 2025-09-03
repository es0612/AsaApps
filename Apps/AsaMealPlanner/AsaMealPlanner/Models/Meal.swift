import Foundation
import SwiftData

// MARK: - Meal Model
@Model
final class Meal {
    var id: UUID
    var title: String
    var mealDescription: String
    var mealType: MealType
    var dayOfWeek: Int // 0 = 日曜日, 1 = 月曜日, etc.
    var estimatedCookingTime: Int // 分
    var servings: Int
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.meal)
    var ingredients: [Ingredient]
    
    var weeklyPlan: WeeklyPlan?
    
    init(
        title: String,
        mealDescription: String = "",
        mealType: MealType,
        dayOfWeek: Int,
        estimatedCookingTime: Int = 30,
        servings: Int = 2
    ) {
        self.id = UUID()
        self.title = title
        self.mealDescription = mealDescription
        self.mealType = mealType
        self.dayOfWeek = dayOfWeek
        self.estimatedCookingTime = estimatedCookingTime
        self.servings = servings
        self.ingredients = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Meal Type
enum MealType: String, CaseIterable, Codable {
    case breakfast = "朝食"
    case lunch = "昼食"
    case dinner = "夕食"
    case snack = "スナック"
    
    var displayName: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch: return "☀️"
        case .dinner: return "🌙"
        case .snack: return "🍪"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }
}

// MARK: - Meal Extensions
extension Meal {
    var dayOfWeekName: String {
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        return weekdays[dayOfWeek % 7]
    }
    
    var totalIngredients: Int {
        return ingredients.count
    }
    
    func addIngredient(_ ingredient: Ingredient) {
        ingredients.append(ingredient)
        ingredient.meal = self
        updatedAt = Date()
    }
    
    func removeIngredient(_ ingredient: Ingredient) {
        if let index = ingredients.firstIndex(of: ingredient) {
            ingredients.remove(at: index)
            ingredient.meal = nil
            updatedAt = Date()
        }
    }
    
    static let sampleData: [Meal] = [
        Meal(title: "和風オムレツ", mealDescription: "野菜たっぷりの栄養満点オムレツ", mealType: .breakfast, dayOfWeek: 1),
        Meal(title: "親子丼", mealDescription: "家族みんな大好きな定番丼", mealType: .lunch, dayOfWeek: 1),
        Meal(title: "鮭の塩焼き定食", mealDescription: "健康的な和定食", mealType: .dinner, dayOfWeek: 1),
        Meal(title: "りんご", mealDescription: "デザートに新鮮なりんご", mealType: .snack, dayOfWeek: 1)
    ]
}