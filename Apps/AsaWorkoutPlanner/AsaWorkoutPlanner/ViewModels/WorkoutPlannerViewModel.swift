//
//  WorkoutPlannerViewModel.swift
//  AsaWorkoutPlanner
//
//  メインのViewModel - ワークアウトプラン管理
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import AsaHealthKit

@Observable
@MainActor
final class WorkoutPlannerViewModel {
    // MARK: - Properties
    
    // データ管理
    private var modelContext: ModelContext?
    private var healthManager: HealthManager
    
    // ワークアウトプラン
    var workoutPlans: [WorkoutPlan] = []
    var activeWorkoutPlan: WorkoutPlan?
    var selectedPlan: WorkoutPlan?
    
    // セッション管理
    var currentSession: WorkoutSession?
    var recentSessions: [WorkoutSession] = []
    
    // UI状態
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var selectedCategory: WorkoutCategory?
    var selectedDifficulty: Difficulty?
    var showingCreatePlan = false
    var showingSession = false
    
    // 統計データ
    var totalWorkouts = 0
    var totalDuration: TimeInterval = 0
    var totalCaloriesBurned: Double = 0
    var currentStreak = 0
    var weeklyGoal = 3
    var weeklyProgress = 0
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        self.healthManager = HealthManager()
        
        if modelContext != nil {
            loadWorkoutPlans()
            loadRecentSessions()
            updateStatistics()
        }
    }
    
    // MARK: - Computed Properties
    
    var filteredPlans: [WorkoutPlan] {
        var filtered = workoutPlans
        
        // カテゴリーフィルタ
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 難易度フィルタ
        if let difficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        // 検索フィルタ
        if !searchText.isEmpty {
            filtered = filtered.filter { plan in
                plan.name.localizedCaseInsensitiveContains(searchText) ||
                plan.planDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var todaysWorkout: WorkoutPlan? {
        let today = Calendar.current.component(.weekday, from: Date())
        let todayWeekDay = weekDayFromCalendarDay(today)
        
        return workoutPlans.first { plan in
            plan.isActive && plan.scheduledDays.contains(todayWeekDay)
        }
    }
    
    var weeklyProgressPercentage: Double {
        guard weeklyGoal > 0 else { return 0 }
        return min(Double(weeklyProgress) / Double(weeklyGoal), 1.0)
    }
    
    var hasActiveSession: Bool {
        currentSession != nil && !currentSession!.isCompleted
    }
    
    // MARK: - Data Loading
    
    func loadWorkoutPlans() {
        guard let context = modelContext else { return }
        
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<WorkoutPlan>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            workoutPlans = try context.fetch(descriptor)
            
            // アクティブプランを設定
            activeWorkoutPlan = workoutPlans.first { $0.isActive }
            
            isLoading = false
        } catch {
            errorMessage = "プランの読み込みに失敗しました: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func loadRecentSessions() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<WorkoutSession>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            let allSessions = try context.fetch(descriptor)
            recentSessions = Array(allSessions.prefix(10))
        } catch {
            errorMessage = "セッションの読み込みに失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Plan Management
    
    func createWorkoutPlan(
        name: String,
        description: String,
        difficulty: Difficulty,
        category: WorkoutCategory
    ) {
        guard let context = modelContext else { return }
        
        let plan = WorkoutPlan(
            name: name,
            description: description,
            difficulty: difficulty,
            category: category
        )
        
        context.insert(plan)
        
        do {
            try context.save()
            workoutPlans.append(plan)
            
            // AsaHealthKitに目標を設定
            Task {
                try? await healthManager.setGoal(
                    for: .workout,
                    targetValue: Double(weeklyGoal * 60),  // 分単位
                    period: .weekly
                )
            }
        } catch {
            errorMessage = "プランの保存に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func duplicatePlan(_ plan: WorkoutPlan) {
        guard let context = modelContext else { return }
        
        let newPlan = plan.duplicate()
        context.insert(newPlan)
        
        do {
            try context.save()
            workoutPlans.append(newPlan)
        } catch {
            errorMessage = "プランの複製に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func deletePlan(_ plan: WorkoutPlan) {
        guard let context = modelContext else { return }
        
        context.delete(plan)
        
        do {
            try context.save()
            workoutPlans.removeAll { $0.id == plan.id }
        } catch {
            errorMessage = "プランの削除に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func setActivePlan(_ plan: WorkoutPlan) {
        // 現在のアクティブプランを無効化
        if let currentActive = activeWorkoutPlan {
            currentActive.isActive = false
        }
        
        // 新しいプランをアクティブ化
        plan.isActive = true
        activeWorkoutPlan = plan
        
        saveContext()
    }
    
    // MARK: - Session Management
    
    func startWorkoutSession(with plan: WorkoutPlan) {
        let session = WorkoutSession(workoutPlan: plan)
        currentSession = session
        showingSession = true
        
        // エクササイズをCompletedExerciseに変換
        for exercise in plan.exercises {
            let completedExercise = CompletedExercise(from: exercise)
            session.addCompletedExercise(completedExercise)
        }
        
        guard let context = modelContext else { return }
        context.insert(session)
        
        saveContext()
    }
    
    func pauseSession() {
        currentSession?.pause()
        saveContext()
    }
    
    func resumeSession() {
        currentSession?.resume()
        saveContext()
    }
    
    func completeSession() {
        guard let session = currentSession else { return }
        
        session.complete()
        
        // AsaHealthKitにワークアウトデータを記録
        let workoutRecord = GenericHealthRecord(
            value: session.duration / 60,  // 分単位
            metricType: .workout,
            note: session.notes
        )
        Task {
            try? await healthManager.addRecord(workoutRecord)
        }
        
        // 統計を更新
        updateStatistics()
        
        currentSession = nil
        showingSession = false
        
        saveContext()
    }
    
    func cancelSession() {
        guard let session = currentSession else { return }
        
        session.cancel()
        currentSession = nil
        showingSession = false
        
        saveContext()
    }
    
    // MARK: - Statistics
    
    func updateStatistics() {
        guard let context = modelContext else { return }
        
        do {
            // 全セッション数
            let sessionDescriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate { $0.isCompleted }
            )
            let completedSessions = try context.fetch(sessionDescriptor)
            totalWorkouts = completedSessions.count
            
            // 合計時間とカロリー
            totalDuration = completedSessions.reduce(0) { $0 + $1.duration }
            totalCaloriesBurned = completedSessions.reduce(0) { $0 + $1.totalCaloriesBurned }
            
            // 週間進捗
            let calendar = Calendar.current
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let weekSessions = completedSessions.filter { $0.startTime >= weekStart }
            weeklyProgress = weekSessions.count
            
            // ストリーク計算
            calculateStreak(from: completedSessions)
            
            // AsaHealthKitから統計を取得（将来の拡張用）
            _ = healthManager.getStatistics(for: .workout)
        } catch {
            errorMessage = "統計の更新に失敗しました: \(error.localizedDescription)"
        }
    }
    
    private func calculateStreak(from sessions: [WorkoutSession]) {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        let sortedSessions = sessions.sorted { $0.startTime > $1.startTime }
        let sessionDates = Set(sortedSessions.map { calendar.startOfDay(for: $0.startTime) })

        while sessionDates.contains(calendar.startOfDay(for: currentDate)) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        currentStreak = streak
    }
    
    // MARK: - Helper Methods
    
    private func saveContext() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            errorMessage = "データの保存に失敗しました: \(error.localizedDescription)"
        }
    }
    
    private func weekDayFromCalendarDay(_ day: Int) -> WeekDay {
        switch day {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
    
    // MARK: - Sample Data
    
    func createSamplePlans() {
        let beginnerPlan = WorkoutPlan(
            name: "初心者向け全身トレーニング",
            description: "週3回の基本的な全身運動プログラム",
            difficulty: .beginner,
            category: .general
        )
        
        // エクササイズを追加
        beginnerPlan.addExercise(Exercise(
            name: "プッシュアップ",
            category: .chest,
            sets: 3,
            reps: 10,
            restTime: 60
        ))
        
        beginnerPlan.addExercise(Exercise(
            name: "スクワット",
            category: .legs,
            sets: 3,
            reps: 15,
            restTime: 60
        ))
        
        beginnerPlan.addExercise(Exercise(
            name: "プランク",
            category: .core,
            sets: 3,
            reps: 1,
            restTime: 45
        ))
        
        beginnerPlan.scheduledDays = [.monday, .wednesday, .friday]
        
        guard let context = modelContext else { return }
        context.insert(beginnerPlan)
        
        saveContext()
        loadWorkoutPlans()
    }
}