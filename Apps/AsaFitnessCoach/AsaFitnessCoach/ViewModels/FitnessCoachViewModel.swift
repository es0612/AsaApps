//
//  FitnessCoachViewModel.swift
//  AsaFitnessCoach
//
//  メインViewModel
//

import Foundation
import SwiftData

@Observable
@MainActor
final class FitnessCoachViewModel {
    // MARK: - Properties

    // サービス
    private let dataService = DataService()
    private let healthKitService = HealthKitService()
    private let planGenerator = WorkoutPlanGenerator()
    private let progressiveOverloadService = ProgressiveOverloadService()

    // 状態
    var userProfile: UserProfile?
    var workoutPlans: [WorkoutPlan] = []
    var recentSessions: [WorkoutSession] = []
    var todayPlans: [WorkoutPlan] = []
    var aiRecommendation: AIRecommendation?
    var overloadSuggestions: [ProgressiveOverloadSuggestion] = []

    // ヘルスデータ
    var todaySteps: Double = 0
    var todayCalories: Double = 0
    var todayActiveTime: Double = 0
    var todayWorkoutCount: Int = 0

    // 統計
    var weeklyStats: WeeklyStats?
    var monthlyStats: MonthlyStats?

    // UI状態
    var isLoading = false
    var errorMessage: String?
    var showOnboarding: Bool {
        userProfile == nil
    }

    // MARK: - Initialization

    func setModelContext(_ context: ModelContext) {
        dataService.setModelContext(context)
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        errorMessage = nil

        // ユーザープロファイル読み込み
        userProfile = dataService.fetchUserProfile()

        // ワークアウトプラン読み込み
        workoutPlans = dataService.fetchWorkoutPlans()
        todayPlans = dataService.fetchTodayPlans()

        // セッション読み込み
        recentSessions = dataService.fetchWorkoutSessions(limit: 30)

        // 統計読み込み
        weeklyStats = dataService.fetchWeeklyStats()
        monthlyStats = dataService.fetchMonthlyStats()

        // HealthKitデータ読み込み
        if healthKitService.isAuthorized {
            await loadHealthKitData()
        }

        // AI提案生成
        if let profile = userProfile {
            generateAIRecommendation(for: profile)
        }

        // プログレッシブオーバーロード提案
        loadOverloadSuggestions()

        isLoading = false
    }

    func refreshData() async {
        await loadData()
    }

    // MARK: - HealthKit

    var healthKitService_: HealthKitService {
        healthKitService
    }

    func requestHealthKitAuthorization() async {
        await healthKitService.requestAuthorization()
        if healthKitService.isAuthorized {
            await loadHealthKitData()
        }
    }

    private func loadHealthKitData() async {
        let today = Date()
        todaySteps = await healthKitService.fetchStepCount(for: today)
        todayCalories = await healthKitService.fetchCalories(for: today)
        todayActiveTime = await healthKitService.fetchActiveTime(for: today)
        todayWorkoutCount = await healthKitService.fetchWorkoutCount(for: today)
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) {
        dataService.saveUserProfile(profile)
        userProfile = profile
        generateAIRecommendation(for: profile)
    }

    func updateUserProfile(_ profile: UserProfile) {
        dataService.updateUserProfile(profile)
        userProfile = profile
        generateAIRecommendation(for: profile)
    }

    // MARK: - Workout Plans

    func createPlan(_ plan: WorkoutPlan) {
        dataService.saveWorkoutPlan(plan)
        workoutPlans = dataService.fetchWorkoutPlans()
        todayPlans = dataService.fetchTodayPlans()
    }

    func deletePlan(_ plan: WorkoutPlan) {
        dataService.deleteWorkoutPlan(plan)
        workoutPlans = dataService.fetchWorkoutPlans()
        todayPlans = dataService.fetchTodayPlans()
    }

    func togglePlanActive(_ plan: WorkoutPlan) {
        plan.isActive.toggle()
        plan.updatedAt = Date()
        workoutPlans = dataService.fetchWorkoutPlans()
        todayPlans = dataService.fetchTodayPlans()
    }

    // MARK: - AI Recommendation

    func generateAIRecommendation(for profile: UserProfile) {
        aiRecommendation = planGenerator.generatePlan(
            for: profile,
            recentSessions: recentSessions,
            existingPlans: workoutPlans
        )
    }

    func createPlanFromRecommendation(_ recommendation: AIRecommendation) {
        let plan = WorkoutPlan(
            name: recommendation.planName,
            description: recommendation.planDescription,
            difficulty: recommendation.difficulty,
            category: recommendation.category
        )

        plan.isAIGenerated = true
        plan.aiConfidence = recommendation.confidence
        plan.estimatedDuration = Double(recommendation.estimatedDuration)

        for recommendedExercise in recommendation.exercises {
            let exercise = Exercise(
                name: recommendedExercise.name,
                category: recommendedExercise.category,
                sets: recommendedExercise.suggestedSets,
                reps: recommendedExercise.suggestedReps,
                restTime: recommendedExercise.restTime
            )
            exercise.targetMuscles = recommendedExercise.targetMuscles
            exercise.duration = recommendedExercise.suggestedDuration
            exercise.weight = recommendedExercise.suggestedWeight
            exercise.instructions = recommendedExercise.instructions

            plan.addExercise(exercise)
        }

        createPlan(plan)
    }

    func regenerateRecommendation() {
        guard let profile = userProfile else { return }
        // 重みをランダムに調整して多様性を出す
        planGenerator.weights = PlanWeights(
            goalAlignment: 0.25 + Double.random(in: -0.05...0.05),
            fitnessLevel: 0.20 + Double.random(in: -0.05...0.05),
            equipmentMatch: 0.15 + Double.random(in: -0.03...0.03),
            timeConstraint: 0.15 + Double.random(in: -0.03...0.03),
            recoveryStatus: 0.15 + Double.random(in: -0.03...0.03),
            progressionRate: 0.10 + Double.random(in: -0.02...0.02)
        )
        generateAIRecommendation(for: profile)
    }

    // MARK: - Progressive Overload

    private func loadOverloadSuggestions() {
        overloadSuggestions = progressiveOverloadService.suggestAllWeightIncreases(
            sessions: recentSessions
        )
    }

    // MARK: - Workout Session

    func startWorkoutSession(for plan: WorkoutPlan) -> WorkoutSession {
        let session = WorkoutSession(planName: plan.name, startTime: Date())
        session.planId = plan.id
        session.workoutPlan = plan

        // エクササイズを準備
        for exercise in plan.exercises {
            var completedExercise = CompletedExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                isCompleted: false
            )

            // セットを準備
            for setNumber in 1...exercise.sets {
                let setRecord = SetRecord(
                    setNumber: setNumber,
                    reps: exercise.reps,
                    weight: exercise.weight,
                    duration: exercise.duration,
                    isCompleted: false
                )
                completedExercise.actualSets.append(setRecord)
            }

            session.addCompletedExercise(completedExercise)
        }

        dataService.saveWorkoutSession(session)
        return session
    }

    func completeWorkoutSession(_ session: WorkoutSession) {
        session.complete()
        recentSessions = dataService.fetchWorkoutSessions(limit: 30)
        weeklyStats = dataService.fetchWeeklyStats()
        monthlyStats = dataService.fetchMonthlyStats()
        loadOverloadSuggestions()
    }
}
