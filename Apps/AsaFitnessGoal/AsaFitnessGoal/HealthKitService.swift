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
        // 全てのデータタイプの権限状態をチェック
        let authorizationStatuses = getDetailedAuthorizationStatus()
        
        // 全データタイプを考慮した総合的な権限判定
        let authorizedCount = authorizationStatuses.values.filter { $0 == .sharingAuthorized }.count
        let deniedCount = authorizationStatuses.values.filter { $0 == .sharingDenied }.count
        let totalCount = authorizationStatuses.count
        
        // 権限状態の総合判定
        if authorizedCount > 0 {
            // 少なくとも一つのデータタイプが許可されている場合
            authorizationStatus = .sharingAuthorized
        } else if deniedCount == totalCount {
            // 全てのデータタイプが明示的に拒否されている場合
            authorizationStatus = .sharingDenied
        } else {
            // 未確定の状態
            authorizationStatus = .notDetermined
        }
        
        print("HealthKit権限状態: \(authorizationStatusDescription)")
        print("詳細権限状態: \(authorizationStatuses)")
        print("総合判定: 許可=\(authorizedCount)/\(totalCount), 拒否=\(deniedCount)/\(totalCount)")
    }
    
    // 権限状態の説明テキストを取得
    var authorizationStatusDescription: String {
        let authorizationStatuses = getDetailedAuthorizationStatus()
        let authorizedCount = authorizationStatuses.values.filter { $0 == .sharingAuthorized }.count
        let deniedCount = authorizationStatuses.values.filter { $0 == .sharingDenied }.count
        let totalCount = authorizationStatuses.count
        
        switch authorizationStatus {
        case .notDetermined:
            if hasRequestedPermission {
                return "権限の確認中です。データアクセスを試行します。"
            } else {
                return "権限の許可が必要です"
            }
        case .sharingDenied:
            return "HealthKitアクセスが拒否されています。設定から許可してください。"
        case .sharingAuthorized:
            if authorizedCount == totalCount {
                return "HealthKitアクセスが許可されています"
            } else {
                return "HealthKitアクセスが部分的に許可されています（\(authorizedCount)/\(totalCount)項目）"
            }
        @unknown default:
            return "不明な権限状態です"
        }
    }
    
    // HealthKitが利用可能でデータアクセスが可能かチェック
    var isAuthorized: Bool {
        guard isHealthKitAvailable else { return false }
        
        // authorizationStatusと整合性を保つため、同じ判定ロジックを使用
        return authorizationStatus == .sharingAuthorized
    }
    
    // MARK: - 歩数取得
    func fetchStepCount(for date: Date) async -> Double {
        guard isHealthKitAvailable else {
            print("HealthKitが利用できません")
            return 0
        }
        
        // 権限が明示的に拒否されている場合のみ処理を中断
        if authorizationStatus == .sharingDenied {
            print("HealthKit権限が拒否されています")
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
                    print("歩数取得エラー: \(error.localizedDescription)")
                    // 権限エラーの場合は詳細を記録
                    if (error as NSError).code == HKError.errorAuthorizationDenied.rawValue {
                        print("HealthKit権限が拒否されました")
                    }
                    continuation.resume(returning: 0)
                    return
                }
                
                let stepCount = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                print("歩数データ取得成功: \(stepCount)歩")
                continuation.resume(returning: stepCount)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 距離取得
    func fetchDistance(for date: Date) async -> Double {
        guard isHealthKitAvailable else {
            print("HealthKitが利用できません")
            return 0
        }
        
        if authorizationStatus == .sharingDenied {
            print("HealthKit権限が拒否されています")
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
                    print("距離取得エラー: \(error.localizedDescription)")
                    if (error as NSError).code == HKError.errorAuthorizationDenied.rawValue {
                        print("HealthKit権限が拒否されました")
                    }
                    continuation.resume(returning: 0)
                    return
                }
                
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                let distanceKm = distance / 1000
                print("距離データ取得成功: \(distanceKm)km")
                continuation.resume(returning: distanceKm)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 運動時間取得
    func fetchActiveTime(for date: Date) async -> Double {
        guard isHealthKitAvailable else {
            print("HealthKitが利用できません")
            return 0
        }
        
        if authorizationStatus == .sharingDenied {
            print("HealthKit権限が拒否されています")
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
                    print("運動時間取得エラー: \(error.localizedDescription)")
                    if (error as NSError).code == HKError.errorAuthorizationDenied.rawValue {
                        print("HealthKit権限が拒否されました")
                    }
                    continuation.resume(returning: 0)
                    return
                }
                
                let activeTime = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                print("運動時間データ取得成功: \(activeTime)分")
                continuation.resume(returning: activeTime)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 消費カロリー取得
    func fetchCalories(for date: Date) async -> Double {
        guard isHealthKitAvailable else {
            print("HealthKitが利用できません")
            return 0
        }
        
        if authorizationStatus == .sharingDenied {
            print("HealthKit権限が拒否されています")
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
                    print("カロリー取得エラー: \(error.localizedDescription)")
                    if (error as NSError).code == HKError.errorAuthorizationDenied.rawValue {
                        print("HealthKit権限が拒否されました")
                    }
                    continuation.resume(returning: 0)
                    return
                }
                
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                print("カロリーデータ取得成功: \(calories)kcal")
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - ワークアウト回数取得
    func fetchWorkoutCount(for date: Date) async -> Double {
        guard isHealthKitAvailable else {
            print("HealthKitが利用できません")
            return 0
        }
        
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
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    print("ワークアウト回数取得エラー: \(error.localizedDescription)")
                    if (error as NSError).code == HKError.errorAuthorizationDenied.rawValue {
                        print("HealthKit権限が拒否されました")
                    }
                    continuation.resume(returning: 0)
                    return
                }
                
                let workoutCount = Double(samples?.count ?? 0)
                print("ワークアウト回数データ取得成功: \(workoutCount)回")
                continuation.resume(returning: workoutCount)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 詳細権限状態取得
    func getDetailedAuthorizationStatus() -> [String: HKAuthorizationStatus] {
        var statuses: [String: HKAuthorizationStatus] = [:]
        
        for dataType in readTypes {
            let status = healthStore.authorizationStatus(for: dataType)
            
            if let quantityType = dataType as? HKQuantityType {
                switch quantityType.identifier {
                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    statuses["歩数"] = status
                case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                    statuses["距離"] = status
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    statuses["カロリー"] = status
                case HKQuantityTypeIdentifier.appleExerciseTime.rawValue:
                    statuses["運動時間"] = status
                default:
                    statuses[quantityType.identifier] = status
                }
            } else if dataType == HKObjectType.workoutType() {
                statuses["ワークアウト"] = status
            }
        }
        
        return statuses
    }
    
    // MARK: - 権限状態強制更新
    @MainActor
    func forceUpdateAuthorizationStatus() {
        print("権限状態を強制更新します...")
        updateAuthorizationStatus()
    }
    
    // MARK: - 実際のデータアクセステスト
    func testActualDataAccess() async -> [String: Bool] {
        print("実際のデータアクセステストを開始します...")
        
        var accessResults: [String: Bool] = [:]
        let today = Date()
        
        // 歩数データのテスト
        let stepCount = await fetchStepCount(for: today)
        accessResults["歩数"] = stepCount >= 0
        print("歩数アクセステスト: \(stepCount >= 0 ? "成功" : "失敗") (値: \(stepCount))")
        
        // 距離データのテスト
        let distance = await fetchDistance(for: today)
        accessResults["距離"] = distance >= 0
        print("距離アクセステスト: \(distance >= 0 ? "成功" : "失敗") (値: \(distance))")
        
        // 運動時間データのテスト
        let activeTime = await fetchActiveTime(for: today)
        accessResults["運動時間"] = activeTime >= 0
        print("運動時間アクセステスト: \(activeTime >= 0 ? "成功" : "失敗") (値: \(activeTime))")
        
        // カロリーデータのテスト
        let calories = await fetchCalories(for: today)
        accessResults["カロリー"] = calories >= 0
        print("カロリーアクセステスト: \(calories >= 0 ? "成功" : "失敗") (値: \(calories))")
        
        // ワークアウトデータのテスト
        let workouts = await fetchWorkoutCount(for: today)
        accessResults["ワークアウト"] = workouts >= 0
        print("ワークアウトアクセステスト: \(workouts >= 0 ? "成功" : "失敗") (値: \(workouts))")
        
        return accessResults
    }
    
    // 実際のアクセスに基づく権限判定
    func hasActualDataAccess() async -> Bool {
        let accessResults = await testActualDataAccess()
        let hasAccess = accessResults.values.contains(true)
        print("実際のデータアクセス判定: \(hasAccess ? "利用可能" : "利用不可")")
        return hasAccess
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