//
//  Exercise.swift
//  AsaFitnessCoach
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
    var requiredEquipment: [Equipment] = []

    // トレーニング設定
    var sets: Int = 3
    var reps: Int = 10
    var weight: Double?           // kg単位
    var duration: TimeInterval?   // 秒単位（時間ベースの運動用）
    var restTime: TimeInterval = 60  // セット間休憩（秒単位）

    // 詳細情報
    var instructions: String?
    var tips: String?
    var videoURL: String?
    var imageURL: String?

    // 難易度
    var difficulty: ExerciseDifficulty = ExerciseDifficulty.intermediate

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

    /// 総ボリューム（重量 × セット × レップ）
    var totalVolume: Double? {
        guard let weight = weight else { return nil }
        return weight * Double(sets * reps)
    }

    /// 表示用の継続時間
    var displayDuration: String {
        guard let duration = duration else { return "" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// 表示用の休憩時間
    var displayRestTime: String {
        let minutes = Int(restTime) / 60
        let seconds = Int(restTime) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)秒"
        }
    }

    /// 時間ベースのエクササイズかどうか
    var isTimeBasedExercise: Bool {
        duration != nil
    }

    /// エクササイズの推定所要時間（秒）
    var estimatedDuration: TimeInterval {
        if let duration = duration {
            // 時間ベースのエクササイズ
            return (duration * Double(sets)) + (restTime * Double(sets - 1))
        } else {
            // レップベースのエクササイズ（1レップ約3秒と仮定）
            let exerciseTime = Double(sets * reps) * 3.0
            let restTotal = restTime * Double(sets - 1)
            return exerciseTime + restTotal
        }
    }

    // MARK: - Methods

    /// エクササイズを複製
    func duplicate() -> Exercise {
        let newExercise = Exercise(
            name: name,
            category: category,
            sets: sets,
            reps: reps,
            restTime: restTime
        )

        newExercise.targetMuscles = targetMuscles
        newExercise.requiredEquipment = requiredEquipment
        newExercise.weight = weight
        newExercise.duration = duration
        newExercise.instructions = instructions
        newExercise.tips = tips
        newExercise.videoURL = videoURL
        newExercise.imageURL = imageURL
        newExercise.difficulty = difficulty
        newExercise.order = order

        return newExercise
    }

    /// 重量を更新
    func updateWeight(_ newWeight: Double) {
        weight = newWeight
        updatedAt = Date()
    }

    /// プログレッシブオーバーロード適用
    func applyProgressiveOverload(percentage: Double = 0.05) {
        if let currentWeight = weight {
            weight = currentWeight * (1 + percentage)
        } else {
            reps += 1
        }
        updatedAt = Date()
    }
}

// MARK: - ExerciseCategory

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
    case fullBody = "全身"

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
        case .fullBody: return "figure.stand"
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
        case .fullBody: return "brown"
        }
    }
}

// MARK: - MuscleGroup

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

    var bodyPart: BodyPart {
        switch self {
        case .pectoralisMajor, .pectoralisMinor, .latissimusDorsi, .trapezius, .rhomboids, .deltoids, .biceps, .triceps, .forearms:
            return .upperBody
        case .rectusAbdominis, .obliques, .transverseAbdominis, .erectorSpinae:
            return .core
        case .quadriceps, .hamstrings, .glutes, .calves, .hipFlexors, .adductors, .abductors:
            return .lowerBody
        }
    }

    /// 回復に必要な時間（時間単位）
    var recoveryTime: Int {
        switch self {
        case .glutes, .quadriceps, .hamstrings, .latissimusDorsi:
            return 72  // 大きな筋肉群
        case .pectoralisMajor, .deltoids, .trapezius:
            return 48  // 中程度の筋肉群
        default:
            return 24  // 小さな筋肉群
        }
    }
}

enum BodyPart: String, CaseIterable, Codable {
    case upperBody = "上半身"
    case core = "体幹"
    case lowerBody = "下半身"
}

// MARK: - ExerciseDifficulty

enum ExerciseDifficulty: String, CaseIterable, Codable {
    case beginner = "初心者向け"
    case intermediate = "中級者向け"
    case advanced = "上級者向け"
    case expert = "エキスパート向け"

    var numericValue: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}
