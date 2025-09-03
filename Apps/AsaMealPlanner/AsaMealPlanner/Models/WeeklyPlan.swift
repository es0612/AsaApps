import Foundation
import SwiftData

// MARK: - WeeklyPlan Model
@Model
final class WeeklyPlan {
    var id: UUID
    var planName: String
    var startDate: Date
    var endDate: Date
    var planDescription: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Meal.weeklyPlan)
    var meals: [Meal]
    
    init(
        planName: String,
        startDate: Date,
        planDescription: String = ""
    ) {
        self.id = UUID()
        self.planName = planName
        self.startDate = startDate
        self.endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        self.planDescription = planDescription
        self.isActive = true
        self.meals = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - WeeklyPlan Extensions
extension WeeklyPlan {
    var weekDates: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                dates.append(date)
            }
        }
        return dates
    }
    
    var totalMeals: Int {
        return meals.count
    }
    
    var completedDays: Int {
        let uniqueDays = Set(meals.map { $0.dayOfWeek })
        return uniqueDays.count
    }
    
    func getMeals(for dayOfWeek: Int, type: MealType? = nil) -> [Meal] {
        let dayMeals = meals.filter { $0.dayOfWeek == dayOfWeek }
        if let type = type {
            return dayMeals.filter { $0.mealType == type }.sorted { $0.mealType.sortOrder < $1.mealType.sortOrder }
        }
        return dayMeals.sorted { $0.mealType.sortOrder < $1.mealType.sortOrder }
    }
    
    func addMeal(_ meal: Meal) {
        meals.append(meal)
        meal.weeklyPlan = self
        updatedAt = Date()
    }
    
    func removeMeal(_ meal: Meal) {
        if let index = meals.firstIndex(of: meal) {
            meals.remove(at: index)
            meal.weeklyPlan = nil
            updatedAt = Date()
        }
    }
    
    // 週間の全食材を取得（重複除去・統合）
    func getConsolidatedIngredients() -> [ConsolidatedIngredient] {
        var ingredientMap: [String: ConsolidatedIngredient] = [:]
        
        for meal in meals {
            for ingredient in meal.ingredients {
                let key = "\(ingredient.name)-\(ingredient.unit)"
                
                if let existing = ingredientMap[key] {
                    existing.totalAmount += ingredient.amount
                    existing.mealTitles.insert(meal.title)
                } else {
                    let consolidated = ConsolidatedIngredient(
                        name: ingredient.name,
                        totalAmount: ingredient.amount,
                        unit: ingredient.unit,
                        category: ingredient.category,
                        mealTitles: Set([meal.title])
                    )
                    ingredientMap[key] = consolidated
                }
            }
        }
        
        return Array(ingredientMap.values).sorted { $0.name < $1.name }
    }
    
    static let sampleData: WeeklyPlan = {
        let plan = WeeklyPlan(planName: "家族の健康週間プラン", startDate: Date(), planDescription: "栄養バランスを考えた1週間の食事プラン")
        
        // サンプル食事を追加
        let meals = Meal.sampleData
        meals.forEach { meal in
            plan.addMeal(meal)
            // サンプル食材を追加
            let ingredients = Ingredient.sampleData.prefix(2)
            ingredients.forEach { ingredient in
                meal.addIngredient(ingredient)
            }
        }
        
        return plan
    }()
}

// MARK: - Consolidated Ingredient
class ConsolidatedIngredient: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    var totalAmount: Double
    let unit: String
    let category: IngredientCategory
    var mealTitles: Set<String>
    @Published var isPurchased: Bool = false
    
    init(name: String, totalAmount: Double, unit: String, category: IngredientCategory, mealTitles: Set<String>) {
        self.name = name
        self.totalAmount = totalAmount
        self.unit = unit
        self.category = category
        self.mealTitles = mealTitles
    }
    
    var displayAmount: String {
        if totalAmount.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(totalAmount))\(unit)"
        } else {
            return String(format: "%.1f%@", totalAmount, unit)
        }
    }
}