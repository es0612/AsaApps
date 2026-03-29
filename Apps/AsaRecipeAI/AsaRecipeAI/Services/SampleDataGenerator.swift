//
//  SampleDataGenerator.swift
//  AsaRecipeAI
//
//  デモ動画撮影用のサンプルデータ投入
//

import Foundation

@MainActor
final class SampleDataGenerator {

    // MARK: - Properties

    private let dataService: DataService

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
    }

    // MARK: - Public

    func insertSampleData() {
        let recipes = createSampleRecipes()
        for recipe in recipes {
            dataService.saveRecipe(recipe)
        }

        let histories = createSampleHistories()
        for history in histories {
            dataService.saveHistory(history)
        }
    }

    // MARK: - Recipes

    private func createSampleRecipes() -> [Recipe] {
        let calendar = Calendar.current

        let nikujaga = Recipe(
            name: "肉じゃが",
            description: "家庭の定番料理。ホクホクのじゃがいもと甘辛い味付けが美味しい一品",
            difficulty: .normal,
            cookingTimeMinutes: 40,
            servings: 4,
            ingredients: [
                SavedRecipeIngredient(name: "じゃがいも", amount: "4個", isAvailable: true),
                SavedRecipeIngredient(name: "にんじん", amount: "1本", isAvailable: true),
                SavedRecipeIngredient(name: "玉ねぎ", amount: "1個", isAvailable: true),
                SavedRecipeIngredient(name: "牛肉（薄切り）", amount: "200g", isAvailable: true),
                SavedRecipeIngredient(name: "しらたき", amount: "1袋", isAvailable: false),
                SavedRecipeIngredient(name: "醤油", amount: "大さじ3", isAvailable: true),
                SavedRecipeIngredient(name: "みりん", amount: "大さじ2", isAvailable: true),
            ],
            steps: [
                SavedCookingStep(stepNumber: 1, instruction: "じゃがいもは皮をむいて一口大に切り、水にさらす", tip: "水にさらすとホクホクに仕上がります"),
                SavedCookingStep(stepNumber: 2, instruction: "にんじんは乱切り、玉ねぎはくし切りにする", tip: nil),
                SavedCookingStep(stepNumber: 3, instruction: "鍋にサラダ油を熱し、牛肉を炒めて色が変わったら野菜を加える", tip: nil),
                SavedCookingStep(stepNumber: 4, instruction: "だし汁400mlを加え、沸騰したらアクを取る", tip: nil),
                SavedCookingStep(stepNumber: 5, instruction: "醤油、みりん、砂糖を加えて落し蓋をし、中火で20分煮る", tip: "落し蓋で味がしっかり染みます"),
            ],
            recommendationReason: "認識した野菜で作れる定番の家庭料理です",
            isFavorite: true,
            cookCount: 3,
            createdAt: calendar.date(byAdding: .day, value: -14, to: Date())!,
            lastCookedAt: calendar.date(byAdding: .day, value: -2, to: Date())
        )

        let oyakodon = Recipe(
            name: "親子丼",
            description: "ふわとろ卵と鶏肉の絶妙なハーモニー。15分で完成する時短レシピ",
            difficulty: .easy,
            cookingTimeMinutes: 15,
            servings: 2,
            ingredients: [
                SavedRecipeIngredient(name: "鶏もも肉", amount: "200g", isAvailable: true),
                SavedRecipeIngredient(name: "卵", amount: "3個", isAvailable: true),
                SavedRecipeIngredient(name: "玉ねぎ", amount: "1/2個", isAvailable: true),
                SavedRecipeIngredient(name: "ご飯", amount: "2杯分", isAvailable: true),
                SavedRecipeIngredient(name: "三つ葉", amount: "適量", isAvailable: false),
            ],
            steps: [
                SavedCookingStep(stepNumber: 1, instruction: "鶏もも肉を一口大に切り、玉ねぎを薄切りにする", tip: nil),
                SavedCookingStep(stepNumber: 2, instruction: "小鍋にだし汁、醤油、みりんを入れ煮立てる", tip: nil),
                SavedCookingStep(stepNumber: 3, instruction: "玉ねぎと鶏肉を加えて中火で3分煮る", tip: nil),
                SavedCookingStep(stepNumber: 4, instruction: "溶き卵を回し入れ、半熟になったら火を止める", tip: "卵は2回に分けて入れるとふわとろに"),
            ],
            recommendationReason: "鶏肉と卵で手早く作れるスピードメニュー",
            isFavorite: true,
            cookCount: 5,
            createdAt: calendar.date(byAdding: .day, value: -10, to: Date())!,
            lastCookedAt: calendar.date(byAdding: .day, value: -1, to: Date())
        )

        let yasaiItame = Recipe(
            name: "彩り野菜のガーリック炒め",
            description: "色鮮やかな野菜をにんにくの香りで仕上げたヘルシーな一品",
            difficulty: .easy,
            cookingTimeMinutes: 10,
            servings: 2,
            ingredients: [
                SavedRecipeIngredient(name: "パプリカ（赤・黄）", amount: "各1/2個", isAvailable: true),
                SavedRecipeIngredient(name: "ブロッコリー", amount: "1/2株", isAvailable: true),
                SavedRecipeIngredient(name: "にんにく", amount: "2片", isAvailable: true),
                SavedRecipeIngredient(name: "オリーブオイル", amount: "大さじ2", isAvailable: true),
            ],
            steps: [
                SavedCookingStep(stepNumber: 1, instruction: "野菜を食べやすい大きさに切る。ブロッコリーは小房に分ける", tip: nil),
                SavedCookingStep(stepNumber: 2, instruction: "にんにくをみじん切りにし、オリーブオイルで香りを出す", tip: "弱火でじっくり香りを引き出して"),
                SavedCookingStep(stepNumber: 3, instruction: "野菜を加えて強火で手早く炒め、塩コショウで味を調える", tip: "強火で手早く炒めるとシャキシャキに"),
            ],
            recommendationReason: "手持ちの野菜で10分で完成するヘルシーレシピ",
            isFavorite: true,
            cookCount: 1,
            createdAt: calendar.date(byAdding: .day, value: -5, to: Date())!,
            lastCookedAt: calendar.date(byAdding: .day, value: -3, to: Date())
        )

        return [nikujaga, oyakodon, yasaiItame]
    }

    // MARK: - Recognition Histories

    private func createSampleHistories() -> [RecognitionHistory] {
        let calendar = Calendar.current

        let history1 = RecognitionHistory(
            ingredients: [
                SavedIngredient(name: "にんじん", category: "野菜", confidence: 0.95, emoji: "🥕"),
                SavedIngredient(name: "玉ねぎ", category: "野菜", confidence: 0.92, emoji: "🧅"),
                SavedIngredient(name: "じゃがいも", category: "野菜", confidence: 0.88, emoji: "🥔"),
                SavedIngredient(name: "牛肉", category: "肉類", confidence: 0.85, emoji: "🥩"),
            ],
            summary: "野菜3種と肉類1種を認識しました",
            recognizedAt: calendar.date(byAdding: .day, value: -14, to: Date())!,
            generatedRecipeCount: 3
        )

        let history2 = RecognitionHistory(
            ingredients: [
                SavedIngredient(name: "鶏もも肉", category: "肉類", confidence: 0.93, emoji: "🍗"),
                SavedIngredient(name: "卵", category: "卵", confidence: 0.98, emoji: "🥚"),
                SavedIngredient(name: "玉ねぎ", category: "野菜", confidence: 0.90, emoji: "🧅"),
            ],
            summary: "肉類と卵、野菜を認識しました",
            recognizedAt: calendar.date(byAdding: .day, value: -10, to: Date())!,
            generatedRecipeCount: 2
        )

        let history3 = RecognitionHistory(
            ingredients: [
                SavedIngredient(name: "パプリカ", category: "野菜", confidence: 0.96, emoji: "🫑"),
                SavedIngredient(name: "ブロッコリー", category: "野菜", confidence: 0.91, emoji: "🥦"),
                SavedIngredient(name: "にんにく", category: "野菜", confidence: 0.87, emoji: "🧄"),
            ],
            summary: "野菜3種を認識しました",
            recognizedAt: calendar.date(byAdding: .day, value: -5, to: Date())!,
            generatedRecipeCount: 2
        )

        return [history1, history2, history3]
    }
}
