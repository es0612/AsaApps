//
//  HealthManagerTests.swift
//  AsaHealthKitTests
//
//  HealthManager中央管理クラスのテスト
//

import Testing
import Foundation
@testable import AsaHealthKit

// MARK: - HealthManager Tests

@MainActor
struct HealthManagerTests {
    
    @Test("HealthManager初期化テスト")
    func testHealthManagerInitialization() {
        let healthManager = HealthManager()
        
        #expect(healthManager.isLoading == false)
        #expect(healthManager.error == nil)
        #expect(healthManager.healthGoals.isEmpty)
        #expect(healthManager.currentStatistics.isEmpty)
        #expect(healthManager.selectedPeriod == .today)
    }
    
    @Test("健康目標設定テスト")
    func testSetHealthGoal() async throws {
        let healthManager = HealthManager()
        
        // 水分摂取目標を設定
        try await healthManager.setGoal(
            for: .waterIntake, 
            targetValue: 2500.0, 
            period: .daily,
            note: "夏場の水分補給"
        )
        
        // 目標が正しく設定されているか確認
        let goal = healthManager.getGoal(for: .waterIntake)
        #expect(goal != nil)
        #expect(goal?.targetValue == 2500.0)
        #expect(goal?.period == .daily)
        #expect(goal?.note == "夏場の水分補給")
        #expect(goal?.isActive == true)
    }
    
    @Test("健康目標更新テスト")
    func testUpdateHealthGoal() async throws {
        let healthManager = HealthManager()
        
        // 最初の目標を設定
        try await healthManager.setGoal(for: .steps, targetValue: 8000.0, period: .daily)
        let firstGoal = healthManager.getGoal(for: .steps)
        #expect(firstGoal?.targetValue == 8000.0)
        
        // 目標を更新
        try await healthManager.setGoal(for: .steps, targetValue: 12000.0, period: .daily)
        let updatedGoal = healthManager.getGoal(for: .steps)
        #expect(updatedGoal?.targetValue == 12000.0)
        
        // 古い目標は非アクティブになっているはず
        let activeGoals = healthManager.healthGoals.filter { $0.isActive && $0.metricType == .steps }
        #expect(activeGoals.count == 1)
        #expect(activeGoals.first?.targetValue == 12000.0)
    }
    
    @Test("水分摂取記録追加テスト")
    func testAddWaterIntakeRecord() async throws {
        let healthManager = HealthManager()
        
        // 目標を設定
        try await healthManager.setGoal(for: .waterIntake, targetValue: 2000.0, period: .daily)
        
        // 水分摂取記録を追加
        let record = WaterIntakeRecord(amount: 500.0, drinkType: .water, note: "朝の水分補給")
        try await healthManager.addRecord(record)
        
        // 記録が正しく追加されているか確認
        let records = healthManager.getRecords(for: .waterIntake, as: WaterIntakeRecord.self)
        #expect(records.count == 1)
        #expect(records.first?.value == 500.0)
        #expect(records.first?.drinkType == .water)
        #expect(records.first?.note == "朝の水分補給")
    }
    
    @Test("歩数記録追加テスト")
    func testAddStepRecord() async throws {
        let healthManager = HealthManager()
        
        // 歩数記録を追加
        let record = StepRecord(steps: 7500, distance: 6.0, calories: 300.0)
        try await healthManager.addRecord(record)
        
        // 記録が正しく追加されているか確認
        let records = healthManager.getRecords(for: .steps, as: StepRecord.self)
        #expect(records.count == 1)
        #expect(records.first?.value == 7500.0)
        #expect(records.first?.distance == 6.0)
        #expect(records.first?.calories == 300.0)
    }
    
    @Test("睡眠記録追加テスト")
    func testAddSleepRecord() async throws {
        let healthManager = HealthManager()
        
        // 睡眠記録を追加
        let bedtime = Date()
        let wakeupTime = Date(timeIntervalSince1970: bedtime.timeIntervalSince1970 + 8 * 3600)  // 8時間後
        let record = SleepRecord(bedtime: bedtime, wakeupTime: wakeupTime, quality: 8)
        try await healthManager.addRecord(record)
        
        // 記録が正しく追加されているか確認
        let records = healthManager.getRecords(for: .sleep, as: SleepRecord.self)
        #expect(records.count == 1)
        #expect(abs(records.first!.value - 8.0) < 0.1)  // 約8時間
        #expect(records.first?.quality == 8)
    }
    
    @Test("気分記録追加テスト")
    func testAddMoodRecord() async throws {
        let healthManager = HealthManager()
        
        // 気分記録を追加
        let record = MoodRecord(score: 7, tags: [.happy, .relaxed], note: "良い気分です")
        try await healthManager.addRecord(record)
        
        // 記録が正しく追加されているか確認
        let records = healthManager.getRecords(for: .mood, as: MoodRecord.self)
        #expect(records.count == 1)
        #expect(records.first?.value == 7.0)
        #expect(records.first?.tags.contains(.happy) == true)
        #expect(records.first?.tags.contains(.relaxed) == true)
        #expect(records.first?.note == "良い気分です")
    }
    
    @Test("記録削除テスト")
    func testDeleteRecord() async throws {
        let healthManager = HealthManager()
        
        // 記録を追加
        let record = WaterIntakeRecord(amount: 300.0, drinkType: .tea)
        try await healthManager.addRecord(record)
        
        // 記録が追加されていることを確認
        var records = healthManager.getRecords(for: .waterIntake, as: WaterIntakeRecord.self)
        #expect(records.count == 1)
        
        // 記録を削除
        try await healthManager.deleteRecord(id: record.id, metricType: .waterIntake)
        
        // 記録が削除されていることを確認
        records = healthManager.getRecords(for: .waterIntake, as: WaterIntakeRecord.self)
        #expect(records.count == 0)
    }
    
    @Test("汎用健康記録追加テスト")
    func testAddGenericHealthRecord() async throws {
        let healthManager = HealthManager()
        
        // 体重記録を追加
        let weightRecord = GenericHealthRecord(value: 70.5, metricType: .weight, note: "朝の体重測定")
        try await healthManager.addRecord(weightRecord)
        
        // 心拍数記録を追加
        let heartRateRecord = GenericHealthRecord(value: 68.0, metricType: .heartRate)
        try await healthManager.addRecord(heartRateRecord)
        
        // 記録が正しく追加されているか確認
        let weightRecords = healthManager.getRecords(for: .weight, as: GenericHealthRecord.self)
        let heartRateRecords = healthManager.getRecords(for: .heartRate, as: GenericHealthRecord.self)
        
        #expect(weightRecords.count == 1)
        #expect(weightRecords.first?.value == 70.5)
        #expect(weightRecords.first?.note == "朝の体重測定")
        
        #expect(heartRateRecords.count == 1)
        #expect(heartRateRecords.first?.value == 68.0)
    }
    
    @Test("統計期間変更テスト")
    func testChangePeriod() async throws {
        let healthManager = HealthManager()
        
        // 期間を変更
        healthManager.changePeriod(to: .thisWeek)
        #expect(healthManager.selectedPeriod == .thisWeek)
        
        healthManager.changePeriod(to: .thisMonth)
        #expect(healthManager.selectedPeriod == .thisMonth)
        
        healthManager.changePeriod(to: .last30Days)
        #expect(healthManager.selectedPeriod == .last30Days)
    }
    
    @Test("統計情報取得テスト")
    func testGetStatistics() async throws {
        let healthManager = HealthManager()
        
        // 目標を設定
        try await healthManager.setGoal(for: .waterIntake, targetValue: 2000.0, period: .daily)
        
        // 記録を追加
        let record1 = WaterIntakeRecord(amount: 500.0, drinkType: .water)
        let record2 = WaterIntakeRecord(amount: 300.0, drinkType: .tea)
        try await healthManager.addRecord(record1)
        try await healthManager.addRecord(record2)
        
        // 統計情報を取得
        let statistics = healthManager.getStatistics(for: .waterIntake)
        #expect(statistics != nil)
        #expect(statistics?.metricType == .waterIntake)
        #expect(statistics?.totalValue == 800.0)
        #expect(statistics?.recordCount == 2)
        #expect(statistics?.averageValue == 400.0)
    }
}

// MARK: - Integration Tests

@MainActor  
struct HealthManagerIntegrationTests {
    
    @Test("複数指標統合テスト")
    func testMultipleMetricsIntegration() async throws {
        let healthManager = HealthManager()
        
        // 複数の目標を設定
        try await healthManager.setGoal(for: .waterIntake, targetValue: 2000.0, period: .daily)
        try await healthManager.setGoal(for: .steps, targetValue: 10000.0, period: .daily)
        try await healthManager.setGoal(for: .sleep, targetValue: 8.0, period: .daily)
        
        // 各指標の記録を追加
        try await healthManager.addRecord(WaterIntakeRecord(amount: 500.0, drinkType: .water))
        try await healthManager.addRecord(StepRecord(steps: 7500))
        
        let bedtime = Date()
        let wakeupTime = Date(timeIntervalSince1970: bedtime.timeIntervalSince1970 + 7.5 * 3600)
        try await healthManager.addRecord(SleepRecord(bedtime: bedtime, wakeupTime: wakeupTime, quality: 7))
        
        // 各指標の記録が正しく管理されているか確認
        let waterRecords = healthManager.getRecords(for: .waterIntake, as: WaterIntakeRecord.self)
        let stepRecords = healthManager.getRecords(for: .steps, as: StepRecord.self)
        let sleepRecords = healthManager.getRecords(for: .sleep, as: SleepRecord.self)
        
        #expect(waterRecords.count == 1)
        #expect(stepRecords.count == 1)
        #expect(sleepRecords.count == 1)
        
        // 各指標の目標が設定されているか確認
        #expect(healthManager.getGoal(for: .waterIntake)?.targetValue == 2000.0)
        #expect(healthManager.getGoal(for: .steps)?.targetValue == 10000.0)
        #expect(healthManager.getGoal(for: .sleep)?.targetValue == 8.0)
    }
    
    @Test("今日のサマリー取得テスト")
    func testGetTodaysSummary() async throws {
        let healthManager = HealthManager()
        
        // 複数の目標と記録を設定
        try await healthManager.setGoal(for: .waterIntake, targetValue: 2000.0, period: .daily)
        try await healthManager.setGoal(for: .steps, targetValue: 10000.0, period: .daily)
        
        try await healthManager.addRecord(WaterIntakeRecord(amount: 1800.0, drinkType: .water))  // 90%達成
        try await healthManager.addRecord(StepRecord(steps: 12000))  // 120%達成（上限100%）
        
        // 今日のサマリーを取得
        let summary = healthManager.getTodaysSummary()
        
        // サマリーが取得できているか確認
        #expect(summary.count >= 2)
        
        // 達成率順にソートされているか確認（高い順）
        if summary.count >= 2 {
            #expect(summary[0].achievementRate >= summary[1].achievementRate)
        }
    }
}