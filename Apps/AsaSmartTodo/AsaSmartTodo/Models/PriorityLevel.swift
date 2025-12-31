//
//  PriorityLevel.swift
//  AsaSmartTodo
//
//  タスクの優先度レベル定義
//

import Foundation
import SwiftUI
import AsaUIKit

/// タスクの優先度レベルを表すenum
enum PriorityLevel: String, CaseIterable, Identifiable, Codable, Sendable {
    case high = "high"     // 高優先度
    case medium = "medium" // 中優先度
    case low = "low"       // 低優先度

    var id: String { rawValue }

    /// 優先度の日本語表示名
    var displayName: String {
        switch self {
        case .high:
            return "高"
        case .medium:
            return "中"
        case .low:
            return "低"
        }
    }

    /// 優先度を表す色（AsaUIKit準拠）
    var color: Color {
        switch self {
        case .high:
            return .red  // 高優先度は赤
        case .medium:
            return AsaColors.coffeeBrown  // 中優先度はブランドカラー
        case .low:
            return AsaColors.mutedSage    // 低優先度はアクセントカラー
        }
    }

    /// 優先度のアイコン（emoji）
    var icon: String {
        switch self {
        case .high:
            return "🔴"
        case .medium:
            return "🟡"
        case .low:
            return "🟢"
        }
    }

    /// 優先度の数値スコア（0.0-1.0）
    /// AI予測での閾値判定に使用
    var score: Double {
        switch self {
        case .high:
            return 0.7
        case .medium:
            return 0.4
        case .low:
            return 0.0
        }
    }
}
