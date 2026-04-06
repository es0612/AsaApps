import Foundation
import SwiftData
import AsaLifeLogKit

// MARK: - SampleDataLoader

/// デモ動画撮影用サンプルデータローダー
/// UserDefaults フラグで初回起動時のみ投入
@MainActor
struct SampleDataLoader {
    private static let sampleDataKey = "AsaLifeLog_SampleDataLoaded_v1"

    /// 初回起動時のみサンプルデータを投入
    static func loadIfNeeded(into context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: sampleDataKey) else { return }
        loadSampleData(into: context)
        UserDefaults.standard.set(true, forKey: sampleDataKey)
    }

    static func loadSampleData(into context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()

        // 手動エントリー
        let manualEntry = LifeLogEntry(
            timestamp: calendar.date(bySettingHour: 6, minute: 30, second: 0, of: today) ?? today,
            entryType: .manual,
            title: "朝のジョギング",
            content: "公園を30分走った。気持ちいい朝！",
            moodScore: .great,
            tags: ["朝活", "運動"],
            source: .manual
        )
        context.insert(manualEntry)

        // 気分エントリー
        let moodEntry = LifeLogEntry(
            timestamp: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today,
            entryType: .mood,
            title: "朝の気分チェック",
            moodScore: .good,
            tags: ["朝活"],
            source: .manual
        )
        context.insert(moodEntry)

        // 健康エントリー
        let healthEntry = LifeLogEntry(
            timestamp: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today) ?? today,
            entryType: .health,
            title: "歩数データ",
            source: .healthKit,
            healthMetricTypeRawValue: "steps",
            healthMetricValue: 5000
        )
        context.insert(healthEntry)

        // アクティビティエントリー
        let activityEntry = LifeLogEntry(
            timestamp: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: today) ?? today,
            entryType: .activity,
            title: "ランニング",
            activityType: .running,
            durationSeconds: 1800,
            source: .coreMotion
        )
        context.insert(activityEntry)

        // 場所エントリー
        let locationEntry = LifeLogEntry(
            timestamp: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today) ?? today,
            entryType: .location,
            title: "ランチ",
            tags: ["食事"],
            latitude: 35.6812,
            longitude: 139.7671,
            locationName: "東京駅周辺",
            source: .coreLocation
        )
        context.insert(locationEntry)

        // 日次サマリー
        let summary = DailySummary(
            date: today,
            entryCount: 5,
            moodAverage: 4.0,
            totalSteps: 8500,
            totalDistanceKm: 6.2,
            sleepHours: 7.5,
            waterIntakeMl: 2000,
            visitedPlaces: ["東京駅周辺", "公園"],
            photoCount: 3,
            aiInsightText: "朝活が充実した一日でした。6:00からの朝活で高い生産性を発揮しています。"
        )
        context.insert(summary)

        // 場所ログ
        let place = PlaceLog(
            name: "東京駅",
            latitude: 35.6812,
            longitude: 139.7671,
            address: "東京都千代田区丸の内1丁目",
            category: .work,
            visitCount: 15
        )
        context.insert(place)

        // ユーザー設定
        let prefs = UserPreferences()
        context.insert(prefs)

        try? context.save()
    }
}
