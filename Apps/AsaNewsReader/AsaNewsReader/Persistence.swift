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
        } else {
            // 自動マイグレーションを有効にする
            let storeDescription = container.persistentStoreDescriptions.first!
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
        }
        
        let containerRef = container
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // マイグレーションエラーの場合、データベースを削除して再作成
                print("🔄 Core Data: マイグレーションエラーが発生しました。データベースをリセットします。")
                print("🔄 Core Data: エラー詳細: \(error.localizedDescription)")
                PersistenceController.deleteAndRecreateStore(container: containerRef)
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// データベースストアを削除して再作成する（静的メソッド）
    private static func deleteAndRecreateStore(container: NSPersistentContainer) {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        
        do {
            // 既存のストアファイルを削除
            try FileManager.default.removeItem(at: storeURL)
            
            // 関連ファイルも削除
            let walURL = storeURL.appendingPathExtension("wal")
            let shmURL = storeURL.appendingPathExtension("shm")
            
            try? FileManager.default.removeItem(at: walURL)
            try? FileManager.default.removeItem(at: shmURL)
            
            print("🔄 Core Data: 古いデータベースファイルを削除しました。")
            
            // 新しいストアを作成
            container.loadPersistentStores { _, error in
                if let error = error {
                    print("🔄 Core Data: 新しいデータベースの作成に失敗: \(error)")
                } else {
                    print("🔄 Core Data: 新しいデータベースを作成しました。")
                }
            }
        } catch {
            print("🔄 Core Data: ファイル削除エラー: \(error)")
        }
    }
}