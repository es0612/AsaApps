//
//  IdeaCategory.swift
//  AsaCrowdsource
//
//  アイデアのカテゴリ分類
//

import Foundation

/// アイデアのカテゴリ
enum IdeaCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case familyTrip = "family_trip"
    case weekend = "weekend"
    case parenting = "parenting"
    case shopping = "shopping"
    case homeImprovement = "home_improvement"
    case meal = "meal"
    case event = "event"
    case health = "health"
    case other = "other"

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Display Properties

    /// カテゴリの表示名
    var displayName: String {
        switch self {
        case .familyTrip: return "家族旅行"
        case .weekend: return "週末の過ごし方"
        case .parenting: return "子育て"
        case .shopping: return "買い物"
        case .homeImprovement: return "住まい"
        case .meal: return "食事・レシピ"
        case .event: return "イベント"
        case .health: return "健康・運動"
        case .other: return "その他"
        }
    }

    /// カテゴリの絵文字
    var emoji: String {
        switch self {
        case .familyTrip: return "✈️"
        case .weekend: return "☀️"
        case .parenting: return "👨‍👩‍👧"
        case .shopping: return "🛒"
        case .homeImprovement: return "🏠"
        case .meal: return "🍽️"
        case .event: return "📅"
        case .health: return "❤️"
        case .other: return "💡"
        }
    }

    /// 絵文字付きの表示名
    var displayNameWithEmoji: String {
        "\(emoji) \(displayName)"
    }

    /// カテゴリの色（AsaUIKitのカラーに対応）
    var colorName: String {
        switch self {
        case .familyTrip: return "AsaCoffeeBrown"
        case .weekend: return "AsaSoftCream"
        case .parenting: return "AsaMocha"
        case .shopping: return "AsaMutedSage"
        case .homeImprovement: return "AsaDarkSlate"
        case .meal: return "AsaCoffeeBrown"
        case .event: return "AsaMocha"
        case .health: return "AsaMutedSage"
        case .other: return "AsaDarkSlate"
        }
    }
}
