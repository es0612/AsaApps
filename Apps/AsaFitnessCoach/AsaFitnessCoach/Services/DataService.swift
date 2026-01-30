//
//  DataService.swift
//  AsaFitnessCoach
//
//  Swift Data CRUD操作サービス
//

import Foundation
import SwiftData

@MainActor
final class DataService {
    // MARK: - Properties

    private var modelContext: ModelContext?

    // MARK: - Initialization

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - UserProfile

    func fetchUserProfile() -> UserProfile? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let profiles = try context.fetch(descriptor)
            return profiles.first
        } catch {
            print("ユーザープロファイル取得エラー: \(error)")
            return nil
        }
    }

    func saveUserProfile(_ profile: UserProfile) {
        guard let context = modelContext else { return }
        context.insert(profile)
        saveContext()
    }

    func updateUserProfile(_ profile: UserProfile) {
        profile.updateProfile()
        saveContext()
    }

    // MARK: - WorkoutPlan

    func fetchWorkoutPlans() -> [WorkoutPlan] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<WorkoutPlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            print("ワークアウトプラン取得エラー: \(error)")
            return []
        }
    }

    func fetchActivePlans() -> [WorkoutPlan] {
        fetchWorkoutPlans().filter { $0.isActive }
    }

    func fetchTodayPlans() -> [WorkoutPlan] {
        fetchWorkoutPlans().filter { $0.isScheduledForToday }
    }

    func saveWorkoutPlan(_ plan: WorkoutPlan) {
        guard let context = modelContext else { return }
        context.insert(plan)
        saveContext()
    }

    func deleteWorkoutPlan(_ plan: WorkoutPlan) {
        guard let context = modelContext else { return }
        context.delete(plan)
        saveContext()
    }

    // MARK: - Exercise

    func fetchExercises() -> [Exercise] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.order)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            print("エクササイズ取得エラー: \(error)")
            return []
        }
    }

    func saveExercise(_ exercise: Exercise) {
        guard let context = modelContext else { return }
        context.insert(exercise)
        saveContext()
    }

    func deleteExercise(_ exercise: Exercise) {
        guard let context = modelContext else { return }
        context.delete(exercise)
        saveContext()
    }

    // MARK: - WorkoutSession

    func fetchWorkoutSessions(limit: Int? = nil) -> [WorkoutSession] {
        guard let context = modelContext else { return [] }
        var descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        do {
            return try context.fetch(descriptor)
        } catch {
            print("ワークアウトセッション取得エラー: \(error)")
            return []
        }
    }

    func fetchCompletedSessions(days: Int = 30) -> [WorkoutSession] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return fetchWorkoutSessions().filter { session in
            session.isCompleted && session.startTime >= startDate
        }
    }

    func fetchSessionsForPlan(_ planId: UUID) -> [WorkoutSession] {
        fetchWorkoutSessions().filter { $0.planId == planId }
    }

    func saveWorkoutSession(_ session: WorkoutSession) {
        guard let context = modelContext else { return }
        context.insert(session)
        saveContext()
    }

    func deleteWorkoutSession(_ session: WorkoutSession) {
        guard let context = modelContext else { return }
        context.delete(session)
        saveContext()
    }

    // MARK: - Statistics

    /// 週間ワークアウト統計
    func fetchWeeklyStats() -> WeeklyStats {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today

        let sessions = fetchWorkoutSessions().filter { session in
            session.isCompleted && session.startTime >= weekStart
        }

        let totalDuration = sessions.reduce(0.0) { $0 + $1.duration }
        let totalCalories = sessions.compactMap { $0.totalCalories }.reduce(0, +)

        return WeeklyStats(
            workoutCount: sessions.count,
            totalDuration: totalDuration,
            totalCalories: totalCalories,
            averageRating: calculateAverageRating(sessions)
        )
    }

    /// 月間ワークアウト統計
    func fetchMonthlyStats() -> MonthlyStats {
        let calendar = Calendar.current
        let today = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today

        let sessions = fetchWorkoutSessions().filter { session in
            session.isCompleted && session.startTime >= monthStart
        }

        let totalDuration = sessions.reduce(0.0) { $0 + $1.duration }
        let totalCalories = sessions.compactMap { $0.totalCalories }.reduce(0, +)
        let totalVolume = sessions.reduce(0.0) { $0 + $1.totalVolume }

        return MonthlyStats(
            workoutCount: sessions.count,
            totalDuration: totalDuration,
            totalCalories: totalCalories,
            totalVolume: totalVolume,
            averageRating: calculateAverageRating(sessions)
        )
    }

    // MARK: - Private Methods

    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("保存エラー: \(error)")
        }
    }

    private func calculateAverageRating(_ sessions: [WorkoutSession]) -> Double {
        let ratings = sessions.compactMap { $0.rating?.rawValue }
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }
}

// MARK: - Statistics Structs

struct WeeklyStats {
    let workoutCount: Int
    let totalDuration: TimeInterval  // 分
    let totalCalories: Double
    let averageRating: Double

    var displayDuration: String {
        let hours = Int(totalDuration) / 60
        let minutes = Int(totalDuration) % 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        }
        return "\(minutes)分"
    }
}

struct MonthlyStats {
    let workoutCount: Int
    let totalDuration: TimeInterval  // 分
    let totalCalories: Double
    let totalVolume: Double
    let averageRating: Double

    var displayDuration: String {
        let hours = Int(totalDuration) / 60
        let minutes = Int(totalDuration) % 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        }
        return "\(minutes)分"
    }
}
