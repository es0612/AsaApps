//
//  AIRecommendation.swift
//  AsaFitnessCoach
//
//  AI運動プラン提案結果のデータモデル
//

import Foundation

// MARK: - AIRecommendation

/// AI運動プラン提案の結果
struct AIRecommendation: Identifiable {
    var id: UUID = UUID()
    var planName: String
    var planDescription: String
    var exercises: [RecommendedExercise]
    var category: WorkoutCategory
    var difficulty: Difficulty
    var estimatedDuration: Int  // 分
    var confidence: Double  // 0.0-1.0
    var reasons: [RecommendationReason]
    var createdAt: Date = Date()

    /// 信頼度のテキスト表現
    var confidenceText: String {
        switch confidence {
        case 0.9...: return "非常に高い"
        case 0.75..<0.9: return "高い"
        case 0.6..<0.75: return "中程度"
        case 0.4..<0.6: return "やや低い"
        default: return "低い"
        }
    }

    /// 信頼度のカラー
    var confidenceColor: String {
        switch confidence {
        case 0.75...: return "green"
        case 0.5..<0.75: return "yellow"
        default: return "red"
        }
    }
}

// MARK: - RecommendedExercise

/// 提案されたエクササイズ
struct RecommendedExercise: Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: ExerciseCategory
    var targetMuscles: [MuscleGroup]
    var suggestedSets: Int
    var suggestedReps: Int
    var suggestedWeight: Double?
    var suggestedDuration: TimeInterval?
    var restTime: TimeInterval
    var instructions: String?
    var matchScore: Double  // 0.0-1.0 このエクササイズがどれだけユーザーに適しているか
}

// MARK: - RecommendationReason

/// 提案理由
struct RecommendationReason: Identifiable {
    var id: UUID = UUID()
    var factor: RecommendationFactor
    var score: Double  // 0.0-1.0
    var explanation: String

    var displayScore: String {
        "\(Int(score * 100))%"
    }
}

// MARK: - RecommendationFactor

/// 6要因の提案ファクター
enum RecommendationFactor: String, CaseIterable {
    case goalAlignment = "目標適合度"
    case fitnessLevel = "体力レベル"
    case equipmentMatch = "機器適合"
    case timeConstraint = "時間制約"
    case recoveryStatus = "回復状態"
    case progressionRate = "進捗ペース"

    var description: String {
        switch self {
        case .goalAlignment:
            return "ユーザーの目標との一致度"
        case .fitnessLevel:
            return "体力レベルに適した難易度"
        case .equipmentMatch:
            return "利用可能な器具でできるか"
        case .timeConstraint:
            return "設定時間内に収まるか"
        case .recoveryStatus:
            return "筋肉グループの回復状態"
        case .progressionRate:
            return "過去の進捗に基づく適切な負荷"
        }
    }

    var icon: String {
        switch self {
        case .goalAlignment: return "target"
        case .fitnessLevel: return "chart.line.uptrend.xyaxis"
        case .equipmentMatch: return "dumbbell"
        case .timeConstraint: return "clock"
        case .recoveryStatus: return "heart.fill"
        case .progressionRate: return "arrow.up.right"
        }
    }

    /// デフォルトの重み
    var defaultWeight: Double {
        switch self {
        case .goalAlignment: return 0.25
        case .fitnessLevel: return 0.20
        case .equipmentMatch: return 0.15
        case .timeConstraint: return 0.15
        case .recoveryStatus: return 0.15
        case .progressionRate: return 0.10
        }
    }
}

// MARK: - PlanWeights

/// 6要因の重み設定
struct PlanWeights {
    var goalAlignment: Double
    var fitnessLevel: Double
    var equipmentMatch: Double
    var timeConstraint: Double
    var recoveryStatus: Double
    var progressionRate: Double

    static let `default` = PlanWeights(
        goalAlignment: 0.25,
        fitnessLevel: 0.20,
        equipmentMatch: 0.15,
        timeConstraint: 0.15,
        recoveryStatus: 0.15,
        progressionRate: 0.10
    )

    /// 合計が1.0になるよう正規化
    func normalized() -> PlanWeights {
        let total = goalAlignment + fitnessLevel + equipmentMatch + timeConstraint + recoveryStatus + progressionRate
        guard total > 0 else { return PlanWeights.default }
        return PlanWeights(
            goalAlignment: goalAlignment / total,
            fitnessLevel: fitnessLevel / total,
            equipmentMatch: equipmentMatch / total,
            timeConstraint: timeConstraint / total,
            recoveryStatus: recoveryStatus / total,
            progressionRate: progressionRate / total
        )
    }
}

// MARK: - ProgressiveOverloadSuggestion

/// プログレッシブオーバーロードの提案
struct ProgressiveOverloadSuggestion: Identifiable {
    var id: UUID = UUID()
    var exerciseName: String
    var currentWeight: Double
    var suggestedWeight: Double
    var increasePercentage: Double
    var reason: String
    var confidence: ConfidenceLevel

    enum ConfidenceLevel: String {
        case high = "高い自信度"
        case medium = "中程度の自信度"
        case low = "低い自信度"

        var color: String {
            switch self {
            case .high: return "green"
            case .medium: return "yellow"
            case .low: return "red"
            }
        }
    }

    var displayIncrease: String {
        String(format: "+%.1f%%", increasePercentage)
    }

    var displayWeightChange: String {
        String(format: "%.1fkg → %.1fkg", currentWeight, suggestedWeight)
    }
}
