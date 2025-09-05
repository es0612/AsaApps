//
//  TimerDataService.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import Foundation

/// タイマーデータ永続化サービス
final class TimerDataService: Sendable {
    static let shared = TimerDataService()
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // UserDefaultsキー
    private enum Keys {
        static let multiTimer = "AsaTimerPro.multiTimer"
        static let appSettings = "AsaTimerPro.appSettings"
        static let timerHistory = "AsaTimerPro.timerHistory"
        static let dataVersion = "AsaTimerPro.dataVersion"
    }
    
    private let currentDataVersion = 1
    
    init() {
        setupDateFormatters()
        performDataMigrationIfNeeded()
    }
    
    // MARK: - Data Persistence
    
    /// MultiTimerデータを保存
    func saveMultiTimer(_ multiTimer: MultiTimer) throws {
        do {
            let data = try encoder.encode(multiTimer)
            userDefaults.set(data, forKey: Keys.multiTimer)
            userDefaults.set(Date(), forKey: Keys.multiTimer + ".lastSaved")
            print("MultiTimerデータを保存しました")
        } catch {
            print("MultiTimerデータの保存に失敗: \(error)")
            throw DataServiceError.saveError(error)
        }
    }
    
    /// MultiTimerデータを読み込み
    func loadMultiTimer() throws -> MultiTimer {
        guard let data = userDefaults.data(forKey: Keys.multiTimer) else {
            print("MultiTimerデータが見つからないため、新規作成します")
            return MultiTimer()
        }
        
        do {
            let multiTimer = try decoder.decode(MultiTimer.self, from: data)
            print("MultiTimerデータを読み込みました: \(multiTimer.sessions.count)個のタイマー")
            return multiTimer
        } catch {
            print("MultiTimerデータの読み込みに失敗: \(error)")
            throw DataServiceError.loadError(error)
        }
    }
    
    /// アプリ設定を保存
    func saveAppSettings(_ settings: AppSettings) throws {
        do {
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: Keys.appSettings)
        } catch {
            throw DataServiceError.saveError(error)
        }
    }
    
    /// アプリ設定を読み込み
    func loadAppSettings() throws -> AppSettings {
        guard let data = userDefaults.data(forKey: Keys.appSettings) else {
            return AppSettings.default
        }
        
        do {
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            throw DataServiceError.loadError(error)
        }
    }
    
    /// タイマー履歴を保存
    func saveTimerHistory(_ history: [TimerSession]) throws {
        do {
            let data = try encoder.encode(history)
            userDefaults.set(data, forKey: Keys.timerHistory)
        } catch {
            throw DataServiceError.saveError(error)
        }
    }
    
    /// タイマー履歴を読み込み
    func loadTimerHistory() throws -> [TimerSession] {
        guard let data = userDefaults.data(forKey: Keys.timerHistory) else {
            return []
        }
        
        do {
            return try decoder.decode([TimerSession].self, from: data)
        } catch {
            throw DataServiceError.loadError(error)
        }
    }
    
    // MARK: - Data Export/Import
    
    /// 全データをエクスポート
    func exportAllData() throws -> Data {
        let exportData = ExportData(
            multiTimer: try loadMultiTimer(),
            appSettings: try loadAppSettings(),
            timerHistory: try loadTimerHistory(),
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            dataVersion: currentDataVersion
        )
        
        do {
            return try encoder.encode(exportData)
        } catch {
            throw DataServiceError.exportError(error)
        }
    }
    
    /// データをインポート
    func importData(_ data: Data, mergeMode: ImportMergeMode = .replace) throws {
        do {
            let importData = try decoder.decode(ExportData.self, from: data)
            
            // データバージョンチェック
            if importData.dataVersion > currentDataVersion {
                throw DataServiceError.unsupportedDataVersion(importData.dataVersion)
            }
            
            // インポート実行
            switch mergeMode {
            case .replace:
                try saveMultiTimer(importData.multiTimer)
                try saveAppSettings(importData.appSettings)
                try saveTimerHistory(importData.timerHistory)
                
            case .merge:
                // 既存データとマージ
                let existingTimer = try loadMultiTimer()
                var mergedTimer = existingTimer
                
                // 重複しないタイマーセッションのみ追加
                for session in importData.multiTimer.sessions {
                    if !existingTimer.sessions.contains(where: { $0.id == session.id }) {
                        mergedTimer.addTimer(session)
                    }
                }
                
                try saveMultiTimer(mergedTimer)
                
                // 履歴もマージ
                let existingHistory = try loadTimerHistory()
                let mergedHistory = mergeSessions(existing: existingHistory, new: importData.timerHistory)
                try saveTimerHistory(mergedHistory)
            }
            
            print("データのインポートが完了しました")
            
        } catch {
            throw DataServiceError.importError(error)
        }
    }
    
    // MARK: - Data Management
    
    /// 古いデータを削除（指定した日数より古い完了済みタイマー）
    func cleanupOldData(olderThanDays days: Int) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        var multiTimer = try loadMultiTimer()
        let originalCount = multiTimer.sessions.count
        
        // 古い完了済みタイマーを削除
        multiTimer = MultiTimer(maxConcurrentTimers: multiTimer.maxConcurrentTimers)
        let activeSessions = try loadMultiTimer().sessions.filter { session in
            return !session.isCompleted || session.createdAt > cutoffDate
        }
        
        for session in activeSessions {
            multiTimer.addTimer(session)
        }
        
        try saveMultiTimer(multiTimer)
        
        let deletedCount = originalCount - multiTimer.sessions.count
        print("古いデータを削除しました: \(deletedCount)個のタイマー")
    }
    
    /// 全データを削除
    func clearAllData() throws {
        userDefaults.removeObject(forKey: Keys.multiTimer)
        userDefaults.removeObject(forKey: Keys.appSettings)
        userDefaults.removeObject(forKey: Keys.timerHistory)
        
        print("全データを削除しました")
    }
    
    /// データサイズを取得
    func getDataSize() -> DataSize {
        let multiTimerSize = userDefaults.data(forKey: Keys.multiTimer)?.count ?? 0
        let settingsSize = userDefaults.data(forKey: Keys.appSettings)?.count ?? 0
        let historySize = userDefaults.data(forKey: Keys.timerHistory)?.count ?? 0
        
        return DataSize(
            multiTimer: multiTimerSize,
            settings: settingsSize,
            history: historySize,
            total: multiTimerSize + settingsSize + historySize
        )
    }
    
    // MARK: - Private Methods
    
    private func setupDateFormatters() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    private func performDataMigrationIfNeeded() {
        let currentVersion = userDefaults.integer(forKey: Keys.dataVersion)
        
        if currentVersion < currentDataVersion {
            print("データマイグレーションを実行します: \(currentVersion) → \(currentDataVersion)")
            // 将来的なマイグレーション処理をここに追加
            userDefaults.set(currentDataVersion, forKey: Keys.dataVersion)
        }
    }
    
    private func mergeSessions(existing: [TimerSession], new: [TimerSession]) -> [TimerSession] {
        var merged = existing
        
        for session in new {
            if !existing.contains(where: { $0.id == session.id }) {
                merged.append(session)
            }
        }
        
        return merged
    }
}

// MARK: - Supporting Types

/// データサービスエラー
enum DataServiceError: LocalizedError {
    case saveError(Error)
    case loadError(Error)
    case exportError(Error)
    case importError(Error)
    case unsupportedDataVersion(Int)
    
    var errorDescription: String? {
        switch self {
        case .saveError(let error):
            return "データの保存に失敗しました: \(error.localizedDescription)"
        case .loadError(let error):
            return "データの読み込みに失敗しました: \(error.localizedDescription)"
        case .exportError(let error):
            return "データのエクスポートに失敗しました: \(error.localizedDescription)"
        case .importError(let error):
            return "データのインポートに失敗しました: \(error.localizedDescription)"
        case .unsupportedDataVersion(let version):
            return "サポートされていないデータバージョンです: \(version)"
        }
    }
}

/// インポート時のマージモード
enum ImportMergeMode {
    case replace    // 既存データを置き換え
    case merge      // 既存データとマージ
}

/// エクスポートデータ構造
struct ExportData: Codable {
    let multiTimer: MultiTimer
    let appSettings: AppSettings
    let timerHistory: [TimerSession]
    let exportDate: Date
    let appVersion: String
    let dataVersion: Int
}

/// アプリ設定
struct AppSettings: Codable {
    let playSounds: Bool
    let maxConcurrentTimers: Int
    let showCompletedTimers: Bool
    let defaultCategory: TimerCategory
    let autoCleanupDays: Int
    
    static let `default` = AppSettings(
        playSounds: true,
        maxConcurrentTimers: 4,
        showCompletedTimers: true,
        defaultCategory: .general,
        autoCleanupDays: 30
    )
}

/// データサイズ情報
struct DataSize {
    let multiTimer: Int     // バイト
    let settings: Int       // バイト
    let history: Int        // バイト
    let total: Int          // バイト
    
    var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file)
    }
}