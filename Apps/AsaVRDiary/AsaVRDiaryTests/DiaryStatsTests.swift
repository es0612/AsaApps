//
//  DiaryStatsTests.swift
//  AsaVRDiaryTests
//
//  DiaryStatsおよびDiaryStatsCalculatorのテスト
//

import Testing
import Foundation
@testable import AsaVRDiary

@Suite("DiaryStats Tests")
struct DiaryStatsTests {

    // MARK: - Empty Stats Tests

    @Test("emptyスタッツのテスト")
    func testEmptyStats() {
        let stats = DiaryStats.empty

        #expect(stats.totalEntries == 0)
        #expect(stats.thisMonthEntries == 0)
        #expect(stats.streakDays == 0)
        #expect(stats.categoryCount.isEmpty)
        #expect(stats.moodCount.isEmpty)
        #expect(stats.averageMoodIntensity == 0)
        #expect(stats.topCategory == nil)
        #expect(stats.topMood == nil)
    }

    // MARK: - Top Category Tests

    @Test("topCategoryテスト")
    func testTopCategory() {
        let stats = DiaryStats(
            totalEntries: 10,
            thisMonthEntries: 5,
            streakDays: 3,
            categoryCount: [
                .daily: 5,
                .work: 3,
                .family: 2
            ],
            moodCount: [:],
            averageMoodIntensity: 3.0,
            weeklyEntries: [],
            monthlyEntries: []
        )

        #expect(stats.topCategory == .daily)
    }

    // MARK: - Top Mood Tests

    @Test("topMoodテスト")
    func testTopMood() {
        let stats = DiaryStats(
            totalEntries: 10,
            thisMonthEntries: 5,
            streakDays: 3,
            categoryCount: [:],
            moodCount: [
                .happy: 4,
                .neutral: 3,
                .excited: 3
            ],
            averageMoodIntensity: 3.5,
            weeklyEntries: [],
            monthlyEntries: []
        )

        #expect(stats.topMood == .happy)
    }
}

@Suite("DiaryStatsCalculator Tests")
struct DiaryStatsCalculatorTests {

    // MARK: - Calculate From Empty Tests

    @Test("空の配列からの計算テスト")
    func testCalculateFromEmpty() {
        let entries: [DiaryEntry] = []
        let stats = DiaryStatsCalculator.calculate(from: entries)

        #expect(stats.totalEntries == 0)
        #expect(stats.thisMonthEntries == 0)
        #expect(stats.streakDays == 0)
        #expect(stats.averageMoodIntensity == 0)
    }

    // MARK: - Total Entries Tests

    @Test("totalEntriesテスト")
    func testTotalEntries() {
        let entries = [
            DiaryEntry(title: "1", content: ""),
            DiaryEntry(title: "2", content: ""),
            DiaryEntry(title: "3", content: "")
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        #expect(stats.totalEntries == 3)
    }

    // MARK: - This Month Entries Tests

    @Test("thisMonthEntriesテスト")
    func testThisMonthEntries() {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!

        let entries = [
            DiaryEntry(title: "今月1", content: "", date: now),
            DiaryEntry(title: "今月2", content: "", date: now),
            DiaryEntry(title: "先月", content: "", date: lastMonth)
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        #expect(stats.thisMonthEntries == 2)
    }

    // MARK: - Category Count Tests

    @Test("categoryCountテスト")
    func testCategoryCount() {
        let entries = [
            DiaryEntry(title: "1", content: "", category: .daily),
            DiaryEntry(title: "2", content: "", category: .daily),
            DiaryEntry(title: "3", content: "", category: .work),
            DiaryEntry(title: "4", content: "", category: .family)
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        #expect(stats.categoryCount[.daily] == 2)
        #expect(stats.categoryCount[.work] == 1)
        #expect(stats.categoryCount[.family] == 1)
        #expect(stats.categoryCount[.travel] == 0)
    }

    // MARK: - Mood Count Tests

    @Test("moodCountテスト")
    func testMoodCount() {
        let entries = [
            DiaryEntry(title: "1", content: "", mood: .happy),
            DiaryEntry(title: "2", content: "", mood: .happy),
            DiaryEntry(title: "3", content: "", mood: .sad)
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        #expect(stats.moodCount[.happy] == 2)
        #expect(stats.moodCount[.sad] == 1)
        #expect(stats.moodCount[.neutral] == 0)
    }

    // MARK: - Average Mood Intensity Tests

    @Test("averageMoodIntensityテスト")
    func testAverageMoodIntensity() {
        let entries = [
            DiaryEntry(title: "1", content: "", moodIntensity: 5),
            DiaryEntry(title: "2", content: "", moodIntensity: 3),
            DiaryEntry(title: "3", content: "", moodIntensity: 4)
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        #expect(stats.averageMoodIntensity == 4.0)
    }

    // MARK: - Streak Days Tests

    @Test("streakDaysテスト - 連続3日")
    func testStreakDaysConsecutive() {
        let calendar = Calendar.current
        let now = Date()

        let entries = [
            DiaryEntry(title: "今日", content: "", date: now),
            DiaryEntry(title: "昨日", content: "", date: calendar.date(byAdding: .day, value: -1, to: now)!),
            DiaryEntry(title: "一昨日", content: "", date: calendar.date(byAdding: .day, value: -2, to: now)!)
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        #expect(stats.streakDays == 3)
    }

    @Test("streakDaysテスト - 途切れあり")
    func testStreakDaysWithGap() {
        let calendar = Calendar.current
        let now = Date()

        let entries = [
            DiaryEntry(title: "今日", content: "", date: now),
            DiaryEntry(title: "昨日", content: "", date: calendar.date(byAdding: .day, value: -1, to: now)!),
            // 2日前は欠落
            DiaryEntry(title: "3日前", content: "", date: calendar.date(byAdding: .day, value: -3, to: now)!)
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        #expect(stats.streakDays == 2)
    }

    @Test("streakDaysテスト - 今日の記録なし")
    func testStreakDaysNoToday() {
        let calendar = Calendar.current
        let now = Date()

        let entries = [
            DiaryEntry(title: "昨日", content: "", date: calendar.date(byAdding: .day, value: -1, to: now)!),
            DiaryEntry(title: "一昨日", content: "", date: calendar.date(byAdding: .day, value: -2, to: now)!)
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        #expect(stats.streakDays == 0)
    }

    // MARK: - Weekly Entries Tests

    @Test("weeklyEntriesテスト")
    func testWeeklyEntries() {
        let entries = [
            DiaryEntry(title: "1", content: "")
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        // 8週間分のエントリーがある
        #expect(stats.weeklyEntries.count == 8)
    }

    // MARK: - Monthly Entries Tests

    @Test("monthlyEntriesテスト")
    func testMonthlyEntries() {
        let entries = [
            DiaryEntry(title: "1", content: "")
        ]

        let stats = DiaryStatsCalculator.calculate(from: entries)

        // 12ヶ月分のエントリーがある
        #expect(stats.monthlyEntries.count == 12)
    }
}

// MARK: - WeeklyEntry Tests

@Suite("WeeklyEntry Tests")
struct WeeklyEntryTests {

    @Test("formattedWeekテスト")
    func testFormattedWeek() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 3, day: 11) // 月曜日
        let date = calendar.date(from: components)!

        let entry = WeeklyEntry(weekStart: date, count: 5)

        #expect(entry.formattedWeek == "3/11〜")
    }
}

// MARK: - MonthlyEntry Tests

@Suite("MonthlyEntry Tests")
struct MonthlyEntryTests {

    @Test("formattedMonthテスト")
    func testFormattedMonth() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 3, day: 1)
        let date = calendar.date(from: components)!

        let entry = MonthlyEntry(month: date, count: 10)

        #expect(entry.formattedMonth == "3月")
    }
}
