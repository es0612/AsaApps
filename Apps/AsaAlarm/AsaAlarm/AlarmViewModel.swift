import Foundation
import UserNotifications

@Observable
class AlarmViewModel {
    var alarms: [Alarm] = []
    private let userDefaults = UserDefaults.standard
    private let alarmsKey = "SavedAlarms"
    
    init() {
        loadAlarms()
        requestNotificationPermission()
    }
    
    private func loadAlarms() {
        if let data = userDefaults.data(forKey: alarmsKey),
           let decodedAlarms = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decodedAlarms
        }
    }
    
    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            userDefaults.set(encoded, forKey: alarmsKey)
        }
    }
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
        if alarm.isEnabled {
            scheduleNotification(for: alarm)
        }
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()
            
            cancelNotification(for: alarm.id)
            
            if alarm.isEnabled {
                scheduleNotification(for: alarm)
            }
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
        cancelNotification(for: alarm.id)
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            saveAlarms()
            
            if alarms[index].isEnabled {
                scheduleNotification(for: alarms[index])
            } else {
                cancelNotification(for: alarm.id)
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知権限のリクエストでエラーが発生しました: \(error)")
            } else if granted {
                print("通知権限が許可されました")
            } else {
                print("通知権限が拒否されました")
            }
        }
    }
    
    private func scheduleNotification(for alarm: Alarm) {
        guard let nextDate = alarm.nextAlarmDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "アラーム"
        content.body = alarm.label.isEmpty ? "時間です！" : alarm.label
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知のスケジュールでエラーが発生しました: \(error)")
            } else {
                print("アラーム通知をスケジュールしました: \(alarm.timeString)")
            }
        }
        
        if !alarm.repeatDays.isEmpty {
            scheduleRepeatingNotifications(for: alarm)
        }
    }
    
    private func scheduleRepeatingNotifications(for alarm: Alarm) {
        for day in alarm.repeatDays {
            let content = UNMutableNotificationContent()
            content.title = "アラーム"
            content.body = alarm.label.isEmpty ? "時間です！" : alarm.label
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "ALARM_CATEGORY"
            
            var dateComponents = DateComponents()
            dateComponents.weekday = day.calendarWeekday
            dateComponents.hour = Calendar.current.component(.hour, from: alarm.time)
            dateComponents.minute = Calendar.current.component(.minute, from: alarm.time)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(alarm.id.uuidString)_\(day.rawValue)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("繰り返し通知のスケジュールでエラーが発生しました: \(error)")
                }
            }
        }
    }
    
    private func cancelNotification(for alarmId: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [alarmId.uuidString])
        
        for day in Weekday.allCases {
            let identifier = "\(alarmId.uuidString)_\(day.rawValue)"
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    func snoozeAlarm(_ alarmId: UUID, for minutes: Int = 5) {
        let content = UNMutableNotificationContent()
        content.title = "スヌーズアラーム"
        content.body = "スヌーズが終了しました"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "SNOOZE_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "snooze_\(alarmId.uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("スヌーズ通知のスケジュールでエラーが発生しました: \(error)")
            }
        }
    }
}