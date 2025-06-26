//
//  SleepLogViewModel.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import Foundation

class SleepLogViewModel: ObservableObject {
    @Published var sleepLogs: [SleepLog] = []
    @Published var sleepGoal = SleepGoal()
    @Published var bedTime = Date()
    @Published var wakeTime = Date()
    @Published var fellAsleepTime = Date()
    @Published var selectedQuality: SleepQuality = .normal
    @Published var selectedMood: MoodRating? = nil
    @Published var wakeUpCount = 0
    @Published var notes = ""
    @Published var showAdvancedOptions = false
    
    private let userDefaults = UserDefaults.standard
    private let logsKey = "AsaSleepLogs"
    private let goalKey = "AsaSleepGoal"
    
    init() {
        loadSleepLogs()
        loadSleepGoal()
        setDefaultTimes()
    }
    
    private func setDefaultTimes() {
        let calendar = Calendar.current
        let now = Date()
        
        // 就寝時間のデフォルト（前日の22:00）
        bedTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: now) ?? now) ?? now
        
        // 起床時間のデフォルト（今日の6:00）
        wakeTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now
        
        // 入眠時間のデフォルト（就寝時間の15分後）
        fellAsleepTime = calendar.date(byAdding: .minute, value: 15, to: bedTime) ?? bedTime
    }
    
    func addSleepLog() -> Bool {
        // 時間重複チェック
        if hasTimeConflict(bedTime: bedTime, wakeTime: wakeTime) {
            return false
        }
        
        let newLog = SleepLog(
            date: Date(),
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: selectedQuality,
            notes: notes.isEmpty ? nil : notes,
            fellAsleepTime: showAdvancedOptions ? fellAsleepTime : nil,
            wakeUpCount: showAdvancedOptions ? wakeUpCount : 0,
            mood: selectedMood
        )
        
        sleepLogs.append(newLog)
        sleepLogs.sort { $0.date > $1.date }
        saveSleepLogs()
        
        // リセット
        setDefaultTimes()
        selectedQuality = .normal
        selectedMood = nil
        wakeUpCount = 0
        notes = ""
        showAdvancedOptions = false
        
        return true
    }
    
    func hasTimeConflict(bedTime: Date, wakeTime: Date, excludingId: UUID? = nil) -> Bool {
        let calendar = Calendar.current
        
        for log in sleepLogs {
            if let excludingId = excludingId, log.id == excludingId {
                continue
            }
            
            // 同じ日かチェック
            if calendar.isDate(log.bedTime, inSameDayAs: bedTime) ||
               calendar.isDate(log.wakeTime, inSameDayAs: wakeTime) {
                
                // 時間重複チェック
                let logStart = log.bedTime
                let logEnd = log.wakeTime
                let newStart = bedTime
                let newEnd = wakeTime
                
                if (newStart < logEnd && newEnd > logStart) {
                    return true
                }
            }
        }
        
        return false
    }
    
    func updateSleepLog(_ log: SleepLog) {
        if let index = sleepLogs.firstIndex(where: { $0.id == log.id }) {
            sleepLogs[index] = log
            saveSleepLogs()
        }
    }
    
    func deleteSleepLog(at indexSet: IndexSet) {
        sleepLogs.remove(atOffsets: indexSet)
        saveSleepLogs()
    }
    
    func updateSleepGoal(_ goal: SleepGoal) {
        sleepGoal = goal
        saveSleepGoal()
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
    
    private func saveSleepGoal() {
        if let encoded = try? JSONEncoder().encode(sleepGoal) {
            userDefaults.set(encoded, forKey: goalKey)
        }
    }
    
    private func loadSleepGoal() {
        if let data = userDefaults.data(forKey: goalKey),
           let decodedGoal = try? JSONDecoder().decode(SleepGoal.self, from: data) {
            sleepGoal = decodedGoal
        }
    }
    
    // MARK: - 統計計算
    
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
    
    var averageSleepEfficiency: Double {
        guard !sleepLogs.isEmpty else { return 0 }
        let totalEfficiency = sleepLogs.reduce(0) { $0 + $1.sleepEfficiency }
        return totalEfficiency / Double(sleepLogs.count)
    }
    
    var averageQualityScore: Double {
        guard !sleepLogs.isEmpty else { return 0 }
        let totalScore = sleepLogs.reduce(0) { $0 + $1.qualityScore }
        return Double(totalScore) / Double(sleepLogs.count)
    }
    
    func goalAchievementRate(for period: StatsPeriod = .week) -> Double {
        let logs = sleepLogsForPeriod(period)
        guard !logs.isEmpty else { return 0 }
        
        let achievedLogs = logs.filter { log in
            log.sleepDuration >= sleepGoal.targetSleepDuration - 1800 && // 30分以内の誤差を許容
            log.sleepEfficiency >= sleepGoal.minimumSleepEfficiency
        }
        
        return Double(achievedLogs.count) / Double(logs.count) * 100
    }
    
    func sleepLogsForPeriod(_ period: StatsPeriod) -> [SleepLog] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        }
        
        return sleepLogs.filter { $0.date >= startDate }
    }
    
    func sleepTrendData(for period: StatsPeriod) -> [(Date, TimeInterval)] {
        let logs = sleepLogsForPeriod(period)
        return logs.map { ($0.date, $0.sleepDuration) }.sorted { $0.0 < $1.0 }
    }
    
    func qualityTrendData(for period: StatsPeriod) -> [(Date, Int)] {
        let logs = sleepLogsForPeriod(period)
        return logs.map { ($0.date, $0.qualityScore) }.sorted { $0.0 < $1.0 }
    }
    
    // MARK: - サンプルデータ機能
    
    func generateSampleData() {
        let calendar = Calendar.current
        let today = Date()
        
        // 過去14日分のサンプルデータを生成
        for i in 1...14 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            // ランダムな就寝時間（21:30〜23:30）
            let bedHour = Int.random(in: 21...23)
            let bedMinute = Int.random(in: 0...59)
            guard let bedTime = calendar.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: date) else { continue }
            
            // ランダムな睡眠時間（6.5〜9時間）
            let sleepDurationHours = Double.random(in: 6.5...9.0)
            guard let wakeTime = calendar.date(byAdding: .minute, value: Int(sleepDurationHours * 60), to: bedTime) else { continue }
            
            // ランダムな入眠時間（就寝から5〜30分後）
            let fallAsleepDelay = Int.random(in: 5...30)
            let fellAsleepTime = calendar.date(byAdding: .minute, value: fallAsleepDelay, to: bedTime)
            
            // ランダムなデータ
            let qualities: [SleepQuality] = [.excellent, .good, .normal, .poor, .terrible]
            let moods: [MoodRating] = [.veryHappy, .happy, .neutral, .tired, .exhausted]
            
            let sampleNotes = [
                "よく眠れた",
                "少し寝苦しかった",
                "夢をよく見た",
                "ぐっすり眠れた",
                "途中で目が覚めた",
                nil,
                nil // 空のメモも含める
            ]
            
            let log = SleepLog(
                date: date,
                bedTime: bedTime,
                wakeTime: wakeTime,
                quality: qualities.randomElement() ?? .normal,
                notes: sampleNotes.randomElement() ?? nil,
                fellAsleepTime: fellAsleepTime,
                wakeUpCount: Int.random(in: 0...3),
                mood: moods.randomElement()
            )
            
            sleepLogs.append(log)
        }
        
        sleepLogs.sort { $0.date > $1.date }
        saveSleepLogs()
    }
    
    func clearAllData() {
        sleepLogs.removeAll()
        saveSleepLogs()
    }
}

enum StatsPeriod: String, CaseIterable {
    case week = "week"
    case month = "month"
    case threeMonths = "threeMonths"
    
    var displayName: String {
        switch self {
        case .week: return "1週間"
        case .month: return "1ヶ月"
        case .threeMonths: return "3ヶ月"
        }
    }
}