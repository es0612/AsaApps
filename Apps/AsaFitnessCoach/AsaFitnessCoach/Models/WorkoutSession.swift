//
//  WorkoutSession.swift
//  AsaFitnessCoach
//
//  ワークアウトセッション実績のデータモデル
//

import Foundation
import SwiftData

// MARK: - ワークアウトセッション

@Model
final class WorkoutSession {
    // MARK: - Properties

    var id: UUID = UUID()
    var planId: UUID?
    var planName: String
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool = false

    // 完了したエクササイズ
    var completedExercises: [CompletedExercise] = []

    // ヘルスデータ
    var totalCalories: Double?
    var averageHeartRate: Int?
    var peakHeartRate: Int?

    // フィードバック
    var rating: SessionRating?
    var perceivedExertion: Int?  // RPE 1-10
    var notes: String?

    // リレーション
    var workoutPlan: WorkoutPlan?

    // MARK: - Initialization

    init(planName: String, startTime: Date = Date()) {
        self.planName = planName
        self.startTime = startTime
    }

    // MARK: - Computed Properties

    /// セッションの継続時間（分）
    var duration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime) / 60
        }
        return endTime.timeIntervalSince(startTime) / 60
    }

    /// 表示用の継続時間
    var displayDuration: String {
        let minutes = Int(duration)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)時間\(remainingMinutes)分"
        }
        return "\(minutes)分"
    }

    /// 完了率
    var completionRate: Double {
        guard !completedExercises.isEmpty else { return 0 }
        let completedCount = completedExercises.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(completedExercises.count)
    }

    /// 総ボリューム
    var totalVolume: Double {
        completedExercises.reduce(0) { $0 + ($1.totalVolume ?? 0) }
    }

    /// 平均フォーム品質
    var averageFormQuality: FormQuality? {
        let qualities = completedExercises.compactMap { $0.formQuality }
        guard !qualities.isEmpty else { return nil }
        let average = qualities.reduce(0) { $0 + $1.numericValue } / qualities.count
        return FormQuality.allCases.first { $0.numericValue == average }
    }

    // MARK: - Methods

    func complete() {
        endTime = Date()
        isCompleted = true
    }

    func addCompletedExercise(_ exercise: CompletedExercise) {
        completedExercises.append(exercise)
    }
}

// MARK: - CompletedExercise

/// 完了したエクササイズの記録
struct CompletedExercise: Codable, Identifiable {
    var id: UUID = UUID()
    var exerciseId: UUID
    var exerciseName: String
    var isCompleted: Bool = false

    // 実際の実績
    var actualSets: [SetRecord] = []

    // フォーム品質
    var formQuality: FormQuality?
    var notes: String?

    // 計算プロパティ
    var actualWeight: [Double] {
        actualSets.map { $0.weight ?? 0 }
    }

    var averageWeight: Double? {
        let weights = actualSets.compactMap { $0.weight }
        guard !weights.isEmpty else { return nil }
        return weights.reduce(0, +) / Double(weights.count)
    }

    var totalVolume: Double? {
        actualSets.reduce(0) { total, set in
            total + (set.weight ?? 0) * Double(set.reps ?? 0)
        }
    }

    var completionRate: Double {
        let completedSets = actualSets.filter { $0.isCompleted }.count
        guard !actualSets.isEmpty else { return 0 }
        return Double(completedSets) / Double(actualSets.count)
    }
}

// MARK: - SetRecord

/// 個別セットの記録
struct SetRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var setNumber: Int
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval?
    var isCompleted: Bool = false
    var restTaken: TimeInterval?
}

// MARK: - SessionRating

enum SessionRating: Int, CaseIterable, Codable {
    case terrible = 1
    case poor = 2
    case okay = 3
    case good = 4
    case excellent = 5

    var displayName: String {
        switch self {
        case .terrible: return "とても悪い"
        case .poor: return "悪い"
        case .okay: return "普通"
        case .good: return "良い"
        case .excellent: return "とても良い"
        }
    }

    var emoji: String {
        switch self {
        case .terrible: return "😢"
        case .poor: return "😕"
        case .okay: return "😐"
        case .good: return "😊"
        case .excellent: return "🤩"
        }
    }
}

// MARK: - FormQuality

enum FormQuality: String, CaseIterable, Codable {
    case poor = "要改善"
    case fair = "まあまあ"
    case good = "良い"
    case excellent = "完璧"

    var numericValue: Int {
        switch self {
        case .poor: return 1
        case .fair: return 2
        case .good: return 3
        case .excellent: return 4
        }
    }

    var color: String {
        switch self {
        case .poor: return "red"
        case .fair: return "yellow"
        case .good: return "green"
        case .excellent: return "blue"
        }
    }
}
