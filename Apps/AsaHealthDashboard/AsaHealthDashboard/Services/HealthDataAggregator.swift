//
//  HealthDataAggregator.swift
//  AsaHealthDashboard
//
//  健康データの集計サービス
//

import Foundation

/// 健康データの集計・分析サービス
@Observable
final class HealthDataAggregator {
    private let healthKitService: HealthDataServiceProtocol

    init(healthKitService: HealthDataServiceProtocol) {
        self.healthKitService = healthKitService
    }

    // MARK: - 今日の全メトリクス取得

    func fetchTodayMetrics(goals: [HealthGoal]) async -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        let today = Date()

        for category in HealthCategory.allCases {
            let value = await healthKitService.fetchData(for: category, date: today)
            let goal = goals.targetValue(for: category)

            metrics.append(HealthMetric(
                category: category,
                date: today,
                value: value,
                goal: goal
            ))
        }

        return metrics
    }

    // MARK: - 期間別メトリクス取得

    func fetchMetrics(for category: HealthCategory, in period: TimePeriod, goals: [HealthGoal]) async -> [HealthMetric] {
        await healthKitService.fetchMetrics(for: category, in: period, from: Date(), goals: goals)
    }

    // MARK: - 全カテゴリの期間別メトリクス取得

    func fetchAllMetrics(in period: TimePeriod, goals: [HealthGoal]) async -> [HealthCategory: [HealthMetric]] {
        var result: [HealthCategory: [HealthMetric]] = [:]

        for category in HealthCategory.allCases {
            let metrics = await fetchMetrics(for: category, in: period, goals: goals)
            result[category] = metrics
        }

        return result
    }

    // MARK: - トレンド分析

    func analyzeTrend(for category: HealthCategory, period: TimePeriod) async -> TrendAnalysis {
        let calendar = Calendar.current
        let today = Date()

        // 現在期間のデータ
        var currentValues: [Double] = []
        for i in 0..<period.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let value = await healthKitService.fetchData(for: category, date: date)
                currentValues.append(value)
            }
        }

        // 前期間のデータ
        var previousValues: [Double] = []
        let previousStartDate = period.previousPeriodStartDate(from: today)
        for i in 0..<period.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: previousStartDate) {
                let value = await healthKitService.fetchData(for: category, date: date)
                previousValues.append(value)
            }
        }

        return TrendAnalysis(
            category: category,
            currentValues: currentValues,
            previousValues: previousValues
        )
    }

    // MARK: - 全カテゴリのトレンド分析

    func analyzeAllTrends(period: TimePeriod) async -> [HealthCategory: TrendAnalysis] {
        var result: [HealthCategory: TrendAnalysis] = [:]

        for category in HealthCategory.allCases {
            let analysis = await analyzeTrend(for: category, period: period)
            result[category] = analysis
        }

        return result
    }

    // MARK: - 週間ハイライト

    func fetchWeeklyHighlights(goals: [HealthGoal]) async -> WeeklyHighlights {
        let calendar = Calendar.current
        let today = Date()

        var totalSteps: Double = 0
        var totalDistance: Double = 0
        var totalCalories: Double = 0
        var totalExerciseTime: Double = 0
        var totalSleep: Double = 0
        var sleepDays = 0

        var achievedDays: [HealthCategory: Int] = [:]
        for category in HealthCategory.allCases {
            achievedDays[category] = 0
        }

        // 過去7日間のデータを集計
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }

            let steps = await healthKitService.fetchStepCount(for: date)
            let distance = await healthKitService.fetchDistance(for: date)
            let calories = await healthKitService.fetchCalories(for: date)
            let exerciseTime = await healthKitService.fetchExerciseTime(for: date)

            totalSteps += steps
            totalDistance += distance
            totalCalories += calories
            totalExerciseTime += exerciseTime

            if let sleepData = await healthKitService.fetchSleepData(for: date) {
                totalSleep += sleepData.duration
                sleepDays += 1
            }

            // 目標達成日数をカウント
            let stepsGoal = goals.targetValue(for: .steps)
            let distanceGoal = goals.targetValue(for: .distance)
            let caloriesGoal = goals.targetValue(for: .calories)
            let exerciseGoal = goals.targetValue(for: .exerciseTime)
            let sleepGoal = goals.targetValue(for: .sleep)

            if steps >= stepsGoal { achievedDays[.steps, default: 0] += 1 }
            if distance >= distanceGoal { achievedDays[.distance, default: 0] += 1 }
            if calories >= caloriesGoal { achievedDays[.calories, default: 0] += 1 }
            if exerciseTime >= exerciseGoal { achievedDays[.exerciseTime, default: 0] += 1 }
        }

        // 睡眠の目標達成
        if sleepDays > 0 {
            let avgSleep = totalSleep / Double(sleepDays)
            let sleepGoal = goals.targetValue(for: .sleep)
            if avgSleep >= sleepGoal {
                achievedDays[.sleep] = sleepDays
            }
        }

        return WeeklyHighlights(
            totalSteps: totalSteps,
            totalDistance: totalDistance,
            totalCalories: totalCalories,
            totalExerciseTime: totalExerciseTime,
            averageSleep: sleepDays > 0 ? totalSleep / Double(sleepDays) : 0,
            achievedDays: achievedDays
        )
    }

    // MARK: - 健康スコア計算

    func calculateHealthScore(from metrics: [HealthMetric]) -> HealthScore {
        HealthScore.calculate(from: metrics)
    }
}

// MARK: - 週間ハイライトモデル

struct WeeklyHighlights {
    let totalSteps: Double
    let totalDistance: Double
    let totalCalories: Double
    let totalExerciseTime: Double
    let averageSleep: Double
    let achievedDays: [HealthCategory: Int]

    var averageSteps: Double {
        totalSteps / 7
    }

    var averageDistance: Double {
        totalDistance / 7
    }

    var averageCalories: Double {
        totalCalories / 7
    }

    var averageExerciseTime: Double {
        totalExerciseTime / 7
    }

    /// フォーマット済みの総歩数
    var formattedTotalSteps: String {
        if totalSteps >= 10000 {
            return String(format: "%.1f万", totalSteps / 10000)
        }
        return String(format: "%.0f", totalSteps)
    }

    /// 総合達成率
    var overallAchievementRate: Double {
        let totalAchieved = achievedDays.values.reduce(0, +)
        let totalPossible = HealthCategory.allCases.count * 7
        return Double(totalAchieved) / Double(totalPossible) * 100
    }
}
