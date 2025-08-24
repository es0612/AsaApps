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
    var hasValidatedAccess = false // 実際のアクセス可能性を示すフラグ
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
                // 既に権限が設定されている可能性があるので検証
                await validateHealthKitAccess()
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
            
            // 権限リクエスト後、実際にアクセス可能か検証
            await validateHealthKitAccess()
            
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
    
    // MARK: - HealthKitアクセス検証
    private func validateHealthKitAccess() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        // 実際にデータを取得して権限があるかテスト
        let testSteps = await fetchStepCountForValidation(for: Date())
        
        await MainActor.run {
            if testSteps >= 0 { // 0以上なら権限ありとみなす（0歩でも有効）
                self.hasValidatedAccess = true
                self.lastError = nil
                
                // 実際のアクセス成功時は権限ステータスを適切に設定
                if self.authorizationStatus == .notDetermined {
                    // notDeterminedでもアクセス可能な場合は有効とみなす
                    print("HealthKitアクセス検証成功: \(testSteps)歩 (権限状態: notDetermined)")
                } else {
                    print("HealthKitアクセス検証成功: \(testSteps)歩 (権限状態: \(self.authorizationStatus.rawValue))")
                }
                
                Task {
                    await self.fetchTodayStepCount()
                }
            } else {
                self.hasValidatedAccess = false
                self.lastError = "HealthKitからデータを読み取れません。設定で権限を確認してください。"
                print("HealthKitアクセス検証失敗")
            }
            self.isLoading = false
        }
    }
    
    // 検証専用の歩数取得（エラーハンドリングを簡素化）
    private func fetchStepCountForValidation(for date: Date) async -> Int {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return -1
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
                    // 「No data available」エラーは権限ありの証拠として扱う
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("No data available") {
                        print("検証成功: データなしだが権限あり (\(errorMessage))")
                        continuation.resume(returning: 0) // 0歩として成功扱い
                        return
                    }
                    print("アクセス検証エラー: \(errorMessage)")
                    continuation.resume(returning: -1)
                    return
                }
                
                // result が nil でなければ、データがなくても権限は有効
                let stepCount = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                let steps = Int(stepCount)
                print("検証成功: \(steps)歩のデータを取得")
                
                // 結果が nil でない場合は権限があることの証拠
                if result != nil {
                    continuation.resume(returning: steps >= 0 ? steps : 0)
                } else {
                    print("検証失敗: HKStatistics result が nil")
                    continuation.resume(returning: -1)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 権限状態のテキスト
    var authorizationStatusDescription: String {
        if isLoading {
            return "権限確認中..."
        }
        
        if authorizationStatus == .sharingDenied {
            return "HealthKitアクセスが拒否されています。設定から許可してください。"
        }
        
        if hasValidatedAccess {
            return "HealthKitアクセスが許可されています"
        }
        
        if hasRequestedPermission {
            return "データアクセスを確認中です。権限が拒否されている可能性があります。"
        }
        
        return "HealthKitへのアクセス権限が必要です"
    }
    
    var isAuthorized: Bool {
        guard isHealthKitAvailable else {
            print("isAuthorized: false (HealthKit利用不可)")
            return false
        }
        
        // 実際のアクセス検証が成功している場合は権限ありとみなす
        // HealthKitでは読み取り権限のauthorizationStatusが正確でない場合がある
        if hasValidatedAccess {
            print("isAuthorized: true (アクセス検証済み, authStatus: \(authorizationStatus.rawValue))")
            return true
        }
        
        // 検証前の場合：権限リクエストしていない、または明示的に拒否されていない場合のみtrue
        if !hasRequestedPermission {
            // 初回起動時は権限カードを表示するためにfalseを返す
            print("isAuthorized: false (初回起動時, 権限リクエスト未実施)")
            return false
        }
        
        // 権限リクエスト後で検証前の場合
        let result = authorizationStatus != .sharingDenied
        print("isAuthorized: \(result) (権限リクエスト後検証前, authStatus: \(authorizationStatus.rawValue))")
        return result
    }
    
    // MARK: - 歩数データ取得
    func fetchStepCount(for date: Date) async -> Int {
        guard isHealthKitAvailable, 
              let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("HealthKitまたは歩数データタイプが利用できません")
            return 0
        }
        
        // 権限検証が完了していない場合はスキップ（初期化中など）
        if !hasValidatedAccess && hasRequestedPermission && authorizationStatus == .sharingDenied {
            print("HealthKit権限が明示的に拒否されています")
            return 0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        print("歩数データクエリ実行: \(DateFormatter.shortDate.string(from: date)) (\(startOfDay) - \(endOfDay))")
        
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
                print("歩数データ取得完了: \(steps)歩 (日付: \(DateFormatter.shortDate.string(from: date)))")
                
                // 結果の詳細ログ
                if let result = result {
                    print("HKStatistics詳細: sources=\(result.sources?.count ?? 0), startDate=\(result.startDate), endDate=\(result.endDate)")
                    if let sources = result.sources {
                        for source in sources {
                            print("  データソース: \(source.name) (\(source.bundleIdentifier))")
                        }
                    }
                }
                
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