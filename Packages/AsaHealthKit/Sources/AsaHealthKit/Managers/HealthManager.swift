//
//  HealthManager.swift
//  AsaHealthKit
//
//  健康指標の中央管理クラス
//  目標設定、進捗追跡、統計計算を一元管理
//

import Foundation
import AsaCoreKit
import Observation

// MARK: - 健康目標モデル

/// 健康目標設定
public struct HealthGoal: CRUDModel {
    public let id: UUID
    public let metricType: HealthMetricType
    public let targetValue: Double
    public let period: GoalPeriod
    public let isActive: Bool
    public let createdAt: Date
    public let note: String?
    
    public init(metricType: HealthMetricType, targetValue: Double, period: GoalPeriod = .daily, isActive: Bool = true, note: String? = nil) {
        self.id = UUID()
        self.metricType = metricType
        self.targetValue = targetValue
        self.period = period
        self.isActive = isActive
        self.createdAt = Date()
        self.note = note
    }
}

/// 目標期間
public enum GoalPeriod: String, CaseIterable, Codable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    public var displayName: String {
        switch self {
        case .daily: return "日間"
        case .weekly: return "週間"
        case .monthly: return "月間"
        }
    }
    
    public var durationInDays: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return 30
        }
    }
}

// MARK: - 進捗統計

/// 健康指標の統計情報
public struct HealthStatistics: Sendable {
    public let metricType: HealthMetricType
    public let period: StatisticsPeriod
    public let totalValue: Double
    public let averageValue: Double
    public let recordCount: Int
    public let goal: HealthGoal?
    public let achievementRate: Double  // 目標達成率 (0.0-1.0)
    public let trend: StatisticsTrend
    
    public init(metricType: HealthMetricType, period: StatisticsPeriod, totalValue: Double, recordCount: Int, goal: HealthGoal? = nil) {
        self.metricType = metricType
        self.period = period
        self.totalValue = totalValue
        self.averageValue = recordCount > 0 ? totalValue / Double(recordCount) : 0.0
        self.recordCount = recordCount
        self.goal = goal
        
        // 目標達成率計算
        if let goal = goal, goal.targetValue > 0 {
            let compareValue = (goal.period == .daily) ? averageValue : totalValue
            self.achievementRate = min(1.0, compareValue / goal.targetValue)
        } else {
            self.achievementRate = 0.0
        }
        
        // トレンド計算（簡易版）
        if achievementRate >= 0.9 {
            self.trend = .improving
        } else if achievementRate >= 0.6 {
            self.trend = .stable
        } else {
            self.trend = .declining
        }
    }
}

/// 統計期間
public enum StatisticsPeriod: String, CaseIterable, Codable, Sendable {
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case last30Days = "last_30_days"
    
    public var displayName: String {
        switch self {
        case .today: return "今日"
        case .thisWeek: return "今週"
        case .thisMonth: return "今月"
        case .last30Days: return "過去30日"
        }
    }
}

/// 統計トレンド
public enum StatisticsTrend: String, Codable, Sendable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    public var displayName: String {
        switch self {
        case .improving: return "改善中"
        case .stable: return "安定"
        case .declining: return "要注意"
        }
    }
    
    public var emoji: String {
        switch self {
        case .improving: return "📈"
        case .stable: return "📊"
        case .declining: return "📉"
        }
    }
}

// MARK: - HealthManager

/// 健康指標管理の中央クラス
@MainActor
@Observable
public final class HealthManager: BaseViewModel {
    
    // MARK: - Properties
    
    /// 健康記録のストレージ
    private var healthRecords: [HealthMetricType: [any HealthMetric]] = [:]
    
    /// 健康目標
    public var healthGoals: [HealthGoal] = []
    
    /// 現在の統計情報
    public var currentStatistics: [HealthMetricType: HealthStatistics] = [:]
    
    /// 選択中の統計期間
    public var selectedPeriod: StatisticsPeriod = .today
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        initialize()
    }
    
    public override func initialize() {
        super.initialize()
        loadAllData()
    }
    
    // MARK: - Data Management
    
    /// すべてのデータを読み込み
    private func loadAllData() {
        safeAsync {
            try await self.loadHealthGoals()
            try await self.loadAllHealthRecords()
            await self.updateStatistics()
        }
    }
    
    /// 健康目標を読み込み
    private func loadHealthGoals() async throws {
        let goals: [HealthGoal] = try await PersistenceManager.shared.loadAsync([HealthGoal].self, forKey: "health_goals") ?? []
        healthGoals = goals.filter { $0.isActive }
    }
    
    /// すべての健康記録を読み込み
    private func loadAllHealthRecords() async throws {
        for metricType in HealthMetricType.allCases {
            let persistenceKey = getPersistenceKey(for: metricType)
            
            switch metricType {
            case .waterIntake:
                let records: [WaterIntakeRecord] = try await PersistenceManager.shared.loadAsync([WaterIntakeRecord].self, forKey: persistenceKey) ?? []
                healthRecords[metricType] = records
            case .sleep:
                let records: [SleepRecord] = try await PersistenceManager.shared.loadAsync([SleepRecord].self, forKey: persistenceKey) ?? []
                healthRecords[metricType] = records
            case .steps:
                let records: [StepRecord] = try await PersistenceManager.shared.loadAsync([StepRecord].self, forKey: persistenceKey) ?? []
                healthRecords[metricType] = records
            case .mood:
                let records: [MoodRecord] = try await PersistenceManager.shared.loadAsync([MoodRecord].self, forKey: persistenceKey) ?? []
                healthRecords[metricType] = records
            default:
                let records: [GenericHealthRecord] = try await PersistenceManager.shared.loadAsync([GenericHealthRecord].self, forKey: persistenceKey) ?? []
                healthRecords[metricType] = records.filter { $0.metricType == metricType }
            }
        }
    }
    
    /// 統計情報を更新
    private func updateStatistics() async {
        var statistics: [HealthMetricType: HealthStatistics] = [:]
        
        for (metricType, records) in healthRecords {
            let filteredRecords = filterRecords(records, for: selectedPeriod)
            let goal = healthGoals.first { $0.metricType == metricType }
            let totalValue = filteredRecords.reduce(0) { $0 + $1.value }
            
            statistics[metricType] = HealthStatistics(
                metricType: metricType,
                period: selectedPeriod,
                totalValue: totalValue,
                recordCount: filteredRecords.count,
                goal: goal
            )
        }
        
        currentStatistics = statistics
    }
    
    // MARK: - Record Management
    
    /// 健康記録を追加
    public func addRecord<T: HealthMetric>(_ record: T) async throws {
        let metricType = record.metricType
        
        // メモリ内の記録を更新
        if healthRecords[metricType] == nil {
            healthRecords[metricType] = []
        }
        healthRecords[metricType]?.append(record)
        
        // 永続化
        try await saveRecords(for: metricType)
        
        // 統計情報を更新
        await updateStatistics()
        
        if AsaHealthKitLib.debugMode {
            print("✅ 健康記録追加: \(metricType.displayName) = \(record.value)\(metricType.unit)")
        }
    }
    
    /// 健康記録を削除
    public func deleteRecord(id: UUID, metricType: HealthMetricType) async throws {
        healthRecords[metricType]?.removeAll { record in
            if let recordId = record.id as? UUID {
                return recordId == id
            }
            return false
        }
        try await saveRecords(for: metricType)
        await updateStatistics()
    }
    
    /// 特定の指標の記録を取得
    public func getRecords<T: HealthMetric>(for metricType: HealthMetricType, as type: T.Type) -> [T] {
        guard let records = healthRecords[metricType] else { return [] }
        return records.compactMap { $0 as? T }
    }
    
    // MARK: - Goal Management
    
    /// 健康目標を設定
    public func setGoal(for metricType: HealthMetricType, targetValue: Double, period: GoalPeriod = .daily, note: String? = nil) async throws {
        // 既存の目標を非アクティブ化
        for index in self.healthGoals.indices {
            if self.healthGoals[index].metricType == metricType {
                let updatedGoal = HealthGoal(
                    metricType: self.healthGoals[index].metricType,
                    targetValue: self.healthGoals[index].targetValue,
                    period: self.healthGoals[index].period,
                    isActive: false,
                    note: self.healthGoals[index].note
                )
                self.healthGoals[index] = updatedGoal
            }
        }
        
        // 新しい目標を追加
        let newGoal = HealthGoal(metricType: metricType, targetValue: targetValue, period: period, note: note)
        self.healthGoals.append(newGoal)
        
        try await self.saveHealthGoals()
        await self.updateStatistics()
        
        if AsaHealthKitLib.debugMode {
            print("🎯 健康目標設定: \(metricType.displayName) = \(targetValue)\(metricType.unit)/\(period.displayName)")
        }
    }
    
    /// 健康目標を取得
    public func getGoal(for metricType: HealthMetricType) -> HealthGoal? {
        return healthGoals.first { $0.metricType == metricType && $0.isActive }
    }
    
    // MARK: - Statistics
    
    /// 統計期間を変更
    public func changePeriod(to period: StatisticsPeriod) {
        selectedPeriod = period
        safeAsync {
            await self.updateStatistics()
        }
    }
    
    /// 特定指標の統計情報を取得
    public func getStatistics(for metricType: HealthMetricType) -> HealthStatistics? {
        return currentStatistics[metricType]
    }
    
    /// 今日の進捗サマリーを取得
    public func getTodaysSummary() -> [HealthStatistics] {
        let todayStats = currentStatistics.values.filter { $0.period == .today }
        return Array(todayStats).sorted { $0.achievementRate > $1.achievementRate }
    }
    
    // MARK: - Private Methods
    
    private func getPersistenceKey(for metricType: HealthMetricType) -> String {
        switch metricType {
        case .waterIntake: return HealthKitConstants.PersistenceKeys.waterIntakes
        case .sleep: return HealthKitConstants.PersistenceKeys.sleepRecords
        case .steps: return HealthKitConstants.PersistenceKeys.stepRecords
        case .mood: return HealthKitConstants.PersistenceKeys.moodRecords
        case .weight: return HealthKitConstants.PersistenceKeys.weightRecords
        case .workout: return HealthKitConstants.PersistenceKeys.workoutRecords
        case .heartRate: return "health_heart_rate_records"
        case .bodyFat: return "health_body_fat_records"
        }
    }
    
    private func saveRecords(for metricType: HealthMetricType) async throws {
        guard let records = healthRecords[metricType] else { return }
        let persistenceKey = getPersistenceKey(for: metricType)
        
        switch metricType {
        case .waterIntake:
            let waterRecords = records.compactMap { $0 as? WaterIntakeRecord }
            try await PersistenceManager.shared.saveAsync(waterRecords, forKey: persistenceKey)
        case .sleep:
            let sleepRecords = records.compactMap { $0 as? SleepRecord }
            try await PersistenceManager.shared.saveAsync(sleepRecords, forKey: persistenceKey)
        case .steps:
            let stepRecords = records.compactMap { $0 as? StepRecord }
            try await PersistenceManager.shared.saveAsync(stepRecords, forKey: persistenceKey)
        case .mood:
            let moodRecords = records.compactMap { $0 as? MoodRecord }
            try await PersistenceManager.shared.saveAsync(moodRecords, forKey: persistenceKey)
        default:
            let genericRecords = records.compactMap { $0 as? GenericHealthRecord }
            try await PersistenceManager.shared.saveAsync(genericRecords, forKey: persistenceKey)
        }
    }
    
    private func saveHealthGoals() async throws {
        try await PersistenceManager.shared.saveAsync(healthGoals, forKey: "health_goals")
    }
    
    private func filterRecords(_ records: [any HealthMetric], for period: StatisticsPeriod) -> [any HealthMetric] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch period {
        case .today:
            startDate = calendar.startOfDay(for: now)
        case .thisWeek:
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .thisMonth:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        }
        
        return records.filter { $0.recordedAt >= startDate }
    }
}