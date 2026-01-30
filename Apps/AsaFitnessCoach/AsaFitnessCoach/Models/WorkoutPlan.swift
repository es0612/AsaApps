//
//  WorkoutPlan.swift
//  AsaFitnessCoach
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
    var targetMuscleGroups: [MuscleGroup] = []
    var isActive: Bool = false
    var isAIGenerated: Bool = false
    var aiConfidence: Double?
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
    var estimatedDuration: TimeInterval = 0

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
        sessions
            .filter { $0.isCompleted }
            .max(by: { $0.startTime < $1.startTime })?.startTime
    }

    /// 完了率（%）
    var completionRate: Double {
        let completedCount = sessions.filter { $0.isCompleted }.count
        let totalCount = sessions.count
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount) * 100
    }

    /// 今日実行すべきプランかどうか
    var isScheduledForToday: Bool {
        let today = Calendar.current.component(.weekday, from: Date())
        return scheduledDays.contains { $0.dayNumber == today }
    }

    /// 表示用の推定時間
    var displayEstimatedDuration: String {
        let minutes = Int(estimatedDuration)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)時間\(remainingMinutes)分"
        }
        return "\(minutes)分"
    }

    // MARK: - Methods

    func addExercise(_ exercise: Exercise) {
        exercise.order = exercises.count
        exercises.append(exercise)
        updateEstimatedDuration()
        updatedAt = Date()
    }

    func removeExercise(_ exercise: Exercise) {
        exercises.removeAll { $0.id == exercise.id }
        reorderExercises()
        updateEstimatedDuration()
        updatedAt = Date()
    }

    func reorderExercises() {
        for (index, exercise) in exercises.enumerated() {
            exercise.order = index
        }
    }

    func updateEstimatedDuration() {
        let totalSeconds = exercises.reduce(0.0) { total, exercise in
            total + exercise.estimatedDuration
        }
        // 秒から分に変換
        estimatedDuration = totalSeconds / 60.0
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

        newPlan.targetMuscleGroups = targetMuscleGroups
        newPlan.scheduledDays = scheduledDays
        newPlan.estimatedDuration = estimatedDuration
        newPlan.isAIGenerated = false

        return newPlan
    }
}

// MARK: - Difficulty

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

    var numericValue: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}

// MARK: - WorkoutCategory

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

    var color: String {
        switch self {
        case .general: return "gray"
        case .strength: return "blue"
        case .cardio: return "red"
        case .hiit: return "orange"
        case .yoga: return "purple"
        case .stretching: return "teal"
        case .bodyweight: return "green"
        case .crossfit: return "indigo"
        }
    }
}

// MARK: - WeekDay

enum WeekDay: String, CaseIterable, Codable {
    case sunday = "日曜日"
    case monday = "月曜日"
    case tuesday = "火曜日"
    case wednesday = "水曜日"
    case thursday = "木曜日"
    case friday = "金曜日"
    case saturday = "土曜日"

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

    static var today: WeekDay {
        let todayNumber = Calendar.current.component(.weekday, from: Date())
        return WeekDay.allCases.first { $0.dayNumber == todayNumber } ?? .monday
    }
}
