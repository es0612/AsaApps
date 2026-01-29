//
//  PriorityLevel.swift
//  AsaVoiceAssistant
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

    /// 優先度のアイコン（SF Symbol）
    var iconName: String {
        switch self {
        case .high:
            return "exclamationmark.circle.fill"
        case .medium:
            return "minus.circle.fill"
        case .low:
            return "arrow.down.circle.fill"
        }
    }

    /// 優先度のアイコン（emoji）
    var emoji: String {
        switch self {
        case .high:
            return "🔴"
        case .medium:
            return "🟡"
        case .low:
            return "🟢"
        }
    }
}
