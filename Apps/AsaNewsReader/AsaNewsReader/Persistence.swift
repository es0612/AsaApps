//
//  Persistence.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // サンプルRSSフィードを作成
        let feed1 = RSSFeed(context: viewContext)
        feed1.id = UUID()
        feed1.title = "朝活パパエンジニアブログ"
        feed1.url = "https://asapapalabs.com/feed/"
        feed1.feedDescription = "朝活、プログラミング、家族について"
        feed1.isActive = true
        feed1.createdAt = Date()
        feed1.updatedAt = Date()
        
        let feed2 = RSSFeed(context: viewContext)
        feed2.id = UUID()
        feed2.title = "テックニュース"
        feed2.url = "https://techcrunch.com/feed/"
        feed2.feedDescription = "最新のテクノロジーニュース"
        feed2.isActive = true
        feed2.createdAt = Date()
        feed2.updatedAt = Date()
        
        // サンプルニュース記事を作成
        let newsItem1 = NewsItem(context: viewContext)
        newsItem1.id = UUID()
        newsItem1.title = "SwiftUIの新機能について"
        newsItem1.content = "SwiftUIの最新アップデートで追加された新機能についてまとめました。"
        newsItem1.author = "朝活パパエンジニア"
        newsItem1.publishedDate = Date()
        newsItem1.url = "https://asapapalabs.com/swiftui-new-features"
        newsItem1.isRead = false
        newsItem1.feedID = feed1.id
        newsItem1.createdAt = Date()
        newsItem1.updatedAt = Date()
        
        let newsItem2 = NewsItem(context: viewContext)
        newsItem2.id = UUID()
        newsItem2.title = "朝活のススメ"
        newsItem2.content = "朝活を始めてから生活が変わりました。効果的な朝活の方法を紹介します。"
        newsItem2.author = "朝活パパエンジニア"
        newsItem2.publishedDate = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
        newsItem2.url = "https://asapapalabs.com/morning-routine"
        newsItem2.isRead = true
        newsItem2.feedID = feed1.id
        newsItem2.createdAt = Date()
        newsItem2.updatedAt = Date()
        
        let newsItem3 = NewsItem(context: viewContext)
        newsItem3.id = UUID()
        newsItem3.title = "AI技術の最新動向"
        newsItem3.content = "人工知能分野の最新動向とこれからの展望について解説します。"
        newsItem3.author = "Tech Writer"
        newsItem3.publishedDate = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
        newsItem3.url = "https://techcrunch.com/ai-trends"
        newsItem3.isRead = false
        newsItem3.feedID = feed2.id
        newsItem3.createdAt = Date()
        newsItem3.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NewsReader")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
        } else {
            // 最初に既存のストアファイルをチェックして、互換性がない場合は削除
            self.setupPersistentStore()
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// 永続ストアを設定する（マイグレーションエラー対応）
    private func setupPersistentStore() {
        let storeDescription = container.persistentStoreDescriptions.first!
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        // デバッグ: データベースファイルの場所を表示
        if let storeURL = storeDescription.url {
            print("🔄 Core Data: データベースファイル場所: \(storeURL.path)")
        }
        
        // 最大3回まで試行
        var attempts = 0
        let maxAttempts = 3
        
        func loadStore() {
            attempts += 1
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    print("🔄 Core Data: ストア読み込みエラー (試行 \(attempts)/\(maxAttempts)): \(error.localizedDescription)")
                    
                    if attempts < maxAttempts {
                        // データベースファイルを削除して再試行
                        self.cleanupDatabaseFiles()
                        loadStore()
                    } else {
                        print("🔄 Core Data: 最大試行回数に達しました。アプリを終了します。")
                        fatalError("Core Data setup failed after \(maxAttempts) attempts: \(error)")
                    }
                } else {
                    print("🔄 Core Data: ストアの読み込みが成功しました (試行 \(attempts))")
                }
            })
        }
        
        loadStore()
    }
    
    /// データベースファイルをクリーンアップする
    private func cleanupDatabaseFiles() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        
        let fileManager = FileManager.default
        let storeDirectory = storeURL.deletingLastPathComponent()
        
        do {
            // NewsReader関連のファイルをすべて削除
            let contents = try fileManager.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                let filename = url.lastPathComponent
                if filename.hasPrefix("NewsReader") {
                    try fileManager.removeItem(at: url)
                    print("🔄 Core Data: 削除しました: \(filename)")
                }
            }
        } catch {
            print("🔄 Core Data: ファイル削除エラー: \(error)")
        }
    }
}