//
//  Ingredient.swift
//  AsaRecipeAI
//
//  食材のSwift Dataモデル
//  認識した食材を永続化
//

import Foundation
import SwiftData

/// 保存された食材
@Model
final class Ingredient {
    // MARK: - Properties

    /// 一意識別子
    var id: UUID

    /// 食材名
    var name: String

    /// カテゴリ（Raw Value）
    var categoryRawValue: String

    /// 絵文字
    var emoji: String

    /// 認識信頼度
    var confidence: Double

    /// 作成日時
    var createdAt: Date

    /// お気に入り
    var isFavorite: Bool

    // MARK: - Computed Properties

    /// カテゴリ
    var category: IngredientCategory {
        get { IngredientCategory.from(categoryRawValue) }
        set { categoryRawValue = newValue.rawValue }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        category: IngredientCategory,
        emoji: String,
        confidence: Double = 1.0,
        createdAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = category.rawValue
        self.emoji = emoji
        self.confidence = confidence
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }

    /// IngredientInfoから変換
    convenience init(from info: IngredientInfo) {
        self.init(
            name: info.name,
            category: IngredientCategory.from(info.category),
            emoji: info.emoji,
            confidence: info.confidence
        )
    }
}

// MARK: - Sample Data

extension Ingredient {
    /// サンプルデータ
    static let sampleIngredients: [Ingredient] = [
        Ingredient(name: "にんじん", category: .vegetable, emoji: "🥕", confidence: 0.95),
        Ingredient(name: "玉ねぎ", category: .vegetable, emoji: "🧅", confidence: 0.92),
        Ingredient(name: "じゃがいも", category: .vegetable, emoji: "🥔", confidence: 0.88),
        Ingredient(name: "鶏もも肉", category: .meat, emoji: "🍗", confidence: 0.90),
        Ingredient(name: "卵", category: .egg, emoji: "🥚", confidence: 0.98),
        Ingredient(name: "牛乳", category: .dairy, emoji: "🥛", confidence: 0.85),
    ]
}
