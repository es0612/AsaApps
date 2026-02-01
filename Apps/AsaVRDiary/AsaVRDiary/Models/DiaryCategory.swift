//
//  DiaryCategory.swift
//  AsaVRDiary
//
//  日記カテゴリの定義
//

import SwiftUI

/// 日記カテゴリ
enum DiaryCategory: String, CaseIterable, Codable, Sendable {
    case daily = "daily"           // 日常
    case work = "work"             // 仕事
    case family = "family"         // 家族
    case hobby = "hobby"           // 趣味
    case travel = "travel"         // 旅行
    case health = "health"         // 健康
    case learning = "learning"     // 学び
    case special = "special"       // 特別な日
    case other = "other"           // その他

    // MARK: - Properties

    /// 表示名
    var displayName: String {
        switch self {
        case .daily: return "日常"
        case .work: return "仕事"
        case .family: return "家族"
        case .hobby: return "趣味"
        case .travel: return "旅行"
        case .health: return "健康"
        case .learning: return "学び"
        case .special: return "特別な日"
        case .other: return "その他"
        }
    }

    /// アイコン
    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .work: return "briefcase.fill"
        case .family: return "house.fill"
        case .hobby: return "paintpalette.fill"
        case .travel: return "airplane"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .special: return "star.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    /// カテゴリカラー
    var color: Color {
        switch self {
        case .daily: return Color.orange
        case .work: return Color.blue
        case .family: return Color.pink
        case .hobby: return Color.purple
        case .travel: return Color.green
        case .health: return Color.red
        case .learning: return Color.cyan
        case .special: return Color.yellow
        case .other: return Color.gray
        }
    }

    /// VR空間でのZ軸オフセット（カテゴリ別の奥行き）
    var vrZOffset: Float {
        switch self {
        case .daily: return 0.0
        case .work: return -0.3
        case .family: return 0.3
        case .hobby: return -0.6
        case .travel: return 0.6
        case .health: return -0.9
        case .learning: return 0.9
        case .special: return -1.2
        case .other: return 1.2
        }
    }
}
