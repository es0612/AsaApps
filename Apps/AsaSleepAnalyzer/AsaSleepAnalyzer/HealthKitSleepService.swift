//
//  HealthKitSleepService.swift
//  AsaSleepAnalyzer
//
//  Created on 2025/08/05
//

import Foundation
import HealthKit

@Observable
final class HealthKitSleepService {
    private let healthStore = HKHealthStore()
    var isHealthKitAvailable = false
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var hasRequestedPermission = false
    var lastError: String?
    var debugInfo: [String] = []
    private var lastPermissionUpdateTime: Date?
    private var actualAccessTestResult: Bool = false
    
    // 睡眠データ取得に必要なデータタイプ
    private let sleepTypes: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]
    
    init() {
        checkHealthKitAvailability()
        if isHealthKitAvailable {
            Task { @MainActor in
                await comprehensivePermissionCheck()
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
            try await healthStore.requestAuthorization(toShare: [], read: sleepTypes)
            
            await MainActor.run {
                self.updateAuthorizationStatus()
                self.hasRequestedPermission = true
            }
            print("HealthKit睡眠データ権限リクエストが完了しました")
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
        guard let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            authorizationStatus = .notDetermined
            addDebugInfo("エラー: sleepAnalysisTypeの取得に失敗")
            return
        }
        
        let previousStatus = authorizationStatus
        authorizationStatus = healthStore.authorizationStatus(for: sleepAnalysisType)
        lastPermissionUpdateTime = Date()
        
        let statusDescription = getStatusDescription(authorizationStatus)
        print("HealthKit睡眠データ権限状態: \(statusDescription)")
        addDebugInfo("権限状態更新: \(statusDescription) (前回: \(getStatusDescription(previousStatus)))")
        
        if previousStatus != authorizationStatus {
            addDebugInfo("権限状態が変更されました: \(getStatusDescription(previousStatus)) → \(statusDescription)")
        }
    }
    
    // 権限状態の説明テキストを取得
    var authorizationStatusDescription: String {
        // 実際のアクセステスト結果を考慮
        if actualAccessTestResult {
            return "睡眠データアクセスが利用可能です（実測値優先）"
        }
        
        switch authorizationStatus {
        case .notDetermined:
            if hasRequestedPermission {
                return "権限の確認中です"
            } else {
                return "睡眠データへのアクセス権限が必要です"
            }
        case .sharingDenied:
            return "API状態は拒否ですが、実際のアクセスをテスト中です。設定を確認してください。"
        case .sharingAuthorized:
            return "睡眠データアクセスが許可されています"
        @unknown default:
            return "不明な権限状態です"
        }
    }
    
    // HealthKitが利用可能で睡眠データアクセスが可能かチェック
    var isAuthorized: Bool {
        guard isHealthKitAvailable else { return false }
        
        // 実際のアクセステスト結果を優先（ログ出力なし）
        if actualAccessTestResult {
            return true
        }
        
        // API状態での判定
        return authorizationStatus == .sharingAuthorized
    }
    
    // MARK: - 睡眠データ取得
    func fetchSleepData(for date: Date) async -> SleepAnalysisResult? {
        guard isHealthKitAvailable else {
            print("HealthKitが利用できません")
            return nil
        }
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("睡眠分析タイプを取得できません")
            return nil
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        // 前日の夜から当日の夜まで検索（睡眠は日をまたぐため）
        let searchStart = calendar.date(byAdding: .hour, value: -8, to: startOfDay) ?? startOfDay
        let searchEnd = calendar.date(byAdding: .hour, value: 8, to: endOfDay) ?? endOfDay
        
        let predicate = HKQuery.predicateForSamples(
            withStart: searchStart,
            end: searchEnd,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    print("睡眠データ取得エラー: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    print("睡眠データの変換に失敗しました")
                    continuation.resume(returning: nil)
                    return
                }
                
                let result = self.analyzeSleepSamples(sleepSamples, for: date)
                print("睡眠データ取得成功: \(result?.formattedTotalSleep ?? "データなし")")
                continuation.resume(returning: result)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 週間睡眠データ取得
    func fetchWeeklySleepData(for date: Date) async -> [SleepAnalysisResult] {
        let calendar = Calendar.current
        var results: [SleepAnalysisResult] = []
        
        // 指定された日付から7日前まで取得
        for i in 0..<7 {
            if let targetDate = calendar.date(byAdding: .day, value: -i, to: date) {
                if let sleepData = await fetchSleepData(for: targetDate) {
                    results.append(sleepData)
                } else {
                    // データがない場合は空のデータを作成
                    let emptySleep = SleepAnalysisResult(
                        date: targetDate,
                        bedtime: nil,
                        wakeTime: nil,
                        totalSleepDuration: 0,
                        inBedDuration: 0,
                        sleepEfficiency: 0,
                        sleepStages: []
                    )
                    results.append(emptySleep)
                }
            }
        }
        
        return results.sorted { $0.date < $1.date }
    }
    
    // MARK: - 睡眠サンプル解析
    private func analyzeSleepSamples(_ samples: [HKCategorySample], for date: Date) -> SleepAnalysisResult? {
        guard !samples.isEmpty else { return nil }
        
        let calendar = Calendar.current
        
        // 睡眠ステージ別の分析
        var sleepStages: [SleepStage] = []
        var totalSleepDuration: TimeInterval = 0
        var totalInBedDuration: TimeInterval = 0
        var bedtime: Date?
        var wakeTime: Date?
        
        for sample in samples {
            let stage = SleepStage(
                startTime: sample.startDate,
                endTime: sample.endDate,
                value: sample.value,
                duration: sample.endDate.timeIntervalSince(sample.startDate)
            )
            sleepStages.append(stage)
            
            // HKCategoryValueSleepAnalysis の値に基づいて分類
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                totalInBedDuration += stage.duration
                if bedtime == nil || sample.startDate < bedtime! {
                    bedtime = sample.startDate
                }
                if wakeTime == nil || sample.endDate > wakeTime! {
                    wakeTime = sample.endDate
                }
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                 HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                 HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                totalSleepDuration += stage.duration
                if bedtime == nil || sample.startDate < bedtime! {
                    bedtime = sample.startDate
                }
                if wakeTime == nil || sample.endDate > wakeTime! {
                    wakeTime = sample.endDate
                }
            default:
                break
            }
        }
        
        // 睡眠効率の計算
        let sleepEfficiency = totalInBedDuration > 0 ? totalSleepDuration / totalInBedDuration : 0
        
        return SleepAnalysisResult(
            date: date,
            bedtime: bedtime,
            wakeTime: wakeTime,
            totalSleepDuration: totalSleepDuration,
            inBedDuration: totalInBedDuration,
            sleepEfficiency: sleepEfficiency,
            sleepStages: sleepStages
        )
    }
    
    // 権限状態の説明を取得するヘルパーメソッド
    private func getStatusDescription(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "未確定(.notDetermined)"
        case .sharingDenied:
            return "拒否(.sharingDenied)"
        case .sharingAuthorized:
            return "許可(.sharingAuthorized)"
        @unknown default:
            return "不明(@unknown default, rawValue: \(status.rawValue))"
        }
    }
    
    // MARK: - 権限状態強制更新
    @MainActor
    func forceUpdateAuthorizationStatus() {
        print("睡眠データ権限状態を強制更新します...")
        addDebugInfo("権限状態強制更新を実行")
        updateAuthorizationStatus()
    }
    
    // MARK: - 包括的な権限チェック
    @MainActor
    func comprehensivePermissionCheck() async {
        addDebugInfo("包括的権限チェック開始")
        
        updateAuthorizationStatus()
        
        if authorizationStatus == .sharingDenied {
            addDebugInfo("API権限状態: 拒否 - 実データアクセステストを実行")
            await testActualDataAccess()
        }
        
        addDebugInfo("包括的権限チェック完了 - API状態: \(getStatusDescription(authorizationStatus)), 実アクセス: \(actualAccessTestResult)")
    }
    
    // MARK: - 実データアクセステスト
    private func testActualDataAccess() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            addDebugInfo("エラー: 睡眠データタイプの取得に失敗")
            actualAccessTestResult = false
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        
        let predicate = HKQuery.predicateForSamples(
            withStart: yesterday,
            end: now,
            options: .strictStartDate
        )
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.addDebugInfo("実データアクセステストエラー: \(error.localizedDescription)")
                        // 権限関連のエラーかチェック
                        let errorDescription = error.localizedDescription.lowercased()
                        if errorDescription.contains("権限") || errorDescription.contains("permission") || errorDescription.contains("authorization") {
                            self.actualAccessTestResult = false
                            self.addDebugInfo("❌ 権限エラー検出: アクセス不可")
                        } else {
                            // 権限以外のエラー（データなしなど）の場合は権限ありとみなす
                            self.actualAccessTestResult = true
                            self.addDebugInfo("⚠️ 権限外エラー: アクセス権限は有効")
                        }
                    } else {
                        self.actualAccessTestResult = true
                        let dataCount = samples?.count ?? 0
                        self.addDebugInfo("✅ 実データアクセステスト成功: \(dataCount)件のデータを取得")
                        
                        if dataCount == 0 {
                            self.addDebugInfo("💡 ヒント: 睡眠データが記録されていません。iPhoneまたはApple Watchで睡眠追跡を有効にしてください")
                        }
                        
                        if self.authorizationStatus == .sharingDenied && self.actualAccessTestResult {
                            self.addDebugInfo("⚠️ 権限不整合検出: API状態は拒否だが実アクセスは成功")
                            self.addDebugInfo("🔄 実際のアクセス結果を優先して権限ありとして動作します")
                        }
                    }
                    continuation.resume()
                }
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - アプリライフサイクル対応
    @MainActor
    func handleAppDidBecomeActive() async {
        addDebugInfo("アプリがアクティブになりました - 権限状態を再確認")
        await comprehensivePermissionCheck()
    }
    
    // MARK: - デバッグ情報管理
    private func addDebugInfo(_ message: String) {
        // 同じメッセージの連続追加を防ぐ
        if let lastMessage = debugInfo.last, lastMessage.contains(message) {
            return
        }
        
        let timestamp = DateFormatter.debugFormatter.string(from: Date())
        let debugMessage = "[\(timestamp)] \(message)"
        debugInfo.append(debugMessage)
        print(debugMessage)
        
        if debugInfo.count > 50 {
            debugInfo.removeFirst(10)
        }
    }
    
    func getDebugInfo() -> String {
        return debugInfo.joined(separator: "\n")
    }
    
    func clearDebugInfo() {
        debugInfo.removeAll()
        addDebugInfo("デバッグ情報がクリアされました")
    }
}

// MARK: - Data Models

struct SleepAnalysisResult {
    let date: Date
    let bedtime: Date?
    let wakeTime: Date?
    let totalSleepDuration: TimeInterval
    let inBedDuration: TimeInterval
    let sleepEfficiency: Double
    let sleepStages: [SleepStage]
    
    var formattedTotalSleep: String {
        let hours = Int(totalSleepDuration) / 3600
        let minutes = Int(totalSleepDuration) % 3600 / 60
        return String(format: "%d時間%d分", hours, minutes)
    }
    
    var formattedSleepEfficiency: String {
        return String(format: "%.1f%%", sleepEfficiency * 100)
    }
    
    var qualityScore: Double {
        // 睡眠効率と睡眠時間に基づいて品質スコアを計算
        let efficiencyScore = sleepEfficiency * 5.0 // 最大5点
        let durationScore: Double
        
        let hours = totalSleepDuration / 3600
        switch hours {
        case 7.0...9.0:
            durationScore = 5.0 // 理想的な睡眠時間
        case 6.0..<7.0, 9.0..<10.0:
            durationScore = 4.0
        case 5.0..<6.0, 10.0..<11.0:
            durationScore = 3.0
        case 4.0..<5.0, 11.0..<12.0:
            durationScore = 2.0
        default:
            durationScore = 1.0
        }
        
        return min(10.0, efficiencyScore + durationScore)
    }
}

struct SleepStage {
    let startTime: Date
    let endTime: Date
    let value: Int
    let duration: TimeInterval
    
    var stageType: SleepStageType {
        switch value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            return .inBed
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
            return .asleep
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            return .lightSleep
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            return .deepSleep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return .remSleep
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return .awake
        default:
            return .unknown
        }
    }
}

enum SleepStageType: String, CaseIterable {
    case inBed = "就寝中"
    case asleep = "睡眠"
    case lightSleep = "浅い睡眠"
    case deepSleep = "深い睡眠"
    case remSleep = "REM睡眠"
    case awake = "覚醒"
    case unknown = "不明"
    
    var color: String {
        switch self {
        case .inBed:
            return "AsaMutedSage"
        case .asleep:
            return "AsaCoffeeBrown"
        case .lightSleep:
            return "AsaSoftCream"
        case .deepSleep:
            return "AsaDarkSlate"
        case .remSleep:
            return "AsaMocha"
        case .awake:
            return "red"
        case .unknown:
            return "gray"
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let debugFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}