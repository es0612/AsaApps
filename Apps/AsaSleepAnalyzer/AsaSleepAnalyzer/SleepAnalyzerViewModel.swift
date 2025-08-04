//
//  SleepAnalyzerViewModel.swift
//  AsaSleepAnalyzer
//
//  Created on 2025/08/05
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class SleepAnalyzerViewModel {
    private let healthKitService = HealthKitSleepService()
    private var modelContext: ModelContext?
    
    // UI状態
    var isLoading = false
    var errorMessage: String?
    var showingPermissionAlert = false
    
    // 睡眠データ
    var todaySleepData: SleepData?
    var weeklySleepData: [SleepData] = []
    var selectedDate = Date()
    var selectedSleepData: SleepData?
    
    // 統計データ
    var averageSleepDuration: TimeInterval = 0
    var averageSleepEfficiency: Double = 0
    var averageQualityScore: Double = 0
    var totalSleepHours: TimeInterval = 0
    
    // HealthKit権限関連
    var isHealthKitAuthorized: Bool {
        healthKitService.isAuthorized
    }
    
    var authorizationStatusDescription: String {
        healthKitService.authorizationStatusDescription
    }
    
    init() {
        checkInitialPermissions()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadTodaySleepData()
        loadWeeklySleepData()
        calculateStatistics()
    }
    
    // MARK: - HealthKit権限管理
    
    private func checkInitialPermissions() {
        if !healthKitService.isHealthKitAvailable {
            errorMessage = "このデバイスではHealthKitをご利用いただけません"
        } else if !healthKitService.hasRequestedPermission && !isHealthKitAuthorized {
            showingPermissionAlert = true
        }
    }
    
    func requestHealthKitPermission() async {
        isLoading = true
        await healthKitService.requestAuthorization()
        isLoading = false
        
        if isHealthKitAuthorized {
            await refreshAllData()
        }
    }
    
    // MARK: - データ更新
    
    @MainActor
    func refreshAllData() async {
        guard isHealthKitAuthorized else {
            errorMessage = "HealthKitの権限が必要です"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 今日のデータを更新
            await refreshTodaySleepData()
            
            // 週間データを更新
            await refreshWeeklySleepData()
            
            // 統計を再計算
            calculateStatistics()
            
        } catch {
            errorMessage = "データの更新に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    private func refreshTodaySleepData() async {
        guard let healthKitResult = await healthKitService.fetchSleepData(for: Date()) else {
            return
        }
        
        // HealthKitのデータからSwiftDataモデルを作成または更新
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let existingData = findSleepData(for: today) {
            updateSleepData(existingData, with: healthKitResult)
        } else {
            createSleepData(from: healthKitResult)
        }
        
        // UI用のデータを更新
        todaySleepData = findSleepData(for: today)
    }
    
    @MainActor
    private func refreshWeeklySleepData() async {
        let weeklyResults = await healthKitService.fetchWeeklySleepData(for: Date())
        let calendar = Calendar.current
        
        weeklySleepData.removeAll()
        
        for result in weeklyResults {
            let dateKey = calendar.startOfDay(for: result.date)
            
            if let existingData = findSleepData(for: dateKey) {
                updateSleepData(existingData, with: result)
                weeklySleepData.append(existingData)
            } else {
                let newData = createSleepData(from: result)
                weeklySleepData.append(newData)
            }
        }
        
        weeklySleepData.sort { $0.date < $1.date }
    }
    
    // MARK: - SwiftDataデータ管理
    
    private func loadTodaySleepData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        todaySleepData = findSleepData(for: today)
    }
    
    private func loadWeeklySleepData() {
        guard let modelContext = modelContext else { return }
        
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let predicate = #Predicate<SleepData> { sleepData in
            sleepData.date >= weekAgo
        }
        
        let descriptor = FetchDescriptor<SleepData>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            weeklySleepData = try modelContext.fetch(descriptor)
        } catch {
            print("週間睡眠データの読み込みに失敗: \(error)")
            errorMessage = "データの読み込みに失敗しました"
        }
    }
    
    private func findSleepData(for date: Date) -> SleepData? {
        guard let modelContext = modelContext else { return nil }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = #Predicate<SleepData> { sleepData in
            sleepData.date >= startOfDay && sleepData.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<SleepData>(predicate: predicate)
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("睡眠データの検索に失敗: \(error)")
            return nil
        }
    }
    
    @discardableResult
    private func createSleepData(from result: SleepAnalysisResult) -> SleepData {
        let sleepData = SleepData(
            date: result.date,
            bedtime: result.bedtime,
            wakeTime: result.wakeTime,
            totalSleepDuration: result.totalSleepDuration,
            sleepEfficiency: result.sleepEfficiency,
            qualityScore: result.qualityScore
        )
        
        modelContext?.insert(sleepData)
        
        do {
            try modelContext?.save()
        } catch {
            print("睡眠データの保存に失敗: \(error)")
            errorMessage = "データの保存に失敗しました"
        }
        
        return sleepData
    }
    
    private func updateSleepData(_ sleepData: SleepData, with result: SleepAnalysisResult) {
        sleepData.bedtime = result.bedtime
        sleepData.wakeTime = result.wakeTime
        sleepData.totalSleepDuration = result.totalSleepDuration
        sleepData.sleepEfficiency = result.sleepEfficiency
        sleepData.qualityScore = result.qualityScore
        
        do {
            try modelContext?.save()
        } catch {
            print("睡眠データの更新に失敗: \(error)")
            errorMessage = "データの更新に失敗しました"
        }
    }
    
    // MARK: - 統計計算
    
    private func calculateStatistics() {
        guard !weeklySleepData.isEmpty else {
            resetStatistics()
            return
        }
        
        let validData = weeklySleepData.filter { $0.totalSleepDuration > 0 }
        guard !validData.isEmpty else {
            resetStatistics()
            return
        }
        
        // 平均睡眠時間
        averageSleepDuration = validData.reduce(0) { $0 + $1.totalSleepDuration } / Double(validData.count)
        
        // 平均睡眠効率
        averageSleepEfficiency = validData.reduce(0) { $0 + $1.sleepEfficiency } / Double(validData.count)
        
        // 平均品質スコア
        averageQualityScore = validData.reduce(0) { $0 + $1.qualityScore } / Double(validData.count)
        
        // 総睡眠時間
        totalSleepHours = validData.reduce(0) { $0 + $1.totalSleepDuration }
    }
    
    private func resetStatistics() {
        averageSleepDuration = 0
        averageSleepEfficiency = 0
        averageQualityScore = 0
        totalSleepHours = 0
    }
    
    // MARK: - UI Helper Methods
    
    func selectDate(_ date: Date) {
        selectedDate = date
        selectedSleepData = findSleepData(for: date)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return String(format: "%d時間%d分", hours, minutes)
    }
    
    func formatEfficiency(_ efficiency: Double) -> String {
        return String(format: "%.1f%%", efficiency * 100)
    }
    
    func formatScore(_ score: Double) -> String {
        return String(format: "%.1f", score)
    }
    
    // MARK: - データエクスポート
    
    func exportSleepData() -> String {
        let header = "日付,就寝時刻,起床時刻,睡眠時間,睡眠効率,品質スコア\n"
        
        let dataRows = weeklySleepData.map { sleepData in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.string(from: sleepData.date)
            
            return "\(date),\(sleepData.formattedBedtime),\(sleepData.formattedWakeTime),\(sleepData.formattedTotalSleepDuration),\(sleepData.formattedSleepEfficiency),\(sleepData.formattedQualityScore)"
        }.joined(separator: "\n")
        
        return header + dataRows
    }
    
    // MARK: - 睡眠目標管理
    
    var dailySleepGoal: TimeInterval = 8 * 3600 // デフォルト8時間
    
    func updateSleepGoal(_ newGoal: TimeInterval) {
        dailySleepGoal = newGoal
        UserDefaults.standard.set(newGoal, forKey: "dailySleepGoal")
    }
    
    func loadSleepGoal() {
        let savedGoal = UserDefaults.standard.double(forKey: "dailySleepGoal")
        if savedGoal > 0 {
            dailySleepGoal = savedGoal
        }
    }
    
    var todaySleepProgress: Double {
        guard let todayData = todaySleepData, dailySleepGoal > 0 else { return 0 }
        return min(1.0, todayData.totalSleepDuration / dailySleepGoal)
    }
}