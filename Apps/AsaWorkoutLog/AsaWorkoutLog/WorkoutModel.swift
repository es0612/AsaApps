//
//  WorkoutModel.swift
//  AsaWorkoutLog
//  
//  Created on 2025/07/01
//

import Foundation

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let workoutType: WorkoutType
    let duration: TimeInterval // 秒単位
    let intensity: WorkoutIntensity
    let caloriesBurned: Int?
    let notes: String?
    
    init(id: UUID = UUID(), date: Date, workoutType: WorkoutType, duration: TimeInterval, intensity: WorkoutIntensity = .moderate, caloriesBurned: Int? = nil, notes: String? = nil) {
        self.id = id
        self.date = date
        self.workoutType = workoutType
        self.duration = duration
        self.intensity = intensity
        self.caloriesBurned = caloriesBurned
        self.notes = notes
    }
    
    var durationFormatted: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct WorkoutGoal: Codable {
    var weeklyTargetMinutes: Int
    var weeklyTargetSessions: Int
    var preferredWorkoutTypes: [WorkoutType]
    
    init() {
        self.weeklyTargetMinutes = 150 // WHO推奨の週150分
        self.weeklyTargetSessions = 3
        self.preferredWorkoutTypes = [.walking, .running]
    }
    
    var weeklyTargetFormatted: String {
        let hours = weeklyTargetMinutes / 60
        let minutes = weeklyTargetMinutes % 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

enum WorkoutType: String, CaseIterable, Codable {
    case running = "running"
    case walking = "walking"
    case cycling = "cycling"
    case swimming = "swimming"
    case weightTraining = "weightTraining"
    case yoga = "yoga"
    case pilates = "pilates"
    case stretching = "stretching"
    case dancing = "dancing"
    case basketball = "basketball"
    case tennis = "tennis"
    case soccer = "soccer"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .running: return "ランニング"
        case .walking: return "ウォーキング"
        case .cycling: return "サイクリング"
        case .swimming: return "水泳"
        case .weightTraining: return "筋トレ"
        case .yoga: return "ヨガ"
        case .pilates: return "ピラティス"
        case .stretching: return "ストレッチ"
        case .dancing: return "ダンス"
        case .basketball: return "バスケットボール"
        case .tennis: return "テニス"
        case .soccer: return "サッカー"
        case .other: return "その他"
        }
    }
    
    var emoji: String {
        switch self {
        case .running: return "🏃‍♂️"
        case .walking: return "🚶‍♂️"
        case .cycling: return "🚴‍♂️"
        case .swimming: return "🏊‍♂️"
        case .weightTraining: return "🏋️‍♂️"
        case .yoga: return "🧘‍♀️"
        case .pilates: return "🤸‍♀️"
        case .stretching: return "🙆‍♂️"
        case .dancing: return "💃"
        case .basketball: return "🏀"
        case .tennis: return "🎾"
        case .soccer: return "⚽"
        case .other: return "🔥"
        }
    }
    
    var color: String {
        switch self {
        case .running, .walking: return "AsaCoffeeBrown"
        case .cycling, .swimming: return "AsaMutedSage"
        case .weightTraining: return "AsaMocha"
        case .yoga, .pilates, .stretching: return "AsaSoftCream"
        default: return "AsaCoffeeBrown"
        }
    }
    
    var estimatedCaloriesPerMinute: Double {
        switch self {
        case .running: return 12.0
        case .walking: return 4.0
        case .cycling: return 8.0
        case .swimming: return 11.0
        case .weightTraining: return 6.0
        case .yoga: return 3.0
        case .pilates: return 4.0
        case .stretching: return 2.0
        case .dancing: return 7.0
        case .basketball: return 10.0
        case .tennis: return 8.0
        case .soccer: return 9.0
        case .other: return 5.0
        }
    }
}

enum WorkoutIntensity: String, CaseIterable, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "veryHigh"
    
    var displayName: String {
        switch self {
        case .low: return "軽い"
        case .moderate: return "普通"
        case .high: return "きつい"
        case .veryHigh: return "とてもきつい"
        }
    }
    
    var emoji: String {
        switch self {
        case .low: return "😌"
        case .moderate: return "😊"
        case .high: return "😤"
        case .veryHigh: return "🔥"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "AsaSoftCream"
        case .moderate: return "AsaMutedSage"
        case .high: return "AsaCoffeeBrown"
        case .veryHigh: return "AsaMocha"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .low: return 0.7
        case .moderate: return 1.0
        case .high: return 1.3
        case .veryHigh: return 1.6
        }
    }
}