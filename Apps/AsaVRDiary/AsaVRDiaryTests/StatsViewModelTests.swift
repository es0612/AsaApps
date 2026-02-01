//
//  StatsViewModelTests.swift
//  AsaVRDiaryTests
//
//  StatsViewModelのテスト
//

import Testing
import Foundation
@testable import AsaVRDiary

@Suite("StatsViewModel Tests")
@MainActor
struct StatsViewModelTests {

    // MARK: - Setup

    func createTestViewModelWithData() -> StatsViewModel {
        let service = DiaryDataService(inMemory: true)

        // テストデータを作成
        let entry1 = DiaryEntry(title: "テスト1", content: "", category: .daily, mood: .happy, moodIntensity: 4)
        let entry2 = DiaryEntry(title: "テスト2", content: "", category: .daily, mood: .happy, moodIntensity: 3)
        let entry3 = DiaryEntry(title: "テスト3", content: "", category: .work, mood: .neutral, moodIntensity: 3)

        service.saveEntry(entry1)
        service.saveEntry(entry2)
        service.saveEntry(entry3)

        return StatsViewModel(dataService: service)
    }

    // MARK: - Initialization Tests

    @Test("初期化テスト")
    func testInitialization() {
        let service = DiaryDataService(inMemory: true)
        let viewModel = StatsViewModel(dataService: service)

        #expect(viewModel.stats.totalEntries == 0)
        #expect(viewModel.selectedPeriod == .month)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Load Stats Tests

    @Test("統計読み込みテスト")
    func testLoadStats() {
        let viewModel = createTestViewModelWithData()

        viewModel.loadStats()

        #expect(viewModel.stats.totalEntries == 3)
    }

    // MARK: - Category Percentages Tests

    @Test("カテゴリ割合テスト")
    func testCategoryPercentages() {
        let viewModel = createTestViewModelWithData()
        viewModel.loadStats()

        let percentages = viewModel.categoryPercentages()

        // dailyが2件、workが1件
        let dailyPercentage = percentages.first { $0.0 == .daily }?.1
        let workPercentage = percentages.first { $0.0 == .work }?.1

        #expect(dailyPercentage != nil)
        #expect(workPercentage != nil)

        // 約66.7%と33.3%
        if let daily = dailyPercentage {
            #expect(daily > 60 && daily < 70)
        }
        if let work = workPercentage {
            #expect(work > 30 && work < 40)
        }
    }

    // MARK: - Mood Percentages Tests

    @Test("気分割合テスト")
    func testMoodPercentages() {
        let viewModel = createTestViewModelWithData()
        viewModel.loadStats()

        let percentages = viewModel.moodPercentages()

        // happyが2件、neutralが1件
        let happyPercentage = percentages.first { $0.0 == .happy }?.1
        let neutralPercentage = percentages.first { $0.0 == .neutral }?.1

        #expect(happyPercentage != nil)
        #expect(neutralPercentage != nil)
    }

    // MARK: - Mood Trend Tests

    @Test("気分トレンドテスト - データなし")
    func testMoodTrendNoData() {
        let service = DiaryDataService(inMemory: true)
        let viewModel = StatsViewModel(dataService: service)
        viewModel.loadStats()

        let trend = viewModel.moodTrend()
        #expect(trend == .stable)
    }

    // MARK: - Streak Status Tests

    @Test("ストリークステータステスト - なし")
    func testStreakStatusNone() {
        let service = DiaryDataService(inMemory: true)
        let viewModel = StatsViewModel(dataService: service)
        viewModel.loadStats()

        let status = viewModel.streakStatus()
        #expect(status == .none)
    }

    @Test("ストリークステータステスト - 開始")
    func testStreakStatusStarted() {
        let service = DiaryDataService(inMemory: true)
        let entry = DiaryEntry(title: "今日", content: "", date: Date())
        service.saveEntry(entry)

        let viewModel = StatsViewModel(dataService: service)
        viewModel.loadStats()

        let status = viewModel.streakStatus()
        #expect(status == .started)
    }

    // MARK: - Chart Data Tests

    @Test("週間チャートデータテスト")
    func testWeeklyChartData() {
        let viewModel = createTestViewModelWithData()
        viewModel.loadStats()

        let chartData = viewModel.weeklyChartData()

        #expect(!chartData.isEmpty)
    }

    @Test("月間チャートデータテスト")
    func testMonthlyChartData() {
        let viewModel = createTestViewModelWithData()
        viewModel.loadStats()

        let chartData = viewModel.monthlyChartData()

        #expect(!chartData.isEmpty)
    }
}

// MARK: - StatsPeriod Tests

@Suite("StatsPeriod Tests")
struct StatsPeriodTests {

    @Test("displayNameテスト")
    func testDisplayNames() {
        #expect(StatsPeriod.week.displayName == "週")
        #expect(StatsPeriod.month.displayName == "月")
        #expect(StatsPeriod.year.displayName == "年")
    }

    @Test("allCasesテスト")
    func testAllCases() {
        #expect(StatsPeriod.allCases.count == 3)
    }
}

// MARK: - MoodTrend Tests

@Suite("MoodTrend Tests")
struct MoodTrendTests {

    @Test("iconテスト")
    func testIcons() {
        #expect(MoodTrend.increasing.icon == "arrow.up.right")
        #expect(MoodTrend.decreasing.icon == "arrow.down.right")
        #expect(MoodTrend.stable.icon == "arrow.right")
    }

    @Test("descriptionテスト")
    func testDescriptions() {
        #expect(MoodTrend.increasing.description == "増加傾向")
        #expect(MoodTrend.decreasing.description == "減少傾向")
        #expect(MoodTrend.stable.description == "安定")
    }
}

// MARK: - StreakStatus Tests

@Suite("StreakStatus Tests")
struct StreakStatusTests {

    @Test("messageテスト")
    func testMessages() {
        #expect(StreakStatus.none.message == "今日から始めよう！")
        #expect(StreakStatus.started.message == "良いスタート！")
        #expect(StreakStatus.building.message == "習慣になりつつあります")
        #expect(StreakStatus.good.message == "素晴らしい継続！")
        #expect(StreakStatus.excellent.message == "驚異的な継続力！")
    }

    @Test("iconテスト")
    func testIcons() {
        #expect(StreakStatus.none.icon == "flame")
        #expect(StreakStatus.started.icon == "flame.fill")
        #expect(StreakStatus.excellent.icon == "flame.fill")
    }
}
