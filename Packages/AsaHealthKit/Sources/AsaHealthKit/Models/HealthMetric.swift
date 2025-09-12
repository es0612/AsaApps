//
//  HealthMetric.swift
//  AsaHealthKit
//
//  健康指標の基本データモデル定義
//  すべての健康関連データの共通インターフェース
//

import Foundation
import AsaCoreKit

// MARK: - 健康指標基本プロトコル

/// 健康指標の基本要件
public protocol HealthMetric: CRUDModel {
    /// 記録日時
    var recordedAt: Date { get }
    /// 指標値（数値）
    var value: Double { get }
    /// 指標の種類
    var metricType: HealthMetricType { get }
    /// オプショナルなメモ
    var note: String? { get }
}

// MARK: - 健康指標タイプ

/// 健康指標の種類を定義する列挙型
public enum HealthMetricType: String, CaseIterable, Codable, Sendable {
    case waterIntake = "water_intake"           // 水分摂取 (ml)
    case steps = "steps"                        // 歩数 (歩)
    case sleep = "sleep"                        // 睡眠時間 (時間)
    case weight = "weight"                      // 体重 (kg)
    case workout = "workout"                    // ワークアウト時間 (分)
    case mood = "mood"                         // 気分 (1-10スケール)
    case heartRate = "heart_rate"              // 心拍数 (bpm)
    case bodyFat = "body_fat"                  // 体脂肪率 (%)
    
    /// 指標の日本語名
    public var displayName: String {
        switch self {
        case .waterIntake: return "水分摂取"
        case .steps: return "歩数"
        case .sleep: return "睡眠"
        case .weight: return "体重"
        case .workout: return "ワークアウト"
        case .mood: return "気分"
        case .heartRate: return "心拍数"
        case .bodyFat: return "体脂肪率"
        }
    }
    
    /// 指標の単位
    public var unit: String {
        switch self {
        case .waterIntake: return HealthKitConstants.Units.waterML
        case .steps: return HealthKitConstants.Units.steps
        case .sleep: return HealthKitConstants.Units.sleepHours
        case .weight: return HealthKitConstants.Units.weight
        case .workout: return HealthKitConstants.Units.workoutMinutes
        case .mood: return "点"
        case .heartRate: return "bpm"
        case .bodyFat: return HealthKitConstants.Units.bodyFat
        }
    }
    
    /// デフォルト目標値
    public var defaultGoal: Double {
        switch self {
        case .waterIntake: return Double(HealthKitConstants.DefaultGoals.dailyWaterML)
        case .steps: return Double(HealthKitConstants.DefaultGoals.dailySteps)
        case .sleep: return HealthKitConstants.DefaultGoals.dailySleepHours
        case .weight: return 65.0  // 参考値
        case .workout: return Double(HealthKitConstants.DefaultGoals.weeklyWorkoutMinutes) / 7.0
        case .mood: return 7.0     // 良好なレベル
        case .heartRate: return 70.0  // 安静時心拍数
        case .bodyFat: return 18.0    // 健康的な体脂肪率
        }
    }
}

// MARK: - 汎用健康記録

/// 汎用的な健康指標記録
public struct GenericHealthRecord: HealthMetric {
    public let id: UUID
    public let recordedAt: Date
    public let value: Double
    public let metricType: HealthMetricType
    public let note: String?
    
    public init(value: Double, metricType: HealthMetricType, recordedAt: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.value = value
        self.metricType = metricType
        self.recordedAt = recordedAt
        self.note = note
    }
}

// MARK: - 専用健康指標モデル

/// 水分摂取記録
public struct WaterIntakeRecord: HealthMetric {
    public let id: UUID
    public let recordedAt: Date
    public let value: Double  // ml
    public let metricType: HealthMetricType
    public let note: String?
    
    /// 飲み物の種類（オプション）
    public let drinkType: DrinkType?
    
    public init(amount: Double, drinkType: DrinkType? = nil, recordedAt: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.value = amount
        self.metricType = .waterIntake
        self.drinkType = drinkType
        self.recordedAt = recordedAt
        self.note = note
    }
}

/// 飲み物の種類
public enum DrinkType: String, CaseIterable, Codable, Sendable {
    case water = "water"
    case tea = "tea"
    case coffee = "coffee"
    case juice = "juice"
    case sports = "sports"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .water: return "水"
        case .tea: return "お茶"
        case .coffee: return "コーヒー"
        case .juice: return "ジュース"
        case .sports: return "スポーツ飲料"
        case .other: return "その他"
        }
    }
}

/// 睡眠記録
public struct SleepRecord: HealthMetric {
    public let id: UUID
    public let recordedAt: Date
    public let value: Double  // 睡眠時間（時間）
    public let metricType: HealthMetricType
    public let note: String?
    
    /// 就寝時間
    public let bedtime: Date
    /// 起床時間
    public let wakeupTime: Date
    /// 睡眠の質（1-10スケール）
    public let quality: Int?
    
    public init(bedtime: Date, wakeupTime: Date, quality: Int? = nil, note: String? = nil) {
        self.id = UUID()
        self.bedtime = bedtime
        self.wakeupTime = wakeupTime
        self.value = wakeupTime.timeIntervalSince(bedtime) / 3600  // 時間に変換
        self.metricType = .sleep
        self.recordedAt = wakeupTime  // 起床時を記録時間とする
        self.quality = quality
        self.note = note
    }
}

/// 歩数記録
public struct StepRecord: HealthMetric {
    public let id: UUID
    public let recordedAt: Date
    public let value: Double  // 歩数
    public let metricType: HealthMetricType
    public let note: String?
    
    /// 距離（km）
    public let distance: Double?
    /// カロリー消費（kcal）
    public let calories: Double?
    
    public init(steps: Int, distance: Double? = nil, calories: Double? = nil, recordedAt: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.value = Double(steps)
        self.metricType = .steps
        self.distance = distance
        self.calories = calories
        self.recordedAt = recordedAt
        self.note = note
    }
}

/// 気分記録
public struct MoodRecord: HealthMetric {
    public let id: UUID
    public let recordedAt: Date
    public let value: Double  // 気分スコア (1-10)
    public let metricType: HealthMetricType
    public let note: String?
    
    /// 気分のタグ
    public let tags: [MoodTag]
    
    public init(score: Int, tags: [MoodTag] = [], recordedAt: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.value = Double(max(1, min(10, score)))  // 1-10の範囲に制限
        self.metricType = .mood
        self.tags = tags
        self.recordedAt = recordedAt
        self.note = note
    }
}

/// 気分タグ
public enum MoodTag: String, CaseIterable, Codable, Sendable {
    case happy = "happy"
    case sad = "sad"
    case stressed = "stressed"
    case relaxed = "relaxed"
    case energetic = "energetic"
    case tired = "tired"
    case anxious = "anxious"
    case confident = "confident"
    
    public var displayName: String {
        switch self {
        case .happy: return "嬉しい"
        case .sad: return "悲しい"
        case .stressed: return "ストレス"
        case .relaxed: return "リラックス"
        case .energetic: return "元気"
        case .tired: return "疲れ"
        case .anxious: return "不安"
        case .confident: return "自信"
        }
    }
    
    public var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .stressed: return "😰"
        case .relaxed: return "😌"
        case .energetic: return "⚡"
        case .tired: return "😴"
        case .anxious: return "😟"
        case .confident: return "💪"
        }
    }
}