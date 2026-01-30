//
//  ProgressViewModel.swift
//  AsaFitnessCoach
//
//  進捗分析ViewModel
//

import Foundation
import SwiftData

@Observable
@MainActor
final class ProgressViewModel {
    // MARK: - Properties

    private let dataService = DataService()
    private let progressiveOverloadService = ProgressiveOverloadService()

    // 期間選択
    var selectedTimeRange: TimeRange = .week

    // データ
    var sessions: [WorkoutSession] = []
    var dailyData: [DailyWorkoutData] = []
    var weeklyStats: WeeklyStats?
    var monthlyStats: MonthlyStats?
    var overloadSuggestions: [ProgressiveOverloadSuggestion] = []

    // MARK: - Time Range

    enum TimeRange: String, CaseIterable {
        case week = "週"
        case month = "月"
        case threeMonths = "3ヶ月"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }

    // MARK: - Initialization

    func setModelContext(_ context: ModelContext) {
        dataService.setModelContext(context)
    }

    // MARK: - Data Loading

    func loadData() {
        loadSessions()
        calculateDailyData()
        loadStats()
        loadOverloadSuggestions()
    }

    private func loadSessions() {
        sessions = dataService.fetchCompletedSessions(days: selectedTimeRange.days)
    }

    private func calculateDailyData() {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: today) ?? today

        var data: [DailyWorkoutData] = []

        for dayOffset in 0..<selectedTimeRange.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            let daySessions = sessions.filter { session in
                calendar.isDate(session.startTime, inSameDayAs: date)
            }

            let workoutCount = daySessions.count
            let totalDuration = daySessions.reduce(0.0) { $0 + $1.duration }
            let totalCalories = daySessions.compactMap { $0.totalCalories }.reduce(0, +)
            let totalVolume = daySessions.reduce(0.0) { $0 + $1.totalVolume }

            data.append(DailyWorkoutData(
                date: date,
                workoutCount: workoutCount,
                duration: totalDuration,
                calories: totalCalories,
                volume: totalVolume
            ))
        }

        dailyData = data
    }

    private func loadStats() {
        weeklyStats = dataService.fetchWeeklyStats()
        monthlyStats = dataService.fetchMonthlyStats()
    }

    private func loadOverloadSuggestions() {
        overloadSuggestions = progressiveOverloadService.suggestAllWeightIncreases(
            sessions: sessions
        )
    }

    // MARK: - Computed Properties

    var totalWorkouts: Int {
        sessions.count
    }

    var totalDuration: TimeInterval {
        sessions.reduce(0.0) { $0 + $1.duration }
    }

    var totalCalories: Double {
        sessions.compactMap { $0.totalCalories }.reduce(0, +)
    }

    var totalVolume: Double {
        sessions.reduce(0.0) { $0 + $1.totalVolume }
    }

    var averageSessionDuration: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        return totalDuration / Double(sessions.count)
    }

    var averageRating: Double {
        let ratings = sessions.compactMap { $0.rating?.rawValue }
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    var workoutStreak: Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()

        while true {
            let hasWorkout = sessions.contains { session in
                calendar.isDate(session.startTime, inSameDayAs: currentDate)
            }

            if hasWorkout {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Chart Data

    var chartData: [ChartDataPoint] {
        dailyData.map { day in
            ChartDataPoint(
                date: day.date,
                value: day.duration
            )
        }
    }

    var volumeChartData: [ChartDataPoint] {
        dailyData.map { day in
            ChartDataPoint(
                date: day.date,
                value: day.volume
            )
        }
    }

    // MARK: - Refresh

    func refreshData() {
        loadData()
    }
}

// MARK: - Supporting Types

struct DailyWorkoutData: Identifiable {
    var id: Date { date }
    let date: Date
    let workoutCount: Int
    let duration: TimeInterval  // 分
    let calories: Double
    let volume: Double

    var hasWorkout: Bool {
        workoutCount > 0
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct ChartDataPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let value: Double
}
