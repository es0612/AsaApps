//
//  SleepLogViewModel.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import Foundation

class SleepLogViewModel: ObservableObject {
    @Published var sleepLogs: [SleepLog] = []
    @Published var bedTime = Date()
    @Published var wakeTime = Date()
    @Published var selectedQuality: SleepQuality = .normal
    @Published var notes = ""
    
    private let userDefaults = UserDefaults.standard
    private let logsKey = "AsaSleepLogs"
    
    init() {
        loadSleepLogs()
        setDefaultTimes()
    }
    
    private func setDefaultTimes() {
        let calendar = Calendar.current
        let now = Date()
        
        // 就寝時間のデフォルト（前日の22:00）
        bedTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: now) ?? now) ?? now
        
        // 起床時間のデフォルト（今日の6:00）
        wakeTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now
    }
    
    func addSleepLog() {
        let newLog = SleepLog(
            date: Date(),
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: selectedQuality,
            notes: notes.isEmpty ? nil : notes
        )
        
        sleepLogs.append(newLog)
        saveSleepLogs()
        
        // リセット
        setDefaultTimes()
        selectedQuality = .normal
        notes = ""
    }
    
    func deleteSleepLog(at indexSet: IndexSet) {
        sleepLogs.remove(atOffsets: indexSet)
        saveSleepLogs()
    }
    
    private func saveSleepLogs() {
        if let encoded = try? JSONEncoder().encode(sleepLogs) {
            userDefaults.set(encoded, forKey: logsKey)
        }
    }
    
    private func loadSleepLogs() {
        if let data = userDefaults.data(forKey: logsKey),
           let decodedLogs = try? JSONDecoder().decode([SleepLog].self, from: data) {
            sleepLogs = decodedLogs.sorted { $0.date > $1.date }
        }
    }
    
    var averageSleepDuration: TimeInterval {
        guard !sleepLogs.isEmpty else { return 0 }
        let totalDuration = sleepLogs.reduce(0) { $0 + $1.sleepDuration }
        return totalDuration / Double(sleepLogs.count)
    }
    
    var averageSleepDurationFormatted: String {
        let hours = Int(averageSleepDuration / 3600)
        let minutes = Int((averageSleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)時間\(minutes)分"
    }
}