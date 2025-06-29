//
//  Recipe.swift
//  AsaRecipe
//  
//  Created on 2025/06/30
//

import Foundation

struct Recipe: Identifiable, Codable {
    let id = UUID()
    var name: String
    var ingredients: [String]
    var instructions: [String]
    var cookingTime: Int // 分
    var servings: Int
    var category: RecipeCategory
    var isFavorite: Bool = false
    var dateCreated: Date = Date()
    
    init(name: String = "", 
         ingredients: [String] = [], 
         instructions: [String] = [], 
         cookingTime: Int = 0, 
         servings: Int = 1, 
         category: RecipeCategory = .main) {
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
        self.cookingTime = cookingTime
        self.servings = servings
        self.category = category
    }
}

enum RecipeCategory: String, CaseIterable, Codable {
    case main = "メイン料理"
    case side = "副菜"
    case soup = "スープ"
    case dessert = "デザート"
    case snack = "おやつ"
    case drink = "ドリンク"
    
    var icon: String {
        switch self {
        case .main: return "🍽️"
        case .side: return "🥗"
        case .soup: return "🍲"
        case .dessert: return "🍰"
        case .snack: return "🍪"
        case .drink: return "🥤"
        }
    }
}