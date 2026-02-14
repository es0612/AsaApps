import Foundation
@testable import AsaLifeLogKit

// MARK: - MockInsightsEngine

/// テスト用のモックインサイトエンジン
@MainActor
final class MockInsightsEngine: InsightsEngineProtocol {
    var dailyInsightResult: DailyInsightResult?
    var weeklyInsightResult: WeeklyInsightResult?
    var morningScoreResult: Int = 50
    var patternsResult: [PatternResult] = []

    func generateDailyInsight(
        entries: [LifeLogEntry],
        date: Date,
        preferences: UserPreferences
    ) -> DailyInsightResult {
        dailyInsightResult ?? DailyInsightResult(
            date: date,
            summaryText: "テスト日次サマリー",
            morningScore: morningScoreResult,
            suggestions: ["テスト提案"]
        )
    }

    func generateWeeklyInsight(
        entries: [LifeLogEntry],
        weekStart: Date
    ) -> WeeklyInsightResult {
        weeklyInsightResult ?? WeeklyInsightResult(
            weekStartDate: weekStart,
            summaryText: "テスト週次サマリー",
            topTags: ["朝活", "運動"],
            moodTrend: "安定"
        )
    }

    func calculateMorningScore(
        entries: [LifeLogEntry],
        preferences: UserPreferences
    ) -> Int {
        morningScoreResult
    }

    func detectPatterns(entries: [LifeLogEntry]) -> [PatternResult] {
        patternsResult
    }
}
