//
//  AsaRecipeAITests.swift
//  AsaRecipeAITests
//
//  AsaRecipeAI のユニットテスト
//  Swift Testing フレームワーク使用
//

import Testing
import Foundation
@testable import AsaRecipeAI

// MARK: - IngredientInfo Tests

@Suite("IngredientInfo テスト")
struct IngredientInfoTests {
    @Test("食材情報の初期化")
    func testIngredientInfoInitialization() {
        let ingredient = IngredientInfo(
            name: "にんじん",
            category: "野菜",
            confidence: 0.95,
            emoji: "🥕"
        )

        #expect(ingredient.name == "にんじん")
        #expect(ingredient.category == "野菜")
        #expect(ingredient.confidence == 0.95)
        #expect(ingredient.emoji == "🥕")
    }

    @Test("食材IDの一意性")
    func testIngredientInfoId() {
        let ingredient1 = IngredientInfo(name: "にんじん", category: "野菜", confidence: 0.9, emoji: "🥕")
        let ingredient2 = IngredientInfo(name: "玉ねぎ", category: "野菜", confidence: 0.9, emoji: "🧅")

        #expect(ingredient1.id != ingredient2.id)
    }

    @Test("同じ名前・カテゴリのIDが一致")
    func testSameIngredientId() {
        let ingredient1 = IngredientInfo(name: "にんじん", category: "野菜", confidence: 0.9, emoji: "🥕")
        let ingredient2 = IngredientInfo(name: "にんじん", category: "野菜", confidence: 0.8, emoji: "🥕")

        #expect(ingredient1.id == ingredient2.id)
    }
}

// MARK: - IngredientCategory Tests

@Suite("IngredientCategory テスト")
struct IngredientCategoryTests {
    @Test("カテゴリの文字列変換")
    func testCategoryFromString() {
        #expect(IngredientCategory.from("野菜") == .vegetable)
        #expect(IngredientCategory.from("肉類") == .meat)
        #expect(IngredientCategory.from("魚介類") == .seafood)
        #expect(IngredientCategory.from("乳製品") == .dairy)
        #expect(IngredientCategory.from("穀物") == .grain)
        #expect(IngredientCategory.from("調味料") == .seasoning)
        #expect(IngredientCategory.from("卵") == .egg)
        #expect(IngredientCategory.from("豆腐・大豆製品") == .tofu)
        #expect(IngredientCategory.from("果物") == .fruit)
    }

    @Test("不明なカテゴリはotherになる")
    func testUnknownCategoryBecomesOther() {
        #expect(IngredientCategory.from("不明なカテゴリ") == .other)
        #expect(IngredientCategory.from("") == .other)
    }

    @Test("カテゴリのアイコン")
    func testCategoryIcons() {
        #expect(IngredientCategory.vegetable.icon == "🥬")
        #expect(IngredientCategory.meat.icon == "🥩")
        #expect(IngredientCategory.seafood.icon == "🐟")
        #expect(IngredientCategory.dairy.icon == "🧀")
        #expect(IngredientCategory.egg.icon == "🥚")
    }

    @Test("カテゴリのrawValue")
    func testCategoryRawValues() {
        #expect(IngredientCategory.vegetable.rawValue == "野菜")
        #expect(IngredientCategory.meat.rawValue == "肉類")
    }
}

// MARK: - RecipeRecommendation Tests

@Suite("RecipeRecommendation テスト")
struct RecipeRecommendationTests {
    @Test("レシピ推薦の初期化")
    func testRecipeRecommendationInitialization() {
        let recipe = RecipeRecommendation(
            name: "肉じゃが",
            description: "家庭の定番料理",
            difficulty: "普通",
            cookingTimeMinutes: 40,
            servings: 4,
            ingredients: [],
            steps: [],
            recommendationReason: "定番料理です"
        )

        #expect(recipe.name == "肉じゃが")
        #expect(recipe.difficulty == "普通")
        #expect(recipe.cookingTimeMinutes == 40)
        #expect(recipe.servings == 4)
    }

    @Test("レシピIDは名前に基づく")
    func testRecipeId() {
        let recipe = RecipeRecommendation(
            name: "カレーライス",
            description: "test",
            difficulty: "簡単",
            cookingTimeMinutes: 30,
            servings: 2,
            ingredients: [],
            steps: [],
            recommendationReason: "test"
        )

        #expect(recipe.id == "カレーライス")
    }
}

// MARK: - RecipeIngredient Tests

@Suite("RecipeIngredient テスト")
struct RecipeIngredientTests {
    @Test("レシピ食材の初期化")
    func testRecipeIngredientInitialization() {
        let ingredient = RecipeIngredient(
            name: "じゃがいも",
            amount: "4個",
            isAvailable: true
        )

        #expect(ingredient.name == "じゃがいも")
        #expect(ingredient.amount == "4個")
        #expect(ingredient.isAvailable == true)
    }

    @Test("利用不可の食材")
    func testUnavailableIngredient() {
        let ingredient = RecipeIngredient(
            name: "牛肉",
            amount: "200g",
            isAvailable: false
        )

        #expect(ingredient.isAvailable == false)
    }
}

// MARK: - CookingStep Tests

@Suite("CookingStep テスト")
struct CookingStepTests {
    @Test("調理手順の初期化")
    func testCookingStepInitialization() {
        let step = CookingStep(
            stepNumber: 1,
            instruction: "野菜を切る",
            tip: "大きさを揃えると火の通りが均一になる"
        )

        #expect(step.stepNumber == 1)
        #expect(step.instruction == "野菜を切る")
        #expect(step.tip != nil)
    }

    @Test("tipがnilの調理手順")
    func testCookingStepWithoutTip() {
        let step = CookingStep(
            stepNumber: 2,
            instruction: "フライパンで炒める",
            tip: nil
        )

        #expect(step.tip == nil)
    }

    @Test("手順IDはstepNumberに基づく")
    func testStepId() {
        let step = CookingStep(stepNumber: 3, instruction: "test", tip: nil)
        #expect(step.id == 3)
    }
}

// MARK: - RecipeDifficulty Tests

@Suite("RecipeDifficulty テスト")
struct RecipeDifficultyTests {
    @Test("難易度の文字列変換")
    func testDifficultyFromString() {
        #expect(RecipeDifficulty.from("簡単") == .easy)
        #expect(RecipeDifficulty.from("普通") == .normal)
        #expect(RecipeDifficulty.from("上級") == .advanced)
    }

    @Test("不明な難易度はnormalになる")
    func testUnknownDifficultyBecomesNormal() {
        #expect(RecipeDifficulty.from("不明") == .normal)
        #expect(RecipeDifficulty.from("") == .normal)
    }

    @Test("難易度のアイコン")
    func testDifficultyIcons() {
        #expect(RecipeDifficulty.easy.icon == "⭐️")
        #expect(RecipeDifficulty.normal.icon == "⭐️⭐️")
        #expect(RecipeDifficulty.advanced.icon == "⭐️⭐️⭐️")
    }

    @Test("難易度のrawValue")
    func testDifficultyRawValues() {
        #expect(RecipeDifficulty.easy.rawValue == "簡単")
        #expect(RecipeDifficulty.normal.rawValue == "普通")
        #expect(RecipeDifficulty.advanced.rawValue == "上級")
    }
}

// MARK: - DietaryRestriction Tests

@Suite("DietaryRestriction テスト")
struct DietaryRestrictionTests {
    @Test("食事制限の説明")
    func testDietaryRestrictionDescriptions() {
        #expect(DietaryRestriction.vegetarian.description == "肉・魚を使用しない")
        #expect(DietaryRestriction.vegan.description == "動物性食品を使用しない")
        #expect(DietaryRestriction.glutenFree.description == "小麦粉を使用しない")
    }

    @Test("食事制限のアイコン")
    func testDietaryRestrictionIcons() {
        #expect(DietaryRestriction.vegetarian.icon == "🥬")
        #expect(DietaryRestriction.vegan.icon == "🌱")
        #expect(DietaryRestriction.none.icon == "🍽️")
    }

    @Test("すべての制限が定義されている")
    func testAllRestrictionsAreDefined() {
        let allCases = DietaryRestriction.allCases
        #expect(allCases.count == 6)
        #expect(allCases.contains(.none))
        #expect(allCases.contains(.vegetarian))
        #expect(allCases.contains(.vegan))
    }
}

// MARK: - Ingredient Model Tests

@Suite("Ingredient Model テスト")
struct IngredientModelTests {
    @Test("Ingredientの初期化")
    func testIngredientInitialization() {
        let ingredient = Ingredient(
            name: "トマト",
            category: .vegetable,
            emoji: "🍅",
            confidence: 0.95
        )

        #expect(ingredient.name == "トマト")
        #expect(ingredient.category == .vegetable)
        #expect(ingredient.emoji == "🍅")
        #expect(ingredient.confidence == 0.95)
        #expect(ingredient.isFavorite == false)
    }

    @Test("IngredientInfoからの変換")
    func testIngredientFromInfo() {
        let info = IngredientInfo(
            name: "キャベツ",
            category: "野菜",
            confidence: 0.88,
            emoji: "🥬"
        )

        let ingredient = Ingredient(from: info)

        #expect(ingredient.name == "キャベツ")
        #expect(ingredient.category == .vegetable)
        #expect(ingredient.emoji == "🥬")
        #expect(ingredient.confidence == 0.88)
    }
}

// MARK: - Recipe Model Tests

@Suite("Recipe Model テスト")
struct RecipeModelTests {
    @Test("Recipeの初期化")
    func testRecipeInitialization() {
        let recipe = Recipe(
            name: "オムライス",
            description: "ふわふわ卵のオムライス",
            difficulty: .normal,
            cookingTimeMinutes: 25,
            servings: 2,
            recommendationReason: "卵料理の定番"
        )

        #expect(recipe.name == "オムライス")
        #expect(recipe.difficulty == .normal)
        #expect(recipe.cookingTimeMinutes == 25)
        #expect(recipe.servings == 2)
        #expect(recipe.isFavorite == false)
        #expect(recipe.cookCount == 0)
    }

    @Test("調理完了のマーク")
    func testMarkAsCooked() {
        let recipe = Recipe(
            name: "テスト",
            description: "テスト",
            difficulty: .easy,
            cookingTimeMinutes: 10,
            servings: 1,
            recommendationReason: "テスト"
        )

        #expect(recipe.cookCount == 0)
        #expect(recipe.lastCookedAt == nil)

        recipe.markAsCooked()

        #expect(recipe.cookCount == 1)
        #expect(recipe.lastCookedAt != nil)
    }

    @Test("複数回の調理記録")
    func testMultipleCookings() {
        let recipe = Recipe(
            name: "テスト",
            description: "テスト",
            difficulty: .easy,
            cookingTimeMinutes: 10,
            servings: 1,
            recommendationReason: "テスト"
        )

        recipe.markAsCooked()
        recipe.markAsCooked()
        recipe.markAsCooked()

        #expect(recipe.cookCount == 3)
    }
}

// MARK: - UserPreferences Tests

@Suite("UserPreferences テスト")
struct UserPreferencesTests {
    @Test("デフォルト設定の確認")
    func testDefaultPreferences() {
        let preferences = UserPreferences()

        #expect(preferences.maxCookingTime == 60)
        #expect(preferences.defaultServings == 2)
        #expect(preferences.recipeCount == 3)
        #expect(preferences.autoSaveHistory == true)
        #expect(preferences.dietaryRestriction == nil)
    }

    @Test("カスタム設定の初期化")
    func testCustomPreferences() {
        let preferences = UserPreferences(
            maxCookingTime: 90,
            defaultServings: 4,
            recipeCount: 5,
            autoSaveHistory: false,
            dietaryRestriction: .vegetarian
        )

        #expect(preferences.maxCookingTime == 90)
        #expect(preferences.defaultServings == 4)
        #expect(preferences.recipeCount == 5)
        #expect(preferences.autoSaveHistory == false)
        #expect(preferences.dietaryRestriction == .vegetarian)
    }

    @Test("設定更新でupdatedAtが変更される")
    func testPreferencesUpdate() {
        let preferences = UserPreferences()
        let originalUpdatedAt = preferences.updatedAt

        // 少し待つ
        Thread.sleep(forTimeInterval: 0.1)
        preferences.update()

        #expect(preferences.updatedAt > originalUpdatedAt)
    }
}

// MARK: - RecognitionHistory Tests

@Suite("RecognitionHistory テスト")
struct RecognitionHistoryTests {
    @Test("履歴の初期化")
    func testHistoryInitialization() {
        let history = RecognitionHistory(
            ingredients: [
                SavedIngredient(name: "にんじん", category: "野菜", confidence: 0.9, emoji: "🥕")
            ],
            summary: "野菜1種類を認識"
        )

        #expect(history.summary == "野菜1種類を認識")
        #expect(history.ingredientCount == 1)
        #expect(history.generatedRecipeCount == 0)
    }

    @Test("食材数の計算")
    func testIngredientCount() {
        let history = RecognitionHistory(
            ingredients: [
                SavedIngredient(name: "にんじん", category: "野菜", confidence: 0.9, emoji: "🥕"),
                SavedIngredient(name: "玉ねぎ", category: "野菜", confidence: 0.8, emoji: "🧅"),
                SavedIngredient(name: "じゃがいも", category: "野菜", confidence: 0.85, emoji: "🥔"),
            ],
            summary: "野菜3種類を認識"
        )

        #expect(history.ingredientCount == 3)
    }

    @Test("IngredientRecognitionResultからの変換")
    func testHistoryFromResult() {
        let result = IngredientRecognitionResult(
            ingredients: [
                IngredientInfo(name: "鶏肉", category: "肉類", confidence: 0.9, emoji: "🍗")
            ],
            summary: "肉類1種類を認識"
        )

        let history = RecognitionHistory(from: result, thumbnailData: nil)

        #expect(history.summary == "肉類1種類を認識")
        #expect(history.ingredientCount == 1)
    }
}

// MARK: - AppStatistics Tests

@Suite("AppStatistics テスト")
struct AppStatisticsTests {
    @Test("統計情報の初期化")
    func testStatisticsInitialization() {
        let stats = AppStatistics(
            totalRecipes: 10,
            favoriteRecipes: 3,
            totalRecognitions: 20,
            totalIngredientsRecognized: 50,
            totalCookCount: 15
        )

        #expect(stats.totalRecipes == 10)
        #expect(stats.favoriteRecipes == 3)
        #expect(stats.totalRecognitions == 20)
        #expect(stats.totalIngredientsRecognized == 50)
        #expect(stats.totalCookCount == 15)
    }
}

// MARK: - RecipeAIError Tests

@Suite("RecipeAIError テスト")
struct RecipeAIErrorTests {
    @Test("エラーメッセージの確認")
    func testErrorDescriptions() {
        #expect(RecipeAIError.sessionNotReady.errorDescription == "AIセッションが準備できていません")
        #expect(RecipeAIError.deviceNotSupported.errorDescription == "このデバイスではAI機能を利用できません")
        #expect(RecipeAIError.invalidResponse.errorDescription == "無効な応答を受信しました")
    }

    @Test("generationFailedエラーにメッセージが含まれる")
    func testGenerationFailedError() {
        let error = RecipeAIError.generationFailed("テストエラー")
        #expect(error.errorDescription?.contains("テストエラー") == true)
    }
}

// MARK: - VisionError Tests

@Suite("VisionError テスト")
struct VisionErrorTests {
    @Test("エラーメッセージの確認")
    func testVisionErrorDescriptions() {
        #expect(VisionError.imageConversionFailed.errorDescription == "画像の変換に失敗しました")
        #expect(VisionError.noResults.errorDescription == "分類結果がありませんでした")
    }
}
