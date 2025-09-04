// AsaApps/Apps/AsaBookTracker/Models/ReadingSession.swift
import Foundation
import SwiftData

/// 読書セッション（個別の読書時間）を管理するSwift Dataモデル
@Model
final class ReadingSession {
    @Attribute(.unique) var id: UUID
    var startPage: Int
    var endPage: Int
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval // 読書時間（秒）
    var notes: String?
    var sessionDate: Date
    var location: String? // 読書場所
    var mood: ReadingMood?
    var concentration: Int? // 集中度 (1-5)
    
    // 本との関係（逆参照）
    @Relationship(inverse: \Book.sessions) var book: Book?
    
    init(startPage: Int, startTime: Date = Date()) {
        self.id = UUID()
        self.startPage = startPage
        self.endPage = startPage
        self.startTime = startTime
        self.duration = 0
        self.sessionDate = startTime
    }
    
    /// セッションを終了
    func endSession(at endPage: Int, endTime: Date = Date()) {
        self.endPage = max(endPage, startPage) // endPageがstartPageより小さくならないように
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
    }
}

// MARK: - ReadingSession Extensions

extension ReadingSession {
    /// 読んだページ数
    var pagesRead: Int {
        return max(endPage - startPage, 0)
    }
    
    /// 1分あたりのページ数
    var pagesPerMinute: Double {
        guard duration > 0 else { return 0.0 }
        return Double(pagesRead) / (duration / 60.0)
    }
    
    /// セッションの長さ（分）
    var durationInMinutes: Int {
        return Int(duration / 60)
    }
    
    /// セッションの効率性（ページ数/時間の比率）
    var efficiency: ReadingEfficiency {
        let pagesPerHour = pagesPerMinute * 60
        
        if pagesPerHour >= 30 {
            return .high
        } else if pagesPerHour >= 15 {
            return .medium
        } else if pagesPerHour > 0 {
            return .low
        } else {
            return .none
        }
    }
    
    /// セッションの質を評価
    var qualityScore: Double {
        var score: Double = 0
        
        // 読書時間による評価（最大40点）
        let durationMinutes = durationInMinutes
        if durationMinutes >= 60 {
            score += 40
        } else if durationMinutes >= 30 {
            score += 30
        } else if durationMinutes >= 15 {
            score += 20
        } else if durationMinutes >= 5 {
            score += 10
        }
        
        // ページ数による評価（最大30点）
        if pagesRead >= 20 {
            score += 30
        } else if pagesRead >= 10 {
            score += 20
        } else if pagesRead >= 5 {
            score += 15
        } else if pagesRead >= 1 {
            score += 10
        }
        
        // 集中度による評価（最大20点）
        if let concentration = concentration {
            score += Double(concentration) * 4
        }
        
        // 気分による評価（最大10点）
        if let mood = mood {
            switch mood {
            case .excellent: score += 10
            case .good: score += 8
            case .neutral: score += 5
            case .tired: score += 3
            case .distracted: score += 1
            }
        }
        
        return min(score, 100) // 最大100点
    }
    
    /// フォーマットされた時間表示
    var formattedDuration: String {
        let hours = durationInMinutes / 60
        let minutes = durationInMinutes % 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    /// セッション時間帯
    var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: startTime)
        
        switch hour {
        case 5..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<22:
            return .evening
        default:
            return .night
        }
    }
}

// MARK: - ReadingMood Enum

enum ReadingMood: String, CaseIterable, Codable {
    case excellent = "最高"
    case good = "良い"
    case neutral = "普通"
    case tired = "疲れ気味"
    case distracted = "散漫"
    
    var icon: String {
        switch self {
        case .excellent: return "😍"
        case .good: return "😊"
        case .neutral: return "😐"
        case .tired: return "😴"
        case .distracted: return "😵‍💫"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .neutral: return "gray"
        case .tired: return "orange"
        case .distracted: return "red"
        }
    }
}

// MARK: - ReadingEfficiency Enum

enum ReadingEfficiency: String, CaseIterable {
    case high = "高効率"
    case medium = "中効率"
    case low = "低効率"
    case none = "計測不可"
    
    var color: String {
        switch self {
        case .high: return "green"
        case .medium: return "blue"
        case .low: return "orange"
        case .none: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "bolt.fill"
        case .medium: return "gauge.medium"
        case .low: return "tortoise.fill"
        case .none: return "questionmark"
        }
    }
}

// MARK: - TimeOfDay Enum

enum TimeOfDay: String, CaseIterable {
    case morning = "朝"
    case afternoon = "昼"
    case evening = "夕方"
    case night = "夜"
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }
    
    var color: String {
        switch self {
        case .morning: return "orange"
        case .afternoon: return "yellow"
        case .evening: return "purple"
        case .night: return "indigo"
        }
    }
}