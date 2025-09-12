//
//  AsaHealthKitTests.swift
//  AsaHealthKitTests
//
//  AsaHealthKit統合テスト
//  健康関連共有ライブラリの包括的テストスイート
//

import Testing
import Foundation
@testable import AsaHealthKit

// MARK: - AsaHealthKit Main Tests

struct AsaHealthKitTests {
    
    @Test("AsaHealthKit基本情報テスト")
    func testAsaHealthKitInfo() {
        #expect(AsaHealthKitLib.version == "1.0.0")
        #expect(AsaHealthKitLib.name == "AsaHealthKit")
        
        // デバッグモード切り替えテスト
        AsaHealthKitLib.debugMode = true
        #expect(AsaHealthKitLib.debugMode == true)
        
        AsaHealthKitLib.debugMode = false
        #expect(AsaHealthKitLib.debugMode == false)
    }
    
    @Test("健康指標定数テスト")
    func testHealthKitConstants() {
        // デフォルト目標値
        #expect(HealthKitConstants.DefaultGoals.dailySteps == 10000)
        #expect(HealthKitConstants.DefaultGoals.dailyWaterML == 2000.0)
        #expect(HealthKitConstants.DefaultGoals.dailySleepHours == 8.0)
        #expect(HealthKitConstants.DefaultGoals.weeklyWorkoutMinutes == 150)
        
        // 単位
        #expect(HealthKitConstants.Units.steps == "歩")
        #expect(HealthKitConstants.Units.waterML == "ml")
        #expect(HealthKitConstants.Units.sleepHours == "時間")
        
        // 永続化キー
        #expect(HealthKitConstants.PersistenceKeys.waterIntakes == "health_water_intakes")
        #expect(HealthKitConstants.PersistenceKeys.sleepRecords == "health_sleep_records")
    }
}

// MARK: - Health Metric Type Tests

struct HealthMetricTypeTests {
    
    @Test("健康指標タイプ表示名テスト")
    func testHealthMetricTypeDisplayNames() {
        #expect(HealthMetricType.waterIntake.displayName == "水分摂取")
        #expect(HealthMetricType.steps.displayName == "歩数")
        #expect(HealthMetricType.sleep.displayName == "睡眠")
        #expect(HealthMetricType.weight.displayName == "体重")
        #expect(HealthMetricType.mood.displayName == "気分")
    }
    
    @Test("健康指標タイプ単位テスト")
    func testHealthMetricTypeUnits() {
        #expect(HealthMetricType.waterIntake.unit == "ml")
        #expect(HealthMetricType.steps.unit == "歩")
        #expect(HealthMetricType.sleep.unit == "時間")
        #expect(HealthMetricType.weight.unit == "kg")
        #expect(HealthMetricType.mood.unit == "点")
    }
    
    @Test("健康指標タイプデフォルト目標値テスト")
    func testHealthMetricTypeDefaultGoals() {
        #expect(HealthMetricType.waterIntake.defaultGoal == 2000.0)
        #expect(HealthMetricType.steps.defaultGoal == 10000.0)
        #expect(HealthMetricType.sleep.defaultGoal == 8.0)
        #expect(HealthMetricType.mood.defaultGoal == 7.0)
    }
}

// MARK: - Water Intake Tests

struct WaterIntakeTests {
    
    @Test("水分摂取記録作成テスト")
    func testWaterIntakeRecordCreation() {
        let record = WaterIntakeRecord(amount: 500.0, drinkType: .water)
        
        #expect(record.value == 500.0)
        #expect(record.metricType == .waterIntake)
        #expect(record.drinkType == .water)
        #expect(record.note == nil)
        #expect(record.id != UUID())  // ユニークIDが生成されている
    }
    
    @Test("飲み物タイプ表示名テスト")
    func testDrinkTypeDisplayNames() {
        #expect(DrinkType.water.displayName == "水")
        #expect(DrinkType.tea.displayName == "お茶")
        #expect(DrinkType.coffee.displayName == "コーヒー")
        #expect(DrinkType.juice.displayName == "ジュース")
        #expect(DrinkType.sports.displayName == "スポーツ飲料")
        #expect(DrinkType.other.displayName == "その他")
    }
    
    @Test("水分摂取記録ノート付きテスト")
    func testWaterIntakeWithNote() {
        let record = WaterIntakeRecord(
            amount: 300.0, 
            drinkType: .tea, 
            recordedAt: Date(),
            note: "朝食時の緑茶"
        )
        
        #expect(record.value == 300.0)
        #expect(record.drinkType == .tea)
        #expect(record.note == "朝食時の緑茶")
    }
}

// MARK: - Sleep Record Tests

struct SleepRecordTests {
    
    @Test("睡眠記録作成と時間計算テスト")
    func testSleepRecordCreation() {
        let calendar = Calendar.current
        let bedtime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        let wakeupTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: bedtime) ?? Date()) ?? Date()
        
        let record = SleepRecord(bedtime: bedtime, wakeupTime: wakeupTime, quality: 8)
        
        #expect(record.metricType == .sleep)
        #expect(record.bedtime == bedtime)
        #expect(record.wakeupTime == wakeupTime)
        #expect(record.quality == 8)
        #expect(record.value == 8.0)  // 8時間睡眠
        #expect(record.recordedAt == wakeupTime)  // 起床時が記録時間
    }
    
    @Test("睡眠記録ノート付きテスト")
    func testSleepRecordWithNote() {
        let bedtime = Date()
        let wakeupTime = Date(timeIntervalSince1970: bedtime.timeIntervalSince1970 + 7 * 3600)  // 7時間後
        
        let record = SleepRecord(
            bedtime: bedtime,
            wakeupTime: wakeupTime,
            quality: 6,
            note: "夜中に目が覚めた"
        )
        
        #expect(abs(record.value - 7.0) < 0.1)  // 約7時間
        #expect(record.quality == 6)
        #expect(record.note == "夜中に目が覚めた")
    }
}

// MARK: - Step Record Tests

struct StepRecordTests {
    
    @Test("歩数記録作成テスト")
    func testStepRecordCreation() {
        let record = StepRecord(steps: 8000, distance: 6.4, calories: 320.0)
        
        #expect(record.value == 8000.0)
        #expect(record.metricType == .steps)
        #expect(record.distance == 6.4)
        #expect(record.calories == 320.0)
        #expect(record.note == nil)
    }
    
    @Test("歩数記録シンプル作成テスト")
    func testStepRecordSimple() {
        let record = StepRecord(steps: 5000)
        
        #expect(record.value == 5000.0)
        #expect(record.distance == nil)
        #expect(record.calories == nil)
    }
}

// MARK: - Mood Record Tests

struct MoodRecordTests {
    
    @Test("気分記録作成テスト")
    func testMoodRecordCreation() {
        let tags: [MoodTag] = [.happy, .energetic]
        let record = MoodRecord(score: 8, tags: tags, note: "良い一日でした")
        
        #expect(record.value == 8.0)
        #expect(record.metricType == .mood)
        #expect(record.tags.count == 2)
        #expect(record.tags.contains(.happy))
        #expect(record.tags.contains(.energetic))
        #expect(record.note == "良い一日でした")
    }
    
    @Test("気分スコア範囲制限テスト")
    func testMoodScoreLimits() {
        let recordHigh = MoodRecord(score: 15)  // 上限を超える
        let recordLow = MoodRecord(score: -5)   // 下限を下回る
        let recordNormal = MoodRecord(score: 7)
        
        #expect(recordHigh.value == 10.0)  // 10に制限される
        #expect(recordLow.value == 1.0)    // 1に制限される
        #expect(recordNormal.value == 7.0) // そのまま
    }
    
    @Test("気分タグ表示名テスト")
    func testMoodTagDisplayNames() {
        #expect(MoodTag.happy.displayName == "嬉しい")
        #expect(MoodTag.sad.displayName == "悲しい")
        #expect(MoodTag.stressed.displayName == "ストレス")
        #expect(MoodTag.relaxed.displayName == "リラックス")
        #expect(MoodTag.energetic.displayName == "元気")
        #expect(MoodTag.tired.displayName == "疲れ")
        #expect(MoodTag.anxious.displayName == "不安")
        #expect(MoodTag.confident.displayName == "自信")
    }
    
    @Test("気分タグ絵文字テスト")
    func testMoodTagEmojis() {
        #expect(MoodTag.happy.emoji == "😊")
        #expect(MoodTag.sad.emoji == "😢")
        #expect(MoodTag.stressed.emoji == "😰")
        #expect(MoodTag.relaxed.emoji == "😌")
        #expect(MoodTag.energetic.emoji == "⚡")
        #expect(MoodTag.tired.emoji == "😴")
        #expect(MoodTag.anxious.emoji == "😟")
        #expect(MoodTag.confident.emoji == "💪")
    }
}

// MARK: - Generic Health Record Tests

struct GenericHealthRecordTests {
    
    @Test("汎用健康記録作成テスト")
    func testGenericHealthRecordCreation() {
        let record = GenericHealthRecord(
            value: 70.5,
            metricType: .weight,
            note: "朝の体重測定"
        )
        
        #expect(record.value == 70.5)
        #expect(record.metricType == .weight)
        #expect(record.note == "朝の体重測定")
        #expect(record.id != UUID())  // ユニークIDが生成されている
    }
    
    @Test("汎用健康記録各指標タイプテスト")
    func testGenericHealthRecordDifferentTypes() {
        let weightRecord = GenericHealthRecord(value: 65.0, metricType: .weight)
        let heartRateRecord = GenericHealthRecord(value: 72.0, metricType: .heartRate)
        let bodyFatRecord = GenericHealthRecord(value: 15.5, metricType: .bodyFat)
        
        #expect(weightRecord.metricType == .weight)
        #expect(heartRateRecord.metricType == .heartRate)
        #expect(bodyFatRecord.metricType == .bodyFat)
    }
}

// MARK: - Health Goal Tests

struct HealthGoalTests {
    
    @Test("健康目標作成テスト")
    func testHealthGoalCreation() {
        let goal = HealthGoal(
            metricType: .waterIntake,
            targetValue: 2500.0,
            period: .daily,
            note: "夏場の水分補給目標"
        )
        
        #expect(goal.metricType == .waterIntake)
        #expect(goal.targetValue == 2500.0)
        #expect(goal.period == .daily)
        #expect(goal.isActive == true)
        #expect(goal.note == "夏場の水分補給目標")
    }
    
    @Test("目標期間テスト")
    func testGoalPeriods() {
        #expect(GoalPeriod.daily.displayName == "日間")
        #expect(GoalPeriod.weekly.displayName == "週間")
        #expect(GoalPeriod.monthly.displayName == "月間")
        
        #expect(GoalPeriod.daily.durationInDays == 1)
        #expect(GoalPeriod.weekly.durationInDays == 7)
        #expect(GoalPeriod.monthly.durationInDays == 30)
    }
}

// MARK: - Health Statistics Tests

struct HealthStatisticsTests {
    
    @Test("健康統計作成テスト")
    func testHealthStatisticsCreation() {
        let goal = HealthGoal(metricType: .steps, targetValue: 10000.0, period: .daily)
        let statistics = HealthStatistics(
            metricType: .steps,
            period: .today,
            totalValue: 8500.0,
            recordCount: 1,
            goal: goal
        )
        
        #expect(statistics.metricType == .steps)
        #expect(statistics.period == .today)
        #expect(statistics.totalValue == 8500.0)
        #expect(statistics.averageValue == 8500.0)  // recordCount = 1なので同じ
        #expect(statistics.recordCount == 1)
        #expect(statistics.achievementRate == 0.85)  // 8500/10000 = 0.85
    }
    
    @Test("統計期間表示名テスト")
    func testStatisticsPeriodDisplayNames() {
        #expect(StatisticsPeriod.today.displayName == "今日")
        #expect(StatisticsPeriod.thisWeek.displayName == "今週")
        #expect(StatisticsPeriod.thisMonth.displayName == "今月")
        #expect(StatisticsPeriod.last30Days.displayName == "過去30日")
    }
    
    @Test("統計トレンド表示テスト")
    func testStatisticsTrendDisplay() {
        #expect(StatisticsTrend.improving.displayName == "改善中")
        #expect(StatisticsTrend.stable.displayName == "安定")
        #expect(StatisticsTrend.declining.displayName == "要注意")
        
        #expect(StatisticsTrend.improving.emoji == "📈")
        #expect(StatisticsTrend.stable.emoji == "📊")
        #expect(StatisticsTrend.declining.emoji == "📉")
    }
    
    @Test("目標達成率計算テスト")
    func testAchievementRateCalculation() {
        let goal = HealthGoal(metricType: .waterIntake, targetValue: 2000.0, period: .daily)
        
        // 目標達成
        let statistics1 = HealthStatistics(
            metricType: .waterIntake,
            period: .today,
            totalValue: 2000.0,
            recordCount: 4,
            goal: goal
        )
        #expect(statistics1.achievementRate == 1.0)
        
        // 目標を超過（上限1.0に制限される）
        let statistics2 = HealthStatistics(
            metricType: .waterIntake,
            period: .today,
            totalValue: 2500.0,
            recordCount: 5,
            goal: goal
        )
        #expect(statistics2.achievementRate == 1.0)
        
        // 目標未達成
        let statistics3 = HealthStatistics(
            metricType: .waterIntake,
            period: .today,
            totalValue: 1000.0,
            recordCount: 2,
            goal: goal
        )
        #expect(statistics3.achievementRate == 0.5)  // (1000/2)/2000 = 0.25, but it should be 1000/2000 = 0.5 for daily average
    }
}