//
//  HealthKitService.swift
//  AsaHealthDashboard
//
//  HealthKit統合サービス
//

import Foundation
import HealthKit

@Observable
final class HealthKitService: HealthDataServiceProtocol {
    private let healthStore = HKHealthStore()

    var isHealthKitAvailable = false
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var hasRequestedPermission = false
    var lastError: String?

    // キャッシュ（パフォーマンス最適化）
    private var cachedActualAccessResults: [String: Bool]?
    private var lastActualAccessTest: Date?

    // 読み取り権限が必要なデータタイプ
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
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

    // MARK: - Protocol Properties

    var isAuthorized: Bool {
        guard isHealthKitAvailable else { return false }

        if let actualResults = cachedActualAccessResults,
           let lastTest = lastActualAccessTest,
           Date().timeIntervalSince(lastTest) < 300 {
            return actualResults.values.contains(true)
        }

        return authorizationStatus == .sharingAuthorized
    }

    var authorizationStatusDescription: String {
        if let actualResults = cachedActualAccessResults,
           let lastTest = lastActualAccessTest,
           Date().timeIntervalSince(lastTest) < 300 {
            let accessCount = actualResults.values.filter { $0 }.count
            let totalCount = actualResults.count

            if accessCount > 0 {
                if accessCount == totalCount {
                    return "HealthKitアクセスが許可されています"
                } else {
                    return "HealthKitアクセスが部分的に許可されています（\(accessCount)/\(totalCount)項目）"
                }
            } else {
                return "HealthKitアクセスが拒否されています。設定から許可してください。"
            }
        }

        switch authorizationStatus {
        case .notDetermined:
            return hasRequestedPermission ? "権限の確認中です" : "権限の許可が必要です"
        case .sharingDenied:
            return "HealthKitアクセスが拒否されています。設定から許可してください。"
        case .sharingAuthorized:
            return "HealthKitアクセスが許可されています"
        @unknown default:
            return "不明な権限状態です"
        }
    }

    // MARK: - 権限要求

    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            await MainActor.run {
                self.authorizationStatus = .notDetermined
                self.lastError = "HealthKitが利用できません"
                self.hasRequestedPermission = true
            }
            return
        }

        await MainActor.run {
            self.lastError = nil
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            await updateAuthorizationStatusWithActualTest()
            await MainActor.run {
                self.hasRequestedPermission = true
            }
        } catch {
            await MainActor.run {
                self.authorizationStatus = .notDetermined
                self.lastError = "権限リクエストに失敗しました: \(error.localizedDescription)"
                self.hasRequestedPermission = true
            }
        }
    }

    @MainActor
    private func updateAuthorizationStatus() {
        var authorizedCount = 0

        for dataType in readTypes {
            let status = healthStore.authorizationStatus(for: dataType)
            if status == .sharingAuthorized {
                authorizedCount += 1
            }
        }

        if authorizedCount > 0 {
            authorizationStatus = .sharingAuthorized
        } else {
            authorizationStatus = .notDetermined
        }
    }

    @MainActor
    func updateAuthorizationStatusWithActualTest() async {
        let actualResults = await testActualDataAccess()
        cachedActualAccessResults = actualResults
        lastActualAccessTest = Date()

        let accessCount = actualResults.values.filter { $0 }.count

        if accessCount > 0 {
            authorizationStatus = .sharingAuthorized
        } else {
            authorizationStatus = .sharingDenied
        }
    }

    private func testActualDataAccess() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        let today = Date()

        let steps = await fetchStepCount(for: today)
        results["歩数"] = steps >= 0

        let distance = await fetchDistance(for: today)
        results["距離"] = distance >= 0

        let calories = await fetchCalories(for: today)
        results["カロリー"] = calories >= 0

        let exerciseTime = await fetchExerciseTime(for: today)
        results["運動時間"] = exerciseTime >= 0

        return results
    }

    // MARK: - 歩数取得

    func fetchStepCount(for date: Date) async -> Double {
        guard isHealthKitAvailable else { return 0 }

        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        let (startOfDay, endOfDay) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let stepCount = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: stepCount)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 距離取得

    func fetchDistance(for date: Date) async -> Double {
        guard isHealthKitAvailable else { return 0 }

        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return 0
        }

        let (startOfDay, endOfDay) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                continuation.resume(returning: distance / 1000) // km変換
            }
            healthStore.execute(query)
        }
    }

    // MARK: - カロリー取得

    func fetchCalories(for date: Date) async -> Double {
        guard isHealthKitAvailable else { return 0 }

        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }

        let (startOfDay, endOfDay) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 運動時間取得

    func fetchExerciseTime(for date: Date) async -> Double {
        guard isHealthKitAvailable else { return 0 }

        guard let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            return 0
        }

        let (startOfDay, endOfDay) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseTimeType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let exerciseTime = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                continuation.resume(returning: exerciseTime)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 睡眠データ取得

    func fetchSleepData(for date: Date) async -> (duration: Double, efficiency: Double)? {
        guard isHealthKitAvailable else { return nil }

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        // 前日の夜から当日の朝までを対象
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: date)
        let startOfPreviousEvening = calendar.date(byAdding: .hour, value: -12, to: endOfDay) ?? date

        let predicate = HKQuery.predicateForSamples(withStart: startOfPreviousEvening, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // 睡眠時間の合計を計算
                var totalSleepDuration: TimeInterval = 0
                var inBedDuration: TimeInterval = 0

                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)

                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                        inBedDuration += duration
                    } else if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                              sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                              sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                              sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        totalSleepDuration += duration
                    }
                }

                // 睡眠効率（睡眠時間 / ベッド時間）
                let efficiency = inBedDuration > 0 ? (totalSleepDuration / inBedDuration) * 100 : 0

                // 時間単位に変換
                let sleepHours = totalSleepDuration / 3600

                continuation.resume(returning: (duration: sleepHours, efficiency: efficiency))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - カテゴリ別データ取得

    func fetchData(for category: HealthCategory, date: Date) async -> Double {
        switch category {
        case .steps:
            return await fetchStepCount(for: date)
        case .distance:
            return await fetchDistance(for: date)
        case .calories:
            return await fetchCalories(for: date)
        case .exerciseTime:
            return await fetchExerciseTime(for: date)
        case .sleep:
            if let sleepData = await fetchSleepData(for: date) {
                return sleepData.duration
            }
            return 0
        }
    }

    // MARK: - 期間指定でのメトリクス取得

    func fetchMetrics(for category: HealthCategory, in period: TimePeriod, from date: Date, goals: [HealthGoal]) async -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        let calendar = Calendar.current
        let goal = goals.targetValue(for: category)

        for i in 0..<period.days {
            guard let targetDate = calendar.date(byAdding: .day, value: -i, to: date) else { continue }

            let value = await fetchData(for: category, date: targetDate)

            metrics.append(HealthMetric(
                category: category,
                date: targetDate,
                value: value,
                goal: goal
            ))
        }

        return metrics.sortedByDate
    }

    // MARK: - Helper

    private func dayBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        return (startOfDay, endOfDay)
    }
}
