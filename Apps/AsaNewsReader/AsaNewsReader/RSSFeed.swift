//
//  RSSFeed.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import Foundation
import CoreData

extension RSSFeed {
    
    // MARK: - 便利なプロパティ
    
    /// フィードのタイトル（安全な文字列）
    var safeTitle: String {
        return title ?? "タイトルなし"
    }
    
    /// フィードのURL（安全な文字列）
    var safeUrl: String {
        return url ?? ""
    }
    
    /// フィードの説明（安全な文字列）
    var safeDescription: String {
        return feedDescription ?? ""
    }
    
    /// 最後の取得日時（フォーマット済み）
    var formattedLastFetched: String {
        guard let lastFetched = lastFetched else { return "取得なし" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: lastFetched)
    }
    
    /// 最後の取得日時（相対時間）
    var relativeLastFetched: String {
        guard let lastFetched = lastFetched else { return "取得なし" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: lastFetched, relativeTo: Date())
    }
    
    /// フィードのニュース記事数
    var newsItemCount: Int {
        guard let context = managedObjectContext,
              let feedID = id else { return 0 }
        
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "feedID == %@", feedID as CVarArg)
        
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    /// フィードの未読記事数
    var unreadNewsItemCount: Int {
        guard let context = managedObjectContext,
              let feedID = id else { return 0 }
        
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "feedID == %@ AND isRead == false", feedID as CVarArg)
        
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    /// フィードの最新記事の公開日
    var latestNewsDate: Date? {
        guard let context = managedObjectContext,
              let feedID = id else { return nil }
        
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "feedID == %@", feedID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NewsItem.publishedDate, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let items = try context.fetch(request)
            return items.first?.publishedDate
        } catch {
            return nil
        }
    }
    
    /// フィードが最近更新されたかどうか（24時間以内）
    var isRecentlyUpdated: Bool {
        guard let lastFetched = lastFetched else { return false }
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return lastFetched > dayAgo
    }
    
    /// フィードのステータス文字列
    var statusText: String {
        if !isActive {
            return "無効"
        } else if lastFetched == nil {
            return "未取得"
        } else if isRecentlyUpdated {
            return "最新"
        } else {
            return "古い"
        }
    }
    
    /// フィードのニュース記事を配列で取得（最新順）
    var sortedNewsItems: [NewsItem] {
        guard let context = managedObjectContext,
              let feedID = id else { return [] }
        
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "feedID == %@", feedID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NewsItem.publishedDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// フィードの未読記事を配列で取得（最新順）
    var unreadNewsItems: [NewsItem] {
        guard let context = managedObjectContext,
              let feedID = id else { return [] }
        
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "feedID == %@ AND isRead == false", feedID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NewsItem.publishedDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    // MARK: - 便利なメソッド
    
    /// フィードを有効にする
    func activate() {
        if !isActive {
            isActive = true
            updatedAt = Date()
        }
    }
    
    /// フィードを無効にする
    func deactivate() {
        if isActive {
            isActive = false
            updatedAt = Date()
        }
    }
    
    /// フィードの有効状態を切り替える
    func toggleActiveStatus() {
        isActive.toggle()
        updatedAt = Date()
    }
    
    /// フィードの情報を更新する
    func updateInfo(title: String?, description: String?) {
        if let title = title { self.title = title }
        if let description = description { self.feedDescription = description }
        self.updatedAt = Date()
    }
    
    /// フィードの最終取得日時を更新
    func updateLastFetched() {
        lastFetched = Date()
        updatedAt = Date()
    }
    
    /// フィードの全記事を既読にする
    func markAllAsRead() {
        let newsItems = sortedNewsItems
        for newsItem in newsItems {
            newsItem.markAsRead()
        }
    }
    
    /// フィードの全記事を未読にする
    func markAllAsUnread() {
        let newsItems = sortedNewsItems
        for newsItem in newsItems {
            newsItem.markAsUnread()
        }
    }
    
    /// フィードの古い記事を削除（指定した日数より古い記事）
    func deleteOldNews(olderThan days: Int) {
        guard let context = managedObjectContext,
              let feedID = id else { return }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "feedID == %@ AND publishedDate < %@", feedID as CVarArg, cutoffDate as NSDate)
        
        do {
            let oldItems = try context.fetch(request)
            for item in oldItems {
                context.delete(item)
            }
        } catch {
            print("Error deleting old news items: \(error)")
        }
    }
    
    // MARK: - 静的メソッド
    
    /// 新しいRSSFeedを作成
    static func create(in context: NSManagedObjectContext, 
                      title: String, 
                      url: String, 
                      description: String? = nil) -> RSSFeed {
        let feed = RSSFeed(context: context)
        feed.id = UUID()
        feed.title = title
        feed.url = url
        feed.feedDescription = description
        feed.isActive = true
        feed.createdAt = Date()
        feed.updatedAt = Date()
        return feed
    }
    
    /// アクティブなフィードのfetch request
    static func activeFeedsRequest() -> NSFetchRequest<RSSFeed> {
        let request: NSFetchRequest<RSSFeed> = RSSFeed.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RSSFeed.title, ascending: true)]
        return request
    }
    
    /// 全フィードのfetch request
    static func allFeedsRequest() -> NSFetchRequest<RSSFeed> {
        let request: NSFetchRequest<RSSFeed> = RSSFeed.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RSSFeed.title, ascending: true)]
        return request
    }
    
    /// URLでフィードを検索するfetch request
    static func feedByUrl(_ url: String) -> NSFetchRequest<RSSFeed> {
        let request: NSFetchRequest<RSSFeed> = RSSFeed.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", url)
        request.fetchLimit = 1
        return request
    }
}