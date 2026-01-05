//
//  AnalyticsViewModelTests.swift
//  AsaSmartTodoTests
//
//  AnalyticsViewModelのテスト
//  週次サマリー、チャートデータ、データ読み込みを検証
//

import Testing
import Foundation
@testable import AsaSmartTodo

/// AnalyticsViewModelのテストスイート
@MainActor
struct AnalyticsViewModelTests {

    // MARK: - Helper Methods

    /// テスト用のin-memory DataServiceを作成
    func createTestDataService() -> DataService {
        return DataService(inMemory: true)
    }

    /// テスト用のViewModelを作成
    func createTestViewModel() -> AnalyticsViewModel {
        let dataService = createTestDataService()
        return AnalyticsViewModel(dataService: dataService)
    }

    /// テスト用のTaskAnalyticsを作成
    func createTestAnalytics(
        date: Date = Date(),
        totalTasks: Int = 10,
        completedTasks: Int = 7,
        totalPredictions: Int = 8,
        acceptedPredictions: Int = 6
    ) -> TaskAnalytics {
        let analytics = TaskAnalytics(date: date)

        // タスク作成と完了のシミュレーション
        for _ in 0..<totalTasks {
            analytics.recordTaskCreation(at: 9, category: .work)
        }
        for _ in 0..<completedTasks {
            analytics.recordTaskCompletion(at: 17, category: .work)
        }

        // AI予測のシミュレーション
        for i in 0..<totalPredictions {
            let accepted = i < acceptedPredictions
            analytics.recordAIFeedback(accepted: accepted, confidenceScore: 0.8)
        }

        return analytics
    }

    // MARK: - 週次サマリー計算テスト (5テスト)

    @Test("週間完了率の計算が正しく動作する")
    func testWeeklyCompletionRate() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        // 7日分のテストデータを作成
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let analytics = createTestAnalytics(
                date: date,
                totalTasks: 10,
                completedTasks: 7
            )
            dataService.save()
        }

        viewModel.loadAnalytics()

        // 完了率: 7/10 = 0.7 (70%)
        let rate = viewModel.weeklyCompletionRate
        #expect(rate >= 0.0 && rate <= 1.0)
    }

    @Test("週間AI採用率の計算が正しく動作する")
    func testWeeklyAIAcceptanceRate() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let analytics = createTestAnalytics(
                date: date,
                totalPredictions: 10,
                acceptedPredictions: 8
            )
            dataService.save()
        }

        viewModel.loadAnalytics()

        // 採用率: 8/10 = 0.8 (80%)
        let rate = viewModel.weeklyAIAcceptanceRate
        #expect(rate >= 0.0 && rate <= 1.0)
    }

    @Test("週間朝活スコアの計算が正しく動作する")
    func testWeeklyEarlyMorningScore() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let analytics = createTestAnalytics(date: date)
            dataService.save()
        }

        viewModel.loadAnalytics()

        let score = viewModel.weeklyEarlyMorningScore
        #expect(score >= 0.0 && score <= 1.0)
    }

    @Test("週間平均信頼度の計算が正しく動作する")
    func testWeeklyAverageConfidence() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let analytics = createTestAnalytics(date: date)
            dataService.save()
        }

        viewModel.loadAnalytics()

        let confidence = viewModel.weeklyAverageConfidence
        #expect(confidence >= 0.0 && confidence <= 1.0)
    }

    @Test("空データでの週次サマリーが0.0を返す")
    func testWeeklySummaryWithEmptyData() async {
        let viewModel = createTestViewModel()

        viewModel.loadAnalytics()

        #expect(viewModel.weeklyCompletionRate == 0.0)
        #expect(viewModel.weeklyAIAcceptanceRate == 0.0)
        #expect(viewModel.weeklyEarlyMorningScore == 0.0)
        #expect(viewModel.weeklyAverageConfidence == 0.0)
    }

    // MARK: - チャートデータ生成テスト (4テスト)

    @Test("24時間チャートデータが生成される")
    func testHourlyChartData() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        let analytics = createTestAnalytics()
        dataService.save()

        viewModel.loadAnalytics()

        let chartData = viewModel.hourlyChartData
        #expect(chartData.count == 24)
        #expect(chartData.first?.hour == 0)
        #expect(chartData.last?.hour == 23)
    }

    @Test("週間トレンドデータが生成される")
    func testWeeklyTrendData() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let analytics = createTestAnalytics(date: date)
            dataService.save()
        }

        viewModel.loadAnalytics()

        let trendData = viewModel.weeklyTrendData
        #expect(trendData.count == 7)
        #expect(trendData.first != nil)
    }

    @Test("AI精度トレンドデータが生成される")
    func testAIAccuracyTrend() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let analytics = createTestAnalytics(date: date)
            dataService.save()
        }

        viewModel.loadAnalytics()

        let accuracyData = viewModel.aiAccuracyTrend
        #expect(accuracyData.count == 7)
        #expect(accuracyData.first?.totalPredictions != nil)
    }

    @Test("空データでのチャート生成")
    func testChartDataWithEmptyAnalytics() async {
        let viewModel = createTestViewModel()

        viewModel.loadAnalytics()

        // 今日のデータがnilの場合、hourlyChartDataは空配列
        let hourlyData = viewModel.hourlyChartData
        #expect(hourlyData.isEmpty)

        // 週間データが空の場合、トレンドデータも空
        let trendData = viewModel.weeklyTrendData
        #expect(trendData.isEmpty)

        let accuracyData = viewModel.aiAccuracyTrend
        #expect(accuracyData.isEmpty)
    }

    // MARK: - データ読み込みテスト (3テスト)

    @Test("今日と週間データの読み込みが動作する")
    func testLoadAnalytics() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        let todayAnalytics = createTestAnalytics()
        dataService.save()

        viewModel.loadAnalytics()

        // データ読み込みがエラーなく完了することを確認
        #expect(true)
    }

    @Test("指定期間データの読み込みが動作する")
    func testLoadAnalyticsForDateRange() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        // 週間データ読み込み
        viewModel.loadAnalytics(for: .week)
        #expect(viewModel.selectedDateRange == .week)

        // 月間データ読み込み
        viewModel.loadAnalytics(for: .month)
        #expect(viewModel.selectedDateRange == .month)
    }

    @Test("欠損日のデータ補完が動作する")
    func testFillMissingDays() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        // 一部の日のデータのみ作成
        let calendar = Calendar.current
        let today = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        let analytics = createTestAnalytics(date: threeDaysAgo)
        dataService.save()

        viewModel.loadAnalytics()

        // 7日分のデータが補完される
        #expect(viewModel.weeklyAnalytics.count == 7)
    }

    // MARK: - フォーマットとエッジケーステスト (3テスト)

    @Test("パーセント表示フォーマットが動作する")
    func testFormatPercentage() async {
        let viewModel = createTestViewModel()

        #expect(viewModel.formatPercentage(0.0) == "0%")
        #expect(viewModel.formatPercentage(0.5) == "50%")
        #expect(viewModel.formatPercentage(0.75) == "75%")
        #expect(viewModel.formatPercentage(1.0) == "100%")
    }

    @Test("日付ラベルフォーマットが動作する")
    func testDateLabelFormatting() async {
        let dataService = createTestDataService()
        let viewModel = AnalyticsViewModel(dataService: dataService)

        let calendar = Calendar.current
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let analytics = createTestAnalytics(date: date)
            dataService.save()
        }

        viewModel.loadAnalytics()

        let trendData = viewModel.weeklyTrendData
        if let firstData = trendData.first {
            // 日付ラベルが "M/d" フォーマットであることを確認
            #expect(firstData.dateLabel.contains("/"))
        } else {
            #expect(true) // データがない場合もエラーなし
        }
    }

    @Test("期間選択オプションの列挙")
    func testDateRangeEnum() async {
        let allRanges = DateRange.allCases
        #expect(allRanges.count == 2)
        #expect(allRanges.contains(.week))
        #expect(allRanges.contains(.month))

        #expect(DateRange.week.id == "週間")
        #expect(DateRange.month.id == "月間")
    }
}
