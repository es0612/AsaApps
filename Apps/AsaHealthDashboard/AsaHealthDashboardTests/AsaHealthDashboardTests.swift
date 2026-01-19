//
//  AsaHealthDashboardTests.swift
//  AsaHealthDashboardTests
//
//  テストファイル
//

import Testing
@testable import AsaHealthDashboard

// MARK: - HealthCategory Tests

@Suite("HealthCategory Tests")
struct HealthCategoryTests {

    @Test("カテゴリが正しい表示名を持つ")
    func testDisplayNames() {
        #expect(HealthCategory.steps.displayName == "歩数")
        #expect(HealthCategory.distance.displayName == "距離")
        #expect(HealthCategory.calories.displayName == "消費カロリー")
        #expect(HealthCategory.exerciseTime.displayName == "運動時間")
        #expect(HealthCategory.sleep.displayName == "睡眠時間")
    }

    @Test("カテゴリが正しい単位を持つ")
    func testUnits() {
        #expect(HealthCategory.steps.unit == "歩")
        #expect(HealthCategory.distance.unit == "km")
        #expect(HealthCategory.calories.unit == "kcal")
        #expect(HealthCategory.exerciseTime.unit == "分")
        #expect(HealthCategory.sleep.unit == "時間")
    }

    @Test("カテゴリが正しいデフォルト目標を持つ")
    func testDefaultGoals() {
        #expect(HealthCategory.steps.defaultGoal == 10000)
        #expect(HealthCategory.distance.defaultGoal == 8.0)
        #expect(HealthCategory.calories.defaultGoal == 500)
        #expect(HealthCategory.exerciseTime.defaultGoal == 30)
        #expect(HealthCategory.sleep.defaultGoal == 8.0)
    }

    @Test("全てのカテゴリがCaseIterableで取得可能")
    func testAllCases() {
        #expect(HealthCategory.allCases.count == 5)
    }
}

// MARK: - HealthMetric Tests

@Suite("HealthMetric Tests")
struct HealthMetricTests {

    @Test("進捗率が正しく計算される")
    func testProgress() {
        let metric = HealthMetric(
            category: .steps,
            date: Date(),
            value: 7500,
            goal: 10000
        )
        #expect(metric.progress == 0.75)
        #expect(metric.progressPercentage == 75)
    }

    @Test("目標達成判定が正しく動作する")
    func testGoalAchievement() {
        let achieved = HealthMetric(
            category: .steps,
            date: Date(),
            value: 12000,
            goal: 10000
        )
        #expect(achieved.isGoalAchieved == true)

        let notAchieved = HealthMetric(
            category: .steps,
            date: Date(),
            value: 8000,
            goal: 10000
        )
        #expect(notAchieved.isGoalAchieved == false)
    }

    @Test("進捗率が100%を超えない")
    func testProgressCap() {
        let metric = HealthMetric(
            category: .steps,
            date: Date(),
            value: 15000,
            goal: 10000
        )
        #expect(metric.progress == 1.0)
    }

    @Test("目標がnilの場合、進捗率は0")
    func testNilGoal() {
        let metric = HealthMetric(
            category: .steps,
            date: Date(),
            value: 5000,
            goal: nil
        )
        #expect(metric.progress == 0)
    }

    @Test("歩数のフォーマットが正しい")
    func testStepsFormatting() {
        let metric = HealthMetric(
            category: .steps,
            date: Date(),
            value: 8500,
            goal: 10000
        )
        #expect(metric.formattedValue == "8500")
    }

    @Test("睡眠時間のフォーマットが正しい")
    func testSleepFormatting() {
        let metric = HealthMetric(
            category: .sleep,
            date: Date(),
            value: 7.5,
            goal: 8.0
        )
        #expect(metric.formattedValue == "7時間30分")
    }
}

// MARK: - HealthMetric Array Extension Tests

@Suite("HealthMetric Array Tests")
struct HealthMetricArrayTests {

    @Test("平均値が正しく計算される")
    func testAverage() {
        let metrics = [
            HealthMetric(category: .steps, date: Date(), value: 8000, goal: 10000),
            HealthMetric(category: .steps, date: Date(), value: 10000, goal: 10000),
            HealthMetric(category: .steps, date: Date(), value: 12000, goal: 10000)
        ]
        #expect(metrics.average == 10000)
    }

    @Test("合計値が正しく計算される")
    func testTotal() {
        let metrics = [
            HealthMetric(category: .steps, date: Date(), value: 8000, goal: 10000),
            HealthMetric(category: .steps, date: Date(), value: 10000, goal: 10000)
        ]
        #expect(metrics.total == 18000)
    }

    @Test("空配列の平均値は0")
    func testEmptyAverage() {
        let metrics: [HealthMetric] = []
        #expect(metrics.average == 0)
    }
}

// MARK: - TimePeriod Tests

@Suite("TimePeriod Tests")
struct TimePeriodTests {

    @Test("期間の日数が正しい")
    func testDays() {
        #expect(TimePeriod.day.days == 1)
        #expect(TimePeriod.week.days == 7)
        #expect(TimePeriod.month.days == 30)
    }

    @Test("全ての期間がCaseIterableで取得可能")
    func testAllCases() {
        #expect(TimePeriod.allCases.count == 3)
    }
}

// MARK: - TrendAnalysis Tests

@Suite("TrendAnalysis Tests")
struct TrendAnalysisTests {

    @Test("上昇トレンドが正しく検出される")
    func testUpwardTrend() {
        let analysis = TrendAnalysis(
            category: .steps,
            currentValues: [10000, 11000, 12000],
            previousValues: [8000, 8500, 9000]
        )
        #expect(analysis.trend == .up)
        #expect(analysis.percentageChange > 5)
    }

    @Test("下降トレンドが正しく検出される")
    func testDownwardTrend() {
        let analysis = TrendAnalysis(
            category: .steps,
            currentValues: [7000, 6500, 6000],
            previousValues: [10000, 10500, 11000]
        )
        #expect(analysis.trend == .down)
        #expect(analysis.percentageChange < -5)
    }

    @Test("安定トレンドが正しく検出される")
    func testStableTrend() {
        let analysis = TrendAnalysis(
            category: .steps,
            currentValues: [10000, 10100, 10050],
            previousValues: [10000, 9950, 10000]
        )
        #expect(analysis.trend == .stable)
    }

    @Test("前期間が空の場合、安定トレンド")
    func testEmptyPreviousPeriod() {
        let analysis = TrendAnalysis(
            category: .steps,
            currentValues: [10000, 11000],
            previousValues: []
        )
        #expect(analysis.trend == .stable)
        #expect(analysis.percentageChange == 0)
    }
}

// MARK: - HealthScore Tests

@Suite("HealthScore Tests")
struct HealthScoreTests {

    @Test("スコアからグレードが正しく計算される")
    func testGrades() {
        let scoreA = HealthScore(score: 95, breakdown: [:], date: Date())
        #expect(scoreA.grade == "A")

        let scoreB = HealthScore(score: 85, breakdown: [:], date: Date())
        #expect(scoreB.grade == "B")

        let scoreC = HealthScore(score: 75, breakdown: [:], date: Date())
        #expect(scoreC.grade == "C")

        let scoreD = HealthScore(score: 65, breakdown: [:], date: Date())
        #expect(scoreD.grade == "D")

        let scoreF = HealthScore(score: 50, breakdown: [:], date: Date())
        #expect(scoreF.grade == "F")
    }

    @Test("メトリクスからスコアが計算される")
    func testCalculateFromMetrics() {
        let metrics = [
            HealthMetric(category: .steps, date: Date(), value: 10000, goal: 10000),
            HealthMetric(category: .distance, date: Date(), value: 8.0, goal: 8.0),
            HealthMetric(category: .calories, date: Date(), value: 500, goal: 500),
            HealthMetric(category: .exerciseTime, date: Date(), value: 30, goal: 30),
            HealthMetric(category: .sleep, date: Date(), value: 8.0, goal: 8.0)
        ]

        let score = HealthScore.calculate(from: metrics)
        #expect(score.score == 100)
        #expect(score.grade == "A")
    }
}
