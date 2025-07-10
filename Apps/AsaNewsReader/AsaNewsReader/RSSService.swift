//
//  RSSService.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import Foundation
import CoreData

class RSSService: ObservableObject {
    private let session = URLSession.shared
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - フィード取得メソッド
    
    /// RSSフィードを取得して解析する
    func fetchFeed(_ feed: RSSFeed) async throws -> [RSSItem] {
        guard let url = URL(string: feed.safeUrl) else {
            throw RSSError.invalidURL
        }
        
        print("🌐 RSSService: RSSフィードを取得中: \(feed.safeUrl)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RSSError.invalidResponse
        }
        
        let parser = RSSParser()
        let items = try parser.parse(data)
        
        print("🌐 RSSService: \(items.count)件の記事を取得")
        
        return items
    }
    
    /// 複数のフィードを同時に取得する
    func fetchMultipleFeeds(_ feeds: [RSSFeed]) async throws -> [RSSFeed: [RSSItem]] {
        var results: [RSSFeed: [RSSItem]] = [:]
        
        await withTaskGroup(of: (RSSFeed, Result<[RSSItem], Error>).self) { group in
            for feed in feeds {
                group.addTask {
                    do {
                        let items = try await self.fetchFeed(feed)
                        return (feed, .success(items))
                    } catch {
                        return (feed, .failure(error))
                    }
                }
            }
            
            for await (feed, result) in group {
                switch result {
                case .success(let items):
                    results[feed] = items
                case .failure(let error):
                    print("🌐 RSSService: \(feed.safeTitle)の取得に失敗: \(error)")
                }
            }
        }
        
        return results
    }
    
    /// フィードを取得してCore Dataに保存する
    func fetchAndSaveNews(for feed: RSSFeed) async throws {
        let items = try await fetchFeed(feed)
        
        try await context.perform {
            for item in items {
                // 既存の記事をチェック（重複回避）
                let existingRequest = NSFetchRequest<NewsItem>(entityName: "NewsItem")
                existingRequest.predicate = NSPredicate(format: "url == %@ AND feedID == %@", item.link, feed.id! as CVarArg)
                existingRequest.fetchLimit = 1
                
                do {
                    let existingItems = try self.context.fetch(existingRequest)
                    if existingItems.isEmpty {
                        // 新しい記事を作成
                        let newsItem = NewsItem.create(
                            in: self.context,
                            title: item.title,
                            content: item.description,
                            author: item.author,
                            publishedDate: item.publishedDate,
                            url: item.link,
                            feedID: feed.id!
                        )
                        print("🌐 RSSService: 新しい記事を追加: \(newsItem.safeTitle)")
                    }
                } catch {
                    print("🌐 RSSService: 既存記事チェック時のエラー: \(error)")
                }
            }
            
            // フィードの最終取得時刻を更新
            feed.updateLastFetched()
            
            // 保存
            do {
                try self.context.save()
                print("🌐 RSSService: データを保存しました")
            } catch {
                print("🌐 RSSService: 保存エラー: \(error)")
                // Core Dataエラーの場合は上位に投げる
                throw RSSError.dataCorrupted
            }
        }
    }
    
    /// 全てのアクティブなフィードを更新する
    func updateAllActiveFeeds() async throws {
        let request = RSSFeed.activeFeedsRequest()
        let feeds = try context.fetch(request)
        
        print("🌐 RSSService: \(feeds.count)個のアクティブなフィードを更新中")
        
        for feed in feeds {
            do {
                try await fetchAndSaveNews(for: feed)
            } catch {
                print("🌐 RSSService: \(feed.safeTitle)の更新に失敗: \(error)")
            }
        }
    }
    
    /// フィードのURLを検証する
    func validateFeedURL(_ urlString: String) async throws -> RSSFeedInfo {
        guard let url = URL(string: urlString) else {
            throw RSSError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RSSError.invalidResponse
        }
        
        let parser = RSSParser()
        let feedInfo = try parser.parseFeedInfo(data)
        
        return feedInfo
    }
}

// MARK: - データ構造

/// RSSアイテムの構造
struct RSSItem {
    let title: String
    let link: String
    let description: String
    let author: String?
    let publishedDate: Date
    let guid: String?
}

/// RSSフィード情報の構造
struct RSSFeedInfo {
    let title: String
    let description: String
    let link: String
}

// MARK: - エラー定義

enum RSSError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case parsingError
    case networkError
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .parsingError:
            return "RSSフィードの解析に失敗しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .dataCorrupted:
            return "データが破損しています"
        }
    }
}

// MARK: - RSS Parser

class RSSParser: NSObject, XMLParserDelegate {
    private var items: [RSSItem] = []
    private var currentItem: RSSItem?
    private var feedInfo: RSSFeedInfo?
    
    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentLink: String = ""
    private var currentDescription: String = ""
    private var currentAuthor: String = ""
    private var currentPubDate: String = ""
    private var currentGuid: String = ""
    
    private var feedTitle: String = ""
    private var feedDescription: String = ""
    private var feedLink: String = ""
    
    private var inItem: Bool = false
    private var inChannel: Bool = false
    
    func parse(_ data: Data) throws -> [RSSItem] {
        items = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        if parser.parse() {
            return items
        } else {
            throw RSSError.parsingError
        }
    }
    
    func parseFeedInfo(_ data: Data) throws -> RSSFeedInfo {
        feedInfo = nil
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        if parser.parse(), let info = feedInfo {
            return info
        } else {
            throw RSSError.parsingError
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            inItem = true
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentAuthor = ""
            currentPubDate = ""
            currentGuid = ""
        } else if elementName == "channel" {
            inChannel = true
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !data.isEmpty {
            switch currentElement {
            case "title":
                if inItem {
                    currentTitle += data
                } else if inChannel {
                    feedTitle += data
                }
            case "link":
                if inItem {
                    currentLink += data
                } else if inChannel {
                    feedLink += data
                }
            case "description":
                if inItem {
                    currentDescription += data
                } else if inChannel {
                    feedDescription += data
                }
            case "author", "dc:creator":
                if inItem {
                    currentAuthor += data
                }
            case "pubDate":
                if inItem {
                    currentPubDate += data
                }
            case "guid":
                if inItem {
                    currentGuid += data
                }
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            inItem = false
            
            // 日付を解析
            let publishedDate = parseDate(from: currentPubDate) ?? Date()
            
            let item = RSSItem(
                title: currentTitle,
                link: currentLink,
                description: currentDescription,
                author: currentAuthor.isEmpty ? nil : currentAuthor,
                publishedDate: publishedDate,
                guid: currentGuid.isEmpty ? nil : currentGuid
            )
            
            items.append(item)
        } else if elementName == "channel" {
            inChannel = false
            
            feedInfo = RSSFeedInfo(
                title: feedTitle,
                description: feedDescription,
                link: feedLink
            )
        }
    }
    
    // MARK: - 日付解析
    
    private func parseDate(from string: String) -> Date? {
        let formatters = [
            // RFC 2822 形式
            DateFormatter.rfc2822,
            // ISO 8601 形式
            DateFormatter.iso8601,
            // その他の形式
            DateFormatter.custom("yyyy-MM-dd'T'HH:mm:ss'Z'"),
            DateFormatter.custom("yyyy-MM-dd HH:mm:ss")
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        return nil
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let rfc2822: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static func custom(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}

// MARK: - Singleton

extension RSSService {
    static func shared(context: NSManagedObjectContext) -> RSSService {
        return RSSService(context: context)
    }
}