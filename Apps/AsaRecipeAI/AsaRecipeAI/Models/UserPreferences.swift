//
//  UserPreferences.swift
//  AsaRecipeAI
//
//  ユーザー設定のSwift Dataモデル
//  アプリの設定を永続化
//

import Foundation
import SwiftData

/// ユーザー設定
@Model
final class UserPreferences {
    // MARK: - Properties

    /// 一意識別子
    var id: UUID

    /// 最大調理時間（分）
    var maxCookingTime: Int

    /// 人数設定（デフォルト）
    var defaultServings: Int

    /// 好みの難易度フィルター（JSON）
    var preferredDifficultiesJSON: Data?

    /// アレルギー・避けたい食材（JSON）
    var excludedIngredientsJSON: Data?

    /// 食事制限（ベジタリアン、ヴィーガン等）
    var dietaryRestrictionRawValue: String?

    /// レシピ生成数
    var recipeCount: Int

    /// 自動保存（履歴）
    var autoSaveHistory: Bool

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    // MARK: - Computed Properties

    /// 好みの難易度リスト
    var preferredDifficulties: [RecipeDifficulty] {
        get {
            guard let data = preferredDifficultiesJSON else { return RecipeDifficulty.allCases }
            let rawValues = (try? JSONDecoder().decode([String].self, from: data)) ?? []
            return rawValues.compactMap { RecipeDifficulty.from($0) }
        }
        set {
            let rawValues = newValue.map { $0.rawValue }
            preferredDifficultiesJSON = try? JSONEncoder().encode(rawValues)
        }
    }

    /// 除外食材リスト
    var excludedIngredients: [String] {
        get {
            guard let data = excludedIngredientsJSON else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            excludedIngredientsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// 食事制限
    var dietaryRestriction: DietaryRestriction? {
        get {
            guard let raw = dietaryRestrictionRawValue else { return nil }
            return DietaryRestriction(rawValue: raw)
        }
        set {
            dietaryRestrictionRawValue = newValue?.rawValue
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        maxCookingTime: Int = 60,
        defaultServings: Int = 2,
        preferredDifficulties: [RecipeDifficulty] = RecipeDifficulty.allCases,
        excludedIngredients: [String] = [],
        dietaryRestriction: DietaryRestriction? = nil,
        recipeCount: Int = 3,
        autoSaveHistory: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.maxCookingTime = maxCookingTime
        self.defaultServings = defaultServings
        self.preferredDifficultiesJSON = try? JSONEncoder().encode(preferredDifficulties.map { $0.rawValue })
        self.excludedIngredientsJSON = try? JSONEncoder().encode(excludedIngredients)
        self.dietaryRestrictionRawValue = dietaryRestriction?.rawValue
        self.recipeCount = recipeCount
        self.autoSaveHistory = autoSaveHistory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Methods

    /// 設定を更新
    func update() {
        updatedAt = Date()
    }
}

// MARK: - 食事制限

/// 食事制限の種類
enum DietaryRestriction: String, CaseIterable, Codable, Sendable {
    case none = "制限なし"
    case vegetarian = "ベジタリアン"
    case vegan = "ヴィーガン"
    case glutenFree = "グルテンフリー"
    case dairyFree = "乳製品不使用"
    case lowCarb = "低糖質"

    /// 説明
    var description: String {
        switch self {
        case .none: return "特に制限なし"
        case .vegetarian: return "肉・魚を使用しない"
        case .vegan: return "動物性食品を使用しない"
        case .glutenFree: return "小麦粉を使用しない"
        case .dairyFree: return "牛乳・乳製品を使用しない"
        case .lowCarb: return "炭水化物を控えめに"
        }
    }

    /// アイコン
    var icon: String {
        switch self {
        case .none: return "🍽️"
        case .vegetarian: return "🥬"
        case .vegan: return "🌱"
        case .glutenFree: return "🌾"
        case .dairyFree: return "🥛"
        case .lowCarb: return "🥗"
        }
    }
}

// MARK: - Default Preferences

extension UserPreferences {
    /// デフォルト設定
    static let defaultPreferences = UserPreferences()
}
