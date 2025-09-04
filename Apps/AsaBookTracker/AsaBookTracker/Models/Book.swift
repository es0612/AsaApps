// AsaApps/Apps/AsaBookTracker/Models/Book.swift
import Foundation
import SwiftData

/// 本の情報を管理するSwift Dataモデル
@Model
final class Book {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String
    var totalPages: Int
    var genre: String
    var isbn: String?
    var coverImageData: Data?
    var addedDate: Date
    var summary: String?
    
    // 読書進捗との関係（1対1）
    @Relationship var progress: ReadingProgress?
    
    // 読書セッションとの関係（1対多）
    @Relationship(deleteRule: .cascade) var sessions: [ReadingSession]
    
    init(title: String, author: String, totalPages: Int, genre: String, isbn: String? = nil) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.genre = genre
        self.isbn = isbn
        self.addedDate = Date()
        self.sessions = []
    }
}

// MARK: - Book Extensions

extension Book {
    /// 完了率を計算（0.0 - 1.0）
    var completionRatio: Double {
        guard let progress = progress, totalPages > 0 else { return 0.0 }
        return min(Double(progress.currentPage) / Double(totalPages), 1.0)
    }
    
    /// 完了パーセンテージを計算
    var completionPercentage: Int {
        Int(completionRatio * 100)
    }
    
    /// 読書状況に応じた色を返す
    var statusColor: String {
        guard let progress = progress else { return "gray" }
        
        switch progress.status {
        case .notStarted: return "gray"
        case .reading: return "blue"
        case .completed: return "green"
        case .paused: return "orange"
        }
    }
    
    /// 読書経過日数
    var readingDays: Int? {
        guard let progress = progress,
              let startDate = progress.startDate else { return nil }
        
        if let completedDate = progress.completedDate {
            return Calendar.current.dateComponents([.day], from: startDate, to: completedDate).day
        } else {
            return Calendar.current.dateComponents([.day], from: startDate, to: Date()).day
        }
    }
    
    /// 総読書時間（分）
    var totalReadingMinutes: Int {
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        return Int(totalSeconds / 60)
    }
    
    /// 日平均ページ数
    var averagePagesPerDay: Double {
        guard let readingDays = readingDays, readingDays > 0,
              let progress = progress else { return 0.0 }
        
        return Double(progress.currentPage) / Double(readingDays)
    }
}

// MARK: - Book Genre Enum

enum BookGenre: String, CaseIterable, Identifiable {
    case fiction = "小説"
    case nonFiction = "ノンフィクション"
    case business = "ビジネス"
    case selfImprovement = "自己啓発"
    case technical = "技術書"
    case history = "歴史"
    case biography = "伝記"
    case science = "科学"
    case philosophy = "哲学"
    case art = "芸術"
    case cooking = "料理"
    case travel = "旅行"
    case health = "健康"
    case education = "教育"
    case other = "その他"
    
    var id: String { rawValue }
    
    /// ジャンルに応じたアイコン
    var icon: String {
        switch self {
        case .fiction: return "📚"
        case .nonFiction: return "📖"
        case .business: return "💼"
        case .selfImprovement: return "🌟"
        case .technical: return "💻"
        case .history: return "🏛️"
        case .biography: return "👤"
        case .science: return "🔬"
        case .philosophy: return "🤔"
        case .art: return "🎨"
        case .cooking: return "🍳"
        case .travel: return "✈️"
        case .health: return "💊"
        case .education: return "🎓"
        case .other: return "📙"
        }
    }
}