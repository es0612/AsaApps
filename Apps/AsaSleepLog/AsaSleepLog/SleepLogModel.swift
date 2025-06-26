//
//  SleepLogModel.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import Foundation

struct SleepLog: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let bedTime: Date
    let wakeTime: Date
    let sleepDuration: TimeInterval
    let timeInBed: TimeInterval
    let quality: SleepQuality
    let notes: String?
    let fellAsleepTime: Date?
    let wakeUpCount: Int
    let mood: MoodRating?
    
    init(date: Date, bedTime: Date, wakeTime: Date, quality: SleepQuality = .normal, notes: String? = nil, fellAsleepTime: Date? = nil, wakeUpCount: Int = 0, mood: MoodRating? = nil) {
        self.date = date
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.fellAsleepTime = fellAsleepTime ?? bedTime
        self.sleepDuration = wakeTime.timeIntervalSince(self.fellAsleepTime!)
        self.timeInBed = wakeTime.timeIntervalSince(bedTime)
        self.quality = quality
        self.notes = notes
        self.wakeUpCount = wakeUpCount
        self.mood = mood
    }
    
    var sleepDurationFormatted: String {
        let hours = Int(sleepDuration / 3600)
        let minutes = Int((sleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)時間\(minutes)分"
    }
    
    var sleepEfficiency: Double {
        guard timeInBed > 0 else { return 0 }
        return (sleepDuration / timeInBed) * 100
    }
    
    var sleepEfficiencyFormatted: String {
        return String(format: "%.1f%%", sleepEfficiency)
    }
    
    var qualityScore: Int {
        switch quality {
        case .excellent: return 5
        case .good: return 4
        case .normal: return 3
        case .poor: return 2
        case .terrible: return 1
        }
    }
}

struct SleepGoal: Codable {
    var targetBedTime: Date
    var targetWakeTime: Date
    var targetSleepDuration: TimeInterval
    var minimumSleepEfficiency: Double
    
    init() {
        let calendar = Calendar.current
        let now = Date()
        self.targetBedTime = calendar.date(bySettingHour: 22, minute: 30, second: 0, of: now) ?? now
        self.targetWakeTime = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: now) ?? now
        self.targetSleepDuration = 8 * 3600 // 8時間
        self.minimumSleepEfficiency = 85.0 // 85%
    }
    
    var targetSleepDurationFormatted: String {
        let hours = Int(targetSleepDuration / 3600)
        let minutes = Int((targetSleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)時間\(minutes)分"
    }
}

enum SleepQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case normal = "normal"
    case poor = "poor"
    case terrible = "terrible"
    
    var displayName: String {
        switch self {
        case .excellent: return "とても良い"
        case .good: return "良い"
        case .normal: return "普通"
        case .poor: return "悪い"
        case .terrible: return "とても悪い"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "😴"
        case .good: return "😊"
        case .normal: return "😐"
        case .poor: return "😕"
        case .terrible: return "😰"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "AsaCoffeeBrown"
        case .good: return "AsaCoffeeBrown"
        case .normal: return "AsaMutedSage"
        case .poor: return "AsaMocha"
        case .terrible: return "AsaDarkSlate"
        }
    }
}

enum MoodRating: String, CaseIterable, Codable {
    case veryHappy = "veryHappy"
    case happy = "happy"
    case neutral = "neutral"
    case tired = "tired"
    case exhausted = "exhausted"
    
    var displayName: String {
        switch self {
        case .veryHappy: return "とても元気"
        case .happy: return "元気"
        case .neutral: return "普通"
        case .tired: return "疲れ気味"
        case .exhausted: return "とても疲れた"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy: return "😊"
        case .neutral: return "😐"
        case .tired: return "😴"
        case .exhausted: return "😵"
        }
    }
}