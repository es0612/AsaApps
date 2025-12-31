//
//  AnalyticsViewModel.swift
//  AsaSmartTodo
//
//  分析データ管理ViewModel
//  生産性ダッシュボードとAI精度トラッキングのビジネスロジック
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class AnalyticsViewModel {
    // MARK: - Properties

    /// 今日の分析データ
    var todayAnalytics: TaskAnalytics?

    /// 週間分析データ（7日分）
    var weeklyAnalytics: [TaskAnalytics] = []

    /// 選択中の期間
    var selectedDateRange: DateRange = .week

    /// データサービス
    private let dataService: DataService

    // MARK: - Initializer

    init(dataService: DataService) {
        self.dataService = dataService
    }

    // MARK: - Computed Properties

    /// 週間完了率（0.0-1.0）
    var weeklyCompletionRate: Double {
        guard !weeklyAnalytics.isEmpty else { return 0.0 }

        let totalTasks = weeklyAnalytics.reduce(0) { $0 + $1.totalTasks }
        let completedTasks = weeklyAnalytics.reduce(0) { $0 + $1.completedTasks }

        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }

    /// 週間AI予測採用率（0.0-1.0）
    var weeklyAIAcceptanceRate: Double {
        guard !weeklyAnalytics.isEmpty else { return 0.0 }

        let totalPredictions = weeklyAnalytics.reduce(0) { $0 + $1.totalPredictions }
        let acceptedPredictions = weeklyAnalytics.reduce(0) { $0 + $1.acceptedPredictions }

        guard totalPredictions > 0 else { return 0.0 }
        return Double(acceptedPredictions) / Double(totalPredictions)
    }

    /// 週間朝活スコア（平均）
    var weeklyEarlyMorningScore: Double {
        guard !weeklyAnalytics.isEmpty else { return 0.0 }

        let totalScore = weeklyAnalytics.reduce(0.0) { $0 + $1.earlyMorningProductivityScore }
        return totalScore / Double(weeklyAnalytics.count)
    }

    /// 週間平均信頼度スコア
    var weeklyAverageConfidence: Double {
        guard !weeklyAnalytics.isEmpty else { return 0.0 }

        let totalConfidence = weeklyAnalytics.reduce(0.0) { $0 + $1.averageConfidence }
        return totalConfidence / Double(weeklyAnalytics.count)
    }

    // MARK: - Chart Data

    /// 24時間チャート用データ
    var hourlyChartData: [HourlyData] {
        guard let today = todayAnalytics else { return [] }

        let creation = today.hourlyTaskCreation
        let completion = today.hourlyCompletionRate

        return (0..<24).map { hour in
            HourlyData(
                hour: hour,
                hourLabel: "\(hour)時",
                tasksCreated: creation[hour],
                completionRate: completion[hour]
            )
        }
    }

    /// 週間トレンドチャート用データ
    var weeklyTrendData: [DailyTrendData] {
        weeklyAnalytics.map { analytics in
            DailyTrendData(
                date: analytics.date,
                dateLabel: formatDateLabel(analytics.date),
                completionRate: analytics.completionRate,
                aiAcceptanceRate: analytics.aiAcceptanceRate,
                earlyMorningScore: analytics.earlyMorningProductivityScore
            )
        }
    }

    /// AI精度トレンドチャート用データ
    var aiAccuracyTrend: [AIAccuracyData] {
        weeklyAnalytics.map { analytics in
            AIAccuracyData(
                date: analytics.date,
                dateLabel: formatDateLabel(analytics.date),
                acceptanceRate: analytics.aiAcceptanceRate,
                averageConfidence: analytics.averageConfidence,
                totalPredictions: analytics.totalPredictions
            )
        }
    }

    // MARK: - Methods

    /// 分析データを読み込む
    func loadAnalytics() {
        todayAnalytics = dataService.getTodayAnalytics()

        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        weeklyAnalytics = dataService.getAnalytics(from: weekAgo, to: today)

        // データが足りない場合は空のデータで埋める
        fillMissingDays(from: weekAgo, to: today)
    }

    /// 指定期間の分析データを読み込む
    func loadAnalytics(for range: DateRange) {
        selectedDateRange = range

        let calendar = Calendar.current
        let today = Date()

        let startDate: Date
        switch range {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        case .month:
            startDate = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        }

        weeklyAnalytics = dataService.getAnalytics(from: startDate, to: today)
        fillMissingDays(from: startDate, to: today)
    }

    /// パーセント表示用フォーマット
    func formatPercentage(_ value: Double) -> String {
        let percentage = Int(value * 100)
        return "\(percentage)%"
    }

    // MARK: - Private Helpers

    /// 日付ラベルのフォーマット
    private func formatDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    /// 欠けている日のデータを空で埋める
    private func fillMissingDays(from startDate: Date, to endDate: Date) {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        var allDates: [Date] = []
        while currentDate <= end {
            allDates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // 既存データの日付を取得
        let existingDates = Set(weeklyAnalytics.map { calendar.startOfDay(for: $0.date) })

        // 足りない日付を追加（空のデータ）
        for date in allDates {
            if !existingDates.contains(date) {
                let emptyAnalytics = TaskAnalytics(date: date)
                weeklyAnalytics.append(emptyAnalytics)
            }
        }

        // 日付順にソート
        weeklyAnalytics.sort { $0.date < $1.date }
    }
}

// MARK: - Supporting Types

/// 期間選択オプション
enum DateRange: String, CaseIterable, Identifiable {
    case week = "週間"
    case month = "月間"

    var id: String { rawValue }
}

/// 24時間チャート用データ
struct HourlyData: Identifiable {
    let id = UUID()
    let hour: Int
    let hourLabel: String
    let tasksCreated: Int
    let completionRate: Double
}

/// 日別トレンドデータ
struct DailyTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let dateLabel: String
    let completionRate: Double
    let aiAcceptanceRate: Double
    let earlyMorningScore: Double
}

/// AI精度データ
struct AIAccuracyData: Identifiable {
    let id = UUID()
    let date: Date
    let dateLabel: String
    let acceptanceRate: Double
    let averageConfidence: Double
    let totalPredictions: Int
}
