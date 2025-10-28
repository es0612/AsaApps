//
//  Exercise.swift
//  AsaWorkoutPlanner
//
//  エクササイズのデータモデル
//

import Foundation
import SwiftData

// MARK: - エクササイズ

@Model
final class Exercise {
    // MARK: - Properties
    
    var id: UUID = UUID()
    var name: String
    var category: ExerciseCategory
    var targetMuscles: [MuscleGroup] = []
    var equipmentNeeded: String?
    
    // トレーニング設定
    var sets: Int = 3
    var reps: Int = 10
    var weight: Double?  // kg単位
    var duration: TimeInterval?  // 秒単位（時間ベースの運動用）

    /// セット間の休憩時間（秒単位）
    /// - Note: WorkoutPlanの推定時間計算時には分単位に変換される
    var restTime: TimeInterval = 60  // デフォルト: 60秒

    var tempo: String?  // 例: "3-1-2-1" (下降-停止-上昇-停止)
    
    // 詳細情報
    var notes: String?
    var videoURL: String?
    var imageURL: String?
    var instructions: String?
    var tips: String?
    
    // 順序管理
    var order: Int = 0
    
    // 作成・更新日時
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // リレーション
    var workoutPlan: WorkoutPlan?
    
    // MARK: - Initialization
    
    init(
        name: String,
        category: ExerciseCategory,
        sets: Int = 3,
        reps: Int = 10,
        restTime: TimeInterval = 60
    ) {
        self.name = name
        self.category = category
        self.sets = sets
        self.reps = reps
        self.restTime = restTime
    }
    
    // MARK: - Computed Properties
    
    var totalVolume: Double? {
        guard let weight = weight else { return nil }
        return weight * Double(sets * reps)
    }
    
    var displayDuration: String {
        if let duration = duration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        return ""
    }
    
    var displayRestTime: String {
        let minutes = Int(restTime) / 60
        let seconds = Int(restTime) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)秒"
        }
    }
    
    var isTimeBasedExercise: Bool {
        duration != nil
    }
    
    // MARK: - Methods
    
    func duplicate() -> Exercise {
        let newExercise = Exercise(
            name: name,
            category: category,
            sets: sets,
            reps: reps,
            restTime: restTime
        )
        
        newExercise.targetMuscles = targetMuscles
        newExercise.equipmentNeeded = equipmentNeeded
        newExercise.weight = weight
        newExercise.duration = duration
        newExercise.tempo = tempo
        newExercise.notes = notes
        newExercise.videoURL = videoURL
        newExercise.imageURL = imageURL
        newExercise.instructions = instructions
        newExercise.tips = tips
        newExercise.order = order
        
        return newExercise
    }
    
    func updateWeight(_ newWeight: Double) {
        weight = newWeight
        updatedAt = Date()
    }
    
    func progressiveOverload(percentage: Double = 0.05) {
        if let currentWeight = weight {
            weight = currentWeight * (1 + percentage)
        } else {
            reps += 1
        }
        updatedAt = Date()
    }
}

// MARK: - Enums

enum ExerciseCategory: String, CaseIterable, Codable {
    case chest = "胸"
    case back = "背中"
    case legs = "脚"
    case shoulders = "肩"
    case arms = "腕"
    case core = "体幹"
    case cardio = "有酸素"
    case flexibility = "柔軟性"
    case compound = "コンパウンド"
    
    var icon: String {
        switch self {
        case .chest: return "rectangle.expand.vertical"
        case .back: return "arrow.up.and.down"
        case .legs: return "figure.walk"
        case .shoulders: return "chevron.up"
        case .arms: return "hand.raised"
        case .core: return "circle.grid.3x3"
        case .cardio: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .compound: return "square.stack.3d.up"
        }
    }
    
    var color: String {
        switch self {
        case .chest: return "blue"
        case .back: return "green"
        case .legs: return "orange"
        case .shoulders: return "purple"
        case .arms: return "red"
        case .core: return "yellow"
        case .cardio: return "pink"
        case .flexibility: return "teal"
        case .compound: return "indigo"
        }
    }
}

enum MuscleGroup: String, CaseIterable, Codable {
    // 上半身
    case pectoralisMajor = "大胸筋"
    case pectoralisMinor = "小胸筋"
    case latissimusDorsi = "広背筋"
    case trapezius = "僧帽筋"
    case rhomboids = "菱形筋"
    case deltoids = "三角筋"
    case biceps = "上腕二頭筋"
    case triceps = "上腕三頭筋"
    case forearms = "前腕"
    
    // 体幹
    case rectusAbdominis = "腹直筋"
    case obliques = "腹斜筋"
    case transverseAbdominis = "腹横筋"
    case erectorSpinae = "脊柱起立筋"
    
    // 下半身
    case quadriceps = "大腿四頭筋"
    case hamstrings = "ハムストリング"
    case glutes = "大臀筋"
    case calves = "ふくらはぎ"
    case hipFlexors = "腸腰筋"
    case adductors = "内転筋"
    case abductors = "外転筋"
    
    var category: String {
        switch self {
        case .pectoralisMajor, .pectoralisMinor:
            return "胸"
        case .latissimusDorsi, .trapezius, .rhomboids:
            return "背中"
        case .deltoids:
            return "肩"
        case .biceps, .triceps, .forearms:
            return "腕"
        case .rectusAbdominis, .obliques, .transverseAbdominis, .erectorSpinae:
            return "体幹"
        case .quadriceps, .hamstrings, .glutes, .calves, .hipFlexors, .adductors, .abductors:
            return "脚"
        }
    }
}