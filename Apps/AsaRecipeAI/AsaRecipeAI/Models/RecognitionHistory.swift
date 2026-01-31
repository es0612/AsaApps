//
//  RecognitionHistory.swift
//  AsaRecipeAI
//
//  認識履歴のSwift Dataモデル
//  過去の食材認識を記録
//

import Foundation
import SwiftData

/// 食材認識の履歴
@Model
final class RecognitionHistory {
    // MARK: - Properties

    /// 一意識別子
    var id: UUID

    /// 画像データ（サムネイル）
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    /// 認識された食材リスト（JSON）
    var ingredientsJSON: Data?

    /// 分析サマリー
    var summary: String

    /// 認識日時
    var recognizedAt: Date

    /// 生成されたレシピ数
    var generatedRecipeCount: Int

    // MARK: - Computed Properties

    /// 食材リスト
    var ingredients: [SavedIngredient] {
        get {
            guard let data = ingredientsJSON else { return [] }
            return (try? JSONDecoder().decode([SavedIngredient].self, from: data)) ?? []
        }
        set {
            ingredientsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// 食材数
    var ingredientCount: Int {
        ingredients.count
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        thumbnailData: Data? = nil,
        ingredients: [SavedIngredient] = [],
        summary: String,
        recognizedAt: Date = Date(),
        generatedRecipeCount: Int = 0
    ) {
        self.id = id
        self.thumbnailData = thumbnailData
        self.ingredientsJSON = try? JSONEncoder().encode(ingredients)
        self.summary = summary
        self.recognizedAt = recognizedAt
        self.generatedRecipeCount = generatedRecipeCount
    }

    /// IngredientRecognitionResultから変換
    convenience init(from result: IngredientRecognitionResult, thumbnailData: Data? = nil) {
        let savedIngredients = result.ingredients.map {
            SavedIngredient(
                name: $0.name,
                category: $0.category,
                confidence: $0.confidence,
                emoji: $0.emoji
            )
        }

        self.init(
            thumbnailData: thumbnailData,
            ingredients: savedIngredients,
            summary: result.summary
        )
    }
}

// MARK: - Supporting Types

/// 保存用食材情報
struct SavedIngredient: Codable, Identifiable, Sendable {
    var id: String { "\(name)-\(category)" }
    let name: String
    let category: String
    let confidence: Double
    let emoji: String
}

// MARK: - Sample Data

extension RecognitionHistory {
    /// サンプルデータ
    static let sampleHistories: [RecognitionHistory] = [
        RecognitionHistory(
            ingredients: [
                SavedIngredient(name: "にんじん", category: "野菜", confidence: 0.95, emoji: "🥕"),
                SavedIngredient(name: "玉ねぎ", category: "野菜", confidence: 0.92, emoji: "🧅"),
                SavedIngredient(name: "じゃがいも", category: "野菜", confidence: 0.88, emoji: "🥔"),
            ],
            summary: "野菜3種類を認識しました",
            recognizedAt: Date().addingTimeInterval(-3600),
            generatedRecipeCount: 3
        ),
        RecognitionHistory(
            ingredients: [
                SavedIngredient(name: "鶏もも肉", category: "肉類", confidence: 0.90, emoji: "🍗"),
                SavedIngredient(name: "卵", category: "卵", confidence: 0.98, emoji: "🥚"),
            ],
            summary: "肉と卵を認識しました",
            recognizedAt: Date().addingTimeInterval(-86400),
            generatedRecipeCount: 2
        ),
    ]
}
