//
//  IngredientInfo.swift
//  AsaRecipeAI
//
//  食材認識結果の@Generableモデル
//  Foundation Modelsで構造化データを生成
//

import Foundation
import FoundationModels

// MARK: - 食材情報

/// 認識された食材の情報
@Generable
struct IngredientInfo: Equatable, Sendable, Identifiable {
    var id: String { "\(name)-\(category)" }

    /// 食材名（日本語）
    @Guide(description: "食材の名前（日本語で出力）")
    let name: String

    /// カテゴリ
    @Guide(description: "食材のカテゴリ（野菜、肉類、魚介類、乳製品、穀物、調味料、卵、豆腐・大豆製品、果物、その他のいずれか）")
    let category: String

    /// 認識信頼度（0.0〜1.0）
    @Guide(description: "認識の信頼度（0.0〜1.0の範囲）", .range(0.0...1.0))
    let confidence: Double

    /// 絵文字アイコン
    @Guide(description: "食材を表す絵文字（1文字のみ）")
    let emoji: String
}

// MARK: - 食材認識結果

/// 画像からの食材認識結果
@Generable
struct IngredientRecognitionResult: Equatable, Sendable {
    /// 認識された食材リスト
    @Guide(description: "認識された食材のリスト（最大20個まで）", .count(1...20))
    let ingredients: [IngredientInfo]

    /// 分析サマリー
    @Guide(description: "認識結果の概要（日本語で50文字以内）")
    let summary: String
}

// MARK: - IngredientCategory

/// 食材カテゴリの列挙型
enum IngredientCategory: String, CaseIterable, Codable, Sendable {
    case vegetable = "野菜"
    case meat = "肉類"
    case seafood = "魚介類"
    case dairy = "乳製品"
    case grain = "穀物"
    case seasoning = "調味料"
    case egg = "卵"
    case tofu = "豆腐・大豆製品"
    case fruit = "果物"
    case other = "その他"

    /// カテゴリのアイコン
    var icon: String {
        switch self {
        case .vegetable: return "🥬"
        case .meat: return "🥩"
        case .seafood: return "🐟"
        case .dairy: return "🧀"
        case .grain: return "🌾"
        case .seasoning: return "🧂"
        case .egg: return "🥚"
        case .tofu: return "🫘"
        case .fruit: return "🍎"
        case .other: return "📦"
        }
    }

    /// カテゴリの色
    var colorName: String {
        switch self {
        case .vegetable: return "green"
        case .meat: return "red"
        case .seafood: return "blue"
        case .dairy: return "yellow"
        case .grain: return "orange"
        case .seasoning: return "purple"
        case .egg: return "orange"
        case .tofu: return "brown"
        case .fruit: return "pink"
        case .other: return "gray"
        }
    }

    /// 文字列からカテゴリを取得
    static func from(_ string: String) -> IngredientCategory {
        allCases.first { $0.rawValue == string } ?? .other
    }
}
