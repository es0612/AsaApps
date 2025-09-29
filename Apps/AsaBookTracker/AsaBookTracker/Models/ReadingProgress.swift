// AsaApps/Apps/AsaBookTracker/Models/ReadingProgress.swift
import Foundation
import SwiftData

/// 読書進捗を管理するSwift Dataモデル
@Model
final class ReadingProgress {
    @Attribute(.unique) var id: UUID
    var currentPage: Int
    var status: ReadingStatus
    var startDate: Date?
    var completedDate: Date?
    var rating: Int? // 1-5 stars
    var review: String?
    var notes: String?
    var targetCompletionDate: Date?
    
    // 本との関係（逆参照）
    @Relationship(inverse: \Book.progress) var book: Book?
    
    init(currentPage: Int = 0, status: ReadingStatus = .notStarted) {
        self.id = UUID()
        self.currentPage = currentPage
        self.status = status
    }
    
    /// 読書を開始
    func startReading() {
        guard status == .notStarted else { return }
        status = .reading
        startDate = Date()
    }
    
    /// 進捗を更新
    func updateProgress(to page: Int) {
        currentPage = page
        
        // 自動で読書中に変更
        if status == .notStarted {
            startReading()
        }
        
        // 完読判定
        if let book = book, page >= book.totalPages {
            completeReading()
        }
    }
    
    /// 読書を完了
    func completeReading() {
        status = .completed
        completedDate = Date()
        
        if let book = book {
            currentPage = book.totalPages
        }
    }
    
    /// 読書を一時停止
    func pauseReading() {
        guard status == .reading else { return }
        status = .paused
    }
    
    /// 読書を再開
    func resumeReading() {
        guard status == .paused else { return }
        status = .reading
    }
}

// MARK: - ReadingProgress Extensions

extension ReadingProgress {
    /// 読書期間（日数）
    var readingDuration: Int? {
        guard let startDate = startDate else { return nil }
        
        let endDate = completedDate ?? Date()
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day
    }
    
    /// 残りページ数
    var remainingPages: Int {
        guard let book = book else { return 0 }
        return max(book.totalPages - currentPage, 0)
    }
    
    /// 1日平均ページ数
    var averagePagesPerDay: Double {
        guard let duration = readingDuration, duration > 0 else { return 0.0 }
        return Double(currentPage) / Double(duration)
    }
    
    /// 完了予想日
    var estimatedCompletionDate: Date? {
        guard status == .reading,
              let startDate = startDate,
              currentPage > 0,
              let book = book else { return nil }
        
        let remainingPages = book.totalPages - currentPage
        let averagePages = averagePagesPerDay
        
        guard remainingPages > 0, averagePages > 0 else { return nil }
        
        let estimatedDays = Int(ceil(Double(remainingPages) / averagePages))
        return Calendar.current.date(byAdding: .day, value: estimatedDays, to: Date())
    }
    
    /// 目標達成まで必要な1日あたりページ数
    var requiredPagesPerDay: Double? {
        guard let targetDate = targetCompletionDate,
              let book = book,
              status == .reading else { return nil }
        
        let remainingPages = book.totalPages - currentPage
        let remainingDays = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        
        guard remainingDays > 0 else { return nil }
        
        return Double(remainingPages) / Double(remainingDays)
    }
    
    /// 目標に対する進捗状況
    var targetProgressStatus: TargetProgressStatus {
        guard let requiredPages = requiredPagesPerDay,
              averagePagesPerDay > 0 else { return .unknown }
        
        let ratio = averagePagesPerDay / requiredPages
        
        if ratio >= 1.2 {
            return .ahead
        } else if ratio >= 0.8 {
            return .onTrack
        } else {
            return .behind
        }
    }
}

// MARK: - ReadingStatus Enum

enum ReadingStatus: String, CaseIterable, Codable {
    case notStarted = "未読"
    case reading = "読書中"
    case completed = "完読"
    case paused = "中断"
    
    var description: String { rawValue }
    
    var color: String {
        switch self {
        case .notStarted: return "gray"
        case .reading: return "blue" 
        case .completed: return "green"
        case .paused: return "orange"
        }
    }
    
    var icon: String {
        switch self {
        case .notStarted: return "book.closed"
        case .reading: return "book"
        case .completed: return "checkmark.circle.fill"
        case .paused: return "pause.circle"
        }
    }
}

// MARK: - TargetProgressStatus Enum

enum TargetProgressStatus: String, CaseIterable {
    case ahead = "順調"
    case onTrack = "予定通り"
    case behind = "遅れ気味"
    case unknown = "不明"
    
    var color: String {
        switch self {
        case .ahead: return "green"
        case .onTrack: return "blue"
        case .behind: return "red"
        case .unknown: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .ahead: return "chevron.up.circle.fill"
        case .onTrack: return "equal.circle.fill"
        case .behind: return "chevron.down.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}