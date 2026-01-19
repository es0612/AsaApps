//
//  HealthMetric.swift
//  AsaHealthDashboard
//
//  健康指標データモデル
//

import Foundation

/// 健康指標データ
struct HealthMetric: Identifiable, Equatable {
    let id = UUID()
    let category: HealthCategory
    let date: Date
    let value: Double
    let goal: Double?

    /// 目標達成率（0.0〜1.0）
    var progress: Double {
        guard let goal = goal, goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }

    /// 目標達成率（パーセント）
    var progressPercentage: Int {
        Int(progress * 100)
    }

    /// 目標達成済みかどうか
    var isGoalAchieved: Bool {
        guard let goal = goal else { return false }
        return value >= goal
    }

    /// フォーマット済みの値
    var formattedValue: String {
        switch category {
        case .steps:
            return String(format: "%.0f", value)
        case .distance:
            return String(format: "%.1f", value)
        case .calories:
            return String(format: "%.0f", value)
        case .exerciseTime:
            return String(format: "%.0f", value)
        case .sleep:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            if minutes > 0 {
                return "\(hours)時間\(minutes)分"
            } else {
                return "\(hours)時間"
            }
        }
    }

    /// 短いフォーマット済みの値（チャート用）
    var shortFormattedValue: String {
        switch category {
        case .steps:
            if value >= 10000 {
                return String(format: "%.1f万", value / 10000)
            }
            return String(format: "%.0f", value)
        case .distance:
            return String(format: "%.1f", value)
        case .calories:
            return String(format: "%.0f", value)
        case .exerciseTime:
            return String(format: "%.0f", value)
        case .sleep:
            return String(format: "%.1f", value)
        }
    }

    /// フォーマット済みの目標値
    var formattedGoal: String? {
        guard let goal = goal else { return nil }
        switch category {
        case .steps:
            return String(format: "%.0f", goal)
        case .distance:
            return String(format: "%.1f", goal)
        case .calories:
            return String(format: "%.0f", goal)
        case .exerciseTime:
            return String(format: "%.0f", goal)
        case .sleep:
            return String(format: "%.1f", goal)
        }
    }
}

// MARK: - HealthMetric配列の拡張

extension Array where Element == HealthMetric {
    /// 平均値を計算
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0) { $0 + $1.value } / Double(count)
    }

    /// 合計値を計算
    var total: Double {
        reduce(0) { $0 + $1.value }
    }

    /// 最大値を取得
    var maxValue: Double {
        map { $0.value }.max() ?? 0
    }

    /// 最小値を取得
    var minValue: Double {
        map { $0.value }.min() ?? 0
    }

    /// 日付でソート
    var sortedByDate: [HealthMetric] {
        sorted { $0.date < $1.date }
    }
}
