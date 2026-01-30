//
//  UserProfile.swift
//  AsaFitnessCoach
//
//  ユーザープロファイルのデータモデル
//

import Foundation
import SwiftData

// MARK: - ユーザープロファイル

@Model
final class UserProfile {
    // MARK: - Properties

    var id: UUID = UUID()
    var name: String
    var birthDate: Date?
    var gender: Gender?
    var height: Double?           // cm
    var weight: Double?           // kg
    var fitnessLevel: FitnessLevel
    var primaryGoal: FitnessGoalType
    var availableEquipment: [Equipment] = []
    var preferredWorkoutDuration: Int  // 分
    var workoutDaysPerWeek: Int
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Initialization

    init(
        name: String,
        fitnessLevel: FitnessLevel = .beginner,
        primaryGoal: FitnessGoalType = .generalFitness,
        preferredWorkoutDuration: Int = 30,
        workoutDaysPerWeek: Int = 3
    ) {
        self.name = name
        self.fitnessLevel = fitnessLevel
        self.primaryGoal = primaryGoal
        self.preferredWorkoutDuration = preferredWorkoutDuration
        self.workoutDaysPerWeek = workoutDaysPerWeek
    }

    // MARK: - Computed Properties

    var age: Int? {
        guard let birthDate = birthDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: Date())
        return components.year
    }

    var bmi: Double? {
        guard let weight = weight, let height = height, height > 0 else { return nil }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }

    var bmiCategory: String? {
        guard let bmi = bmi else { return nil }
        switch bmi {
        case ..<18.5:
            return "低体重"
        case 18.5..<25:
            return "標準"
        case 25..<30:
            return "過体重"
        default:
            return "肥満"
        }
    }

    // MARK: - Methods

    func updateProfile() {
        updatedAt = Date()
    }
}

// MARK: - Gender

enum Gender: String, CaseIterable, Codable {
    case male = "男性"
    case female = "女性"
    case other = "その他"
    case preferNotToSay = "未回答"

    var icon: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .other: return "person"
        case .preferNotToSay: return "person.crop.circle.badge.questionmark"
        }
    }
}

// MARK: - FitnessLevel

enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "初心者"
    case intermediate = "中級者"
    case advanced = "上級者"
    case expert = "エキスパート"

    var description: String {
        switch self {
        case .beginner:
            return "運動習慣を始めたばかり、または6ヶ月未満"
        case .intermediate:
            return "定期的に運動している（6ヶ月〜2年）"
        case .advanced:
            return "高強度トレーニングができる（2年以上）"
        case .expert:
            return "プロレベルのトレーニング経験"
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "star"
        case .intermediate: return "star.leadinghalf.filled"
        case .advanced: return "star.fill"
        case .expert: return "crown.fill"
        }
    }

    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }

    /// 難易度乗数（AIスコアリング用）
    var difficultyMultiplier: Double {
        switch self {
        case .beginner: return 0.6
        case .intermediate: return 0.8
        case .advanced: return 1.0
        case .expert: return 1.2
        }
    }
}

// MARK: - FitnessGoalType

enum FitnessGoalType: String, CaseIterable, Codable {
    case muscleGain = "筋力アップ"
    case weightLoss = "減量"
    case endurance = "持久力向上"
    case flexibility = "柔軟性向上"
    case generalFitness = "総合的な健康"
    case athleticPerformance = "運動能力向上"
    case rehabilitation = "リハビリ"

    var description: String {
        switch self {
        case .muscleGain:
            return "筋肉量を増やし、力強い体を目指す"
        case .weightLoss:
            return "体脂肪を減らし、理想の体重に近づく"
        case .endurance:
            return "スタミナと心肺機能を向上させる"
        case .flexibility:
            return "可動域を広げ、怪我を予防する"
        case .generalFitness:
            return "バランスの良い健康的な体づくり"
        case .athleticPerformance:
            return "スポーツパフォーマンスを向上させる"
        case .rehabilitation:
            return "怪我からの回復と機能改善"
        }
    }

    var icon: String {
        switch self {
        case .muscleGain: return "dumbbell.fill"
        case .weightLoss: return "flame.fill"
        case .endurance: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .generalFitness: return "figure.walk"
        case .athleticPerformance: return "sportscourt.fill"
        case .rehabilitation: return "cross.case.fill"
        }
    }

    /// 推奨されるワークアウトカテゴリ
    var recommendedCategories: [WorkoutCategory] {
        switch self {
        case .muscleGain:
            return [.strength, .bodyweight]
        case .weightLoss:
            return [.hiit, .cardio, .strength]
        case .endurance:
            return [.cardio, .hiit]
        case .flexibility:
            return [.yoga, .stretching]
        case .generalFitness:
            return [.general, .bodyweight, .cardio]
        case .athleticPerformance:
            return [.crossfit, .hiit, .strength]
        case .rehabilitation:
            return [.stretching, .yoga, .bodyweight]
        }
    }
}

// MARK: - Equipment

enum Equipment: String, CaseIterable, Codable {
    case none = "器具なし"
    case dumbbells = "ダンベル"
    case barbell = "バーベル"
    case kettlebell = "ケトルベル"
    case resistanceBands = "レジスタンスバンド"
    case pullUpBar = "懸垂バー"
    case bench = "ベンチ"
    case cableMachine = "ケーブルマシン"
    case treadmill = "トレッドミル"
    case stationaryBike = "エアロバイク"
    case rowingMachine = "ローイングマシン"
    case yogaMat = "ヨガマット"
    case foamRoller = "フォームローラー"
    case jumpRope = "縄跳び"
    case medicineBall = "メディシンボール"

    var icon: String {
        switch self {
        case .none: return "hand.raised"
        case .dumbbells: return "dumbbell"
        case .barbell: return "figure.strengthtraining.traditional"
        case .kettlebell: return "figure.strengthtraining.functional"
        case .resistanceBands: return "arrow.up.and.down"
        case .pullUpBar: return "figure.climbing"
        case .bench: return "rectangle.split.3x3"
        case .cableMachine: return "square.stack.3d.up"
        case .treadmill: return "figure.run"
        case .stationaryBike: return "bicycle"
        case .rowingMachine: return "figure.rower"
        case .yogaMat: return "figure.yoga"
        case .foamRoller: return "circle"
        case .jumpRope: return "figure.jumprope"
        case .medicineBall: return "circle.fill"
        }
    }

    /// カテゴリ（ホームジム、ジム、自重）
    var category: EquipmentCategory {
        switch self {
        case .none:
            return .bodyweight
        case .dumbbells, .resistanceBands, .yogaMat, .foamRoller, .jumpRope, .medicineBall:
            return .home
        case .barbell, .kettlebell, .pullUpBar, .bench, .cableMachine, .treadmill, .stationaryBike, .rowingMachine:
            return .gym
        }
    }
}

enum EquipmentCategory: String, CaseIterable, Codable {
    case bodyweight = "自重"
    case home = "ホームジム"
    case gym = "ジム"
}
