//
//  TaskCategory.swift
//  AsaVoiceAssistant
//
//  タスクのカテゴリ定義
//

import Foundation
import SwiftUI
import AsaUIKit

/// タスクのカテゴリを表すenum
enum TaskCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case work = "work"           // 仕事
    case personal = "personal"   // 個人
    case family = "family"       // 家族
    case shopping = "shopping"   // 買い物
    case health = "health"       // 健康
    case study = "study"         // 勉強
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
        case .shopping:
            return "買い物"
        case .health:
            return "健康"
        case .study:
            return "勉強"
        case .other:
            return "その他"
        }
    }

    /// カテゴリを表すアイコン（SF Symbol）
    var iconName: String {
        switch self {
        case .work:
            return "briefcase.fill"
        case .personal:
            return "person.fill"
        case .family:
            return "house.fill"
        case .shopping:
            return "cart.fill"
        case .health:
            return "heart.fill"
        case .study:
            return "book.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }

    /// カテゴリを表す色
    var color: Color {
        switch self {
        case .work:
            return AsaColors.coffeeBrown
        case .personal:
            return .blue
        case .family:
            return .orange
        case .shopping:
            return .purple
        case .health:
            return .pink
        case .study:
            return .green
        case .other:
            return AsaColors.mutedSage
        }
    }

    /// カテゴリ検出用キーワード（日本語コマンド解析用）
    var keywords: [String] {
        switch self {
        case .work:
            return ["仕事", "会議", "ミーティング", "報告", "プレゼン", "資料", "提出", "メール", "連絡", "打ち合わせ", "業務", "案件"]
        case .personal:
            return ["個人", "自分", "私用", "プライベート"]
        case .family:
            return ["家族", "子供", "子ども", "妻", "夫", "親", "母", "父", "家庭"]
        case .shopping:
            return ["買い物", "購入", "買う", "スーパー", "コンビニ", "ショッピング", "注文"]
        case .health:
            return ["健康", "病院", "薬", "運動", "ジム", "検診", "医者", "診察"]
        case .study:
            return ["勉強", "学習", "読書", "本", "セミナー", "講座", "資格"]
        case .other:
            return []
        }
    }
}
