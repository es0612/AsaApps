//
//  IdeaStatus.swift
//  AsaCrowdsource
//
//  アイデアのステータス管理
//

import Foundation

/// アイデアのステータス
enum IdeaStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case proposed = "proposed"
    case discussing = "discussing"
    case approved = "approved"
    case inProgress = "in_progress"
    case completed = "completed"
    case archived = "archived"

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Display Properties

    /// ステータスの表示名
    var displayName: String {
        switch self {
        case .proposed: return "提案中"
        case .discussing: return "議論中"
        case .approved: return "承認済み"
        case .inProgress: return "実行中"
        case .completed: return "完了"
        case .archived: return "アーカイブ"
        }
    }

    /// ステータスの絵文字
    var emoji: String {
        switch self {
        case .proposed: return "💡"
        case .discussing: return "💬"
        case .approved: return "✅"
        case .inProgress: return "🚀"
        case .completed: return "🎉"
        case .archived: return "📦"
        }
    }

    /// 絵文字付きの表示名
    var displayNameWithEmoji: String {
        "\(emoji) \(displayName)"
    }

    /// ステータスの色名
    var colorName: String {
        switch self {
        case .proposed: return "AsaMutedSage"
        case .discussing: return "AsaCoffeeBrown"
        case .approved: return "AsaMocha"
        case .inProgress: return "AsaCoffeeBrown"
        case .completed: return "AsaMutedSage"
        case .archived: return "AsaDarkSlate"
        }
    }

    /// 次のステータスに進められるかどうか
    var canProgress: Bool {
        switch self {
        case .proposed, .discussing, .approved, .inProgress:
            return true
        case .completed, .archived:
            return false
        }
    }

    /// 次のステータス
    var nextStatus: IdeaStatus? {
        switch self {
        case .proposed: return .discussing
        case .discussing: return .approved
        case .approved: return .inProgress
        case .inProgress: return .completed
        case .completed: return nil
        case .archived: return nil
        }
    }

    /// アクティブなステータスかどうか（フィルタ用）
    var isActive: Bool {
        switch self {
        case .proposed, .discussing, .approved, .inProgress:
            return true
        case .completed, .archived:
            return false
        }
    }
}
