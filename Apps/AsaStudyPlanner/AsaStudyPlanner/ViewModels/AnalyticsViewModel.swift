import Foundation
import SwiftUI

/// 学習分析のViewModel
@MainActor
@Observable
final class AnalyticsViewModel {

    // MARK: - Dependencies

    private let dataService: DataService

    // MARK: - State

    private(set) var weeklyAnalytics: [LearningAnalytics] = []
    private(set) var monthlyAnalytics: [LearningAnalytics] = []
    private(set) var allTimeAnalytics: [LearningAnalytics] = []

    var selectedPeriod: AnalyticsPeriod = .week

    // MARK: - Enums

    enum AnalyticsPeriod: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        case all = "全期間"
    }

    // MARK: - Computed Properties

    var currentAnalytics: [LearningAnalytics] {
        switch selectedPeriod {
        case .week: return weeklyAnalytics
        case .month: return monthlyAnalytics
        case .all: return allTimeAnalytics
        }
    }

    var totalMinutes: Int {
        currentAnalytics.reduce(0) { $0 + $1.totalMinutes }
    }

    var totalSessions: Int {
        currentAnalytics.reduce(0) { $0 + $1.completedSessions }
    }

    var totalCompletedItems: Int {
        currentAnalytics.reduce(0) { $0 + $1.completedItems }
    }

    var averageFocusLevel: Double {
        let validAnalytics = currentAnalytics.filter { $0.averageFocusLevel > 0 }
        guard !validAnalytics.isEmpty else { return 0 }
        return validAnalytics.reduce(0) { $0 + $1.averageFocusLevel } / Double(validAnalytics.count)
    }

    var averageComprehensionLevel: Double {
        let validAnalytics = currentAnalytics.filter { $0.averageComprehensionLevel > 0 }
        guard !validAnalytics.isEmpty else { return 0 }
        return validAnalytics.reduce(0) { $0 + $1.averageComprehensionLevel } / Double(validAnalytics.count)
    }

    var totalMorningMinutes: Int {
        currentAnalytics.reduce(0) { $0 + $1.morningMinutes }
    }

    var totalEarlyMorningMinutes: Int {
        currentAnalytics.reduce(0) { $0 + $1.earlyMorningMinutes }
    }

    var currentStreak: Int {
        allTimeAnalytics.first?.streakDays ?? 0
    }

    var morningStreak: Int {
        allTimeAnalytics.first?.morningStreakDays ?? 0
    }

    var aiAcceptedTotal: Int {
        currentAnalytics.reduce(0) { $0 + $1.aiAcceptedCount }
    }

    var aiRejectedTotal: Int {
        currentAnalytics.reduce(0) { $0 + $1.aiRejectedCount }
    }

    var aiAcceptanceRate: Double {
        let total = aiAcceptedTotal + aiRejectedTotal
        guard total > 0 else { return 0 }
        return Double(aiAcceptedTotal) / Double(total)
    }

    var categoryDistribution: [(category: StudyCategory, minutes: Int)] {
        var totals: [String: Int] = [:]

        for analytic in currentAnalytics {
            for (categoryRaw, minutes) in analytic.categoryMinutes {
                totals[categoryRaw, default: 0] += minutes
            }
        }

        return totals.compactMap { (categoryRaw, minutes) in
            guard let category = StudyCategory(rawValue: categoryRaw) else { return nil }
            return (category, minutes)
        }.sorted { $0.minutes > $1.minutes }
    }

    var dailyAverageMinutes: Double {
        guard !currentAnalytics.isEmpty else { return 0 }
        return Double(totalMinutes) / Double(currentAnalytics.count)
    }

    var productivityScore: Int {
        guard let latest = allTimeAnalytics.first else { return 0 }
        return latest.productivityScore
    }

    // MARK: - Weekly Chart Data

    var weeklyChartData: [(date: Date, minutes: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let minutes = weeklyAnalytics.first { calendar.isDate($0.date, inSameDayAs: date) }?.totalMinutes ?? 0
            return (date, minutes)
        }
    }

    var monthlyChartData: [(weekStart: Date, minutes: Int)] {
        let calendar = Calendar.current
        let today = Date()

        // 過去4週間のデータ
        return (0..<4).reversed().map { weeksAgo in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today)!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

            let weekMinutes = monthlyAnalytics
                .filter { $0.date >= weekStart && $0.date < weekEnd }
                .reduce(0) { $0 + $1.totalMinutes }

            return (weekStart, weekMinutes)
        }
    }

    // MARK: - Initializer

    init(dataService: DataService) {
        self.dataService = dataService
    }

    /// メインアクターコンテキストで使用するデフォルト初期化
    init() {
        self.dataService = DataService()
    }

    // MARK: - Data Loading

    func loadData() {
        let calendar = Calendar.current
        let today = Date()

        // 週間データ
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        weeklyAnalytics = dataService.fetchAnalytics(from: weekAgo, to: today)

        // 月間データ
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
        monthlyAnalytics = dataService.fetchAnalytics(from: monthAgo, to: today)

        // 全期間データ（最新順）
        let yearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
        allTimeAnalytics = dataService.fetchAnalytics(from: yearAgo, to: today)
    }

    // MARK: - Helpers

    func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)時間\(mins)分" : "\(hours)時間"
        }
        return "\(minutes)分"
    }

    func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    func weekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
