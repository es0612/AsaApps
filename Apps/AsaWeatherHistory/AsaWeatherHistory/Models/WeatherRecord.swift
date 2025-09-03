import Foundation
import CoreData

@objc(WeatherRecord)
public class WeatherRecord: NSManagedObject {
    
}

// MARK: - Core Data Properties
extension WeatherRecord {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeatherRecord> {
        return NSFetchRequest<WeatherRecord>(entityName: "WeatherRecord")
    }
    
    // 基本情報
    @NSManaged public var recordDate: Date
    @NSManaged public var locationName: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var country: String?
    
    // 気温情報
    @NSManaged public var temperature: Double
    @NSManaged public var feelsLikeTemperature: Double
    @NSManaged public var minTemperature: Double
    @NSManaged public var maxTemperature: Double
    
    // 気象情報
    @NSManaged public var pressure: Int32
    @NSManaged public var humidity: Int32
    @NSManaged public var weatherCode: Int32
    @NSManaged public var weatherMain: String?
    @NSManaged public var weatherDescription: String?
    
    // 風情報
    @NSManaged public var windSpeed: Double
    @NSManaged public var windDirection: Int32
    
    // 日の出・日の入り
    @NSManaged public var sunrise: Date?
    @NSManaged public var sunset: Date?
    
    // メタデータ
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

// MARK: - Identifiable
extension WeatherRecord: Identifiable {
    
}

// MARK: - Convenience Methods
extension WeatherRecord {
    /// 新しいWeatherRecordを作成
    static func create(in context: NSManagedObjectContext) -> WeatherRecord {
        let record = WeatherRecord(context: context)
        record.createdAt = Date()
        record.updatedAt = Date()
        return record
    }
    
    /// レコードを更新
    func update() {
        updatedAt = Date()
    }
    
    /// 表示用の日付文字列
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: recordDate)
    }
    
    /// 表示用の短い日付文字列
    var shortDisplayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: recordDate)
    }
    
    /// 表示用の気温文字列
    var temperatureString: String {
        return String(format: "%.0f°C", temperature)
    }
    
    /// 表示用の天気アイコン名
    var weatherIconName: String {
        switch weatherMain?.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain":
            return "cloud.rain.fill"
        case "drizzle":
            return "cloud.drizzle.fill"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog":
            return "cloud.fog.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    /// 天気の状況色
    var weatherColor: String {
        switch weatherMain?.lowercased() {
        case "clear":
            return "AsaCoffeeBrown"
        case "clouds":
            return "AsaMutedSage"
        case "rain", "drizzle":
            return "AsaDarkSlate"
        case "thunderstorm":
            return "AsaMocha"
        case "snow":
            return "AsaSoftCream"
        default:
            return "AsaCoffeeBrown"
        }
    }
}

// MARK: - Fetch Request Helpers
extension WeatherRecord {
    
    /// 最新のレコードを取得
    static func fetchLatest(limit: Int = 10, in context: NSManagedObjectContext) -> [WeatherRecord] {
        let request: NSFetchRequest<WeatherRecord> = WeatherRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeatherRecord.recordDate, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch latest weather records: \(error)")
            return []
        }
    }
    
    /// 指定された日付範囲のレコードを取得
    static func fetchRecords(from startDate: Date, to endDate: Date, in context: NSManagedObjectContext) -> [WeatherRecord] {
        let request: NSFetchRequest<WeatherRecord> = WeatherRecord.fetchRequest()
        request.predicate = NSPredicate(format: "recordDate >= %@ AND recordDate <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeatherRecord.recordDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch weather records for date range: \(error)")
            return []
        }
    }
    
    /// 今日のレコードを取得
    static func fetchTodaysRecords(in context: NSManagedObjectContext) -> [WeatherRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        return fetchRecords(from: startOfDay, to: endOfDay, in: context)
    }
    
    /// 古いレコード（指定日数以前）を削除
    static func deleteOldRecords(olderThan days: Int, in context: NSManagedObjectContext) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let request: NSFetchRequest<WeatherRecord> = WeatherRecord.fetchRequest()
        request.predicate = NSPredicate(format: "recordDate < %@", cutoffDate as NSDate)
        
        do {
            let oldRecords = try context.fetch(request)
            for record in oldRecords {
                context.delete(record)
            }
            try context.save()
            print("Deleted \(oldRecords.count) old weather records")
        } catch {
            print("Failed to delete old weather records: \(error)")
        }
    }
    
    /// レコード数を取得
    static func count(in context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<WeatherRecord> = WeatherRecord.fetchRequest()
        
        do {
            return try context.count(for: request)
        } catch {
            print("Failed to count weather records: \(error)")
            return 0
        }
    }
}