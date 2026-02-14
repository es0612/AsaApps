import Foundation

// MARK: - DailySummaryGenerator

/// 日次サマリー生成サービス
///
/// InsightsEngine を使ってその日のエントリーからサマリーを生成する。
@MainActor
@Observable
public final class DailySummaryGenerator {
    private let insightsEngine: any InsightsEngineProtocol

    // MARK: - Init

    public init(insightsEngine: any InsightsEngineProtocol) {
        self.insightsEngine = insightsEngine
    }

    // MARK: - Methods

    /// 指定日のサマリーを生成する
    public func generate(
        entries: [LifeLogEntry],
        date: Date,
        preferences: UserPreferences
    ) -> DailySummary {
        let insight = insightsEngine.generateDailyInsight(
            entries: entries,
            date: date,
            preferences: preferences
        )

        // 気分平均を計算
        let moodValues = entries.compactMap { $0.moodScore?.numericValue }
        let moodAverage = moodValues.isEmpty ? nil :
            Double(moodValues.reduce(0, +)) / Double(moodValues.count)

        // 歩数・距離を集計（ヘルスケアエントリーから）
        let healthEntries = entries.filter { $0.source == .healthKit }
        let totalSteps = healthEntries
            .filter { $0.healthMetricTypeRawValue == "steps" }
            .compactMap { $0.healthMetricValue }
            .reduce(0.0, +)
        let totalDistance = healthEntries
            .filter { $0.healthMetricTypeRawValue == "distance" }
            .compactMap { $0.healthMetricValue }
            .reduce(0.0, +)

        // 睡眠時間
        let sleepHours = healthEntries
            .filter { $0.healthMetricTypeRawValue == "sleep" }
            .compactMap { $0.healthMetricValue }
            .first

        // 水分摂取量
        let waterIntake = healthEntries
            .filter { $0.healthMetricTypeRawValue == "water" }
            .compactMap { $0.healthMetricValue }
            .reduce(0.0, +)

        // 主要アクティビティ
        let activityEntries = entries.filter { $0.activityType != nil }
        let dominantActivity = findDominantActivity(activityEntries)

        // 訪問場所
        let visitedPlaces = Array(Set(entries.compactMap { $0.locationName }))

        // 写真数
        let photoCount = entries.filter { $0.entryType == .photo }.count

        return DailySummary(
            date: date,
            entryCount: entries.count,
            moodAverage: moodAverage,
            totalSteps: Int(totalSteps),
            totalDistanceKm: totalDistance,
            sleepHours: sleepHours,
            waterIntakeMl: waterIntake > 0 ? waterIntake : nil,
            dominantActivity: dominantActivity,
            visitedPlaces: visitedPlaces,
            photoCount: photoCount,
            aiInsightText: insight.summaryText,
            highlightEntryId: insight.highlightEntryId
        )
    }

    // MARK: - Private

    /// 最も頻度の高いアクティビティを返す
    private func findDominantActivity(_ entries: [LifeLogEntry]) -> ActivityType? {
        var counts: [ActivityType: Int] = [:]
        for entry in entries {
            if let type = entry.activityType {
                counts[type, default: 0] += 1
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
