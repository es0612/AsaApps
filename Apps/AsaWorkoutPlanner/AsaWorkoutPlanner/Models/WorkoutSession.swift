//
//  WorkoutSession.swift
//  AsaWorkoutPlanner
//
//  ワークアウトセッションのデータモデル
//

import Foundation
import SwiftData

// MARK: - ワークアウトセッション

@Model
final class WorkoutSession {
    // MARK: - Properties
    
    var id: UUID = UUID()
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool = false
    var isPaused: Bool = false
    var pausedDuration: TimeInterval = 0
    
    // セッション情報
    var totalCaloriesBurned: Double = 0
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var notes: String?
    var rating: SessionRating?
    var weatherCondition: String?
    var location: String?
    
    // リレーション
    var workoutPlan: WorkoutPlan?
    
    @Relationship(deleteRule: .cascade)
    var completedExercises: [CompletedExercise] = []
    
    // MARK: - Initialization
    
    init(workoutPlan: WorkoutPlan? = nil) {
        self.startTime = Date()
        self.workoutPlan = workoutPlan
    }
    
    // MARK: - Computed Properties
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime) - pausedDuration
    }
    
    var displayDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var completionRate: Double {
        guard let plan = workoutPlan, !plan.exercises.isEmpty else { return 0 }
        let completedCount = completedExercises.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(plan.exercises.count)
    }
    
    var completionPercentage: Int {
        Int(completionRate * 100)
    }
    
    var totalVolume: Double {
        completedExercises.reduce(0) { total, exercise in
            total + (exercise.totalVolume ?? 0)
        }
    }
    
    var sessionDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: startTime)
    }
    
    // MARK: - Methods
    
    func start() {
        startTime = Date()
        isCompleted = false
        isPaused = false
    }
    
    func pause() {
        isPaused = true
    }
    
    func resume() {
        isPaused = false
    }
    
    func complete() {
        endTime = Date()
        isCompleted = true
        isPaused = false
        calculateCalories()
    }
    
    func cancel() {
        endTime = Date()
        isCompleted = false
        isPaused = false
    }
    
    func addCompletedExercise(_ exercise: CompletedExercise) {
        completedExercises.append(exercise)
        exercise.workoutSession = self
    }
    
    private func calculateCalories() {
        let durationInMinutes = duration / 60
        let bodyWeight = 70.0  // デフォルト体重（将来的にユーザー設定から取得）
        let age = 30.0  // デフォルト年齢
        let isMale = true  // デフォルト性別

        // 心拍数データがある場合は心拍数ベースの計算
        if let avgHR = averageHeartRate, avgHR > 0 {
            // Keytel式: より正確なカロリー計算
            // 男性: ((年齢 × 0.2017) + (体重 × 0.09036) + (心拍数 × 0.6309) - 55.0969) × 時間 / 4.184
            // 女性: ((年齢 × 0.074) + (体重 × 0.05741) + (心拍数 × 0.4472) - 20.4022) × 時間 / 4.184

            let caloriesPerMinute = if isMale {
                ((age * 0.2017) + (bodyWeight * 0.09036) + (Double(avgHR) * 0.6309) - 55.0969) / 4.184
            } else {
                ((age * 0.074) + (bodyWeight * 0.05741) + (Double(avgHR) * 0.4472) - 20.4022) / 4.184
            }

            totalCaloriesBurned = caloriesPerMinute * durationInMinutes
        } else {
            // 心拍数データがない場合はMET値ベース
            let averageMET = 6.0  // 中強度の運動として仮定
            totalCaloriesBurned = averageMET * bodyWeight * durationInMinutes / 60
        }
    }
    
    func exportSummary() -> String {
        var summary = "【ワークアウトセッション】\n"
        summary += "日時: \(sessionDate)\n"
        summary += "時間: \(displayDuration)\n"
        summary += "完了率: \(completionPercentage)%\n"
        summary += "総ボリューム: \(String(format: "%.1f", totalVolume))kg\n"
        summary += "消費カロリー: \(String(format: "%.0f", totalCaloriesBurned))kcal\n"
        
        if let notes = notes, !notes.isEmpty {
            summary += "メモ: \(notes)\n"
        }
        
        if let rating = rating {
            summary += "評価: \(rating.emoji)\n"
        }
        
        return summary
    }
}

// MARK: - 完了したエクササイズ

@Model
final class CompletedExercise {
    // MARK: - Properties
    
    var id: UUID = UUID()
    var exerciseName: String
    var category: ExerciseCategory
    var isCompleted: Bool = false
    var completedAt: Date?
    
    // 実行データ
    var plannedSets: Int
    var completedSets: Int = 0
    var plannedReps: Int
    var actualReps: [Int] = []  // 各セットの実際のレップ数
    var weight: Double?
    var actualWeight: [Double] = []  // 各セットの実際の重量
    var duration: TimeInterval?
    var actualDuration: TimeInterval?
    var restTimeUsed: [TimeInterval] = []  // 各セット間の実際の休憩時間
    
    // パフォーマンス評価
    var difficulty: ExerciseDifficulty?
    var formQuality: FormQuality?
    var notes: String?
    
    // リレーション
    var workoutSession: WorkoutSession?
    
    // MARK: - Initialization
    
    init(from exercise: Exercise) {
        self.exerciseName = exercise.name
        self.category = exercise.category
        self.plannedSets = exercise.sets
        self.plannedReps = exercise.reps
        self.weight = exercise.weight
        self.duration = exercise.duration
    }
    
    // MARK: - Computed Properties
    
    var totalVolume: Double? {
        guard !actualWeight.isEmpty else { return nil }
        
        var total = 0.0
        for (index, weight) in actualWeight.enumerated() {
            let reps = index < actualReps.count ? actualReps[index] : plannedReps
            total += weight * Double(reps)
        }
        return total
    }
    
    var completionRate: Double {
        guard plannedSets > 0 else { return 0 }
        return Double(completedSets) / Double(plannedSets)
    }
    
    var averageReps: Double {
        guard !actualReps.isEmpty else { return 0 }
        return Double(actualReps.reduce(0, +)) / Double(actualReps.count)
    }
    
    var averageWeight: Double {
        guard !actualWeight.isEmpty else { return 0 }
        return actualWeight.reduce(0, +) / Double(actualWeight.count)
    }
    
    // MARK: - Methods
    
    func completeSet(reps: Int, weight: Double? = nil) {
        completedSets += 1
        actualReps.append(reps)
        
        if let weight = weight {
            actualWeight.append(weight)
        }
        
        if completedSets >= plannedSets {
            complete()
        }
    }
    
    func complete() {
        isCompleted = true
        completedAt = Date()
    }
    
    func setDifficulty(_ difficulty: ExerciseDifficulty) {
        self.difficulty = difficulty
    }
    
    func setFormQuality(_ quality: FormQuality) {
        self.formQuality = quality
    }
}

// MARK: - Enums

enum SessionRating: Int, CaseIterable, Codable {
    case terrible = 1
    case poor = 2
    case average = 3
    case good = 4
    case excellent = 5
    
    var emoji: String {
        switch self {
        case .terrible: return "😞"
        case .poor: return "😕"
        case .average: return "😐"
        case .good: return "😊"
        case .excellent: return "🔥"
        }
    }
    
    var description: String {
        switch self {
        case .terrible: return "とても悪い"
        case .poor: return "悪い"
        case .average: return "普通"
        case .good: return "良い"
        case .excellent: return "最高"
        }
    }
}

enum ExerciseDifficulty: String, CaseIterable, Codable {
    case tooEasy = "簡単すぎる"
    case easy = "簡単"
    case justRight = "ちょうど良い"
    case hard = "難しい"
    case tooHard = "難しすぎる"
    
    var adjustmentSuggestion: String {
        switch self {
        case .tooEasy: return "重量を10%増やすことをお勧めします"
        case .easy: return "重量を5%増やすことをお勧めします"
        case .justRight: return "現在の設定を維持してください"
        case .hard: return "フォームを確認し、必要に応じて重量を減らしてください"
        case .tooHard: return "重量を10%減らすことをお勧めします"
        }
    }
}

enum FormQuality: String, CaseIterable, Codable {
    case poor = "要改善"
    case acceptable = "可"
    case good = "良"
    case excellent = "優秀"
    
    var color: String {
        switch self {
        case .poor: return "red"
        case .acceptable: return "orange"
        case .good: return "yellow"
        case .excellent: return "green"
        }
    }
}