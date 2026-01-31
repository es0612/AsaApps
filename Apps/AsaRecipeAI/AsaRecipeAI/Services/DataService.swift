//
//  DataService.swift
//  AsaRecipeAI
//
//  Swift Dataを使用したデータ永続化サービス
//  レシピ、食材、履歴、設定のCRUD操作を管理
//

import Foundation
import SwiftData

// MARK: - DataService

/// Swift Dataを使用したデータ永続化サービス
@MainActor
final class DataService {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Recipe Operations

    /// すべてのレシピを取得
    func fetchAllRecipes() -> [Recipe] {
        let descriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("レシピの取得に失敗: \(error)")
            return []
        }
    }

    /// お気に入りレシピを取得
    func fetchFavoriteRecipes() -> [Recipe] {
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { $0.isFavorite },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("お気に入りレシピの取得に失敗: \(error)")
            return []
        }
    }

    /// 最近調理したレシピを取得
    func fetchRecentlyCookedRecipes(limit: Int = 10) -> [Recipe] {
        var descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { $0.lastCookedAt != nil },
            sortBy: [SortDescriptor(\.lastCookedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("最近のレシピの取得に失敗: \(error)")
            return []
        }
    }

    /// レシピを保存
    func saveRecipe(_ recipe: Recipe) {
        modelContext.insert(recipe)
        save()
    }

    /// レシピを削除
    func deleteRecipe(_ recipe: Recipe) {
        modelContext.delete(recipe)
        save()
    }

    /// RecipeRecommendationからレシピを保存
    func saveRecipeFromRecommendation(_ recommendation: RecipeRecommendation, isFavorite: Bool = false) -> Recipe {
        let recipe = Recipe(from: recommendation)
        recipe.isFavorite = isFavorite
        modelContext.insert(recipe)
        save()
        return recipe
    }

    // MARK: - Ingredient Operations

    /// すべての食材を取得
    func fetchAllIngredients() -> [Ingredient] {
        let descriptor = FetchDescriptor<Ingredient>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("食材の取得に失敗: \(error)")
            return []
        }
    }

    /// お気に入り食材を取得
    func fetchFavoriteIngredients() -> [Ingredient] {
        let descriptor = FetchDescriptor<Ingredient>(
            predicate: #Predicate<Ingredient> { $0.isFavorite },
            sortBy: [SortDescriptor(\.name)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("お気に入り食材の取得に失敗: \(error)")
            return []
        }
    }

    /// 食材を保存
    func saveIngredient(_ ingredient: Ingredient) {
        modelContext.insert(ingredient)
        save()
    }

    /// 食材を削除
    func deleteIngredient(_ ingredient: Ingredient) {
        modelContext.delete(ingredient)
        save()
    }

    /// IngredientInfoから食材を保存
    func saveIngredientFromInfo(_ info: IngredientInfo) -> Ingredient {
        let ingredient = Ingredient(from: info)
        modelContext.insert(ingredient)
        save()
        return ingredient
    }

    // MARK: - History Operations

    /// すべての履歴を取得
    func fetchAllHistory() -> [RecognitionHistory] {
        let descriptor = FetchDescriptor<RecognitionHistory>(
            sortBy: [SortDescriptor(\.recognizedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("履歴の取得に失敗: \(error)")
            return []
        }
    }

    /// 最近の履歴を取得
    func fetchRecentHistory(limit: Int = 20) -> [RecognitionHistory] {
        var descriptor = FetchDescriptor<RecognitionHistory>(
            sortBy: [SortDescriptor(\.recognizedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("最近の履歴の取得に失敗: \(error)")
            return []
        }
    }

    /// 履歴を保存
    func saveHistory(_ history: RecognitionHistory) {
        modelContext.insert(history)
        save()
    }

    /// 履歴を削除
    func deleteHistory(_ history: RecognitionHistory) {
        modelContext.delete(history)
        save()
    }

    /// 認識結果から履歴を保存
    func saveHistoryFromResult(
        _ result: IngredientRecognitionResult,
        thumbnailData: Data?,
        generatedRecipeCount: Int = 0
    ) -> RecognitionHistory {
        let history = RecognitionHistory(from: result, thumbnailData: thumbnailData)
        history.generatedRecipeCount = generatedRecipeCount
        modelContext.insert(history)
        save()
        return history
    }

    /// すべての履歴を削除
    func clearAllHistory() {
        let histories = fetchAllHistory()
        for history in histories {
            modelContext.delete(history)
        }
        save()
    }

    // MARK: - Preferences Operations

    /// ユーザー設定を取得（存在しない場合はデフォルト作成）
    func fetchUserPreferences() -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()

        do {
            let results = try modelContext.fetch(descriptor)
            if let existing = results.first {
                return existing
            }
        } catch {
            print("設定の取得に失敗: \(error)")
        }

        // デフォルト設定を作成
        let newPreferences = UserPreferences()
        modelContext.insert(newPreferences)
        save()
        return newPreferences
    }

    /// 設定を保存
    func savePreferences(_ preferences: UserPreferences) {
        preferences.update()
        save()
    }

    // MARK: - Statistics

    /// 統計情報を取得
    func fetchStatistics() -> AppStatistics {
        let recipes = fetchAllRecipes()
        let favorites = fetchFavoriteRecipes()
        let histories = fetchAllHistory()

        let totalCookCount = recipes.reduce(0) { $0 + $1.cookCount }
        let totalIngredients = histories.reduce(0) { $0 + $1.ingredientCount }

        return AppStatistics(
            totalRecipes: recipes.count,
            favoriteRecipes: favorites.count,
            totalRecognitions: histories.count,
            totalIngredientsRecognized: totalIngredients,
            totalCookCount: totalCookCount
        )
    }

    // MARK: - Private Methods

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("保存に失敗: \(error)")
        }
    }
}

// MARK: - AppStatistics

/// アプリ統計情報
struct AppStatistics {
    let totalRecipes: Int
    let favoriteRecipes: Int
    let totalRecognitions: Int
    let totalIngredientsRecognized: Int
    let totalCookCount: Int
}
