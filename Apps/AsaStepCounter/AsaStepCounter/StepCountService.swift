//
//  StepCountService.swift
//  AsaStepCounter
//
//  Created on 2025/08/15
//

import Foundation
import HealthKit

@Observable
final class StepCountService {
    private let healthStore = HKHealthStore()
    
    // 状態管理
    var isHealthKitAvailable = false
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var hasRequestedPermission = false
    var lastError: String?
    var isLoading = false
    
    // 歩数データ
    var currentStepCount: Int = 0
    var todayStepCount: Int = 0
    
    init() {
        checkHealthKitAvailability()
        if isHealthKitAvailable {
            Task { @MainActor in
                updateAuthorizationStatus()
            }
        }
    }
    
    // MARK: - HealthKit可用性チェック
    private func checkHealthKitAvailability() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        print("HealthKit利用可能: \(isHealthKitAvailable)")
    }
    
    // MARK: - 権限管理
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            await MainActor.run {
                self.lastError = "HealthKitが利用できません: デバイスがサポートしていません"
                self.authorizationStatus = .sharingDenied
                self.hasRequestedPermission = true
            }
            return
        }
        
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            await MainActor.run {
                self.lastError = "歩数データタイプの取得に失敗しました"
                self.authorizationStatus = .sharingDenied
                self.hasRequestedPermission = true
            }
            return
        }
        
        await MainActor.run {
            self.lastError = nil
            self.isLoading = true
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepCountType])
            await MainActor.run {
                self.updateAuthorizationStatus()
                self.hasRequestedPermission = true
                self.isLoading = false
            }
            print("HealthKit権限リクエストが完了しました")
            
            // 権限取得後、今日の歩数を取得
            if isAuthorized {
                await fetchTodayStepCount()
            }
            
        } catch {
            await MainActor.run {
                self.lastError = "権限リクエストに失敗しました: \(error.localizedDescription)"
                self.authorizationStatus = .sharingDenied
                self.hasRequestedPermission = true
                self.isLoading = false
            }
            print("HealthKit権限リクエストエラー: \(error)")
        }
    }
    
    @MainActor
    private func updateAuthorizationStatus() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            authorizationStatus = .sharingDenied
            return
        }
        
        authorizationStatus = healthStore.authorizationStatus(for: stepCountType)
        print("歩数データ権限状態: \(authorizationStatusDescription)")
    }
    
    // MARK: - 権限状態のテキスト
    var authorizationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return hasRequestedPermission ? "権限確認中..." : "権限が必要です"
        case .sharingDenied:
            return "HealthKitアクセスが拒否されています。設定から許可してください。"
        case .sharingAuthorized:
            return "HealthKitアクセスが許可されています"
        @unknown default:
            return "不明な権限状態です"
        }
    }
    
    var isAuthorized: Bool {
        guard isHealthKitAvailable else { return false }
        return authorizationStatus == .sharingAuthorized
    }
    
    // MARK: - 歩数データ取得
    func fetchStepCount(for date: Date) async -> Int {
        guard isHealthKitAvailable, 
              let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("HealthKitまたは歩数データタイプが利用できません")
            return 0
        }
        
        // 権限が明示的に拒否されている場合のみ処理を中断
        if authorizationStatus == .sharingDenied {
            print("HealthKit権限が拒否されています")
            return 0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("歩数取得エラー: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let stepCount = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                let steps = Int(stepCount)
                print("歩数データ取得成功: \(steps)歩 (日付: \(DateFormatter.shortDate.string(from: date)))")
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 今日の歩数取得
    @MainActor
    func fetchTodayStepCount() async {
        isLoading = true
        let steps = await fetchStepCount(for: Date())
        todayStepCount = steps
        currentStepCount = steps
        isLoading = false
    }
    
    // MARK: - 週間歩数データ取得
    func fetchWeeklyStepCounts() async -> [(Date, Int)] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [(Date, Int)] = []
        
        await MainActor.run {
            self.isLoading = true
        }
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let steps = await fetchStepCount(for: date)
                weeklyData.append((date, steps))
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
        
        // 古い日付から新しい日付の順にソート
        return weeklyData.reversed()
    }
    
    // MARK: - データ更新
    @MainActor
    func refreshData() async {
        lastError = nil
        await fetchTodayStepCount()
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}