import Foundation
import SwiftData
import AsaLifeLogKit

// MARK: - SampleDataLoader

/// デモ動画撮影用サンプルデータローダー
///
/// 既存の LifeLogEntry が空の場合のみ、過去14日分のリアルなライフログを投入する。
/// 判定はデータ存在ベース（fetch().isEmpty）で行うため、ストア再生成時にも冪等に再投入される。
@MainActor
struct SampleDataLoader {

    /// 既存データが無い場合のみサンプルデータを投入
    static func loadIfNeeded(into context: ModelContext) {
        let descriptor = FetchDescriptor<LifeLogEntry>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        loadSampleData(into: context)
    }

    static func loadSampleData(into context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 14日分のエントリーを生成（dayOffset=0が今日、13が13日前）
        var allEntries: [LifeLogEntry] = []
        for dayOffset in 0..<14 {
            guard let baseDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayEntries = generateEntries(for: baseDate, dayOffset: dayOffset)
            allEntries.append(contentsOf: dayEntries)
        }
        for entry in allEntries {
            context.insert(entry)
        }

        // 14日分の DailySummary
        for dayOffset in 0..<14 {
            guard let baseDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayEntries = allEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: baseDate) }
            let summary = generateDailySummary(for: baseDate, dayOffset: dayOffset, entries: dayEntries)
            context.insert(summary)
        }

        // 直近2週分の WeeklySummary
        for weeksAgo in 0...1 {
            let weekSummary = generateWeeklySummary(weeksAgo: weeksAgo, calendar: calendar, today: today)
            context.insert(weekSummary)
        }

        // PlaceLog 6件
        for place in generatePlaces(today: today) {
            context.insert(place)
        }

        // UserPreferences
        context.insert(UserPreferences())

        try? context.save()

        // Widget Extension に渡す当日サマリーを AppGroup に保存
        saveTodayWidgetData(allEntries: allEntries, today: today)
    }

    // MARK: - Entry generation

    private static func generateEntries(for date: Date, dayOffset: Int) -> [LifeLogEntry] {
        let calendar = Calendar.current
        var entries: [LifeLogEntry] = []

        // 6:00 アクティビティ（朝のラン or ウォーク）
        let activity: ActivityType = (dayOffset % 3 == 0) ? .running : .walking
        let activityDuration: Double = (activity == .running) ? 1800 : 2400
        let activityTitle = (activity == .running) ? "朝のジョギング" : "朝の散歩"
        entries.append(
            LifeLogEntry(
                timestamp: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: date) ?? date,
                entryType: .activity,
                title: activityTitle,
                content: "公園を一周。気持ちのいい朝。",
                tags: ["朝活", "運動"],
                activityType: activity,
                durationSeconds: activityDuration,
                source: .coreMotion
            )
        )

        // 6:30 朝活メモ（手動記録）
        let morningTitles = ["読書メモ", "瞑想", "今日のプランニング", "ストレッチ", "朝ヨガ"]
        let morningContents = [
            "「アトミック・ハビッツ」を10ページ。小さな習慣の積み重ねが鍵。",
            "10分の瞑想で頭がクリアに。",
            "今日のタスクを3つに絞り出した。",
            "全身ストレッチで体が目覚める。",
            "ヨガで心身ともにリセット。"
        ]
        let titleIdx = dayOffset % morningTitles.count
        entries.append(
            LifeLogEntry(
                timestamp: calendar.date(bySettingHour: 6, minute: 30, second: 0, of: date) ?? date,
                entryType: .manual,
                title: morningTitles[titleIdx],
                content: morningContents[titleIdx],
                tags: ["朝活", "学習"],
                source: .manual,
                aiSummary: dayOffset == 0 ? "朝のインプットが習慣化されています。継続日数は2週間連続。" : nil
            )
        )

        // 7:00 気分エントリー
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = (weekday == 1 || weekday == 7)
        let mood: MoodScore = isWeekend
            ? .great
            : (dayOffset % 5 == 2 ? .neutral : (dayOffset % 3 == 0 ? .great : .good))
        entries.append(
            LifeLogEntry(
                timestamp: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date) ?? date,
                entryType: .mood,
                title: "朝の気分チェック",
                moodScore: mood,
                tags: ["朝活"],
                source: .manual
            )
        )

        // 8:00 健康データ（歩数）
        let steps = 6000 + (dayOffset * 537) % 6500
        entries.append(
            LifeLogEntry(
                timestamp: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) ?? date,
                entryType: .health,
                title: "歩数データ",
                source: .healthKit,
                healthMetricTypeRawValue: "steps",
                healthMetricValue: Double(steps)
            )
        )

        // 12:30 ランチ場所（位置情報）
        let lunchSpots: [(title: String, lat: Double, lon: Double, place: String)] = [
            ("お気に入りカフェ", 35.6694, 139.7635, "東京都港区新橋"),
            ("皇居外苑", 35.6852, 139.7528, "東京都千代田区皇居外苑"),
            ("社員食堂", 35.6812, 139.7671, "東京都千代田区丸の内"),
            ("近所の蕎麦屋", 35.6772, 139.7634, "東京都千代田区有楽町")
        ]
        let lunch = lunchSpots[dayOffset % lunchSpots.count]
        entries.append(
            LifeLogEntry(
                timestamp: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: date) ?? date,
                entryType: .location,
                title: "ランチ@\(lunch.title)",
                tags: ["食事"],
                latitude: lunch.lat,
                longitude: lunch.lon,
                locationName: lunch.place,
                source: .coreLocation
            )
        )

        // 19:00 家族・学習（隔日で投入）
        if dayOffset % 2 == 0 {
            entries.append(
                LifeLogEntry(
                    timestamp: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date) ?? date,
                    entryType: .manual,
                    title: "家族と夕食",
                    content: "今日の出来事を共有。子どもの学校の話で盛り上がった。",
                    moodScore: .great,
                    tags: ["家族", "食事"],
                    source: .manual
                )
            )
        } else {
            entries.append(
                LifeLogEntry(
                    timestamp: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: date) ?? date,
                    entryType: .manual,
                    title: "夜の振り返り",
                    content: "今日学んだことを3つメモ。",
                    tags: ["学習"],
                    source: .manual
                )
            )
        }

        return entries
    }

    // MARK: - Daily summary

    private static func generateDailySummary(for date: Date, dayOffset: Int, entries: [LifeLogEntry]) -> DailySummary {
        let moodNumerics = entries.compactMap { $0.moodScore?.numericValue }
        let moodAverage: Double? = moodNumerics.isEmpty
            ? nil
            : Double(moodNumerics.reduce(0, +)) / Double(moodNumerics.count)

        let stepsValue = entries.first { $0.entryType == .health }?.healthMetricValue ?? 0
        let totalSteps = Int(stepsValue)
        let totalDistanceKm = Double(totalSteps) / 1300.0

        let visitedPlaces = Array(Set(entries.compactMap { $0.locationName }))
        let dominantActivity = entries.first { $0.entryType == .activity }?.activityType

        let insights = [
            "朝活が充実した一日でした。6:00からの集中時間が高い生産性につながっています。",
            "気分の上昇が顕著です。継続が力になっています。",
            "歩数が1万歩近くに到達。活動量も十分。",
            "家族との時間がリフレッシュにつながっています。",
            "新しい朝のルーチンが定着してきました。",
            "今日は読書時間が長め。インプットの日。",
            "リカバリーを意識した一日。睡眠も十分でした。"
        ]

        return DailySummary(
            date: date,
            entryCount: entries.count,
            moodAverage: moodAverage,
            totalSteps: totalSteps,
            totalDistanceKm: totalDistanceKm,
            sleepHours: 6.5 + Double(dayOffset % 4) * 0.4,
            waterIntakeMl: 1800.0 + Double((dayOffset % 5) * 200),
            dominantActivity: dominantActivity,
            visitedPlaces: visitedPlaces,
            photoCount: dayOffset % 4,
            aiInsightText: insights[dayOffset % insights.count]
        )
    }

    // MARK: - Weekly summary

    private static func generateWeeklySummary(weeksAgo: Int, calendar: Calendar, today: Date) -> WeeklySummary {
        let weekEnd = calendar.date(byAdding: .day, value: -weeksAgo * 7, to: today) ?? today
        let weekStart = calendar.date(byAdding: .day, value: -6, to: weekEnd) ?? weekEnd

        if weeksAgo == 0 {
            return WeeklySummary(
                weekStartDate: weekStart,
                weekEndDate: weekEnd,
                entryCount: 32,
                averageMood: 4.2,
                totalSteps: 65_000,
                averageSleepHours: 7.4,
                topTags: ["朝活", "運動", "家族"],
                trendInsight: "今週は朝活ストリークが7日連続。気分も平均4.2と高水準を維持できています。",
                comparisonWithPreviousWeek: "前週比 エントリー数 +14%、歩数 +12%、気分平均 +0.3pt"
            )
        } else {
            return WeeklySummary(
                weekStartDate: weekStart,
                weekEndDate: weekEnd,
                entryCount: 28,
                averageMood: 3.9,
                totalSteps: 58_000,
                averageSleepHours: 7.1,
                topTags: ["朝活", "学習", "食事"],
                trendInsight: "先週は学習タグの活動が多めでした。インプット中心の週。",
                comparisonWithPreviousWeek: nil
            )
        }
    }

    // MARK: - Places

    private static func generatePlaces(today: Date) -> [PlaceLog] {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        let sixtyDaysAgo = calendar.date(byAdding: .day, value: -60, to: today) ?? today

        return [
            PlaceLog(
                name: "自宅",
                latitude: 35.6580,
                longitude: 139.7016,
                address: "東京都渋谷区",
                category: .home,
                visitCount: 365,
                firstVisitedAt: sixtyDaysAgo,
                lastVisitedAt: today,
                isFavorite: true
            ),
            PlaceLog(
                name: "オフィス",
                latitude: 35.6812,
                longitude: 139.7671,
                address: "東京都千代田区丸の内1丁目",
                category: .work,
                visitCount: 42,
                firstVisitedAt: sixtyDaysAgo,
                lastVisitedAt: yesterday
            ),
            PlaceLog(
                name: "皇居外苑",
                latitude: 35.6852,
                longitude: 139.7528,
                address: "東京都千代田区皇居外苑",
                category: .park,
                visitCount: 14,
                firstVisitedAt: thirtyDaysAgo,
                lastVisitedAt: today,
                isFavorite: true
            ),
            PlaceLog(
                name: "お気に入りカフェ",
                latitude: 35.6694,
                longitude: 139.7635,
                address: "東京都港区新橋",
                category: .restaurant,
                visitCount: 18,
                firstVisitedAt: thirtyDaysAgo,
                lastVisitedAt: yesterday
            ),
            PlaceLog(
                name: "ジム",
                latitude: 35.6720,
                longitude: 139.7568,
                address: "東京都中央区銀座",
                category: .gym,
                visitCount: 8,
                firstVisitedAt: weekAgo,
                lastVisitedAt: yesterday
            ),
            PlaceLog(
                name: "近所の本屋",
                latitude: 35.6610,
                longitude: 139.7050,
                address: "東京都渋谷区代官山",
                category: .shop,
                visitCount: 6,
                firstVisitedAt: thirtyDaysAgo,
                lastVisitedAt: weekAgo
            )
        ]
    }

    // MARK: - Widget data

    private static func saveTodayWidgetData(allEntries: [LifeLogEntry], today: Date) {
        let calendar = Calendar.current
        let todayEntries = allEntries
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .sorted { $0.timestamp < $1.timestamp }

        let moodNumerics = todayEntries.compactMap { $0.moodScore?.numericValue }
        let moodAverage = moodNumerics.isEmpty
            ? 4.0
            : Double(moodNumerics.reduce(0, +)) / Double(moodNumerics.count)
        let representativeMood: MoodScore = {
            switch moodAverage {
            case 4.5...: return .great
            case 3.5..<4.5: return .good
            case 2.5..<3.5: return .neutral
            case 1.5..<2.5: return .bad
            default: return .terrible
            }
        }()

        let stepsValue = todayEntries.first { $0.entryType == .health }?.healthMetricValue ?? 8500
        let totalSteps = Int(stepsValue)

        let entryScore = min(todayEntries.count * 10, 50)
        let moodScoreInt = Int(moodAverage * 10.0)
        let morningScore = min(entryScore + moodScoreInt, 100)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "H:mm"

        let recent = todayEntries.prefix(3).map { entry in
            WidgetEntry(
                title: entry.title,
                icon: entry.entryType.icon,
                time: formatter.string(from: entry.timestamp)
            )
        }

        let widgetData = LifeLogWidgetData(
            date: today,
            entryCount: todayEntries.count,
            morningScore: morningScore,
            totalSteps: totalSteps,
            sleepHours: 7.4,
            moodEmoji: representativeMood.emoji,
            moodLabel: representativeMood.displayName,
            recentEntries: Array(recent)
        )

        SharedDefaults.saveWidgetData(widgetData)
    }
}
