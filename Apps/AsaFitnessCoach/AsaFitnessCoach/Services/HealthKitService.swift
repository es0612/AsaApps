//
//  HealthKitService.swift
//  AsaFitnessCoach
//
//  HealthKit連携サービス
//

import Foundation
import HealthKit

@Observable
@MainActor
final class HealthKitService {
    // MARK: - Properties

    private let healthStore = HKHealthStore()
    var isHealthKitAvailable = false
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var hasRequestedPermission = false
    var lastError: String?

    // キャッシュ
    private var cachedActualAccessResults: [String: Bool]?
    private var lastActualAccessTest: Date?
    private let cacheValidityDuration: TimeInterval = 300  // 5分

    // 読み取り権限が必要なデータタイプ
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.workoutType()
    ]

    // 書き込み権限が必要なデータタイプ
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.workoutType()
    ]

    // MARK: - Initialization

    init() {
        checkHealthKitAvailability()
    }

    // MARK: - HealthKit可用性チェック

    private func checkHealthKitAvailability() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - 権限要求

    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            lastError = "HealthKitが利用できません"
            hasRequestedPermission = true
            return
        }

        lastError = nil

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await updateAuthorizationStatusWithActualTest()
            hasRequestedPermission = true
        } catch {
            lastError = "HealthKit権限リクエストに失敗しました: \(error.localizedDescription)"
            authorizationStatus = .notDetermined
            hasRequestedPermission = true
        }
    }

    // MARK: - 権限状態更新

    private func updateAuthorizationStatus(actualAccessResults: [String: Bool]? = nil) {
        if let actualResults = actualAccessResults {
            let actualAccessCount = actualResults.values.filter { $0 }.count
            authorizationStatus = actualAccessCount > 0 ? .sharingAuthorized : .sharingDenied
        } else {
            // 従来のロジック
            var authorizedCount = 0
            for dataType in readTypes {
                let status = healthStore.authorizationStatus(for: dataType)
                if status == .sharingAuthorized {
                    authorizedCount += 1
                }
            }
            authorizationStatus = authorizedCount > 0 ? .sharingAuthorized : .notDetermined
        }
    }

    func updateAuthorizationStatusWithActualTest() async {
        let actualResults = await testActualDataAccess()
        cachedActualAccessResults = actualResults
        lastActualAccessTest = Date()
        updateAuthorizationStatus(actualAccessResults: actualResults)
    }

    // MARK: - データアクセステスト

    func testActualDataAccess() async -> [String: Bool] {
        var accessResults: [String: Bool] = [:]
        let today = Date()

        // 各データタイプのアクセステスト
        accessResults["歩数"] = await fetchStepCount(for: today) >= 0
        accessResults["距離"] = await fetchDistance(for: today) >= 0
        accessResults["カロリー"] = await fetchCalories(for: today) >= 0
        accessResults["運動時間"] = await fetchActiveTime(for: today) >= 0
        accessResults["心拍数"] = await fetchAverageHeartRate(for: today) != nil

        return accessResults
    }

    // MARK: - 権限確認

    var isAuthorized: Bool {
        guard isHealthKitAvailable else { return false }

        // キャッシュ確認
        if let actualResults = cachedActualAccessResults,
           let lastTest = lastActualAccessTest,
           Date().timeIntervalSince(lastTest) < cacheValidityDuration {
            return actualResults.values.contains(true)
        }

        return authorizationStatus == .sharingAuthorized
    }

    var authorizationStatusDescription: String {
        if !isHealthKitAvailable {
            return "HealthKitが利用できません"
        }

        switch authorizationStatus {
        case .notDetermined:
            return hasRequestedPermission ? "権限の確認中です" : "権限の許可が必要です"
        case .sharingDenied:
            return "HealthKitアクセスが拒否されています"
        case .sharingAuthorized:
            return "HealthKitアクセスが許可されています"
        @unknown default:
            return "不明な権限状態です"
        }
    }

    // MARK: - データ取得

    /// 歩数取得
    func fetchStepCount(for date: Date) async -> Double {
        guard isHealthKitAvailable else { return 0 }

        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        return await fetchCumulativeSum(for: stepCountType, date: date, unit: HKUnit.count())
    }

    /// 距離取得（km）
    func fetchDistance(for date: Date) async -> Double {
        guard isHealthKitAvailable else { return 0 }

        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return 0
        }

        let meters = await fetchCumulativeSum(for: distanceType, date: date, unit: HKUnit.meter())
        return meters / 1000  // km変換
    }

    /// 消費カロリー取得（kcal）
    func fetchCalories(for date: Date) async -> Double {
        guard isHealthKitAvailable else { return 0 }

        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }

        return await fetchCumulativeSum(for: caloriesType, date: date, unit: HKUnit.kilocalorie())
    }

    /// 運動時間取得（分）
    func fetchActiveTime(for date: Date) async -> Double {
        guard isHealthKitAvailable else { return 0 }

        guard let activeTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            return 0
        }

        return await fetchCumulativeSum(for: activeTimeType, date: date, unit: HKUnit.minute())
    }

    /// 平均心拍数取得
    func fetchAverageHeartRate(for date: Date) async -> Double? {
        guard isHealthKitAvailable else { return nil }

        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
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
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }
                let heartRate = result?.averageQuantity()?.doubleValue(
                    for: HKUnit.count().unitDivided(by: HKUnit.minute())
                )
                continuation.resume(returning: heartRate)
            }
            healthStore.execute(query)
        }
    }

    /// ワークアウト回数取得
    func fetchWorkoutCount(for date: Date) async -> Int {
        guard isHealthKitAvailable else { return 0 }

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
            ) { _, samples, _ in
                continuation.resume(returning: samples?.count ?? 0)
            }
            healthStore.execute(query)
        }
    }

    /// 期間内のワークアウト取得
    func fetchWorkouts(from startDate: Date, to endDate: Date) async -> [HKWorkout] {
        guard isHealthKitAvailable else { return [] }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - ワークアウト保存

    func saveWorkout(
        type: HKWorkoutActivityType,
        start: Date,
        end: Date,
        calories: Double?,
        distance: Double?
    ) async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }

        var samples: [HKSample] = []

        // カロリーサンプル
        if let calories = calories,
           let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
            let caloriesSample = HKQuantitySample(
                type: caloriesType,
                quantity: caloriesQuantity,
                start: start,
                end: end
            )
            samples.append(caloriesSample)
        }

        // 距離サンプル
        if let distance = distance,
           let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distance * 1000)
            let distanceSample = HKQuantitySample(
                type: distanceType,
                quantity: distanceQuantity,
                start: start,
                end: end
            )
            samples.append(distanceSample)
        }

        let workout = HKWorkout(
            activityType: type,
            start: start,
            end: end,
            workoutEvents: nil,
            totalEnergyBurned: calories.map { HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: $0) },
            totalDistance: distance.map { HKQuantity(unit: HKUnit.meter(), doubleValue: $0 * 1000) },
            metadata: nil
        )

        try await healthStore.save(workout)

        if !samples.isEmpty {
            try await healthStore.addSamples(samples, to: workout)
        }
    }

    // MARK: - Private Methods

    private func fetchCumulativeSum(
        for quantityType: HKQuantityType,
        date: Date,
        unit: HKUnit
    ) async -> Double {
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
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if error != nil {
                    continuation.resume(returning: 0)
                    return
                }
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - HealthKitError

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKitが利用できません"
        case .authorizationDenied:
            return "HealthKitへのアクセスが拒否されています"
        case .saveFailed:
            return "HealthKitへの保存に失敗しました"
        }
    }
}
