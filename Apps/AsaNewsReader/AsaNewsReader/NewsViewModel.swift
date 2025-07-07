//
//  NewsViewModel.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class NewsViewModel: ObservableObject {
    @Published var newsItems: [NewsItem] = []
    @Published var filteredNewsItems: [NewsItem] = []
    @Published var selectedFeed: RSSFeed?
    @Published var searchText: String = ""
    @Published var showOnlyUnread: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedNewsItem: NewsItem?
    @Published var isRefreshing: Bool = false
    
    private let context: NSManagedObjectContext
    private let rssService: RSSService
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        self.rssService = RSSService(context: context)
        loadNews()
    }
    
    // MARK: - データ読み込み
    
    /// ニュース記事を読み込む
    func loadNews() {
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NewsItem.publishedDate, ascending: false)]
        
        do {
            newsItems = try context.fetch(request)
            applyFilters()
            print("📰 NewsViewModel: \(newsItems.count)件の記事を読み込みました")
        } catch {
            print("📰 NewsViewModel: 記事読み込みエラー: \(error)")
            errorMessage = "記事の読み込みに失敗しました"
        }
    }
    
    /// 指定されたフィードの記事を読み込む
    func loadNews(for feed: RSSFeed) {
        let request = NewsItem.fetchRequest(for: feed)
        
        do {
            newsItems = try context.fetch(request)
            selectedFeed = feed
            applyFilters()
            print("📰 NewsViewModel: \(feed.safeTitle)の\(newsItems.count)件の記事を読み込みました")
        } catch {
            print("📰 NewsViewModel: フィード記事読み込みエラー: \(error)")
            errorMessage = "記事の読み込みに失敗しました"
        }
    }
    
    /// 未読記事のみを読み込む
    func loadUnreadNews() {
        let request = NewsItem.unreadFetchRequest()
        
        do {
            newsItems = try context.fetch(request)
            selectedFeed = nil
            showOnlyUnread = true
            applyFilters()
            print("📰 NewsViewModel: \(newsItems.count)件の未読記事を読み込みました")
        } catch {
            print("📰 NewsViewModel: 未読記事読み込みエラー: \(error)")
            errorMessage = "記事の読み込みに失敗しました"
        }
    }
    
    // MARK: - フィルタリング
    
    /// フィルターを適用する
    func applyFilters() {
        filteredNewsItems = newsItems.filter { newsItem in
            let matchesSearch = searchText.isEmpty ||
                newsItem.safeTitle.lowercased().contains(searchText.lowercased()) ||
                newsItem.safeContent.lowercased().contains(searchText.lowercased())
            
            let matchesUnreadFilter = !showOnlyUnread || !newsItem.isRead
            
            return matchesSearch && matchesUnreadFilter
        }
    }
    
    /// フィルターをクリアする
    func clearFilters() {
        searchText = ""
        showOnlyUnread = false
        selectedFeed = nil
        loadNews()
    }
    
    /// 検索を実行する
    func performSearch(_ text: String) {
        searchText = text
        if text.isEmpty {
            applyFilters()
        } else {
            let request = NewsItem.searchFetchRequest(searchText: text)
            do {
                newsItems = try context.fetch(request)
                applyFilters()
            } catch {
                print("📰 NewsViewModel: 検索エラー: \(error)")
                errorMessage = "検索に失敗しました"
            }
        }
    }
    
    // MARK: - ニュース更新
    
    /// 全てのフィードを更新する
    func refreshAllNews() async {
        isRefreshing = true
        errorMessage = nil
        
        do {
            try await rssService.updateAllActiveFeeds()
            loadNews()
            print("📰 NewsViewModel: 全フィードの更新が完了しました")
        } catch {
            print("📰 NewsViewModel: フィード更新エラー: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
    }
    
    /// 指定されたフィードを更新する
    func refreshFeed(_ feed: RSSFeed) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await rssService.fetchAndSaveNews(for: feed)
            loadNews(for: feed)
            print("📰 NewsViewModel: \(feed.safeTitle)の更新が完了しました")
        } catch {
            print("📰 NewsViewModel: フィード更新エラー: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - 記事操作
    
    /// 記事を既読にする
    func markAsRead(_ newsItem: NewsItem) {
        newsItem.markAsRead()
        saveContext()
        applyFilters()
    }
    
    /// 記事を未読にする
    func markAsUnread(_ newsItem: NewsItem) {
        newsItem.markAsUnread()
        saveContext()
        applyFilters()
    }
    
    /// 記事の既読状態を切り替える
    func toggleReadStatus(_ newsItem: NewsItem) {
        newsItem.toggleReadStatus()
        saveContext()
        applyFilters()
    }
    
    /// 全ての記事を既読にする
    func markAllAsRead() {
        for newsItem in filteredNewsItems {
            newsItem.markAsRead()
        }
        saveContext()
        applyFilters()
    }
    
    /// 記事を削除する
    func deleteNewsItem(_ newsItem: NewsItem) {
        context.delete(newsItem)
        saveContext()
        loadNews()
    }
    
    /// 複数の記事を削除する
    func deleteNewsItems(at offsets: IndexSet) {
        for index in offsets {
            let newsItem = filteredNewsItems[index]
            context.delete(newsItem)
        }
        saveContext()
        loadNews()
    }
    
    /// 古い記事を削除する（指定した日数より古い記事）
    func deleteOldNews(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "publishedDate < %@", cutoffDate as NSDate)
        
        do {
            let oldItems = try context.fetch(request)
            for item in oldItems {
                context.delete(item)
            }
            saveContext()
            loadNews()
            print("📰 NewsViewModel: \(oldItems.count)件の古い記事を削除しました")
        } catch {
            print("📰 NewsViewModel: 古い記事削除エラー: \(error)")
            errorMessage = "古い記事の削除に失敗しました"
        }
    }
    
    // MARK: - 統計情報
    
    /// 全記事数
    var totalNewsCount: Int {
        newsItems.count
    }
    
    /// 未読記事数
    var unreadNewsCount: Int {
        newsItems.filter { !$0.isRead }.count
    }
    
    /// 既読記事数
    var readNewsCount: Int {
        newsItems.filter { $0.isRead }.count
    }
    
    /// 今日の記事数
    var todayNewsCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        return newsItems.filter { newsItem in
            guard let publishedDate = newsItem.publishedDate else { return false }
            return publishedDate >= today && publishedDate < tomorrow
        }.count
    }
    
    /// 今週の記事数
    var thisWeekNewsCount: Int {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        
        return newsItems.filter { newsItem in
            guard let publishedDate = newsItem.publishedDate else { return false }
            return weekInterval.contains(publishedDate)
        }.count
    }
    
    // MARK: - ソート機能
    
    enum SortOption: String, CaseIterable {
        case publishedDate = "公開日"
        case title = "タイトル"
        case author = "作者"
        case readStatus = "既読状態"
        
        var keyPath: PartialKeyPath<NewsItem> {
            switch self {
            case .publishedDate:
                return \NewsItem.publishedDate
            case .title:
                return \NewsItem.title
            case .author:
                return \NewsItem.author
            case .readStatus:
                return \NewsItem.isRead
            }
        }
    }
    
    @Published var sortOption: SortOption = .publishedDate
    @Published var sortAscending: Bool = false
    
    /// ソート順を変更する
    func changeSortOption(_ option: SortOption) {
        if sortOption == option {
            sortAscending.toggle()
        } else {
            sortOption = option
            sortAscending = false
        }
        applySorting()
    }
    
    private func applySorting() {
        switch sortOption {
        case .publishedDate:
            filteredNewsItems.sort { lhs, rhs in
                let lhsDate = lhs.publishedDate ?? Date.distantPast
                let rhsDate = rhs.publishedDate ?? Date.distantPast
                return sortAscending ? lhsDate < rhsDate : lhsDate > rhsDate
            }
        case .title:
            filteredNewsItems.sort { lhs, rhs in
                return sortAscending ? lhs.safeTitle < rhs.safeTitle : lhs.safeTitle > rhs.safeTitle
            }
        case .author:
            filteredNewsItems.sort { lhs, rhs in
                return sortAscending ? lhs.safeAuthor < rhs.safeAuthor : lhs.safeAuthor > rhs.safeAuthor
            }
        case .readStatus:
            filteredNewsItems.sort { lhs, rhs in
                return sortAscending ? (!lhs.isRead && rhs.isRead) : (lhs.isRead && !rhs.isRead)
            }
        }
    }
    
    // MARK: - プライベートメソッド
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("📰 NewsViewModel: 保存エラー: \(error)")
            errorMessage = "データの保存に失敗しました"
        }
    }
}

// MARK: - 便利な拡張

extension NewsViewModel {
    /// フィードが選択されているかどうか
    var hasSelectedFeed: Bool {
        selectedFeed != nil
    }
    
    /// 検索中かどうか
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    /// フィルターが適用されているかどうか
    var hasActiveFilters: Bool {
        !searchText.isEmpty || showOnlyUnread || selectedFeed != nil
    }
}