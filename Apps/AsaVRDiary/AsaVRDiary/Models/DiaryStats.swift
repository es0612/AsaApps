//
//  DiaryStats.swift
//  AsaVRDiary
//
//  日記統計データ
//

import Foundation

/// 日記統計データ
struct DiaryStats: Sendable {
    /// 総日記数
    let totalEntries: Int

    /// 今月の日記数
    let thisMonthEntries: Int

    /// 連続記録日数
    let streakDays: Int

    /// カテゴリ別カウント
    let categoryCount: [DiaryCategory: Int]

    /// 気分別カウント
    let moodCount: [DiaryMood: Int]

    /// 最も多いカテゴリ
    var topCategory: DiaryCategory? {
        categoryCount.max(by: { $0.value < $1.value })?.key
    }

    /// 最も多い気分
    var topMood: DiaryMood? {
        moodCount.max(by: { $0.value < $1.value })?.key
    }

    /// 平均気分強度
    let averageMoodIntensity: Double

    /// 週ごとのエントリー数（過去8週間）
    let weeklyEntries: [WeeklyEntry]

    /// 月ごとのエントリー数（過去12ヶ月）
    let monthlyEntries: [MonthlyEntry]

    // MARK: - Static

    /// 空の統計
    static let empty = DiaryStats(
        totalEntries: 0,
        thisMonthEntries: 0,
        streakDays: 0,
        categoryCount: [:],
        moodCount: [:],
        averageMoodIntensity: 0,
        weeklyEntries: [],
        monthlyEntries: []
    )
}

/// 週ごとのエントリー数
struct WeeklyEntry: Identifiable, Sendable {
    let id: UUID = UUID()
    let weekStart: Date
    let count: Int

    /// フォーマット済み週表示
    var formattedWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: weekStart) + "〜"
    }
}

/// 月ごとのエントリー数
struct MonthlyEntry: Identifiable, Sendable {
    let id: UUID = UUID()
    let month: Date
    let count: Int

    /// フォーマット済み月表示
    var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: month)
    }
}

// MARK: - DiaryStatsCalculator

/// 統計計算ユーティリティ
enum DiaryStatsCalculator {
    /// 日記エントリーから統計を計算
    static func calculate(from entries: [DiaryEntry]) -> DiaryStats {
        let calendar = Calendar.current
        let now = Date()

        // 今月の開始日
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        // 今月のエントリー数
        let thisMonthEntries = entries.filter { $0.date >= thisMonthStart }.count

        // カテゴリ別カウント
        var categoryCount: [DiaryCategory: Int] = [:]
        for category in DiaryCategory.allCases {
            categoryCount[category] = 0
        }
        for entry in entries {
            categoryCount[entry.category, default: 0] += 1
        }

        // 気分別カウント
        var moodCount: [DiaryMood: Int] = [:]
        for mood in DiaryMood.allCases {
            moodCount[mood] = 0
        }
        for entry in entries {
            moodCount[entry.mood, default: 0] += 1
        }

        // 平均気分強度
        let totalIntensity = entries.reduce(0) { $0 + $1.moodIntensity }
        let averageIntensity = entries.isEmpty ? 0 : Double(totalIntensity) / Double(entries.count)

        // 連続記録日数
        let streakDays = calculateStreak(from: entries, calendar: calendar)

        // 週ごとのエントリー数（過去8週間）
        let weeklyEntries = calculateWeeklyEntries(from: entries, calendar: calendar, weeks: 8)

        // 月ごとのエントリー数（過去12ヶ月）
        let monthlyEntries = calculateMonthlyEntries(from: entries, calendar: calendar, months: 12)

        return DiaryStats(
            totalEntries: entries.count,
            thisMonthEntries: thisMonthEntries,
            streakDays: streakDays,
            categoryCount: categoryCount,
            moodCount: moodCount,
            averageMoodIntensity: averageIntensity,
            weeklyEntries: weeklyEntries,
            monthlyEntries: monthlyEntries
        )
    }

    /// 連続記録日数を計算
    private static func calculateStreak(from entries: [DiaryEntry], calendar: Calendar) -> Int {
        guard !entries.isEmpty else { return 0 }

        // 日付でユニークなエントリーを取得
        let uniqueDates = Set(entries.map { calendar.startOfDay(for: $0.date) })
        let sortedDates = uniqueDates.sorted(by: >)

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for date in sortedDates {
            if date == currentDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if date < currentDate {
                break
            }
        }

        return streak
    }

    /// 週ごとのエントリー数を計算
    private static func calculateWeeklyEntries(
        from entries: [DiaryEntry],
        calendar: Calendar,
        weeks: Int
    ) -> [WeeklyEntry] {
        let now = Date()
        var result: [WeeklyEntry] = []

        for weekOffset in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                  let adjustedStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart))
            else { continue }

            let weekEnd = calendar.date(byAdding: .day, value: 7, to: adjustedStart)!
            let count = entries.filter { $0.date >= adjustedStart && $0.date < weekEnd }.count

            result.append(WeeklyEntry(weekStart: adjustedStart, count: count))
        }

        return result.reversed()
    }

    /// 月ごとのエントリー数を計算
    private static func calculateMonthlyEntries(
        from entries: [DiaryEntry],
        calendar: Calendar,
        months: Int
    ) -> [MonthlyEntry] {
        let now = Date()
        var result: [MonthlyEntry] = []

        for monthOffset in 0..<months {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now),
                  let adjustedStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart))
            else { continue }

            let monthEnd = calendar.date(byAdding: .month, value: 1, to: adjustedStart)!
            let count = entries.filter { $0.date >= adjustedStart && $0.date < monthEnd }.count

            result.append(MonthlyEntry(month: adjustedStart, count: count))
        }

        return result.reversed()
    }
}
