//
//  WorkoutViewModel.swift
//  AsaWorkoutLog
//  
//  Created on 2025/07/01
//

import Foundation
import SwiftUI

class WorkoutViewModel: ObservableObject {
    @Published var workoutSessions: [WorkoutSession] = []
    @Published var workoutGoal: WorkoutGoal = WorkoutGoal()
    @Published var isShowingAddSession = false
    @Published var selectedSession: WorkoutSession?
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "WorkoutSessions"
    private let goalKey = "WorkoutGoal"
    
    init() {
        loadData()
    }
    
    // MARK: - Data Management
    func loadData() {
        // セッション履歴を読み込み
        if let sessionData = userDefaults.data(forKey: sessionsKey),
           let sessions = try? JSONDecoder().decode([WorkoutSession].self, from: sessionData) {
            self.workoutSessions = sessions.sorted { $0.date > $1.date }
        }
        
        // 目標設定を読み込み
        if let goalData = userDefaults.data(forKey: goalKey),
           let goal = try? JSONDecoder().decode(WorkoutGoal.self, from: goalData) {
            self.workoutGoal = goal
        }
    }
    
    func saveData() {
        // セッション履歴を保存
        if let sessionData = try? JSONEncoder().encode(workoutSessions) {
            userDefaults.set(sessionData, forKey: sessionsKey)
        }
        
        // 目標設定を保存
        if let goalData = try? JSONEncoder().encode(workoutGoal) {
            userDefaults.set(goalData, forKey: goalKey)
        }
    }
    
    // MARK: - Session Management
    func addWorkoutSession(_ session: WorkoutSession) {
        workoutSessions.append(session)
        workoutSessions.sort { $0.date > $1.date }
        saveData()
    }
    
    func updateWorkoutSession(_ session: WorkoutSession) {
        if let index = workoutSessions.firstIndex(where: { $0.id == session.id }) {
            workoutSessions[index] = session
            workoutSessions.sort { $0.date > $1.date }
            saveData()
        }
    }
    
    func deleteWorkoutSession(_ session: WorkoutSession) {
        workoutSessions.removeAll { $0.id == session.id }
        saveData()
    }
    
    func deleteWorkoutSessions(at offsets: IndexSet) {
        workoutSessions.remove(atOffsets: offsets)
        saveData()
    }
    
    // MARK: - Goal Management
    func updateWorkoutGoal(_ goal: WorkoutGoal) {
        self.workoutGoal = goal
        saveData()
    }
    
    // MARK: - Statistics
    var thisWeekSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return workoutSessions.filter { session in
            session.date >= weekStart && session.date <= now
        }
    }
    
    var thisWeekTotalMinutes: Int {
        let totalSeconds = thisWeekSessions.reduce(0) { $0 + $1.duration }
        return Int(totalSeconds / 60)
    }
    
    var thisWeekProgress: Double {
        guard workoutGoal.weeklyTargetMinutes > 0 else { return 0 }
        return min(Double(thisWeekTotalMinutes) / Double(workoutGoal.weeklyTargetMinutes), 1.0)
    }
    
    var thisWeekSessionCount: Int {
        thisWeekSessions.count
    }
    
    var thisWeekSessionProgress: Double {
        guard workoutGoal.weeklyTargetSessions > 0 else { return 0 }
        return min(Double(thisWeekSessionCount) / Double(workoutGoal.weeklyTargetSessions), 1.0)
    }
    
    var thisMonthSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return workoutSessions.filter { session in
            session.date >= monthStart && session.date <= now
        }
    }
    
    var thisMonthTotalMinutes: Int {
        let totalSeconds = thisMonthSessions.reduce(0) { $0 + $1.duration }
        return Int(totalSeconds / 60)
    }
    
    var averageSessionDuration: Int {
        guard !workoutSessions.isEmpty else { return 0 }
        let totalSeconds = workoutSessions.reduce(0) { $0 + $1.duration }
        return Int(totalSeconds / 60 / workoutSessions.count)
    }
    
    var mostCommonWorkoutType: WorkoutType? {
        guard !workoutSessions.isEmpty else { return nil }
        
        let typeCounts = Dictionary(grouping: workoutSessions, by: { $0.workoutType })
            .mapValues { $0.count }
        
        return typeCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var totalWorkoutSessions: Int {
        workoutSessions.count
    }
    
    var totalWorkoutMinutes: Int {
        let totalSeconds = workoutSessions.reduce(0) { $0 + $1.duration }
        return Int(totalSeconds / 60)
    }
    
    // MARK: - UI Helpers
    func showAddSession() {
        isShowingAddSession = true
    }
    
    func selectSession(_ session: WorkoutSession) {
        selectedSession = session
    }
    
    func clearSelection() {
        selectedSession = nil
    }
}