//
//  RecipeRecommendation.swift
//  AsaRecipeAI
//
//  レシピ推薦の@Generableモデル
//  Foundation Modelsでストリーミング生成
//

import Foundation
import FoundationModels

// MARK: - レシピ推薦

/// AIが推薦するレシピ
@Generable
struct RecipeRecommendation: Equatable, Sendable, Identifiable {
    var id: String { name }

    /// レシピ名
    @Guide(description: "レシピの名前（日本語で簡潔に）")
    let name: String

    /// レシピの説明
    @Guide(description: "レシピの簡単な説明（日本語で100文字以内）")
    let description: String

    /// 難易度
    @Guide(description: "調理の難易度（簡単、普通、上級のいずれか）")
    let difficulty: String

    /// 調理時間（分）
    @Guide(description: "調理にかかる時間（分）", .range(5...180))
    let cookingTimeMinutes: Int

    /// 人数分
    @Guide(description: "何人分の分量か", .range(1...8))
    let servings: Int

    /// 必要な食材
    @Guide(description: "必要な食材のリスト", .count(1...15))
    let ingredients: [RecipeIngredient]

    /// 調理手順
    @Guide(description: "調理手順のリスト", .count(1...20))
    let steps: [CookingStep]

    /// 推薦理由
    @Guide(description: "このレシピを推薦する理由（日本語で50文字以内）")
    let recommendationReason: String
}

// MARK: - レシピ食材

/// レシピに必要な食材
@Generable
struct RecipeIngredient: Equatable, Sendable, Identifiable {
    var id: String { name }

    /// 食材名
    @Guide(description: "食材の名前")
    let name: String

    /// 分量
    @Guide(description: "必要な分量（例：100g、2個、大さじ1）")
    let amount: String

    /// 認識された食材かどうか
    @Guide(description: "ユーザーが持っている食材の場合はtrue")
    let isAvailable: Bool
}

// MARK: - 調理手順

/// 調理の1ステップ
@Generable
struct CookingStep: Equatable, Sendable, Identifiable {
    var id: Int { stepNumber }

    /// ステップ番号
    @Guide(description: "手順の番号（1から始まる）", .range(1...20))
    let stepNumber: Int

    /// 手順の説明
    @Guide(description: "調理手順の詳細な説明（日本語で）")
    let instruction: String

    /// ヒント（オプショナル）
    @Guide(description: "調理のコツやポイント（あれば）")
    let tip: String?
}

// MARK: - レシピ推薦リスト

/// 複数のレシピ推薦を含むレスポンス
@Generable
struct RecipeRecommendations: Equatable, Sendable {
    /// 推薦レシピのリスト
    @Guide(description: "推薦するレシピのリスト（1〜5個）", .count(1...5))
    let recipes: [RecipeRecommendation]
}

// MARK: - 難易度列挙型

/// 料理の難易度
enum RecipeDifficulty: String, CaseIterable, Codable, Sendable {
    case easy = "簡単"
    case normal = "普通"
    case advanced = "上級"

    /// 難易度のアイコン
    var icon: String {
        switch self {
        case .easy: return "⭐️"
        case .normal: return "⭐️⭐️"
        case .advanced: return "⭐️⭐️⭐️"
        }
    }

    /// 難易度の色
    var colorName: String {
        switch self {
        case .easy: return "green"
        case .normal: return "orange"
        case .advanced: return "red"
        }
    }

    /// 文字列から難易度を取得
    static func from(_ string: String) -> RecipeDifficulty {
        allCases.first { $0.rawValue == string } ?? .normal
    }
}
