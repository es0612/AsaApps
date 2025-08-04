//
//  SleepData.swift
//  AsaSleepAnalyzer
//  
//  Created on 2025/08/05
//

import Foundation
import SwiftData

@Model
final class SleepData {
    var date: Date
    var bedtime: Date?
    var wakeTime: Date?
    var totalSleepDuration: TimeInterval // 総睡眠時間（秒）
    var deepSleepDuration: TimeInterval // 深い睡眠時間（秒）
    var lightSleepDuration: TimeInterval // 浅い睡眠時間（秒）
    var remSleepDuration: TimeInterval // REM睡眠時間（秒）
    var awakeTime: TimeInterval // 目覚めた時間（秒）
    var sleepEfficiency: Double // 睡眠効率（0.0-1.0）
    var qualityScore: Double // 睡眠品質スコア（0.0-10.0）
    var notes: String // メモ
    
    init(
        date: Date,
        bedtime: Date? = nil,
        wakeTime: Date? = nil,
        totalSleepDuration: TimeInterval = 0,
        deepSleepDuration: TimeInterval = 0,
        lightSleepDuration: TimeInterval = 0,
        remSleepDuration: TimeInterval = 0,
        awakeTime: TimeInterval = 0,
        sleepEfficiency: Double = 0.0,
        qualityScore: Double = 0.0,
        notes: String = ""
    ) {
        self.date = date
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.totalSleepDuration = totalSleepDuration
        self.deepSleepDuration = deepSleepDuration
        self.lightSleepDuration = lightSleepDuration
        self.remSleepDuration = remSleepDuration
        self.awakeTime = awakeTime
        self.sleepEfficiency = sleepEfficiency
        self.qualityScore = qualityScore
        self.notes = notes
    }
    
    // MARK: - Computed Properties
    
    /// フォーマットされた総睡眠時間
    var formattedTotalSleepDuration: String {
        let hours = Int(totalSleepDuration) / 3600
        let minutes = Int(totalSleepDuration) % 3600 / 60
        return String(format: "%d時間%d分", hours, minutes)
    }
    
    /// フォーマットされた睡眠効率
    var formattedSleepEfficiency: String {
        return String(format: "%.1f%%", sleepEfficiency * 100)
    }
    
    /// フォーマットされた品質スコア
    var formattedQualityScore: String {
        return String(format: "%.1f/10", qualityScore)
    }
    
    /// 睡眠品質レベル
    var qualityLevel: SleepQualityLevel {
        switch qualityScore {
        case 8.0...10.0:
            return .excellent
        case 6.0..<8.0:
            return .good
        case 4.0..<6.0:
            return .fair
        case 2.0..<4.0:
            return .poor
        default:
            return .veryPoor
        }
    }
    
    /// 就寝時刻の文字列
    var formattedBedtime: String {
        guard let bedtime = bedtime else { return "未記録" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: bedtime)
    }
    
    /// 起床時刻の文字列
    var formattedWakeTime: String {
        guard let wakeTime = wakeTime else { return "未記録" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: wakeTime)
    }
}

// MARK: - Enums

enum SleepQualityLevel: String, CaseIterable {
    case excellent = "とても良い"
    case good = "良い"
    case fair = "普通"
    case poor = "悪い"
    case veryPoor = "とても悪い"
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "AsaCoffeeBrown"
        case .fair:
            return "AsaMutedSage"
        case .poor:
            return "orange"
        case .veryPoor:
            return "red"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .excellent:
            return "moon.stars.fill"
        case .good:
            return "moon.fill"
        case .fair:
            return "moon"
        case .poor:
            return "moon.zzz"
        case .veryPoor:
            return "moon.zzz.fill"
        }
    }
}
