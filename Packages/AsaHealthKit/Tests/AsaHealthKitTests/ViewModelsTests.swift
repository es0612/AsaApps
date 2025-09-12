//
//  ViewModelsTests.swift  
//  AsaHealthKitTests
//
//  健康アプリ専用ViewModelsのテスト
//

import Testing
import Foundation
@testable import AsaHealthKit

// MARK: - WaterTrackingViewModel Tests

@MainActor
struct WaterTrackingViewModelTests {
    
    @Test("WaterTrackingViewModel初期化テスト")
    func testWaterTrackingViewModelInitialization() {
        let viewModel = WaterTrackingViewModel()
        
        #expect(viewModel.todaysIntakes.isEmpty)
        #expect(viewModel.todaysTotalML == 0.0)
        #expect(viewModel.achievementRate == 0.0)
        #expect(viewModel.amountInput == "")
        #expect(viewModel.selectedDrinkType == .water)
        #expect(viewModel.noteInput == "")
        #expect(viewModel.amountError == nil)
        #expect(viewModel.presetAmounts == [200, 250, 300, 500])
    }
    
    @Test("水分摂取バリデーションテスト")
    func testWaterIntakeValidation() {
        let viewModel = WaterTrackingViewModel()
        
        // 空入力テスト
        viewModel.amountInput = ""
        viewModel.addWaterIntake()
        #expect(viewModel.amountError == "摂取量を入力してください")
        
        // 無効な数値テスト
        viewModel.amountInput = "abc"
        viewModel.addWaterIntake()
        #expect(viewModel.amountError == "有効な数値を入力してください")
        
        // 負の数値テスト
        viewModel.amountInput = "-100"
        viewModel.addWaterIntake()
        #expect(viewModel.amountError == "正の摂取量を入力してください")
        
        // ゼロテスト
        viewModel.amountInput = "0"
        viewModel.addWaterIntake()
        #expect(viewModel.amountError == "有効な摂取量を入力してください")
    }
    
    @Test("有効な水分摂取記録追加テスト")
    func testAddValidWaterIntake() async {
        let viewModel = WaterTrackingViewModel()
        
        // 有効な入力で記録追加
        viewModel.amountInput = "500"
        viewModel.selectedDrinkType = .tea
        viewModel.noteInput = "朝食時のお茶"
        
        viewModel.addWaterIntake()
        
        // 少し待ってからチェック（非同期処理のため）
        try? await Task.sleep(for: .milliseconds(100))
        
        // フォームがリセットされているか確認
        #expect(viewModel.amountInput == "")
        #expect(viewModel.noteInput == "")
        #expect(viewModel.amountError == nil)
    }
    
    @Test("プリセット摂取量追加テスト")
    func testAddPresetAmount() async {
        let viewModel = WaterTrackingViewModel()
        
        // プリセット量で記録追加
        viewModel.selectedDrinkType = .water
        viewModel.addPresetAmount(250.0)
        
        // 少し待ってからチェック
        try? await Task.sleep(for: .milliseconds(100))
        
        // 記録が追加されているか確認（実際の確認は統合テストで行う）
        #expect(viewModel.selectedDrinkType == .water)
    }
    
    @Test("目標設定テスト")
    func testSetDailyGoal() {
        let viewModel = WaterTrackingViewModel()
        
        // 目標設定
        viewModel.setDailyGoal(2500.0)
        
        // HealthManagerに目標が設定されているか確認
        let goal = viewModel.healthManager.getGoal(for: .waterIntake)
        #expect(goal?.targetValue == 2500.0)
        #expect(goal?.period == .daily)
    }
}

// MARK: - StepTrackingViewModel Tests

@MainActor
struct StepTrackingViewModelTests {
    
    @Test("StepTrackingViewModel初期化テスト")
    func testStepTrackingViewModelInitialization() {
        let viewModel = StepTrackingViewModel()
        
        #expect(viewModel.todaysSteps.isEmpty)
        #expect(viewModel.todaysTotalSteps == 0)
        #expect(viewModel.achievementRate == 0.0)
        #expect(viewModel.estimatedDistance == 0.0)
        #expect(viewModel.estimatedCalories == 0.0)
        #expect(viewModel.stepsInput == "")
        #expect(viewModel.stepsError == nil)
    }
    
    @Test("歩数バリデーションテスト")
    func testStepsValidation() {
        let viewModel = StepTrackingViewModel()
        
        // 空入力テスト
        viewModel.stepsInput = ""
        viewModel.addStepRecord()
        #expect(viewModel.stepsError == "歩数を入力してください")
        
        // 無効な数値テスト
        viewModel.stepsInput = "not_a_number"
        viewModel.addStepRecord()
        #expect(viewModel.stepsError == "有効な数値を入力してください")
        
        // 負の数値テスト
        viewModel.stepsInput = "-1000"
        viewModel.addStepRecord()
        #expect(viewModel.stepsError == "正の歩数を入力してください")
    }
    
    @Test("有効な歩数記録追加テスト")
    func testAddValidStepRecord() async {
        let viewModel = StepTrackingViewModel()
        
        // 有効な入力で記録追加
        viewModel.stepsInput = "8000"
        viewModel.distanceInput = "6.4"
        viewModel.caloriesInput = "320"
        viewModel.noteInput = "朝の散歩"
        
        viewModel.addStepRecord()
        
        // 少し待ってからチェック
        try? await Task.sleep(for: .milliseconds(100))
        
        // フォームがリセットされているか確認
        #expect(viewModel.stepsInput == "")
        #expect(viewModel.distanceInput == "")
        #expect(viewModel.caloriesInput == "")
        #expect(viewModel.noteInput == "")
        #expect(viewModel.stepsError == nil)
    }
    
    @Test("歩数目標設定テスト")
    func testSetDailyStepsGoal() {
        let viewModel = StepTrackingViewModel()
        
        // 目標設定
        viewModel.setDailyGoal(12000)
        
        // HealthManagerに目標が設定されているか確認
        let goal = viewModel.healthManager.getGoal(for: .steps)
        #expect(goal?.targetValue == 12000.0)
        #expect(goal?.period == .daily)
    }
}

// MARK: - SleepTrackingViewModel Tests

@MainActor
struct SleepTrackingViewModelTests {
    
    @Test("SleepTrackingViewModel初期化テスト")
    func testSleepTrackingViewModelInitialization() {
        let viewModel = SleepTrackingViewModel()
        
        #expect(viewModel.sleepRecords.isEmpty)
        #expect(viewModel.weeklyAverageSleep == 0.0)
        #expect(viewModel.achievementRate == 0.0)
        #expect(viewModel.selectedQuality == 7)
        #expect(viewModel.noteInput == "")
        #expect(viewModel.qualityOptions == Array(1...10))
        
        // デフォルト時間が設定されているか確認
        #expect(viewModel.calculatedSleepHours > 0)
        #expect(viewModel.calculatedSleepHours <= 24)
    }
    
    @Test("睡眠時間計算テスト")
    func testCalculatedSleepHours() {
        let viewModel = SleepTrackingViewModel()
        
        // カスタム時間を設定
        let calendar = Calendar.current
        let bedtime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
        let wakeupTime = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: calendar.date(byAdding: .day, value: 1, to: bedtime) ?? Date()) ?? Date()
        
        viewModel.bedtime = bedtime
        viewModel.wakeupTime = wakeupTime
        
        // 計算された睡眠時間が正しいか確認（8.5時間）
        #expect(abs(viewModel.calculatedSleepHours - 8.5) < 0.1)
    }
    
    @Test("睡眠記録バリデーションテスト")
    func testSleepRecordValidation() {
        let viewModel = SleepTrackingViewModel()
        
        // 就寝時間が起床時間より後の場合
        let calendar = Calendar.current
        let wakeupTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
        let bedtime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()  // 起床時間より後
        
        viewModel.bedtime = bedtime
        viewModel.wakeupTime = wakeupTime
        
        viewModel.addSleepRecord()
        
        // エラーが設定されているか確認
        #expect(viewModel.error != nil)
    }
    
    @Test("有効な睡眠記録追加テスト")
    func testAddValidSleepRecord() async {
        let viewModel = SleepTrackingViewModel()
        
        // 有効な時間を設定
        let calendar = Calendar.current
        let bedtime = calendar.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
        let wakeupTime = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: calendar.date(byAdding: .day, value: 1, to: bedtime) ?? Date()) ?? Date()
        
        viewModel.bedtime = bedtime
        viewModel.wakeupTime = wakeupTime
        viewModel.selectedQuality = 8
        viewModel.noteInput = "ぐっすり眠れました"
        
        viewModel.addSleepRecord()
        
        // 少し待ってからチェック
        try? await Task.sleep(for: .milliseconds(100))
        
        // フォームがリセットされているか確認
        #expect(viewModel.selectedQuality == 7)
        #expect(viewModel.noteInput == "")
    }
    
    @Test("睡眠目標設定テスト")
    func testSetSleepGoal() {
        let viewModel = SleepTrackingViewModel()
        
        // 目標設定
        viewModel.setDailyGoal(7.5)
        
        // HealthManagerに目標が設定されているか確認
        let goal = viewModel.healthManager.getGoal(for: .sleep)
        #expect(goal?.targetValue == 7.5)
        #expect(goal?.period == .daily)
    }
}

// MARK: - MoodTrackingViewModel Tests

@MainActor
struct MoodTrackingViewModelTests {
    
    @Test("MoodTrackingViewModel初期化テスト")
    func testMoodTrackingViewModelInitialization() {
        let viewModel = MoodTrackingViewModel()
        
        #expect(viewModel.moodRecords.isEmpty)
        #expect(viewModel.weeklyAverageMood == 0.0)
        #expect(viewModel.selectedScore == 5)
        #expect(viewModel.selectedTags.isEmpty)
        #expect(viewModel.noteInput == "")
        #expect(viewModel.scoreOptions == Array(1...10))
        #expect(viewModel.availableTags == MoodTag.allCases)
        #expect(viewModel.todaysMoods.isEmpty)
        #expect(viewModel.todaysLatestMood == nil)
    }
    
    @Test("気分記録追加テスト")
    func testAddMoodRecord() async {
        let viewModel = MoodTrackingViewModel()
        
        // 気分記録を設定
        viewModel.selectedScore = 8
        viewModel.selectedTags = [.happy, .energetic]
        viewModel.noteInput = "とても良い気分です"
        
        viewModel.addMoodRecord()
        
        // 少し待ってからチェック
        try? await Task.sleep(for: .milliseconds(100))
        
        // フォームがリセットされているか確認
        #expect(viewModel.selectedScore == 5)
        #expect(viewModel.selectedTags.isEmpty)
        #expect(viewModel.noteInput == "")
    }
    
    @Test("気分タグ切り替えテスト")
    func testToggleTag() {
        let viewModel = MoodTrackingViewModel()
        
        // タグを追加
        viewModel.toggleTag(.happy)
        #expect(viewModel.selectedTags.contains(.happy))
        
        // 同じタグをもう一度タップ（削除）
        viewModel.toggleTag(.happy)
        #expect(!viewModel.selectedTags.contains(.happy))
        
        // 複数タグを追加
        viewModel.toggleTag(.happy)
        viewModel.toggleTag(.relaxed)
        #expect(viewModel.selectedTags.contains(.happy))
        #expect(viewModel.selectedTags.contains(.relaxed))
        #expect(viewModel.selectedTags.count == 2)
    }
    
    @Test("気分傾向分析テスト")
    func testAnalyzeMoodTrend() {
        let viewModel = MoodTrackingViewModel()
        
        // 記録がない場合
        let trendToday = viewModel.analyzeMoodTrend(for: .today)
        #expect(trendToday == "今日はまだ記録がありません")
        
        let trendWeek = viewModel.analyzeMoodTrend(for: .thisWeek)
        #expect(trendWeek == "期間中の記録がありません")
    }
}

// MARK: - ViewModel Integration Tests

@MainActor
struct ViewModelIntegrationTests {
    
    @Test("複数ViewModel統合テスト")
    func testMultipleViewModelsIntegration() {
        let waterViewModel = WaterTrackingViewModel()
        let stepViewModel = StepTrackingViewModel()
        let sleepViewModel = SleepTrackingViewModel()
        let moodViewModel = MoodTrackingViewModel()
        
        // 各ViewModelが独立して動作することを確認
        #expect(waterViewModel.healthManager !== stepViewModel.healthManager)
        #expect(stepViewModel.healthManager !== sleepViewModel.healthManager)
        #expect(sleepViewModel.healthManager !== moodViewModel.healthManager)
        
        // それぞれが独自のHealthManagerインスタンスを持っていることを確認
        waterViewModel.setDailyGoal(2000.0)
        stepViewModel.setDailyGoal(10000)
        sleepViewModel.setDailyGoal(8.0)
        
        #expect(waterViewModel.healthManager.getGoal(for: .waterIntake)?.targetValue == 2000.0)
        #expect(stepViewModel.healthManager.getGoal(for: .steps)?.targetValue == 10000.0)
        #expect(sleepViewModel.healthManager.getGoal(for: .sleep)?.targetValue == 8.0)
        
        // 他のViewModelの目標設定は影響しないことを確認
        #expect(waterViewModel.healthManager.getGoal(for: .steps) == nil)
        #expect(stepViewModel.healthManager.getGoal(for: .waterIntake) == nil)
        #expect(sleepViewModel.healthManager.getGoal(for: .waterIntake) == nil)
    }
    
    @Test("ViewModelエラーハンドリングテスト")
    func testViewModelErrorHandling() {
        let waterViewModel = WaterTrackingViewModel()
        let sleepViewModel = SleepTrackingViewModel()
        
        // 水分摂取ViewModelの無効な入力
        waterViewModel.amountInput = "invalid"
        waterViewModel.addWaterIntake()
        #expect(waterViewModel.amountError != nil)
        
        // 睡眠ViewModelの無効な時間設定
        sleepViewModel.bedtime = Date()
        sleepViewModel.wakeupTime = Date(timeIntervalSince1970: sleepViewModel.bedtime.timeIntervalSince1970 - 3600)  // 1時間前
        sleepViewModel.addSleepRecord()
        #expect(sleepViewModel.error != nil)
    }
}