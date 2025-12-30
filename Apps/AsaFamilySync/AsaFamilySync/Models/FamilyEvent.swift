import Foundation
#if FIREBASE_ENABLED
import FirebaseFirestore
#endif

struct FamilyEvent: Codable, Identifiable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?
    #else
    var id: String?
    #endif
    var title: String
    var description: String?
    var startTime: Date
    var endTime: Date
    var category: EventCategory
    var createdBy: String // userId
    var createdByName: String
    var assignedTo: [String] // userIds
    var location: String?
    var isAllDay: Bool = false
    var recurring: RecurringType = .none
    var reminders: [ReminderTime] = []
    var color: String?
    var createdAt: Date
    var updatedAt: Date

    init(title: String,
         description: String? = nil,
         startTime: Date,
         endTime: Date,
         category: EventCategory,
         createdBy: String,
         createdByName: String,
         assignedTo: [String] = []) {
        self.title = title
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.category = category
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.assignedTo = assignedTo
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes > 0 ? "\(minutes)分" : "")"
        } else {
            return "\(minutes)分"
        }
    }
}

enum RecurringType: String, Codable, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .none: return "繰り返しなし"
        case .daily: return "毎日"
        case .weekly: return "毎週"
        case .biweekly: return "隔週"
        case .monthly: return "毎月"
        }
    }
}

enum ReminderTime: String, Codable, CaseIterable {
    case atTime = "atTime"
    case fiveMinutes = "5min"
    case tenMinutes = "10min"
    case thirtyMinutes = "30min"
    case oneHour = "1hour"
    case oneDay = "1day"

    var displayName: String {
        switch self {
        case .atTime: return "時刻通り"
        case .fiveMinutes: return "5分前"
        case .tenMinutes: return "10分前"
        case .thirtyMinutes: return "30分前"
        case .oneHour: return "1時間前"
        case .oneDay: return "1日前"
        }
    }

    var timeInterval: TimeInterval {
        switch self {
        case .atTime: return 0
        case .fiveMinutes: return -300
        case .tenMinutes: return -600
        case .thirtyMinutes: return -1800
        case .oneHour: return -3600
        case .oneDay: return -86400
        }
    }
}