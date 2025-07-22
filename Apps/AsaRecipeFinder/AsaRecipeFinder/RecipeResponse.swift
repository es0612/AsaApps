//
//  RecipeResponse.swift
//  AsaRecipeFinder
//  
//  Created on 2025/07/22
//

import Foundation

// MARK: - TheMealDB API Response Models

struct MealResponse: Codable {
    let meals: [MealData]?
}

struct MealData: Codable {
    let idMeal: String
    let strMeal: String
    let strMealThumb: String?
    let strCategory: String?
    let strInstructions: String?
    let strYoutube: String?
    let strSource: String?
    
    // 材料とメジャー（最大20個まで）
    let strIngredient1, strIngredient2, strIngredient3, strIngredient4, strIngredient5: String?
    let strIngredient6, strIngredient7, strIngredient8, strIngredient9, strIngredient10: String?
    let strIngredient11, strIngredient12, strIngredient13, strIngredient14, strIngredient15: String?
    let strIngredient16, strIngredient17, strIngredient18, strIngredient19, strIngredient20: String?
    
    let strMeasure1, strMeasure2, strMeasure3, strMeasure4, strMeasure5: String?
    let strMeasure6, strMeasure7, strMeasure8, strMeasure9, strMeasure10: String?
    let strMeasure11, strMeasure12, strMeasure13, strMeasure14, strMeasure15: String?
    let strMeasure16, strMeasure17, strMeasure18, strMeasure19, strMeasure20: String?
}

// MARK: - Category Response Models

struct CategoryResponse: Codable {
    let meals: [CategoryData]?
}

struct CategoryData: Codable {
    let strCategory: String
}

// MARK: - Search by Ingredient Response Models

struct SearchResponse: Codable {
    let meals: [SearchData]?
}

struct SearchData: Codable {
    let strMeal: String
    let strMealThumb: String
    let idMeal: String
}

// MARK: - Extensions for Recipe Conversion

extension MealData {
    func toRecipe() -> Recipe {
        let ingredients = extractIngredients()
        return Recipe(
            id: idMeal,
            title: strMeal,
            image: strMealThumb,
            instructions: strInstructions ?? "",
            ingredients: ingredients,
            category: strCategory,
            sourceURL: strSource
        )
    }
    
    private func extractIngredients() -> [Ingredient] {
        var ingredients: [Ingredient] = []
        
        let ingredientNames = [
            strIngredient1, strIngredient2, strIngredient3, strIngredient4, strIngredient5,
            strIngredient6, strIngredient7, strIngredient8, strIngredient9, strIngredient10,
            strIngredient11, strIngredient12, strIngredient13, strIngredient14, strIngredient15,
            strIngredient16, strIngredient17, strIngredient18, strIngredient19, strIngredient20
        ]
        
        let measures = [
            strMeasure1, strMeasure2, strMeasure3, strMeasure4, strMeasure5,
            strMeasure6, strMeasure7, strMeasure8, strMeasure9, strMeasure10,
            strMeasure11, strMeasure12, strMeasure13, strMeasure14, strMeasure15,
            strMeasure16, strMeasure17, strMeasure18, strMeasure19, strMeasure20
        ]
        
        for (index, ingredientName) in ingredientNames.enumerated() {
            if let name = ingredientName, 
               !name.isEmpty, 
               name.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                let measure = measures[index]?.trimmingCharacters(in: .whitespacesAndNewlines)
                let ingredient = Ingredient(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    amount: measure?.isEmpty == false ? measure : nil
                )
                ingredients.append(ingredient)
            }
        }
        
        return ingredients
    }
}

extension SearchData {
    func toRecipe() -> Recipe {
        return Recipe(
            id: idMeal,
            title: strMeal,
            image: strMealThumb
        )
    }
}