import Foundation

@Observable
class Alarm: Identifiable, Codable {
    let id = UUID()
    var time: Date
    var label: String
    var isEnabled: Bool
    var repeatDays: Set<Weekday>
    var soundName: String
    var createdAt: Date
    
    init(time: Date = Date(), label: String = "アラーム", isEnabled: Bool = true, repeatDays: Set<Weekday> = [], soundName: String = "default") {
        self.time = time
        self.label = label
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.soundName = soundName
        self.createdAt = Date()
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    var nextAlarmDate: Date? {
        guard isEnabled else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        if repeatDays.isEmpty {
            let today = calendar.startOfDay(for: now)
            let alarmToday = calendar.date(bySettingHour: calendar.component(.hour, from: time),
                                         minute: calendar.component(.minute, from: time),
                                         second: 0,
                                         of: today)!
            
            if alarmToday > now {
                return alarmToday
            } else {
                return calendar.date(byAdding: .day, value: 1, to: alarmToday)!
            }
        } else {
            let sortedDays = repeatDays.sorted { $0.rawValue < $1.rawValue }
            let currentWeekday = calendar.component(.weekday, from: now)
            
            for day in sortedDays {
                let dayValue = day.calendarWeekday
                let daysToAdd = (dayValue - currentWeekday + 7) % 7
                
                let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: now))!
                let alarmDate = calendar.date(bySettingHour: calendar.component(.hour, from: time),
                                            minute: calendar.component(.minute, from: time),
                                            second: 0,
                                            of: targetDate)!
                
                if alarmDate > now {
                    return alarmDate
                }
            }
            
            let firstDay = sortedDays.first!
            let daysToAdd = (firstDay.calendarWeekday - currentWeekday + 7) % 7 + 7
            let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: now))!
            return calendar.date(bySettingHour: calendar.component(.hour, from: time),
                               minute: calendar.component(.minute, from: time),
                               second: 0,
                               of: targetDate)!
        }
    }
    
    var repeatText: String {
        if repeatDays.isEmpty {
            return "一度のみ"
        } else if repeatDays.count == 7 {
            return "毎日"
        } else if repeatDays == Set([.monday, .tuesday, .wednesday, .thursday, .friday]) {
            return "平日"
        } else if repeatDays == Set([.saturday, .sunday]) {
            return "週末"
        } else {
            return repeatDays.sorted { $0.rawValue < $1.rawValue }.map { $0.shortName }.joined(separator: " ")
        }
    }
}

enum Weekday: Int, CaseIterable, Codable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    
    var name: String {
        switch self {
        case .sunday: return "日曜日"
        case .monday: return "月曜日"
        case .tuesday: return "火曜日"
        case .wednesday: return "水曜日"
        case .thursday: return "木曜日"
        case .friday: return "金曜日"
        case .saturday: return "土曜日"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "日"
        case .monday: return "月"
        case .tuesday: return "火"
        case .wednesday: return "水"
        case .thursday: return "木"
        case .friday: return "金"
        case .saturday: return "土"
        }
    }
    
    var calendarWeekday: Int {
        return rawValue == 0 ? 1 : rawValue + 1
    }
}