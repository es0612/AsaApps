//
//  HealthDashboardViewModel.swift
//  AsaHealthDashboard
//
//  メインのViewModel
//

import Foundation
import SwiftData

@MainActor
@Observable
final class HealthDashboardViewModel {
    // MARK: - Services

    private let healthKitService: HealthKitService
    private let aggregator: HealthDataAggregator
    private var modelContext: ModelContext?

    // MARK: - State

    var isLoading = false
    var selectedPeriod: TimePeriod = .week
    var todayMetrics: [HealthMetric] = []
    var periodMetrics: [HealthCategory: [HealthMetric]] = [:]
    var trendAnalysis: [HealthCategory: TrendAnalysis] = [:]
    var weeklyHighlights: WeeklyHighlights?
    var healthScore: HealthScore?
    var goals: [HealthGoal] = []

    // MARK: - HealthKit State

    var isHealthKitAvailable: Bool {
        healthKitService.isHealthKitAvailable
    }

    var isHealthKitAuthorized: Bool {
        healthKitService.isAuthorized
    }

    var authorizationStatusDescription: String {
        healthKitService.authorizationStatusDescription
    }

    // MARK: - Init

    init() {
        self.healthKitService = HealthKitService()
        self.aggregator = HealthDataAggregator(healthKitService: healthKitService)
    }

    // MARK: - ModelContext設定

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadGoals()
    }

    // MARK: - HealthKit権限

    func requestHealthKitAuthorization() async {
        isLoading = true
        await healthKitService.requestAuthorization()
        isLoading = false

        if isHealthKitAuthorized {
            await refreshAllData()
        }
    }

    // MARK: - データ読み込み

    func refreshAllData() async {
        isLoading = true

        // 目標を再読み込み
        loadGoals()

        // 並行してデータを取得
        async let todayTask = aggregator.fetchTodayMetrics(goals: goals)
        async let highlightsTask = aggregator.fetchWeeklyHighlights(goals: goals)

        todayMetrics = await todayTask
        weeklyHighlights = await highlightsTask
        healthScore = aggregator.calculateHealthScore(from: todayMetrics)

        // 期間別データを取得
        await loadPeriodData()

        isLoading = false
    }

    func loadPeriodData() async {
        periodMetrics = await aggregator.fetchAllMetrics(in: selectedPeriod, goals: goals)
    }

    func loadTrendAnalysis() async {
        trendAnalysis = await aggregator.analyzeAllTrends(period: selectedPeriod)
    }

    func changePeriod(to period: TimePeriod) async {
        selectedPeriod = period
        await loadPeriodData()
        await loadTrendAnalysis()
    }

    // MARK: - 目標管理

    private func loadGoals() {
        guard let context = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<HealthGoal>()
            goals = try context.fetch(descriptor)

            // デフォルト目標がない場合は作成
            for category in HealthCategory.allCases {
                if goals.goal(for: category) == nil {
                    let newGoal = HealthGoal(category: category, targetValue: category.defaultGoal)
                    context.insert(newGoal)
                    goals.append(newGoal)
                }
            }

            try context.save()
        } catch {
            print("目標の読み込みに失敗: \(error)")
        }
    }

    func updateGoal(for category: HealthCategory, value: Double) {
        guard let context = modelContext else { return }

        if let existingGoal = goals.goal(for: category) {
            existingGoal.updateTarget(value)
        } else {
            let newGoal = HealthGoal(category: category, targetValue: value)
            context.insert(newGoal)
            goals.append(newGoal)
        }

        do {
            try context.save()
        } catch {
            print("目標の保存に失敗: \(error)")
        }
    }

    func goalValue(for category: HealthCategory) -> Double {
        goals.targetValue(for: category)
    }

    // MARK: - 特定カテゴリのメトリクス取得

    func metrics(for category: HealthCategory) -> [HealthMetric] {
        periodMetrics[category] ?? []
    }

    func todayMetric(for category: HealthCategory) -> HealthMetric? {
        todayMetrics.first { $0.category == category }
    }

    func trend(for category: HealthCategory) -> TrendAnalysis? {
        trendAnalysis[category]
    }

    // MARK: - 睡眠データ取得

    func fetchSleepData(for date: Date) async -> (duration: Double, efficiency: Double)? {
        await healthKitService.fetchSleepData(for: date)
    }
}
