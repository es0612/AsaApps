//
//  Recipe.swift
//  AsaRecipeAI
//
//  レシピのSwift Dataモデル
//  お気に入りレシピを永続化
//

import Foundation
import SwiftData

/// 保存されたレシピ
@Model
final class Recipe {
    // MARK: - Properties

    /// 一意識別子
    var id: UUID

    /// レシピ名
    var name: String

    /// 説明
    var recipeDescription: String

    /// 難易度（Raw Value）
    var difficultyRawValue: String

    /// 調理時間（分）
    var cookingTimeMinutes: Int

    /// 人数分
    var servings: Int

    /// 食材（JSON形式）
    var ingredientsJSON: Data?

    /// 調理手順（JSON形式）
    var stepsJSON: Data?

    /// 推薦理由
    var recommendationReason: String

    /// お気に入り
    var isFavorite: Bool

    /// 調理回数
    var cookCount: Int

    /// 作成日時
    var createdAt: Date

    /// 最終調理日時
    var lastCookedAt: Date?

    // MARK: - Computed Properties

    /// 難易度
    var difficulty: RecipeDifficulty {
        get { RecipeDifficulty.from(difficultyRawValue) }
        set { difficultyRawValue = newValue.rawValue }
    }

    /// 食材リスト
    var ingredients: [SavedRecipeIngredient] {
        get {
            guard let data = ingredientsJSON else { return [] }
            return (try? JSONDecoder().decode([SavedRecipeIngredient].self, from: data)) ?? []
        }
        set {
            ingredientsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// 調理手順リスト
    var steps: [SavedCookingStep] {
        get {
            guard let data = stepsJSON else { return [] }
            return (try? JSONDecoder().decode([SavedCookingStep].self, from: data)) ?? []
        }
        set {
            stepsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        difficulty: RecipeDifficulty,
        cookingTimeMinutes: Int,
        servings: Int,
        ingredients: [SavedRecipeIngredient] = [],
        steps: [SavedCookingStep] = [],
        recommendationReason: String,
        isFavorite: Bool = false,
        cookCount: Int = 0,
        createdAt: Date = Date(),
        lastCookedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = description
        self.difficultyRawValue = difficulty.rawValue
        self.cookingTimeMinutes = cookingTimeMinutes
        self.servings = servings
        self.ingredientsJSON = try? JSONEncoder().encode(ingredients)
        self.stepsJSON = try? JSONEncoder().encode(steps)
        self.recommendationReason = recommendationReason
        self.isFavorite = isFavorite
        self.cookCount = cookCount
        self.createdAt = createdAt
        self.lastCookedAt = lastCookedAt
    }

    /// RecipeRecommendationから変換
    convenience init(from recommendation: RecipeRecommendation) {
        let savedIngredients = recommendation.ingredients.map {
            SavedRecipeIngredient(name: $0.name, amount: $0.amount, isAvailable: $0.isAvailable)
        }
        let savedSteps = recommendation.steps.map {
            SavedCookingStep(stepNumber: $0.stepNumber, instruction: $0.instruction, tip: $0.tip)
        }

        self.init(
            name: recommendation.name,
            description: recommendation.description,
            difficulty: RecipeDifficulty.from(recommendation.difficulty),
            cookingTimeMinutes: recommendation.cookingTimeMinutes,
            servings: recommendation.servings,
            ingredients: savedIngredients,
            steps: savedSteps,
            recommendationReason: recommendation.recommendationReason
        )
    }

    // MARK: - Methods

    /// 調理を記録
    func markAsCooked() {
        cookCount += 1
        lastCookedAt = Date()
    }
}

// MARK: - Supporting Types

/// 保存用食材
struct SavedRecipeIngredient: Codable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let amount: String
    let isAvailable: Bool
}

/// 保存用調理手順
struct SavedCookingStep: Codable, Identifiable, Sendable {
    var id: Int { stepNumber }
    let stepNumber: Int
    let instruction: String
    let tip: String?
}

// MARK: - Sample Data

extension Recipe {
    /// サンプルデータ
    static var sampleRecipes: [Recipe] { [
        Recipe(
            name: "肉じゃが",
            description: "家庭の定番料理。ホクホクのじゃがいもと甘辛い味付けが美味しい",
            difficulty: .normal,
            cookingTimeMinutes: 40,
            servings: 4,
            ingredients: [
                SavedRecipeIngredient(name: "じゃがいも", amount: "4個", isAvailable: true),
                SavedRecipeIngredient(name: "にんじん", amount: "1本", isAvailable: true),
                SavedRecipeIngredient(name: "玉ねぎ", amount: "1個", isAvailable: true),
                SavedRecipeIngredient(name: "牛肉", amount: "200g", isAvailable: false),
            ],
            steps: [
                SavedCookingStep(stepNumber: 1, instruction: "野菜を一口大に切る", tip: "じゃがいもは水にさらすとホクホクに"),
                SavedCookingStep(stepNumber: 2, instruction: "肉を炒める", tip: nil),
                SavedCookingStep(stepNumber: 3, instruction: "野菜を加えて炒める", tip: nil),
                SavedCookingStep(stepNumber: 4, instruction: "だし汁と調味料を加えて煮る", tip: "落し蓋をすると味がしみやすい"),
            ],
            recommendationReason: "認識した食材で作れる定番料理です",
            isFavorite: true
        ),
        Recipe(
            name: "野菜炒め",
            description: "シンプルで栄養満点の野菜炒め",
            difficulty: .easy,
            cookingTimeMinutes: 15,
            servings: 2,
            ingredients: [
                SavedRecipeIngredient(name: "キャベツ", amount: "1/4個", isAvailable: true),
                SavedRecipeIngredient(name: "にんじん", amount: "1/2本", isAvailable: true),
            ],
            steps: [
                SavedCookingStep(stepNumber: 1, instruction: "野菜を切る", tip: nil),
                SavedCookingStep(stepNumber: 2, instruction: "フライパンで炒める", tip: "強火で手早く"),
            ],
            recommendationReason: "手軽に作れる時短レシピ",
            isFavorite: false
        ),
    ] }
}
