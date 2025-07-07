//
//  NewsItem.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import Foundation
import CoreData

extension NewsItem {
    
    // MARK: - 便利なプロパティ
    
    /// 記事のタイトル（安全な文字列）
    var safeTitle: String {
        return title ?? "タイトルなし"
    }
    
    /// 記事の内容（安全な文字列）
    var safeContent: String {
        return content ?? ""
    }
    
    /// 記事の作者（安全な文字列）
    var safeAuthor: String {
        return author ?? "作者不明"
    }
    
    /// 記事のURL（安全な文字列）
    var safeUrl: String {
        return url ?? ""
    }
    
    /// 記事の公開日（フォーマット済み）
    var formattedPublishedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: publishedDate ?? Date())
    }
    
    /// 記事の公開日（相対時間）
    var relativePublishedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: publishedDate ?? Date(), relativeTo: Date())
    }
    
    /// 記事の内容のプレビュー（最初の100文字）
    var contentPreview: String {
        let maxLength = 100
        if safeContent.count <= maxLength {
            return safeContent
        } else {
            let index = safeContent.index(safeContent.startIndex, offsetBy: maxLength)
            return String(safeContent[..<index]) + "..."
        }
    }
    
    /// 記事が新しいかどうか（24時間以内）
    var isNew: Bool {
        guard let publishedDate = publishedDate else { return false }
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return publishedDate > dayAgo
    }
    
    /// 所属フィードのタイトル
    var feedTitle: String {
        guard let feedID = feedID,
              let context = managedObjectContext else { return "フィードなし" }
        
        let request: NSFetchRequest<RSSFeed> = RSSFeed.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", feedID as CVarArg)
        request.fetchLimit = 1
        
        do {
            let feeds = try context.fetch(request)
            return feeds.first?.safeTitle ?? "フィードなし"
        } catch {
            return "フィードなし"
        }
    }
    
    // MARK: - 便利なメソッド
    
    /// 記事を既読にする
    func markAsRead() {
        if !isRead {
            isRead = true
            updatedAt = Date()
        }
    }
    
    /// 記事を未読にする
    func markAsUnread() {
        if isRead {
            isRead = false
            updatedAt = Date()
        }
    }
    
    /// 記事の既読状態を切り替える
    func toggleReadStatus() {
        isRead.toggle()
        updatedAt = Date()
    }
    
    /// 記事のデータを更新する
    func updateContent(title: String?, content: String?, author: String?, publishedDate: Date?) {
        if let title = title { self.title = title }
        if let content = content { self.content = content }
        if let author = author { self.author = author }
        if let publishedDate = publishedDate { self.publishedDate = publishedDate }
        self.updatedAt = Date()
    }
    
    // MARK: - 静的メソッド
    
    /// 新しいNewsItemを作成
    static func create(in context: NSManagedObjectContext, 
                      title: String, 
                      content: String, 
                      author: String? = nil, 
                      publishedDate: Date, 
                      url: String, 
                      feedID: UUID) -> NewsItem {
        let newsItem = NewsItem(context: context)
        newsItem.id = UUID()
        newsItem.title = title
        newsItem.content = content
        newsItem.author = author
        newsItem.publishedDate = publishedDate
        newsItem.url = url
        newsItem.isRead = false
        newsItem.feedID = feedID
        newsItem.createdAt = Date()
        newsItem.updatedAt = Date()
        return newsItem
    }
    
    /// 指定されたフィードの記事を取得
    static func fetchRequest(for feed: RSSFeed) -> NSFetchRequest<NewsItem> {
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "feedID == %@", feed.id! as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NewsItem.publishedDate, ascending: false)]
        return request
    }
    
    /// 未読記事のfetch request
    static func unreadFetchRequest() -> NSFetchRequest<NewsItem> {
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "isRead == false")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NewsItem.publishedDate, ascending: false)]
        return request
    }
    
    /// 検索用のfetch request
    static func searchFetchRequest(searchText: String) -> NSFetchRequest<NewsItem> {
        let request: NSFetchRequest<NewsItem> = NewsItem.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", searchText, searchText)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NewsItem.publishedDate, ascending: false)]
        return request
    }
}