// AsaApps/Apps/AsaBookTracker/ViewModels/BookTrackerViewModel.swift
import Foundation
import SwiftData
import SwiftUI

/// メインの書籍管理ViewModelクラス
@Observable
final class BookTrackerViewModel {
    // MARK: - Properties
    
    var books: [Book] = []
    var selectedTab: Int = 0
    var searchText: String = ""
    var selectedGenre: BookGenre?
    var selectedStatus: ReadingStatus?
    var sortOption: BookSortOption = .title
    var isLoading: Bool = false
    var errorMessage: String?
    
    // 統計データ
    var statistics: ReadingStatistics = ReadingStatistics()
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {
        calculateStatistics()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadBooks()
    }
    
    // MARK: - Data Loading
    
    func loadBooks() {
        guard let context = modelContext else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<Book>(
                sortBy: [SortDescriptor(\.title)]
            )
            books = try context.fetch(descriptor)
            calculateStatistics()
            errorMessage = nil
        } catch {
            errorMessage = "本の読み込みに失敗しました: \(error.localizedDescription)"
            print("Error loading books: \(error)")
        }
    }
    
    func refreshData() {
        loadBooks()
    }
    
    // MARK: - Book Management
    
    func addBook(title: String, author: String, totalPages: Int, genre: String, isbn: String? = nil) {
        guard let context = modelContext else { return }
        
        let book = Book(title: title, author: author, totalPages: totalPages, genre: genre, isbn: isbn)
        let progress = ReadingProgress()
        book.progress = progress
        
        context.insert(book)
        context.insert(progress)
        
        do {
            try context.save()
            loadBooks()
        } catch {
            errorMessage = "本の追加に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func deleteBook(_ book: Book) {
        guard let context = modelContext else { return }
        
        context.delete(book)
        
        do {
            try context.save()
            loadBooks()
        } catch {
            errorMessage = "本の削除に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func updateBook(_ book: Book) {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
            loadBooks()
        } catch {
            errorMessage = "本の更新に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reading Progress
    
    func startReading(_ book: Book) {
        guard let progress = book.progress else { return }
        progress.startReading()
        updateBook(book)
    }
    
    func updateProgress(_ book: Book, to page: Int) {
        guard let progress = book.progress else { return }
        progress.updateProgress(to: page)
        updateBook(book)
    }
    
    func completeReading(_ book: Book, rating: Int? = nil, review: String? = nil) {
        guard let progress = book.progress else { return }
        progress.completeReading()
        progress.rating = rating
        progress.review = review
        updateBook(book)
    }
    
    func pauseReading(_ book: Book) {
        guard let progress = book.progress else { return }
        progress.pauseReading()
        updateBook(book)
    }
    
    func resumeReading(_ book: Book) {
        guard let progress = book.progress else { return }
        progress.resumeReading()
        updateBook(book)
    }
    
    // MARK: - Reading Sessions
    
    func startReadingSession(_ book: Book, at page: Int) -> ReadingSession {
        guard let context = modelContext else {
            return ReadingSession(startPage: page)
        }
        
        let session = ReadingSession(startPage: page)
        session.book = book
        book.sessions.append(session)
        
        context.insert(session)
        
        do {
            try context.save()
        } catch {
            errorMessage = "読書セッションの開始に失敗しました: \(error.localizedDescription)"
        }
        
        return session
    }
    
    func endReadingSession(_ session: ReadingSession, at page: Int, mood: ReadingMood? = nil, concentration: Int? = nil, notes: String? = nil) {
        session.endSession(at: page)
        session.mood = mood
        session.concentration = concentration
        session.notes = notes
        
        // 本の進捗も更新
        if let book = session.book, let progress = book.progress {
            progress.updateProgress(to: page)
        }
        
        guard let context = modelContext else { return }
        
        do {
            try context.save()
            loadBooks()
        } catch {
            errorMessage = "読書セッションの終了に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Filtering and Sorting
    
    var filteredAndSortedBooks: [Book] {
        var filtered = books
        
        // テキスト検索
        if !searchText.isEmpty {
            filtered = filtered.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // ジャンルフィルタ
        if let genre = selectedGenre {
            filtered = filtered.filter { $0.genre == genre.rawValue }
        }
        
        // ステータスフィルタ
        if let status = selectedStatus {
            filtered = filtered.filter { $0.progress?.status == status }
        }
        
        // ソート
        return filtered.sorted { lhs, rhs in
            switch sortOption {
            case .title:
                return lhs.title < rhs.title
            case .author:
                return lhs.author < rhs.author
            case .addedDate:
                return lhs.addedDate > rhs.addedDate
            case .progress:
                return (lhs.progress?.currentPage ?? 0) > (rhs.progress?.currentPage ?? 0)
            case .rating:
                return (lhs.progress?.rating ?? 0) > (rhs.progress?.rating ?? 0)
            }
        }
    }
    
    // MARK: - Statistics
    
    private func calculateStatistics() {
        let totalBooks = books.count
        let completedBooks = books.filter { $0.progress?.status == .completed }.count
        let currentlyReading = books.filter { $0.progress?.status == .reading }.count
        
        let totalPages = books.compactMap { $0.progress?.currentPage }.reduce(0, +)
        let totalReadingMinutes = books.flatMap { $0.sessions }.reduce(0) { $0 + $1.durationInMinutes }
        
        let averageRating = books.compactMap { $0.progress?.rating }.reduce(0, +) / max(1, books.compactMap { $0.progress?.rating }.count)
        
        let thisMonthCompleted = books.filter { book in
            guard let completedDate = book.progress?.completedDate else { return false }
            return Calendar.current.isDate(completedDate, equalTo: Date(), toGranularity: .month)
        }.count
        
        statistics = ReadingStatistics(
            totalBooks: totalBooks,
            completedBooks: completedBooks,
            currentlyReading: currentlyReading,
            totalPagesRead: totalPages,
            totalReadingHours: totalReadingMinutes / 60,
            averageRating: Double(averageRating),
            booksCompletedThisMonth: thisMonthCompleted
        )
    }
}

// MARK: - BookSortOption

enum BookSortOption: String, CaseIterable, Identifiable {
    case title = "タイトル"
    case author = "著者"
    case addedDate = "追加日"
    case progress = "進捗"
    case rating = "評価"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .title: return "textformat"
        case .author: return "person"
        case .addedDate: return "calendar"
        case .progress: return "chart.bar.fill"
        case .rating: return "star.fill"
        }
    }
}

// MARK: - ReadingStatistics

struct ReadingStatistics {
    let totalBooks: Int
    let completedBooks: Int
    let currentlyReading: Int
    let totalPagesRead: Int
    let totalReadingHours: Int
    let averageRating: Double
    let booksCompletedThisMonth: Int
    
    init(totalBooks: Int = 0, completedBooks: Int = 0, currentlyReading: Int = 0, totalPagesRead: Int = 0, totalReadingHours: Int = 0, averageRating: Double = 0.0, booksCompletedThisMonth: Int = 0) {
        self.totalBooks = totalBooks
        self.completedBooks = completedBooks
        self.currentlyReading = currentlyReading
        self.totalPagesRead = totalPagesRead
        self.totalReadingHours = totalReadingHours
        self.averageRating = averageRating
        self.booksCompletedThisMonth = booksCompletedThisMonth
    }
    
    var completionRate: Double {
        guard totalBooks > 0 else { return 0.0 }
        return Double(completedBooks) / Double(totalBooks)
    }
    
    var averagePagesPerBook: Double {
        guard completedBooks > 0 else { return 0.0 }
        return Double(totalPagesRead) / Double(completedBooks)
    }
    
    var readingPace: Double {
        guard totalReadingHours > 0 else { return 0.0 }
        return Double(totalPagesRead) / Double(totalReadingHours)
    }
}