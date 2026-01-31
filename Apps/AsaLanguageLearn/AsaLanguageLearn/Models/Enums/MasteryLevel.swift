//
//  MasteryLevel.swift
//  AsaLanguageLearn
//
//  学習アイテムの習熟レベル（SRSステージ）
//

import SwiftUI

/// 学習アイテムの習熟レベル
/// SM-2アルゴリズムに基づく段階的な習熟度管理
enum MasteryLevel: String, CaseIterable, Codable, Sendable {
    /// まだ学習していない新規アイテム
    case new = "new"
    /// 学習中（復習間隔が短い）
    case learning = "learning"
    /// 復習段階（間隔が伸びている）
    case review = "review"
    /// 習得済み（長期記憶に定着）
    case mastered = "mastered"

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .new: return "新規"
        case .learning: return "学習中"
        case .review: return "復習"
        case .mastered: return "習得済み"
        }
    }

    var icon: String {
        switch self {
        case .new: return "sparkles"
        case .learning: return "book.fill"
        case .review: return "arrow.clockwise"
        case .mastered: return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .new: return Color.blue
        case .learning: return Color("AsaCoffeeBrown")
        case .review: return Color.orange
        case .mastered: return Color.green
        }
    }

    var sortOrder: Int {
        switch self {
        case .new: return 0
        case .learning: return 1
        case .review: return 2
        case .mastered: return 3
        }
    }

    // MARK: - SRS Thresholds

    /// このレベルに到達するために必要な連続正解数
    var requiredStreak: Int {
        switch self {
        case .new: return 0
        case .learning: return 1
        case .review: return 3
        case .mastered: return 6
        }
    }

    /// 連続正解数から習熟レベルを判定
    static func from(streak: Int) -> MasteryLevel {
        switch streak {
        case 0: return .new
        case 1...2: return .learning
        case 3...5: return .review
        default: return .mastered
        }
    }
}
