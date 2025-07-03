//
//  WorkoutViewModel.swift
//  AsaWorkoutLog
//
//  Created on 2025/07/03
//

import Foundation
import SwiftUI

class WorkoutViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var weeklyGoal: TimeInterval = 150 * 60
    
    private let userDefaults = UserDefaults.standard
    private let workoutsKey = "SavedWorkouts"
    private let goalKey = "WeeklyGoal"
    
    init() {
        loadWorkouts()
        loadGoal()
    }
    
    func addWorkout(_ workout: Workout) {
        workouts.append(workout)
        saveWorkouts()
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        saveWorkouts()
    }
    
    func updateWeeklyGoal(_ newGoal: TimeInterval) {
        weeklyGoal = newGoal
        saveGoal()
    }
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            userDefaults.set(encoded, forKey: workoutsKey)
        }
    }
    
    private func loadWorkouts() {
        if let data = userDefaults.data(forKey: workoutsKey),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
        }
    }
    
    private func saveGoal() {
        userDefaults.set(weeklyGoal, forKey: goalKey)
    }
    
    private func loadGoal() {
        let savedGoal = userDefaults.double(forKey: goalKey)
        if savedGoal > 0 {
            weeklyGoal = savedGoal
        }
    }
    
    var thisWeekWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return workouts.filter { workout in
            workout.date >= startOfWeek
        }
    }
    
    var thisWeekDuration: TimeInterval {
        return thisWeekWorkouts.reduce(0) { $0 + $1.duration }
    }
    
    var weeklyProgress: Double {
        return min(thisWeekDuration / weeklyGoal, 1.0)
    }
    
    var totalWorkouts: Int {
        return workouts.count
    }
    
    var totalDuration: TimeInterval {
        return workouts.reduce(0) { $0 + $1.duration }
    }
    
    var averageWorkoutDuration: TimeInterval {
        guard !workouts.isEmpty else { return 0 }
        return totalDuration / Double(workouts.count)
    }
    
    func workoutsByCategory() -> [WorkoutCategory: [Workout]] {
        return Dictionary(grouping: workouts) { $0.category }
    }
}