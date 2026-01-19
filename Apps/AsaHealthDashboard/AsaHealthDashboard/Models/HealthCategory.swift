//
//  HealthCategory.swift
//  AsaHealthDashboard
//
//  健康指標のカテゴリ定義
//

import SwiftUI
import AsaUIKit

/// 健康データのカテゴリ
enum HealthCategory: String, CaseIterable, Codable, Identifiable {
    case steps = "steps"
    case distance = "distance"
    case calories = "calories"
    case exerciseTime = "exerciseTime"
    case sleep = "sleep"

    var id: String { rawValue }

    /// 表示名
    var displayName: String {
        switch self {
        case .steps: return "歩数"
        case .distance: return "距離"
        case .calories: return "消費カロリー"
        case .exerciseTime: return "運動時間"
        case .sleep: return "睡眠時間"
        }
    }

    /// 単位
    var unit: String {
        switch self {
        case .steps: return "歩"
        case .distance: return "km"
        case .calories: return "kcal"
        case .exerciseTime: return "分"
        case .sleep: return "時間"
        }
    }

    /// SF Symbolsアイコン名
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "location"
        case .calories: return "flame"
        case .exerciseTime: return "timer"
        case .sleep: return "moon.zzz"
        }
    }

    /// カテゴリカラー
    var color: Color {
        switch self {
        case .steps: return AsaColors.coffeeBrown
        case .distance: return AsaColors.mocha
        case .calories: return .orange
        case .exerciseTime: return AsaColors.mutedSage
        case .sleep: return .indigo
        }
    }

    /// デフォルトの目標値
    var defaultGoal: Double {
        switch self {
        case .steps: return 10000
        case .distance: return 8.0
        case .calories: return 500
        case .exerciseTime: return 30
        case .sleep: return 8.0
        }
    }

    /// 目標値の刻み幅（設定画面用）
    var goalStep: Double {
        switch self {
        case .steps: return 1000
        case .distance: return 1.0
        case .calories: return 50
        case .exerciseTime: return 5
        case .sleep: return 0.5
        }
    }

    /// 目標値の範囲
    var goalRange: ClosedRange<Double> {
        switch self {
        case .steps: return 1000...30000
        case .distance: return 1.0...20.0
        case .calories: return 100...1500
        case .exerciseTime: return 10...120
        case .sleep: return 4.0...12.0
        }
    }
}
