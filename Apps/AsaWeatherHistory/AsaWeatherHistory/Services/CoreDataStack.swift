import Foundation
import CoreData
import SwiftUI

/// Core Dataスタック管理クラス
class CoreDataStack: ObservableObject {
    
    static let shared = CoreDataStack()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WeatherHistoryModel")
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Core Data loaded successfully from: \(storeDescription.url?.absoluteString ?? "unknown")")
            }
        }
        
        // 自動的に変更をマージする設定
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Save Context
    func save() {
        let context = persistentContainer.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("Core Data saved successfully")
        } catch {
            print("Failed to save Core Data context: \(error)")
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        context.performAndWait {
            do {
                try context.save()
                print("Background context saved successfully")
            } catch {
                print("Failed to save background context: \(error)")
            }
        }
    }
    
    // MARK: - Batch Operations
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = newBackgroundContext()
        backgroundContext.perform {
            block(backgroundContext)
            
            if backgroundContext.hasChanges {
                do {
                    try backgroundContext.save()
                } catch {
                    print("Failed to save background context: \(error)")
                }
            }
        }
    }
    
    // MARK: - Database Maintenance
    /// データベースの最適化
    func optimizeDatabase() {
        performBackgroundTask { context in
            // 90日以前の古いデータを削除
            WeatherRecord.deleteOldRecords(olderThan: 90, in: context)
            
            // データベース統計を出力
            let totalRecords = WeatherRecord.count(in: context)
            print("Database optimized. Total records: \(totalRecords)")
        }
    }
    
    /// データベースの統計情報を取得
    func getDatabaseStats() -> (totalRecords: Int, todaysRecords: Int, oldestRecord: Date?, newestRecord: Date?) {
        let totalRecords = WeatherRecord.count(in: context)
        let todaysRecords = WeatherRecord.fetchTodaysRecords(in: context).count
        
        // 最古と最新のレコード日付を取得
        let oldestRequest: NSFetchRequest<WeatherRecord> = WeatherRecord.fetchRequest()
        oldestRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WeatherRecord.recordDate, ascending: true)]
        oldestRequest.fetchLimit = 1
        
        let newestRequest: NSFetchRequest<WeatherRecord> = WeatherRecord.fetchRequest()
        newestRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WeatherRecord.recordDate, ascending: false)]
        newestRequest.fetchLimit = 1
        
        let oldestRecord = try? context.fetch(oldestRequest).first?.recordDate
        let newestRecord = try? context.fetch(newestRequest).first?.recordDate
        
        return (totalRecords, todaysRecords, oldestRecord, newestRecord)
    }
    
    // MARK: - Data Migration
    func migrateDataIfNeeded() {
        // 将来のデータマイグレーションのためのプレースホルダー
        print("Checking for data migration...")
    }
    
    // MARK: - Development Helpers
    #if DEBUG
    func printDatabasePath() {
        if let url = persistentContainer.persistentStoreDescriptions.first?.url {
            print("Core Data SQLite file: \(url)")
        }
    }
    
    func deleteAllData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = WeatherRecord.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("All Core Data records deleted")
        } catch {
            print("Failed to delete all records: \(error)")
        }
    }
    
    func seedTestData() {
        performBackgroundTask { context in
            // テスト用のデータを生成
            let locations = [
                ("東京", 35.6762, 139.6503),
                ("大阪", 34.6937, 135.5023),
                ("名古屋", 35.1815, 136.9066)
            ]
            
            let weatherTypes = ["Clear", "Clouds", "Rain", "Snow"]
            let weatherDescriptions = ["晴れ", "曇り", "雨", "雪"]
            
            for i in 0..<30 {
                let record = WeatherRecord.create(in: context)
                let locationIndex = i % locations.count
                let weatherIndex = i % weatherTypes.count
                let location = locations[locationIndex]
                
                record.recordDate = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
                record.locationName = location.0
                record.latitude = location.1
                record.longitude = location.2
                record.country = "JP"
                
                record.temperature = Double.random(in: -5...35)
                record.feelsLikeTemperature = record.temperature + Double.random(in: -3...3)
                record.minTemperature = record.temperature - Double.random(in: 0...5)
                record.maxTemperature = record.temperature + Double.random(in: 0...5)
                record.pressure = Int32.random(in: 990...1030)
                record.humidity = Int32.random(in: 20...90)
                
                record.weatherCode = Int32(weatherIndex)
                record.weatherMain = weatherTypes[weatherIndex]
                record.weatherDescription = weatherDescriptions[weatherIndex]
                
                record.windSpeed = Double.random(in: 0...15)
                record.windDirection = Int32.random(in: 0...360)
            }
            
            print("Test data seeded successfully")
        }
    }
    #endif
}

// MARK: - SwiftUI Environment
extension CoreDataStack {
    /// SwiftUI環境用のViewModifier
    func inject(into view: some View) -> some View {
        view.environment(\.managedObjectContext, context)
    }
}