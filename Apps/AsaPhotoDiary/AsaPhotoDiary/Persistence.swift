//
//  Persistence.swift
//  AsaPhotoDiary
//  
//  Created on 2025/07/05
//

import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // サンプル日記エントリーを作成
        let entry1 = DiaryEntry(context: viewContext)
        entry1.id = UUID()
        entry1.title = "朝活で散歩"
        entry1.content = "今日も早起きして近所の公園を散歩しました。朝の空気がとても気持ちよく、鳥のさえずりが聞こえて心が癒されました。"
        entry1.date = Date()
        entry1.category = "日常"
        entry1.mood = "とても良い"
        entry1.createdAt = Date()
        entry1.updatedAt = Date()
        
        let entry2 = DiaryEntry(context: viewContext)
        entry2.id = UUID()
        entry2.title = "家族でお出かけ"
        entry2.content = "子供たちと一緒に動物園に行きました。子供たちの笑顔を見ているだけで幸せな気持ちになりました。"
        entry2.date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        entry2.category = "家族"
        entry2.mood = "幸せ"
        entry2.createdAt = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        entry2.updatedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        let entry3 = DiaryEntry(context: viewContext)
        entry3.id = UUID()
        entry3.title = "美味しいランチ"
        entry3.content = "新しいレストランで美味しいパスタを食べました。トマトソースの味が絶品でした。"
        entry3.date = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        entry3.category = "食事"
        entry3.mood = "満足"
        entry3.createdAt = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        entry3.updatedAt = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        
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
        container = NSPersistentContainer(name: "AsaPhotoDiary")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}