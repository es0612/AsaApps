// AsaApps/Apps/AsaBookTracker/ViewModels/StatisticsViewModel.swift
import Foundation
import SwiftData
import SwiftUI

/// 読書統計データの管理と計算を担当するViewModel
@Observable
final class StatisticsViewModel {
    // MARK: - Properties
    
    var books: [Book] = []
    var selectedPeriod: StatisticsPeriod = .all
    var selectedChartType: StatisticsChartType = .readingProgress
    var isLoading: Bool = false
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {}
    
    func setModelContext(_ context: ModelContext, books: [Book]) {
        self.modelContext = context
        self.books = books
    }
    
    // MARK: - Chart Data
    
    var readingProgressData: [ReadingProgressData] {
        let filteredBooks = booksForPeriod
        
        return filteredBooks.compactMap { book in
            guard let progress = book.progress else { return nil }
            
            return ReadingProgressData(
                bookTitle: book.title,
                currentPage: progress.currentPage,
                totalPages: book.totalPages,
                completionRatio: book.completionRatio
            )
        }
        .sorted { $0.completionRatio > $1.completionRatio }
    }
    
    var genreDistributionData: [GenreData] {
        let filteredBooks = booksForPeriod
        let genreCounts = Dictionary(grouping: filteredBooks, by: { $0.genre })
            .mapValues { $0.count }
        
        return genreCounts.map { genre, count in
            let percentage = Double(count) / Double(filteredBooks.count) * 100
            return GenreData(genre: genre, count: count, percentage: percentage)
        }
        .sorted { $0.count > $1.count }
    }
    
    var monthlyReadingData: [MonthlyReadingData] {
        let calendar = Calendar.current
        let now = Date()
        
        // 過去12か月のデータを生成
        var monthlyData: [MonthlyReadingData] = []
        
        for i in (0..<12).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            
            let booksCompletedInMonth = books.filter { book in
                guard let completedDate = book.progress?.completedDate else { return false }
                return calendar.isDate(completedDate, equalTo: monthDate, toGranularity: .month)
            }
            
            let sessionsInMonth = books.flatMap { $0.sessions }.filter { session in
                calendar.isDate(session.sessionDate, equalTo: monthDate, toGranularity: .month)
            }
            
            let totalPagesInMonth = booksCompletedInMonth.reduce(0) { $0 + $1.totalPages }
            let totalMinutesInMonth = sessionsInMonth.reduce(0) { $0 + $1.durationInMinutes }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M月"
            
            monthlyData.append(MonthlyReadingData(
                month: formatter.string(from: monthDate),
                booksCompleted: booksCompletedInMonth.count,
                pagesRead: totalPagesInMonth,
                readingMinutes: totalMinutesInMonth,
                date: monthDate
            ))
        }
        
        return monthlyData
    }
    
    var dailyReadingData: [DailyReadingData] {
        let calendar = Calendar.current
        let now = Date()
        
        // 過去30日のデータを生成
        var dailyData: [DailyReadingData] = []
        
        for i in (0..<30).reversed() {
            guard let dayDate = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            
            let sessionsInDay = books.flatMap { $0.sessions }.filter { session in
                calendar.isDate(session.sessionDate, equalTo: dayDate, toGranularity: .day)
            }
            
            let totalPagesInDay = sessionsInDay.reduce(0) { $0 + $1.pagesRead }
            let totalMinutesInDay = sessionsInDay.reduce(0) { $0 + $1.durationInMinutes }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            
            dailyData.append(DailyReadingData(
                day: formatter.string(from: dayDate),
                pagesRead: totalPagesInDay,
                readingMinutes: totalMinutesInDay,
                sessionCount: sessionsInDay.count,
                date: dayDate
            ))
        }
        
        return dailyData
    }
    
    var readingStreakData: ReadingStreakData {
        let calendar = Calendar.current
        let today = Date()
        
        let sessionsByDate = Dictionary(grouping: books.flatMap { $0.sessions }) { session in
            calendar.startOfDay(for: session.sessionDate)
        }
        
        // 現在のストリーク計算
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: today)
        
        while sessionsByDate[checkDate] != nil {
            currentStreak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        // 最長ストリーク計算
        let allDates = Array(sessionsByDate.keys).sorted()
        var longestStreak = 0
        var tempStreak = 0
        var previousDate: Date?
        
        for date in allDates {
            if let prev = previousDate,
               let nextDay = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(date, inSameDayAs: nextDay) {
                tempStreak += 1
            } else {
                tempStreak = 1
            }
            
            longestStreak = max(longestStreak, tempStreak)
            previousDate = date
        }
        
        return ReadingStreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalReadingDays: sessionsByDate.count
        )
    }
    
    // MARK: - Computed Properties
    
    var booksForPeriod: [Book] {
        switch selectedPeriod {
        case .all:
            return books
        case .thisYear:
            return books.filter { book in
                Calendar.current.isDate(book.addedDate, equalTo: Date(), toGranularity: .year)
            }
        case .thisMonth:
            return books.filter { book in
                Calendar.current.isDate(book.addedDate, equalTo: Date(), toGranularity: .month)
            }
        case .lastMonth:
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return books.filter { book in
                Calendar.current.isDate(book.addedDate, equalTo: lastMonth, toGranularity: .month)
            }
        }
    }
    
    var overallStatistics: OverallStatistics {
        let filteredBooks = booksForPeriod
        let completedBooks = filteredBooks.filter { $0.progress?.status == .completed }
        let currentlyReading = filteredBooks.filter { $0.progress?.status == .reading }
        
        let totalPages = completedBooks.reduce(0) { $0 + $1.totalPages }
        let totalSessions = filteredBooks.flatMap { $0.sessions }
        let totalReadingMinutes = totalSessions.reduce(0) { $0 + $1.durationInMinutes }
        
        let averageRating = completedBooks.compactMap { $0.progress?.rating }.reduce(0, +) / max(1, completedBooks.compactMap { $0.progress?.rating }.count)
        
        // 読書効率の計算
        let averagePagesPerHour = totalReadingMinutes > 0 ? Double(totalPages) / (Double(totalReadingMinutes) / 60.0) : 0.0
        
        // 最も読まれているジャンル
        let genreCounts = Dictionary(grouping: filteredBooks, by: { $0.genre }).mapValues { $0.count }
        let favoriteGenre = genreCounts.max { $0.value < $1.value }?.key ?? "なし"
        
        return OverallStatistics(
            totalBooks: filteredBooks.count,
            completedBooks: completedBooks.count,
            currentlyReading: currentlyReading.count,
            totalPagesRead: totalPages,
            totalReadingHours: totalReadingMinutes / 60,
            averageRating: Double(averageRating),
            averagePagesPerHour: averagePagesPerHour,
            favoriteGenre: favoriteGenre,
            completionRate: filteredBooks.count > 0 ? Double(completedBooks.count) / Double(filteredBooks.count) : 0.0
        )
    }
}

// MARK: - Data Structures

struct ReadingProgressData: Identifiable {
    let id = UUID()
    let bookTitle: String
    let currentPage: Int
    let totalPages: Int
    let completionRatio: Double
}

struct GenreData: Identifiable {
    let id = UUID()
    let genre: String
    let count: Int
    let percentage: Double
}

struct MonthlyReadingData: Identifiable {
    let id = UUID()
    let month: String
    let booksCompleted: Int
    let pagesRead: Int
    let readingMinutes: Int
    let date: Date
}

struct DailyReadingData: Identifiable {
    let id = UUID()
    let day: String
    let pagesRead: Int
    let readingMinutes: Int
    let sessionCount: Int
    let date: Date
}

struct ReadingStreakData {
    let currentStreak: Int
    let longestStreak: Int
    let totalReadingDays: Int
}

struct OverallStatistics {
    let totalBooks: Int
    let completedBooks: Int
    let currentlyReading: Int
    let totalPagesRead: Int
    let totalReadingHours: Int
    let averageRating: Double
    let averagePagesPerHour: Double
    let favoriteGenre: String
    let completionRate: Double
}

// MARK: - Enums

enum StatisticsPeriod: String, CaseIterable, Identifiable {
    case all = "全期間"
    case thisYear = "今年"
    case thisMonth = "今月"
    case lastMonth = "先月"
    
    var id: String { rawValue }
}

enum StatisticsChartType: String, CaseIterable, Identifiable {
    case readingProgress = "読書進捗"
    case genreDistribution = "ジャンル分布"
    case monthlyTrend = "月別推移"
    case dailyActivity = "日別活動"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .readingProgress: return "chart.bar.fill"
        case .genreDistribution: return "chart.pie.fill"
        case .monthlyTrend: return "chart.line.uptrend.xyaxis"
        case .dailyActivity: return "calendar"
        }
    }
}