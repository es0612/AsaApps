//
//  FitnessModels.swift
//  AsaFitnessGoal
//  
//  Created on 2025/07/19
//

import Foundation
import SwiftData

// MARK: - 目標カテゴリ
enum GoalCategory: String, CaseIterable, Codable {
    case steps = "steps"
    case distance = "distance"
    case activeTime = "activeTime"
    case calories = "calories"
    case workouts = "workouts"
    
    var displayName: String {
        switch self {
        case .steps: return "歩数"
        case .distance: return "距離"
        case .activeTime: return "運動時間"
        case .calories: return "消費カロリー"
        case .workouts: return "ワークアウト回数"
        }
    }
    
    var unit: String {
        switch self {
        case .steps: return "歩"
        case .distance: return "km"
        case .activeTime: return "分"
        case .calories: return "kcal"
        case .workouts: return "回"
        }
    }
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "location"
        case .activeTime: return "timer"
        case .calories: return "flame"
        case .workouts: return "dumbbell"
        }
    }
}

// MARK: - 目標期間
enum GoalPeriod: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "1日"
        case .weekly: return "1週間"
        case .monthly: return "1ヶ月"
        }
    }
}

// MARK: - フィットネス目標
@Model
final class FitnessGoal {
    var id: UUID
    var title: String
    var category: GoalCategory
    var targetValue: Double
    var period: GoalPeriod
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        title: String,
        category: GoalCategory,
        targetValue: Double,
        period: GoalPeriod
    ) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.targetValue = targetValue
        self.period = period
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 現在の期間の開始日を計算
    var currentPeriodStart: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .daily:
            return calendar.startOfDay(for: now)
        case .weekly:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .monthly:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        }
    }
    
    // 現在の期間の終了日を計算
    var currentPeriodEnd: Date {
        let calendar = Calendar.current
        
        switch period {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: currentPeriodStart) ?? Date()
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: currentPeriodStart) ?? Date()
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: currentPeriodStart) ?? Date()
        }
    }
}

// MARK: - ワークアウト記録
@Model
final class WorkoutRecord {
    var id: UUID
    var goalId: UUID
    var category: GoalCategory
    var value: Double
    var note: String
    var recordedAt: Date
    var isManualEntry: Bool
    
    init(
        goalId: UUID,
        category: GoalCategory,
        value: Double,
        note: String = "",
        isManualEntry: Bool = true
    ) {
        self.id = UUID()
        self.goalId = goalId
        self.category = category
        self.value = value
        self.note = note
        self.recordedAt = Date()
        self.isManualEntry = isManualEntry
    }
    
    // フォーマットされた値を取得
    var formattedValue: String {
        switch category {
        case .steps:
            return String(format: "%.0f", value)
        case .distance:
            return String(format: "%.1f", value)
        case .activeTime:
            return String(format: "%.0f", value)
        case .calories:
            return String(format: "%.0f", value)
        case .workouts:
            return String(format: "%.0f", value)
        }
    }
}
