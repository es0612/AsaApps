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
    let quality: SleepQuality
    let notes: String?
    
    init(date: Date, bedTime: Date, wakeTime: Date, quality: SleepQuality = .normal, notes: String? = nil) {
        self.date = date
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.sleepDuration = wakeTime.timeIntervalSince(bedTime)
        self.quality = quality
        self.notes = notes
    }
    
    var sleepDurationFormatted: String {
        let hours = Int(sleepDuration / 3600)
        let minutes = Int((sleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
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
}