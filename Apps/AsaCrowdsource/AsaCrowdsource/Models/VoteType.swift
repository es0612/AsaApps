//
//  VoteType.swift
//  AsaCrowdsource
//
//  投票タイプの定義
//

import Foundation

/// 投票の種類
enum VoteType: String, CaseIterable, Codable, Identifiable, Sendable {
    case like = "like"
    case love = "love"
    case interested = "interested"

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Display Properties

    /// 投票タイプの表示名
    var displayName: String {
        switch self {
        case .like: return "いいね"
        case .love: return "大好き"
        case .interested: return "興味あり"
        }
    }

    /// 投票タイプの絵文字
    var emoji: String {
        switch self {
        case .like: return "👍"
        case .love: return "❤️"
        case .interested: return "🤔"
        }
    }

    /// 絵文字付きの表示名
    var displayNameWithEmoji: String {
        "\(emoji) \(displayName)"
    }

    /// 投票の重み（優先度計算用）
    var weight: Int {
        switch self {
        case .like: return 1
        case .love: return 3
        case .interested: return 2
        }
    }
}
