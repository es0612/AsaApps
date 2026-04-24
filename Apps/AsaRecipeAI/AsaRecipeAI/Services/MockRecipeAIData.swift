//
//  MockRecipeAIData.swift
//  AsaRecipeAI
//
//  Foundation Models 非対応環境向けのモックデータ供給
//  シミュレータ・Apple Intelligence 非対応端末・初期化失敗時に使用
//

import Foundation

/// Foundation Models 非対応環境向けのモックデータ供給
enum MockRecipeAIData {
    // MARK: - Ingredient Recognition

    /// デモ用の食材認識結果
    /// 認識される定番食材5種類（野菜中心＋肉・卵）
    static func ingredientRecognition() -> IngredientRecognitionResult {
        let ingredients: [IngredientInfo] = [
            IngredientInfo(name: "にんじん", category: "野菜", confidence: 0.95, emoji: "🥕"),
            IngredientInfo(name: "玉ねぎ", category: "野菜", confidence: 0.92, emoji: "🧅"),
            IngredientInfo(name: "じゃがいも", category: "野菜", confidence: 0.88, emoji: "🥔"),
            IngredientInfo(name: "牛肉", category: "肉類", confidence: 0.85, emoji: "🥩"),
            IngredientInfo(name: "卵", category: "卵", confidence: 0.90, emoji: "🥚"),
        ]
        return IngredientRecognitionResult(
            ingredients: ingredients,
            summary: "デモモード：野菜と肉類を認識しました"
        )
    }

    // MARK: - Recipe Recommendations

    /// デモ用のレシピ推薦結果
    /// 認識した食材で作れる定番家庭料理3つ
    static func recommendations() -> RecipeRecommendations {
        RecipeRecommendations(recipes: [
            nikujagaRecipe,
            oyakodonRecipe,
            yasaiItameRecipe,
        ])
    }

    // MARK: - Sample Recipes

    /// 肉じゃが
    private static var nikujagaRecipe: RecipeRecommendation {
        RecipeRecommendation(
            name: "肉じゃが",
            description: "家庭の定番料理。ホクホクのじゃがいもと甘辛い味付けが美味しい一品",
            difficulty: "普通",
            cookingTimeMinutes: 40,
            servings: 4,
            ingredients: [
                RecipeIngredient(name: "じゃがいも", amount: "4個", isAvailable: true),
                RecipeIngredient(name: "にんじん", amount: "1本", isAvailable: true),
                RecipeIngredient(name: "玉ねぎ", amount: "1個", isAvailable: true),
                RecipeIngredient(name: "牛肉（薄切り）", amount: "200g", isAvailable: true),
                RecipeIngredient(name: "醤油", amount: "大さじ3", isAvailable: false),
                RecipeIngredient(name: "みりん", amount: "大さじ2", isAvailable: false),
            ],
            steps: [
                CookingStep(stepNumber: 1, instruction: "じゃがいもは皮をむいて一口大に切り、水にさらす", tip: "水にさらすとホクホクに仕上がります"),
                CookingStep(stepNumber: 2, instruction: "にんじんは乱切り、玉ねぎはくし切りにする", tip: nil),
                CookingStep(stepNumber: 3, instruction: "鍋にサラダ油を熱し、牛肉を炒めて色が変わったら野菜を加える", tip: nil),
                CookingStep(stepNumber: 4, instruction: "だし汁400mlを加え、沸騰したらアクを取る", tip: nil),
                CookingStep(stepNumber: 5, instruction: "醤油、みりん、砂糖を加えて落し蓋をし、中火で20分煮る", tip: "落し蓋で味がしっかり染みます"),
            ],
            recommendationReason: "認識した野菜と牛肉で作れる定番の家庭料理です"
        )
    }

    /// 親子丼
    private static var oyakodonRecipe: RecipeRecommendation {
        RecipeRecommendation(
            name: "親子丼",
            description: "ふわとろ卵と鶏肉の絶妙なハーモニー。15分で完成する時短レシピ",
            difficulty: "簡単",
            cookingTimeMinutes: 15,
            servings: 2,
            ingredients: [
                RecipeIngredient(name: "鶏もも肉", amount: "200g", isAvailable: false),
                RecipeIngredient(name: "卵", amount: "3個", isAvailable: true),
                RecipeIngredient(name: "玉ねぎ", amount: "1/2個", isAvailable: true),
                RecipeIngredient(name: "ごはん", amount: "2杯分", isAvailable: false),
            ],
            steps: [
                CookingStep(stepNumber: 1, instruction: "玉ねぎを薄くスライスし、鶏肉を一口大に切る", tip: nil),
                CookingStep(stepNumber: 2, instruction: "だし汁200mlに醤油・みりん・砂糖を加えて煮立てる", tip: nil),
                CookingStep(stepNumber: 3, instruction: "鶏肉と玉ねぎを入れて中火で5分煮る", tip: "鶏肉はしっかり火を通します"),
                CookingStep(stepNumber: 4, instruction: "溶き卵を回し入れ、半熟になったら火を止める", tip: "余熱でふわとろに仕上がります"),
                CookingStep(stepNumber: 5, instruction: "ごはんに乗せて完成", tip: nil),
            ],
            recommendationReason: "卵と玉ねぎを使った時短の人気丼ぶり"
        )
    }

    /// 野菜炒め
    private static var yasaiItameRecipe: RecipeRecommendation {
        RecipeRecommendation(
            name: "野菜炒め",
            description: "シャキシャキ食感の中華風炒めもの。冷蔵庫の余り野菜で簡単調理",
            difficulty: "簡単",
            cookingTimeMinutes: 10,
            servings: 2,
            ingredients: [
                RecipeIngredient(name: "にんじん", amount: "1/2本", isAvailable: true),
                RecipeIngredient(name: "玉ねぎ", amount: "1/2個", isAvailable: true),
                RecipeIngredient(name: "キャベツ", amount: "1/4個", isAvailable: false),
                RecipeIngredient(name: "豚肉", amount: "150g", isAvailable: false),
            ],
            steps: [
                CookingStep(stepNumber: 1, instruction: "野菜を食べやすい大きさに切る", tip: "厚さを揃えると均等に火が通ります"),
                CookingStep(stepNumber: 2, instruction: "フライパンに油を熱し、豚肉を炒める", tip: nil),
                CookingStep(stepNumber: 3, instruction: "硬い野菜から順に加えて強火で一気に炒める", tip: "シャキシャキ感が大事"),
                CookingStep(stepNumber: 4, instruction: "醤油・塩こしょう・ごま油で味付けして完成", tip: nil),
            ],
            recommendationReason: "認識した野菜ですぐ作れる時短おかず"
        )
    }
}
