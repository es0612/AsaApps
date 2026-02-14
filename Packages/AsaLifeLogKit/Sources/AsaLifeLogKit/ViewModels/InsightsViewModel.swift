import Foundation

// MARK: - InsightsViewModel

/// インサイト表示のViewModel
///
/// 日次/週次サマリー、パターン検出、朝活スコアを管理する。
@MainActor @Observable
public final class InsightsViewModel {
    // MARK: - Dependencies

    private let dataService: any LifeLogDataServiceProtocol
    private let insightsEngine: any InsightsEngineProtocol

    // MARK: - Properties

    public var dailyInsight: DailyInsightResult?
    public var weeklyInsight: WeeklyInsightResult?
    public var patterns: [PatternResult] = []
    public var morningScore: Int = 0
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Init

    public init(
        dataService: any LifeLogDataServiceProtocol,
        insightsEngine: any InsightsEngineProtocol
    ) {
        self.dataService = dataService
        self.insightsEngine = insightsEngine
    }

    // MARK: - Methods

    /// 本日のインサイトを生成する
    public func generateTodayInsights() async {
        isLoading = true
        errorMessage = nil
        do {
            let entries = try await dataService.fetchEntries(for: Date())
            let preferences = try await dataService.fetchOrCreatePreferences()

            dailyInsight = insightsEngine.generateDailyInsight(
                entries: entries,
                date: Date(),
                preferences: preferences
            )
            morningScore = insightsEngine.calculateMorningScore(
                entries: entries,
                preferences: preferences
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 週次インサイトを生成する
    public func generateWeeklyInsights() async {
        isLoading = true
        errorMessage = nil
        do {
            let calendar = Calendar.current
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            // 月曜日を週の開始日とする
            let daysToSubtract = (weekday + 5) % 7
            guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
                return
            }
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { return }

            let entries = try await dataService.fetchEntries(from: weekStart, to: weekEnd)
            weeklyInsight = insightsEngine.generateWeeklyInsight(
                entries: entries,
                weekStart: weekStart
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// パターンを検出する
    public func detectPatterns() async {
        isLoading = true
        errorMessage = nil
        do {
            let calendar = Calendar.current
            guard let startDate = calendar.date(byAdding: .day, value: -30, to: Date()) else { return }
            let entries = try await dataService.fetchEntries(from: startDate, to: Date())
            patterns = insightsEngine.detectPatterns(entries: entries)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
