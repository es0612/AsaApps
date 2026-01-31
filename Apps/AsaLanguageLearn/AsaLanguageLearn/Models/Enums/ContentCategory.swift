//
//  ContentCategory.swift
//  AsaLanguageLearn
//
//  学習コンテンツのカテゴリ分類
//

import SwiftUI

/// 学習コンテンツのカテゴリ
enum ContentCategory: String, CaseIterable, Codable, Sendable {
    case greetings = "greetings"
    case dailyConversation = "daily_conversation"
    case travel = "travel"
    case business = "business"
    case shopping = "shopping"
    case food = "food"
    case emergency = "emergency"
    case culture = "culture"

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .greetings: return "挨拶"
        case .dailyConversation: return "日常会話"
        case .travel: return "旅行"
        case .business: return "ビジネス"
        case .shopping: return "買い物"
        case .food: return "食事"
        case .emergency: return "緊急時"
        case .culture: return "文化"
        }
    }

    var icon: String {
        switch self {
        case .greetings: return "hand.wave.fill"
        case .dailyConversation: return "bubble.left.and.bubble.right.fill"
        case .travel: return "airplane"
        case .business: return "briefcase.fill"
        case .shopping: return "cart.fill"
        case .food: return "fork.knife"
        case .emergency: return "exclamationmark.triangle.fill"
        case .culture: return "theatermasks.fill"
        }
    }

    var color: Color {
        switch self {
        case .greetings: return Color("AsaCoffeeBrown")
        case .dailyConversation: return Color("AsaMocha")
        case .travel: return Color.blue
        case .business: return Color("AsaDarkSlate")
        case .shopping: return Color.orange
        case .food: return Color.green
        case .emergency: return Color.red
        case .culture: return Color.purple
        }
    }

    var description: String {
        switch self {
        case .greetings: return "基本的な挨拶表現を学びます"
        case .dailyConversation: return "日常で使う会話表現を学びます"
        case .travel: return "旅行で役立つフレーズを学びます"
        case .business: return "ビジネスシーンで使える表現を学びます"
        case .shopping: return "買い物で使うフレーズを学びます"
        case .food: return "レストランや食事の場面で使う表現を学びます"
        case .emergency: return "緊急時に必要な表現を学びます"
        case .culture: return "文化に関する表現を学びます"
        }
    }
}
