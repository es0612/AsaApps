import Foundation

// MARK: - InsightsEngineProtocol

/// インサイト分析エンジンプロトコル
///
/// ライフログデータからヒューリスティック分析を行い、
/// 日次/週次インサイト・朝活スコア・パターン検出を提供する。
@MainActor
public protocol InsightsEngineProtocol: Sendable {
    /// 日次インサイトを生成する
    func generateDailyInsight(
        entries: [LifeLogEntry],
        date: Date,
        preferences: UserPreferences
    ) -> DailyInsightResult

    /// 週次インサイトを生成する
    func generateWeeklyInsight(
        entries: [LifeLogEntry],
        weekStart: Date
    ) -> WeeklyInsightResult

    /// 朝活スコアを計算する（0〜100）
    func calculateMorningScore(
        entries: [LifeLogEntry],
        preferences: UserPreferences
    ) -> Int

    /// エントリーからパターンを検出する
    func detectPatterns(entries: [LifeLogEntry]) -> [PatternResult]
}
