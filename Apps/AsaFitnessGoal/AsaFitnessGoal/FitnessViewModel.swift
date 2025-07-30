//
//  FitnessViewModel.swift
//  AsaFitnessGoal
//
//  Created on 2025/07/19
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class FitnessViewModel {
    var goals: [FitnessGoal] = []
    var workoutRecords: [WorkoutRecord] = []
    var selectedGoal: FitnessGoal?
    var isShowingAddGoalSheet = false
    var isShowingAddRecordSheet = false
    var isShowingEditGoalSheet = false
    
    private var modelContext: ModelContext?
    private let healthKitService = HealthKitService()
    
    // 現在の進捗データ
    var currentProgress: [GoalCategory: Double] = [:]
    var isLoadingProgress = false
    
    init() {
        // HealthKit権限のリクエストは、ビューが表示される際に明示的に行う
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadGoals()
        loadWorkoutRecords()
    }
    
    // MARK: - HealthKit権限
    
    var healthKitStatus: HealthKitService {
        return healthKitService
    }
    
    @MainActor
    func requestHealthKitPermission() async {
        await healthKitService.requestAuthorization()
        // 権限取得後、進捗データを更新
        if healthKitService.isAuthorized {
            await loadCurrentProgress()
        }
    }
    
    @MainActor
    func updateHealthKitStatusOnForeground() async {
        print("フォアグラウンド復帰時のHealthKit状態更新を開始...")
        
        // 権限状態を強制更新
        healthKitService.forceUpdateAuthorizationStatus()
        
        // 実際のデータアクセステストを実行
        let hasAccess = await healthKitService.hasActualDataAccess()
        print("実際のアクセス可否: \(hasAccess)")
        
        // 権限が利用可能になった場合は進捗データを更新
        if healthKitService.isAuthorized || hasAccess {
            await loadCurrentProgress()
        }
    }
    
    // MARK: - データ読み込み
    
    func loadGoals() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<FitnessGoal>(
                predicate: #Predicate { $0.isActive == true },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            goals = try context.fetch(descriptor)
        } catch {
            print("目標の読み込みに失敗しました: \(error)")
        }
    }
    
    func loadWorkoutRecords() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<WorkoutRecord>(
                sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
            )
            workoutRecords = try context.fetch(descriptor)
        } catch {
            print("ワークアウト記録の読み込みに失敗しました: \(error)")
        }
    }
    
    // MARK: - 目標管理
    
    func addGoal(title: String, category: GoalCategory, targetValue: Double, period: GoalPeriod) {
        guard let context = modelContext else { return }
        
        let newGoal = FitnessGoal(
            title: title,
            category: category,
            targetValue: targetValue,
            period: period
        )
        
        context.insert(newGoal)
        
        do {
            try context.save()
            loadGoals()
        } catch {
            print("目標の保存に失敗しました: \(error)")
        }
    }
    
    func updateGoal(_ goal: FitnessGoal, title: String, targetValue: Double) {
        guard let context = modelContext else { return }
        
        goal.title = title
        goal.targetValue = targetValue
        goal.updatedAt = Date()
        
        do {
            try context.save()
            loadGoals()
        } catch {
            print("目標の更新に失敗しました: \(error)")
        }
    }
    
    func deleteGoal(_ goal: FitnessGoal) {
        guard let context = modelContext else { return }
        
        // 関連するワークアウト記録も削除
        let relatedRecords = workoutRecords.filter { $0.goalId == goal.id }
        for record in relatedRecords {
            context.delete(record)
        }
        
        context.delete(goal)
        
        do {
            try context.save()
            loadGoals()
            loadWorkoutRecords()
        } catch {
            print("目標の削除に失敗しました: \(error)")
        }
    }
    
    func toggleGoalActive(_ goal: FitnessGoal) {
        guard let context = modelContext else { return }
        
        goal.isActive.toggle()
        goal.updatedAt = Date()
        
        do {
            try context.save()
            loadGoals()
        } catch {
            print("目標状態の更新に失敗しました: \(error)")
        }
    }
    
    // MARK: - ワークアウト記録管理
    
    func addWorkoutRecord(goalId: UUID, category: GoalCategory, value: Double, note: String) {
        guard let context = modelContext else { return }
        
        let newRecord = WorkoutRecord(
            goalId: goalId,
            category: category,
            value: value,
            note: note,
            isManualEntry: true
        )
        
        context.insert(newRecord)
        
        do {
            try context.save()
            loadWorkoutRecords()
        } catch {
            print("ワークアウト記録の保存に失敗しました: \(error)")
        }
    }
    
    func deleteWorkoutRecord(_ record: WorkoutRecord) {
        guard let context = modelContext else { return }
        
        context.delete(record)
        
        do {
            try context.save()
            loadWorkoutRecords()
        } catch {
            print("ワークアウト記録の削除に失敗しました: \(error)")
        }
    }
    
    // MARK: - 進捗計算
    
    func loadCurrentProgress() async {
        await MainActor.run {
            self.isLoadingProgress = true
        }
        
        let currentGoals = await MainActor.run { self.goals }
        var progress: [GoalCategory: Double] = [:]
        
        for goal in currentGoals {
            let currentValue = await getCurrentValue(for: goal)
            progress[goal.category] = currentValue
        }
        
        await MainActor.run {
            self.currentProgress = progress
            self.isLoadingProgress = false
        }
    }
    
    private func getCurrentValue(for goal: FitnessGoal) async -> Double {
        let periodStart = goal.currentPeriodStart
        let periodEnd = goal.currentPeriodEnd
        
        // HealthKitからの自動データ取得
        let healthKitValue = await healthKitService.fetchData(for: goal.category, date: Date())
        
        // 手動記録の合計値
        let manualRecords = workoutRecords.filter { record in
            record.goalId == goal.id &&
            record.recordedAt >= periodStart &&
            record.recordedAt < periodEnd &&
            record.isManualEntry
        }
        
        let manualValue = manualRecords.reduce(0) { $0 + $1.value }
        
        // HealthKitデータと手動記録を統合
        switch goal.category {
        case .steps, .distance, .activeTime, .calories:
            // これらのカテゴリはHealthKitの値を優先し、手動記録は追加分として扱う
            return healthKitValue + manualValue
        case .workouts:
            // ワークアウト回数は手動記録とHealthKitの値を合計
            return healthKitValue + manualValue
        }
    }
    
    func getProgress(for goal: FitnessGoal) -> Double {
        let currentValue = currentProgress[goal.category] ?? 0
        let progressPercentage = min(currentValue / goal.targetValue, 1.0)
        return progressPercentage
    }
    
    func getProgressText(for goal: FitnessGoal) -> String {
        let currentValue = currentProgress[goal.category] ?? 0
        let formattedCurrent = formatValue(currentValue, for: goal.category)
        let formattedTarget = formatValue(goal.targetValue, for: goal.category)
        return "\(formattedCurrent) / \(formattedTarget) \(goal.category.unit)"
    }
    
    private func formatValue(_ value: Double, for category: GoalCategory) -> String {
        switch category {
        case .steps, .workouts:
            return String(format: "%.0f", value)
        case .distance:
            return String(format: "%.1f", value)
        case .activeTime, .calories:
            return String(format: "%.0f", value)
        }
    }
    
    // MARK: - UI制御
    
    func showAddGoalSheet() {
        isShowingAddGoalSheet = true
    }
    
    func hideAddGoalSheet() {
        isShowingAddGoalSheet = false
    }
    
    func showAddRecordSheet() {
        isShowingAddRecordSheet = true
    }
    
    func hideAddRecordSheet() {
        isShowingAddRecordSheet = false
    }
    
    func showEditGoalSheet(for goal: FitnessGoal) {
        selectedGoal = goal
        isShowingEditGoalSheet = true
    }
    
    func hideEditGoalSheet() {
        selectedGoal = nil
        isShowingEditGoalSheet = false
    }
    
    // MARK: - フィルタリング
    
    var activeGoals: [FitnessGoal] {
        goals.filter { $0.isActive }
    }
    
    var completedGoals: [FitnessGoal] {
        activeGoals.filter { getProgress(for: $0) >= 1.0 }
    }
    
    var inProgressGoals: [FitnessGoal] {
        activeGoals.filter { getProgress(for: $0) < 1.0 }
    }
    
    func getRecentRecords(limit: Int = 10) -> [WorkoutRecord] {
        return Array(workoutRecords.prefix(limit))
    }
}