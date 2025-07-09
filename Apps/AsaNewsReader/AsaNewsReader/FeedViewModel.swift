//
//  FeedViewModel.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class FeedViewModel: ObservableObject {
    @Published var feeds: [RSSFeed] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAddingFeed: Bool = false
    @Published var selectedFeed: RSSFeed?
    @Published var feedValidationResult: RSSFeedInfo?
    @Published var isValidatingFeed: Bool = false
    
    private let context: NSManagedObjectContext
    private let rssService: RSSService
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        self.rssService = RSSService(context: context)
        loadFeeds()
    }
    
    // MARK: - フィード読み込み
    
    /// 全てのフィードを読み込む
    func loadFeeds() {
        let request = RSSFeed.allFeedsRequest()
        
        do {
            feeds = try context.fetch(request)
            print("📡 FeedViewModel: \(feeds.count)個のフィードを読み込みました")
        } catch {
            print("📡 FeedViewModel: フィード読み込みエラー: \(error)")
            errorMessage = "フィードの読み込みに失敗しました"
        }
    }
    
    /// アクティブなフィードのみを読み込む
    func loadActiveFeeds() {
        let request = RSSFeed.activeFeedsRequest()
        
        do {
            feeds = try context.fetch(request)
            print("📡 FeedViewModel: \(feeds.count)個のアクティブなフィードを読み込みました")
        } catch {
            print("📡 FeedViewModel: アクティブフィード読み込みエラー: \(error)")
            errorMessage = "フィードの読み込みに失敗しました"
        }
    }
    
    // MARK: - フィード追加
    
    /// フィードURLを検証する
    func validateFeedURL(_ urlString: String) async {
        isValidatingFeed = true
        errorMessage = nil
        feedValidationResult = nil
        
        do {
            let feedInfo = try await rssService.validateFeedURL(urlString)
            feedValidationResult = feedInfo
            print("📡 FeedViewModel: フィードの検証が成功: \(feedInfo.title)")
        } catch {
            print("📡 FeedViewModel: フィード検証エラー: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isValidatingFeed = false
    }
    
    /// 新しいフィードを追加する
    func addFeed(url: String, title: String? = nil, description: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        // 既存のフィードをチェック
        if feedExists(url: url) {
            errorMessage = "このフィードは既に追加されています"
            isLoading = false
            return
        }
        
        do {
            // フィードURLを検証
            let feedInfo = try await rssService.validateFeedURL(url)
            
            // 新しいフィードを作成
            let feed = RSSFeed.create(
                in: context,
                title: title ?? feedInfo.title,
                url: url,
                description: description ?? feedInfo.description
            )
            
            try context.save()
            
            // フィードを更新して記事を取得
            try await rssService.fetchAndSaveNews(for: feed)
            
            loadFeeds()
            print("📡 FeedViewModel: 新しいフィードを追加: \(feed.safeTitle)")
            
        } catch {
            print("📡 FeedViewModel: フィード追加エラー: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        isAddingFeed = false
    }
    
    /// フィードが既に存在するかチェック
    private func feedExists(url: String) -> Bool {
        let request = RSSFeed.feedByUrl(url)
        do {
            let existingFeeds = try context.fetch(request)
            return !existingFeeds.isEmpty
        } catch {
            return false
        }
    }
    
    // MARK: - フィード操作
    
    /// フィードを削除する
    func deleteFeed(_ feed: RSSFeed) {
        context.delete(feed)
        saveContext()
        loadFeeds()
    }
    
    /// 複数のフィードを削除する
    func deleteFeeds(at offsets: IndexSet) {
        for index in offsets {
            let feed = feeds[index]
            context.delete(feed)
        }
        saveContext()
        loadFeeds()
    }
    
    /// フィードの有効状態を切り替える
    func toggleFeedActiveStatus(_ feed: RSSFeed) {
        feed.toggleActiveStatus()
        saveContext()
    }
    
    /// フィードの情報を更新する
    func updateFeed(_ feed: RSSFeed, title: String, description: String) {
        feed.updateInfo(title: title, description: description)
        saveContext()
    }
    
    /// フィードを更新する
    func refreshFeed(_ feed: RSSFeed) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await rssService.fetchAndSaveNews(for: feed)
            loadFeeds()
            print("📡 FeedViewModel: \(feed.safeTitle)を更新しました")
        } catch {
            print("📡 FeedViewModel: フィード更新エラー: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// 全てのアクティブなフィードを更新する
    func refreshAllActiveFeeds() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await rssService.updateAllActiveFeeds()
            loadFeeds()
            print("📡 FeedViewModel: 全てのアクティブなフィードを更新しました")
        } catch {
            print("📡 FeedViewModel: 全フィード更新エラー: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// フィードの全記事を既読にする
    func markAllNewsAsRead(_ feed: RSSFeed) {
        feed.markAllAsRead()
        saveContext()
    }
    
    /// フィードの全記事を未読にする
    func markAllNewsAsUnread(_ feed: RSSFeed) {
        feed.markAllAsUnread()
        saveContext()
    }
    
    /// フィードの古い記事を削除する
    func deleteOldNews(_ feed: RSSFeed, olderThan days: Int) {
        feed.deleteOldNews(olderThan: days)
        saveContext()
    }
    
    // MARK: - 統計情報
    
    /// 全フィード数
    var totalFeedCount: Int {
        feeds.count
    }
    
    /// アクティブなフィード数
    var activeFeedCount: Int {
        feeds.filter { $0.isActive }.count
    }
    
    /// 非アクティブなフィード数
    var inactiveFeedCount: Int {
        feeds.filter { !$0.isActive }.count
    }
    
    /// 全フィードの記事数
    var totalNewsCount: Int {
        feeds.reduce(0) { $0 + $1.newsItemCount }
    }
    
    /// 全フィードの未読記事数
    var totalUnreadCount: Int {
        feeds.reduce(0) { $0 + $1.unreadNewsItemCount }
    }
    
    /// 最近更新されたフィード数（24時間以内）
    var recentlyUpdatedFeedCount: Int {
        feeds.filter { $0.isRecentlyUpdated }.count
    }
    
    /// 未取得のフィード数
    var unfetchedFeedCount: Int {
        feeds.filter { $0.lastFetched == nil }.count
    }
    
    // MARK: - ソート機能
    
    enum SortOption: String, CaseIterable {
        case title = "タイトル"
        case lastFetched = "最終取得日"
        case newsCount = "記事数"
        case unreadCount = "未読数"
        case createdAt = "作成日"
        
        var keyPath: PartialKeyPath<RSSFeed> {
            switch self {
            case .title:
                return \RSSFeed.title
            case .lastFetched:
                return \RSSFeed.lastFetched
            case .newsCount:
                return \RSSFeed.title // newsCountとunreadCountは計算プロパティのためtitleで代用
            case .unreadCount:
                return \RSSFeed.title // newsCountとunreadCountは計算プロパティのためtitleで代用
            case .createdAt:
                return \RSSFeed.createdAt
            }
        }
    }
    
    @Published var sortOption: SortOption = .title
    @Published var sortAscending: Bool = true
    
    /// ソート順を変更する
    func changeSortOption(_ option: SortOption) {
        if sortOption == option {
            sortAscending.toggle()
        } else {
            sortOption = option
            sortAscending = true
        }
        applySorting()
    }
    
    private func applySorting() {
        switch sortOption {
        case .title:
            feeds.sort { lhs, rhs in
                return sortAscending ? lhs.safeTitle < rhs.safeTitle : lhs.safeTitle > rhs.safeTitle
            }
        case .lastFetched:
            feeds.sort { lhs, rhs in
                let lhsDate = lhs.lastFetched ?? Date.distantPast
                let rhsDate = rhs.lastFetched ?? Date.distantPast
                return sortAscending ? lhsDate < rhsDate : lhsDate > rhsDate
            }
        case .newsCount:
            feeds.sort { lhs, rhs in
                return sortAscending ? lhs.newsItemCount < rhs.newsItemCount : lhs.newsItemCount > rhs.newsItemCount
            }
        case .unreadCount:
            feeds.sort { lhs, rhs in
                return sortAscending ? lhs.unreadNewsItemCount < rhs.unreadNewsItemCount : lhs.unreadNewsItemCount > rhs.unreadNewsItemCount
            }
        case .createdAt:
            feeds.sort { lhs, rhs in
                let lhsDate = lhs.createdAt ?? Date.distantPast
                let rhsDate = rhs.createdAt ?? Date.distantPast
                return sortAscending ? lhsDate < rhsDate : lhsDate > rhsDate
            }
        }
    }
    
    // MARK: - 便利なメソッド
    
    /// フィードリストをリフレッシュする
    func refresh() async {
        await refreshAllActiveFeeds()
    }
    
    /// エラーメッセージをクリアする
    func clearError() {
        errorMessage = nil
    }
    
    /// フィード検証結果をクリアする
    func clearValidationResult() {
        feedValidationResult = nil
    }
    
    // MARK: - プライベートメソッド
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("📡 FeedViewModel: 保存エラー: \(error)")
            errorMessage = "データの保存に失敗しました"
        }
    }
}

// MARK: - 便利な拡張

extension FeedViewModel {
    /// フィードが読み込まれているかどうか
    var hasFeeds: Bool {
        !feeds.isEmpty
    }
    
    /// アクティブなフィードがあるかどうか
    var hasActiveFeeds: Bool {
        feeds.contains { $0.isActive }
    }
    
    /// エラーがあるかどうか
    var hasError: Bool {
        errorMessage != nil
    }
    
    /// 検証結果があるかどうか
    var hasValidationResult: Bool {
        feedValidationResult != nil
    }
}