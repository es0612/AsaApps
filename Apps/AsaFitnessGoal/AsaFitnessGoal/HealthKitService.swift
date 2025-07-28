//
//  HealthKitService.swift
//  AsaFitnessGoal
//
//  Created on 2025/07/19
//

import Foundation
import HealthKit

@Observable
final class HealthKitService {
    private let healthStore = HKHealthStore()
    var isHealthKitAvailable = false
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var hasRequestedPermission = false
    var lastError: String?
    
    // 読み取り権限が必要なデータタイプ
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKObjectType.workoutType()
    ]
    
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
    }
    
    // MARK: - 権限要求
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            let errorMessage = "HealthKitが利用できません: デバイスがサポートしていません"
            print(errorMessage)
            await MainActor.run {
                self.authorizationStatus = .notDetermined
                self.lastError = errorMessage
                self.hasRequestedPermission = true
            }
            return
        }
        
        await MainActor.run {
            self.lastError = nil
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            await updateAuthorizationStatus()
            await MainActor.run {
                self.hasRequestedPermission = true
            }
            print("HealthKit権限リクエストが完了しました")
        } catch {
            let errorMessage = "HealthKit権限リクエストに失敗しました: \(error.localizedDescription)"
            print(errorMessage)
            await MainActor.run {
                self.authorizationStatus = .notDetermined
                self.lastError = errorMessage
                self.hasRequestedPermission = true
            }
        }
    }
    
    @MainActor
    private func updateAuthorizationStatus() {
        // 代表的なデータタイプの権限状態をチェック
        if let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            authorizationStatus = healthStore.authorizationStatus(for: stepCountType)
        }
    }
    
    // 権限状態の説明テキストを取得
    var authorizationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return hasRequestedPermission ? "権限が未確定です" : "権限の許可が必要です"
        case .sharingDenied:
            return "HealthKitアクセスが拒否されています。設定から許可してください。"
        case .sharingAuthorized:
            return "HealthKitアクセスが許可されています"
        @unknown default:
            return "不明な権限状態です"
        }
    }
    
    // HealthKitが利用可能で権限が許可されているかチェック
    var isAuthorized: Bool {
        return isHealthKitAvailable && authorizationStatus == .sharingAuthorized
    }
    
    // MARK: - 歩数取得
    func fetchStepCount(for date: Date) async -> Double {
        guard isAuthorized else {
            return 0
        }
        
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
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
                    print("Failed to fetch step count: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let stepCount = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: stepCount)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 距離取得
    func fetchDistance(for date: Date) async -> Double {
        guard isAuthorized else {
            return 0
        }
        
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
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
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("Failed to fetch distance: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                continuation.resume(returning: distance / 1000) // kmに変換
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 運動時間取得
    func fetchActiveTime(for date: Date) async -> Double {
        guard isAuthorized else {
            return 0
        }
        
        guard let activeTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
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
                quantityType: activeTimeType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("Failed to fetch active time: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let activeTime = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                continuation.resume(returning: activeTime)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 消費カロリー取得
    func fetchCalories(for date: Date) async -> Double {
        guard isAuthorized else {
            return 0
        }
        
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
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
                quantityType: caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("Failed to fetch calories: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - ワークアウト回数取得
    func fetchWorkoutCount(for date: Date) async -> Double {
        guard isAuthorized else {
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
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    print("Failed to fetch workout count: \(error)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let workoutCount = Double(samples?.count ?? 0)
                continuation.resume(returning: workoutCount)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - カテゴリ別データ取得
    func fetchData(for category: GoalCategory, date: Date) async -> Double {
        switch category {
        case .steps:
            return await fetchStepCount(for: date)
        case .distance:
            return await fetchDistance(for: date)
        case .activeTime:
            return await fetchActiveTime(for: date)
        case .calories:
            return await fetchCalories(for: date)
        case .workouts:
            return await fetchWorkoutCount(for: date)
        }
    }
}