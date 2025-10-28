//
//  WorkoutPlan.swift
//  AsaWorkoutPlanner
//
//  ワークアウトプランのデータモデル
//

import Foundation
import SwiftData

// MARK: - ワークアウトプラン

@Model
final class WorkoutPlan {
    // MARK: - Properties
    
    var id: UUID = UUID()
    var name: String
    var planDescription: String
    var difficulty: Difficulty
    var category: WorkoutCategory
    var isActive: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // リレーション
    @Relationship(deleteRule: .cascade) 
    var exercises: [Exercise] = []
    
    @Relationship(deleteRule: .cascade)
    var sessions: [WorkoutSession] = []
    
    // スケジュール設定
    var scheduledDays: [WeekDay] = []

    /// ワークアウトの推定所要時間（分単位）
    /// - Note: updateEstimatedDuration()で自動計算、またはユーザーが手動設定可能
    /// - Note: 表示時は分単位、または時:分形式に変換される
    var estimatedDuration: TimeInterval = 0  // 分単位
    
    // MARK: - Initialization
    
    init(
        name: String,
        description: String = "",
        difficulty: Difficulty = .intermediate,
        category: WorkoutCategory = .general
    ) {
        self.name = name
        self.planDescription = description
        self.difficulty = difficulty
        self.category = category
    }
    
    // MARK: - Computed Properties
    
    var totalExercises: Int {
        exercises.count
    }
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets }
    }
    
    var completedSessions: Int {
        sessions.filter { $0.isCompleted }.count
    }
    
    var lastSessionDate: Date? {
        sessions.max(by: { $0.startTime < $1.startTime })?.startTime
    }
    
    // MARK: - Methods
    
    func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
        updateEstimatedDuration()
        updatedAt = Date()
    }
    
    func removeExercise(_ exercise: Exercise) {
        exercises.removeAll { $0.id == exercise.id }
        updateEstimatedDuration()
        updatedAt = Date()
    }
    
    func updateEstimatedDuration() {
        estimatedDuration = exercises.reduce(0) { total, exercise in
            // エクササイズ実行時間（分）
            let exerciseDuration = exercise.duration ?? (Double(exercise.sets) * 2)  // デフォルト: 1セット2分

            // 休憩時間（秒 → 分に変換）
            let restDuration = Double(exercise.sets - 1) * (exercise.restTime / 60.0)

            return total + exerciseDuration + restDuration
        }
    }
    
    func duplicate() -> WorkoutPlan {
        let newPlan = WorkoutPlan(
            name: "\(name) (コピー)",
            description: planDescription,
            difficulty: difficulty,
            category: category
        )
        
        for exercise in exercises {
            newPlan.exercises.append(exercise.duplicate())
        }
        
        newPlan.scheduledDays = scheduledDays
        newPlan.estimatedDuration = estimatedDuration
        
        return newPlan
    }
}

// MARK: - Enums

enum Difficulty: String, CaseIterable, Codable {
    case beginner = "初心者"
    case intermediate = "中級者"
    case advanced = "上級者"
    case expert = "エキスパート"
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "運動習慣を始めたばかりの方向け"
        case .intermediate: return "基本的な動きに慣れた方向け"
        case .advanced: return "高強度トレーニングができる方向け"
        case .expert: return "プロレベルのトレーニング"
        }
    }
}

enum WorkoutCategory: String, CaseIterable, Codable {
    case general = "総合"
    case strength = "筋力トレーニング"
    case cardio = "有酸素運動"
    case hiit = "HIIT"
    case yoga = "ヨガ"
    case stretching = "ストレッチ"
    case bodyweight = "自重トレーニング"
    case crossfit = "クロスフィット"
    
    var icon: String {
        switch self {
        case .general: return "figure.walk"
        case .strength: return "dumbbell"
        case .cardio: return "heart.fill"
        case .hiit: return "flame.fill"
        case .yoga: return "figure.yoga"
        case .stretching: return "figure.flexibility"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .crossfit: return "figure.cross.training"
        }
    }
}

enum WeekDay: String, CaseIterable, Codable {
    case monday = "月曜日"
    case tuesday = "火曜日"
    case wednesday = "水曜日"
    case thursday = "木曜日"
    case friday = "金曜日"
    case saturday = "土曜日"
    case sunday = "日曜日"
    
    var shortName: String {
        String(rawValue.prefix(1))
    }
    
    var dayNumber: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}