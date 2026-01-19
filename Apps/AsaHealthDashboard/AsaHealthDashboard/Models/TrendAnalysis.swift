//
//  TrendAnalysis.swift
//  AsaHealthDashboard
//
//  トレンド分析結果モデル
//

import SwiftUI
import AsaUIKit

/// トレンドの方向
enum TrendDirection {
    case up
    case down
    case stable

    /// SF Symbolsアイコン名
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    /// トレンドカラー（上昇=良い、下降=悪い、は指標による）
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return AsaColors.mutedSage
        }
    }

    /// 表示テキスト
    var displayText: String {
        switch self {
        case .up: return "上昇"
        case .down: return "下降"
        case .stable: return "安定"
        }
    }
}

/// トレンド分析結果
struct TrendAnalysis: Identifiable {
    let id = UUID()
    let category: HealthCategory
    let currentPeriodAverage: Double
    let previousPeriodAverage: Double
    let trend: TrendDirection
    let percentageChange: Double

    init(category: HealthCategory, currentValues: [Double], previousValues: [Double]) {
        self.category = category
        self.currentPeriodAverage = currentValues.isEmpty ? 0 : currentValues.reduce(0, +) / Double(currentValues.count)
        self.previousPeriodAverage = previousValues.isEmpty ? 0 : previousValues.reduce(0, +) / Double(previousValues.count)

        if previousPeriodAverage == 0 {
            self.percentageChange = 0
            self.trend = .stable
        } else {
            let change = ((currentPeriodAverage - previousPeriodAverage) / previousPeriodAverage) * 100
            self.percentageChange = change

            if change > 5 {
                self.trend = .up
            } else if change < -5 {
                self.trend = .down
            } else {
                self.trend = .stable
            }
        }
    }

    /// フォーマット済みの変化率
    var formattedChange: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percentageChange))%"
    }

    /// フォーマット済みの現在期間平均
    var formattedCurrentAverage: String {
        formatValue(currentPeriodAverage)
    }

    /// フォーマット済みの前期間平均
    var formattedPreviousAverage: String {
        formatValue(previousPeriodAverage)
    }

    private func formatValue(_ value: Double) -> String {
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
            return String(format: "%.1f", value)
        }
    }

    /// カテゴリに応じたトレンドカラー
    /// （睡眠は上昇が良い、他も基本的に上昇が良い）
    var adjustedTrendColor: Color {
        trend.color
    }
}

/// 総合健康スコア
struct HealthScore {
    let score: Int // 0-100
    let breakdown: [HealthCategory: Int]
    let date: Date

    /// スコアに基づくグレード
    var grade: String {
        switch score {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }

    /// スコアに基づくカラー
    var color: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    /// スコアに基づくメッセージ
    var message: String {
        switch score {
        case 90...100: return "素晴らしい！健康的な生活を維持しています"
        case 80..<90: return "とても良いです！この調子で続けましょう"
        case 70..<80: return "良い状態です。もう少し改善できそうです"
        case 60..<70: return "まずまずです。目標達成を目指しましょう"
        default: return "改善の余地があります。少しずつ頑張りましょう"
        }
    }

    /// 各カテゴリの達成率から総合スコアを計算
    static func calculate(from metrics: [HealthMetric]) -> HealthScore {
        var breakdown: [HealthCategory: Int] = [:]
        var totalScore = 0
        var categoryCount = 0

        for category in HealthCategory.allCases {
            if let metric = metrics.first(where: { $0.category == category }) {
                let categoryScore = min(Int(metric.progress * 100), 100)
                breakdown[category] = categoryScore
                totalScore += categoryScore
                categoryCount += 1
            }
        }

        let averageScore = categoryCount > 0 ? totalScore / categoryCount : 0

        return HealthScore(
            score: averageScore,
            breakdown: breakdown,
            date: Date()
        )
    }
}
