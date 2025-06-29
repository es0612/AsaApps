//
//  RecipeStore.swift
//  AsaRecipe
//  
//  Created on 2025/06/30
//

import Foundation

@Observable
class RecipeStore {
    var recipes: [Recipe] = []
    private let userDefaults = UserDefaults.standard
    private let recipesKey = "SavedRecipes"
    
    init() {
        loadRecipes()
        if recipes.isEmpty {
            loadSampleRecipes()
        }
    }
    
    func addRecipe(_ recipe: Recipe) {
        recipes.append(recipe)
        saveRecipes()
    }
    
    func updateRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
            saveRecipes()
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        saveRecipes()
    }
    
    func toggleFavorite(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index].isFavorite.toggle()
            saveRecipes()
        }
    }
    
    var favoriteRecipes: [Recipe] {
        recipes.filter { $0.isFavorite }
    }
    
    func recipes(for category: RecipeCategory) -> [Recipe] {
        recipes.filter { $0.category == category }
    }
    
    private func saveRecipes() {
        do {
            let data = try JSONEncoder().encode(recipes)
            userDefaults.set(data, forKey: recipesKey)
        } catch {
            print("レシピの保存に失敗しました: \(error)")
        }
    }
    
    private func loadRecipes() {
        guard let data = userDefaults.data(forKey: recipesKey) else { return }
        do {
            recipes = try JSONDecoder().decode([Recipe].self, from: data)
        } catch {
            print("レシピの読み込みに失敗しました: \(error)")
        }
    }
    
    private func loadSampleRecipes() {
        let sampleRecipes = [
            Recipe(
                name: "カレーライス",
                ingredients: ["玉ねぎ 1個", "にんじん 1本", "じゃがいも 2個", "豚肉 200g", "カレールウ 1/2箱"],
                instructions: ["野菜を切る", "肉と野菜を炒める", "水を加えて煮込む", "カレールウを加える"],
                cookingTime: 30,
                servings: 4,
                category: .main
            ),
            Recipe(
                name: "味噌汁",
                ingredients: ["だし 400ml", "味噌 大さじ2", "豆腐 1/4丁", "わかめ 適量"],
                instructions: ["だしを温める", "豆腐とわかめを入れる", "味噌を溶かし入れる"],
                cookingTime: 10,
                servings: 2,
                category: .soup
            ),
            Recipe(
                name: "パンケーキ",
                ingredients: ["小麦粉 100g", "卵 1個", "牛乳 100ml", "砂糖 大さじ1", "ベーキングパウダー 小さじ1"],
                instructions: ["材料を混ぜる", "フライパンで焼く", "ひっくり返して焼く"],
                cookingTime: 15,
                servings: 2,
                category: .dessert
            )
        ]
        
        recipes = sampleRecipes
        saveRecipes()
    }
}