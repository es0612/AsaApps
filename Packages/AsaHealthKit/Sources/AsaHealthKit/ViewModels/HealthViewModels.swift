//
//  HealthViewModels.swift
//  AsaHealthKit
//
//  健康関連アプリ専用ViewModels
//  AsaWaterTracker、AsaSleepAnalyzer、AsaStepCounter、AsaMoodTracker等で使用
//

import Foundation
import AsaCoreKit
import Observation

// MARK: - 水分追跡ViewModel

/// 水分摂取追跡専用ViewModel（AsaWaterTracker用）
@MainActor
@Observable
public final class WaterTrackingViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    /// 健康データ管理
    public let healthManager = HealthManager()
    
    /// 今日の水分摂取記録
    public var todaysIntakes: [WaterIntakeRecord] = []
    
    /// 今日の合計摂取量（ml）
    public var todaysTotalML: Double = 0.0
    
    /// 目標達成率
    public var achievementRate: Double = 0.0
    
    /// フォーム入力
    public var amountInput: String = ""
    public var selectedDrinkType: DrinkType = .water
    public var noteInput: String = ""
    
    /// 入力バリデーションエラー
    public var amountError: String?
    
    /// プリセット摂取量（ml）
    public let presetAmounts = [200, 250, 300, 500]
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        initialize()
    }
    
    public override func initialize() {
        super.initialize()
        refresh()
    }
    
    public override func refresh() {
        safeAsync {
            await self.loadTodaysData()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTodaysData() async {
        todaysIntakes = healthManager.getRecords(for: .waterIntake, as: WaterIntakeRecord.self)
            .filter { Calendar.current.isDateInToday($0.recordedAt) }
            .sorted { $0.recordedAt > $1.recordedAt }
        
        todaysTotalML = todaysIntakes.reduce(0) { $0 + $1.value }
        
        if let statistics = healthManager.getStatistics(for: .waterIntake) {
            achievementRate = statistics.achievementRate
        }
    }
    
    // MARK: - Water Intake Management
    
    /// 水分摂取を記録
    public func addWaterIntake() {
        validateAmount()
        guard amountError == nil else { return }
        
        guard let amount = Double(amountInput), amount > 0 else {
            if Double(amountInput) == 0 {
                amountError = "有効な摂取量を入力してください"
            } else {
                amountError = "有効な摂取量を入力してください"
            }
            return
        }
        
        safeAsync {
            let record = WaterIntakeRecord(
                amount: amount,
                drinkType: self.selectedDrinkType,
                recordedAt: Date(),
                note: self.noteInput.isEmpty ? nil : self.noteInput
            )
            
            try await self.healthManager.addRecord(record)
            await self.loadTodaysData()
            
            // フォームをリセット
            self.amountInput = ""
            self.noteInput = ""
            self.amountError = nil
            
            if AsaHealthKitLib.debugMode {
                print("💧 水分摂取記録: \(amount)ml - \(self.selectedDrinkType.displayName)")
            }
        }
    }
    
    /// プリセット摂取量で記録
    public func addPresetAmount(_ amount: Double) {
        safeAsync {
            let record = WaterIntakeRecord(
                amount: amount,
                drinkType: self.selectedDrinkType,
                recordedAt: Date()
            )
            
            try await self.healthManager.addRecord(record)
            await self.loadTodaysData()
        }
    }
    
    /// 摂取記録を削除
    public func deleteIntake(_ record: WaterIntakeRecord) {
        safeAsync {
            try await self.healthManager.deleteRecord(id: record.id, metricType: .waterIntake)
            await self.loadTodaysData()
        }
    }
    
    /// 目標を設定
    public func setDailyGoal(_ targetML: Double) {
        safeAsync {
            try await self.healthManager.setGoal(for: .waterIntake, targetValue: targetML, period: .daily)
        }
    }
    
    // MARK: - Validation
    
    private func validateAmount() {
        let validators: [any Validator<String>] = [
            ValidationEngine.required,
            ValidationEngine.number,
            ValidationEngine.positiveNumber
        ]
        
        if let error = ValidationEngine.validateString(amountInput, with: validators) {
            switch error {
            case .empty:
                amountError = "摂取量を入力してください"
            case .notANumber:
                amountError = "有効な数値を入力してください"
            case .notPositive:
                amountError = "正の摂取量を入力してください"
            default:
                amountError = "有効な摂取量を入力してください"
            }
        } else {
            amountError = nil
        }
    }
}

// MARK: - 歩数追跡ViewModel

/// 歩数追跡専用ViewModel（AsaStepCounter用）
@MainActor
@Observable
public final class StepTrackingViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    /// 健康データ管理
    public let healthManager = HealthManager()
    
    /// 今日の歩数記録
    public var todaysSteps: [StepRecord] = []
    
    /// 今日の合計歩数
    public var todaysTotalSteps: Int = 0
    
    /// 目標達成率
    public var achievementRate: Double = 0.0
    
    /// 今日の推定距離（km）
    public var estimatedDistance: Double = 0.0
    
    /// 今日の推定カロリー消費
    public var estimatedCalories: Double = 0.0
    
    /// フォーム入力
    public var stepsInput: String = ""
    public var distanceInput: String = ""
    public var caloriesInput: String = ""
    public var noteInput: String = ""
    
    /// 入力バリデーションエラー
    public var stepsError: String?
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        initialize()
    }
    
    public override func initialize() {
        super.initialize()
        refresh()
    }
    
    public override func refresh() {
        safeAsync {
            await self.loadTodaysData()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTodaysData() async {
        todaysSteps = healthManager.getRecords(for: .steps, as: StepRecord.self)
            .filter { Calendar.current.isDateInToday($0.recordedAt) }
            .sorted { $0.recordedAt > $1.recordedAt }
        
        todaysTotalSteps = Int(todaysSteps.reduce(0) { $0 + $1.value })
        
        // 推定値計算
        estimatedDistance = Double(todaysTotalSteps) * 0.0008  // 1歩=約0.8m
        estimatedCalories = Double(todaysTotalSteps) * 0.04    // 1歩=約0.04kcal
        
        if let statistics = healthManager.getStatistics(for: .steps) {
            achievementRate = statistics.achievementRate
        }
    }
    
    // MARK: - Step Management
    
    /// 歩数を記録
    public func addStepRecord() {
        validateSteps()
        guard stepsError == nil else { return }
        
        guard let steps = Int(stepsInput), steps > 0 else {
            stepsError = "有効な歩数を入力してください"
            return
        }
        
        safeAsync {
            let distance = self.distanceInput.isEmpty ? nil : Double(self.distanceInput)
            let calories = self.caloriesInput.isEmpty ? nil : Double(self.caloriesInput)
            
            let record = StepRecord(
                steps: steps,
                distance: distance,
                calories: calories,
                recordedAt: Date(),
                note: self.noteInput.isEmpty ? nil : self.noteInput
            )
            
            try await self.healthManager.addRecord(record)
            await self.loadTodaysData()
            
            // フォームをリセット
            self.stepsInput = ""
            self.distanceInput = ""
            self.caloriesInput = ""
            self.noteInput = ""
            self.stepsError = nil
        }
    }
    
    /// 歩数記録を削除
    public func deleteStepRecord(_ record: StepRecord) {
        safeAsync {
            try await self.healthManager.deleteRecord(id: record.id, metricType: .steps)
            await self.loadTodaysData()
        }
    }
    
    /// 歩数目標を設定
    public func setDailyGoal(_ targetSteps: Int) {
        safeAsync {
            try await self.healthManager.setGoal(for: .steps, targetValue: Double(targetSteps), period: .daily)
        }
    }
    
    // MARK: - Validation
    
    private func validateSteps() {
        let validators: [any Validator<String>] = [
            ValidationEngine.required,
            ValidationEngine.number,
            ValidationEngine.positiveNumber
        ]
        
        if let error = ValidationEngine.validateString(stepsInput, with: validators) {
            switch error {
            case .empty:
                stepsError = "歩数を入力してください"
            case .notANumber:
                stepsError = "有効な数値を入力してください"
            case .notPositive:
                stepsError = "正の歩数を入力してください"
            default:
                stepsError = "有効な歩数を入力してください"
            }
        } else {
            stepsError = nil
        }
    }
}

// MARK: - 睡眠追跡ViewModel

/// 睡眠追跡専用ViewModel（AsaSleepAnalyzer用）
@MainActor
@Observable
public final class SleepTrackingViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    /// 健康データ管理
    public let healthManager = HealthManager()
    
    /// 睡眠記録
    public var sleepRecords: [SleepRecord] = []
    
    /// 今週の平均睡眠時間
    public var weeklyAverageSleep: Double = 0.0
    
    /// 目標達成率
    public var achievementRate: Double = 0.0
    
    /// フォーム入力
    public var bedtime = Date()
    public var wakeupTime = Date()
    public var selectedQuality: Int = 7
    public var noteInput: String = ""
    
    /// 計算された睡眠時間（時間）
    public var calculatedSleepHours: Double {
        return wakeupTime.timeIntervalSince(bedtime) / 3600
    }
    
    /// 睡眠の質オプション
    public let qualityOptions = Array(1...10)
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        
        // デフォルト時間を設定（昨日22:00〜今日6:00）
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        bedtime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: yesterday) ?? Date()
        wakeupTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
        
        initialize()
    }
    
    public override func initialize() {
        super.initialize()
        refresh()
    }
    
    public override func refresh() {
        safeAsync {
            await self.loadSleepData()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadSleepData() async {
        sleepRecords = healthManager.getRecords(for: .sleep, as: SleepRecord.self)
            .sorted { $0.recordedAt > $1.recordedAt }
        
        // 今週の平均睡眠時間を計算
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let thisWeekRecords = sleepRecords.filter { $0.recordedAt >= weekStart }
        
        if !thisWeekRecords.isEmpty {
            weeklyAverageSleep = thisWeekRecords.reduce(0) { $0 + $1.value } / Double(thisWeekRecords.count)
        }
        
        if let statistics = healthManager.getStatistics(for: .sleep) {
            achievementRate = statistics.achievementRate
        }
    }
    
    // MARK: - Sleep Management
    
    /// 睡眠記録を追加
    public func addSleepRecord() {
        guard bedtime < wakeupTime else {
            error = AsaCoreError.validationFailed("就寝時間は起床時間より前である必要があります")
            return
        }
        
        guard calculatedSleepHours > 0 && calculatedSleepHours <= 24 else {
            error = AsaCoreError.validationFailed("睡眠時間が無効です（0-24時間の範囲で入力してください）")
            return
        }
        
        safeAsync {
            let record = SleepRecord(
                bedtime: self.bedtime,
                wakeupTime: self.wakeupTime,
                quality: self.selectedQuality,
                note: self.noteInput.isEmpty ? nil : self.noteInput
            )
            
            try await self.healthManager.addRecord(record)
            await self.loadSleepData()
            
            // フォームをリセット
            self.selectedQuality = 7
            self.noteInput = ""
            
            if AsaHealthKitLib.debugMode {
                print("😴 睡眠記録: \(String(format: "%.1f", record.value))時間 - 質: \(self.selectedQuality)/10")
            }
        }
    }
    
    /// 睡眠記録を削除
    public func deleteSleepRecord(_ record: SleepRecord) {
        safeAsync {
            try await self.healthManager.deleteRecord(id: record.id, metricType: .sleep)
            await self.loadSleepData()
        }
    }
    
    /// 睡眠目標を設定
    public func setDailyGoal(_ targetHours: Double) {
        safeAsync {
            try await self.healthManager.setGoal(for: .sleep, targetValue: targetHours, period: .daily)
        }
    }
}

// MARK: - 気分追跡ViewModel

/// 気分追跡専用ViewModel（AsaMoodTracker用）
@MainActor
@Observable
public final class MoodTrackingViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    /// 健康データ管理
    public let healthManager = HealthManager()
    
    /// 気分記録
    public var moodRecords: [MoodRecord] = []
    
    /// 今週の平均気分スコア
    public var weeklyAverageMood: Double = 0.0
    
    /// フォーム入力
    public var selectedScore: Int = 5
    public var selectedTags: Set<MoodTag> = []
    public var noteInput: String = ""
    
    /// 気分スコアオプション（1-10）
    public let scoreOptions = Array(1...10)
    
    /// 利用可能な気分タグ
    public let availableTags = MoodTag.allCases
    
    // MARK: - Computed Properties
    
    /// 今日の気分記録
    public var todaysMoods: [MoodRecord] {
        return moodRecords.filter { Calendar.current.isDateInToday($0.recordedAt) }
    }
    
    /// 今日の最新気分スコア
    public var todaysLatestMood: MoodRecord? {
        return todaysMoods.sorted { $0.recordedAt > $1.recordedAt }.first
    }
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        initialize()
    }
    
    public override func initialize() {
        super.initialize()
        refresh()
    }
    
    public override func refresh() {
        safeAsync {
            await self.loadMoodData()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadMoodData() async {
        moodRecords = healthManager.getRecords(for: .mood, as: MoodRecord.self)
            .sorted { $0.recordedAt > $1.recordedAt }
        
        // 今週の平均気分を計算
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let thisWeekRecords = moodRecords.filter { $0.recordedAt >= weekStart }
        
        if !thisWeekRecords.isEmpty {
            weeklyAverageMood = thisWeekRecords.reduce(0) { $0 + $1.value } / Double(thisWeekRecords.count)
        }
    }
    
    // MARK: - Mood Management
    
    /// 気分記録を追加
    public func addMoodRecord() {
        safeAsync {
            let record = MoodRecord(
                score: self.selectedScore,
                tags: Array(self.selectedTags),
                recordedAt: Date(),
                note: self.noteInput.isEmpty ? nil : self.noteInput
            )
            
            try await self.healthManager.addRecord(record)
            await self.loadMoodData()
            
            // フォームをリセット
            self.selectedScore = 5
            self.selectedTags.removeAll()
            self.noteInput = ""
            
            if AsaHealthKitLib.debugMode {
                print("😊 気分記録: \(self.selectedScore)/10 - タグ: \(self.selectedTags.map { $0.displayName }.joined(separator: ", "))")
            }
        }
    }
    
    /// 気分記録を削除
    public func deleteMoodRecord(_ record: MoodRecord) {
        safeAsync {
            try await self.healthManager.deleteRecord(id: record.id, metricType: .mood)
            await self.loadMoodData()
        }
    }
    
    /// 気分タグを切り替え
    public func toggleTag(_ tag: MoodTag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    /// 気分の傾向を分析（簡易版）
    public func analyzeMoodTrend(for period: StatisticsPeriod = .last30Days) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch period {
        case .today:
            return todaysMoods.isEmpty ? "今日はまだ記録がありません" : "今日の気分: \(todaysLatestMood?.value ?? 0)/10"
        case .thisWeek:
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .thisMonth:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        }
        
        let periodRecords = moodRecords.filter { $0.recordedAt >= startDate }
        
        if periodRecords.isEmpty {
            return "期間中の記録がありません"
        }
        
        let averageScore = periodRecords.reduce(0) { $0 + $1.value } / Double(periodRecords.count)
        let trend = averageScore >= 7.0 ? "良好" : averageScore >= 5.0 ? "普通" : "要注意"
        
        return "\(period.displayName)の平均: \(String(format: "%.1f", averageScore))/10 (\(trend))"
    }
}