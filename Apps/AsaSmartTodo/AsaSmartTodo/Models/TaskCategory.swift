//
//  TaskCategory.swift
//  AsaSmartTodo
//
//  AIでタスク優先度を提案するタスクカテゴリ定義
//

import Foundation

/// タスクのカテゴリを表すenum
enum TaskCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case work = "work"           // 仕事関連
    case personal = "personal"   // 個人的な用事
    case family = "family"       // 家族関連
    case health = "health"       // 健康・フィットネス
    case learning = "learning"   // 学習・成長
    case other = "other"         // その他

    var id: String { rawValue }

    /// カテゴリの日本語表示名
    var displayName: String {
        switch self {
        case .work:
            return "仕事"
        case .personal:
            return "個人"
        case .family:
            return "家族"
        case .health:
            return "健康"
        case .learning:
            return "学習"
        case .other:
            return "その他"
        }
    }

    /// カテゴリの重要度重み（AI予測に使用）
    /// 値が高いほど重要度が高いと判断される（0.0-1.0）
    var importanceWeight: Double {
        switch self {
        case .work:
            return 0.8  // 仕事は高優先度
        case .health:
            return 0.7  // 健康は重要
        case .family:
            return 0.7  // 家族も重要
        case .learning:
            return 0.6  // 学習・成長
        case .personal:
            return 0.5  // 個人的な用事
        case .other:
            return 0.4  // その他
        }
    }

    /// カテゴリのアイコン（emoji）
    var icon: String {
        switch self {
        case .work:
            return "💼"
        case .personal:
            return "👤"
        case .family:
            return "👨‍👩‍👧‍👦"
        case .health:
            return "🏥"
        case .learning:
            return "📚"
        case .other:
            return "📝"
        }
    }
}
