import Foundation

// MARK: - DashboardViewModel

/// ダッシュボード表示のViewModel
///
/// 日次統計、気分分布、歩数データ、睡眠データ、アクティビティ内訳を管理する。
@MainActor @Observable
public final class DashboardViewModel {
    // MARK: - Dependencies

    private let dataService: any LifeLogDataServiceProtocol
    private let insightsEngine: any InsightsEngineProtocol

    // MARK: - Properties

    public var dailySummary: DailySummary?
    public var moodDistribution: [MoodScore: Int] = [:]
    public var stepsData: [Date: Int] = [:]
    public var sleepData: [Date: Double] = [:]
    public var activityBreakdown: [ActivityType: Int] = [:]
    public var morningScore: Int = 0
    public var selectedPeriod: ChartPeriod = .week
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

    /// ダッシュボードデータを読み込む
    public func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        do {
            let endDate = Date()
            let calendar = Calendar.current
            guard let startDate = calendar.date(
                byAdding: .day,
                value: -selectedPeriod.dayCount,
                to: endDate
            ) else { return }

            let entries = try await dataService.fetchEntries(from: startDate, to: endDate)
            let preferences = try await dataService.fetchOrCreatePreferences()

            // 日次サマリー
            dailySummary = try await dataService.fetchDailySummary(for: Date())

            // 朝活スコア
            let todayEntries = try await dataService.fetchEntries(for: Date())
            morningScore = insightsEngine.calculateMorningScore(
                entries: todayEntries,
                preferences: preferences
            )

            // 気分分布
            calculateMoodDistribution(entries: entries)

            // 歩数データ
            calculateStepsData(entries: entries)

            // 睡眠データ
            calculateSleepData(entries: entries)

            // アクティビティ内訳
            calculateActivityBreakdown(entries: entries)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// チャート期間を変更する
    public func changePeriod(_ period: ChartPeriod) async {
        selectedPeriod = period
        await loadDashboardData()
    }

    // MARK: - Private

    private func calculateMoodDistribution(entries: [LifeLogEntry]) {
        var distribution: [MoodScore: Int] = [:]
        for entry in entries {
            if let mood = entry.moodScore {
                distribution[mood, default: 0] += 1
            }
        }
        moodDistribution = distribution
    }

    private func calculateStepsData(entries: [LifeLogEntry]) {
        let calendar = Calendar.current
        var data: [Date: Int] = [:]
        let stepEntries = entries.filter { $0.healthMetricTypeRawValue == "steps" }
        for entry in stepEntries {
            let day = calendar.startOfDay(for: entry.timestamp)
            data[day, default: 0] += Int(entry.healthMetricValue ?? 0)
        }
        stepsData = data
    }

    private func calculateSleepData(entries: [LifeLogEntry]) {
        let calendar = Calendar.current
        var data: [Date: Double] = [:]
        let sleepEntries = entries.filter { $0.healthMetricTypeRawValue == "sleep" }
        for entry in sleepEntries {
            let day = calendar.startOfDay(for: entry.timestamp)
            data[day] = entry.healthMetricValue ?? 0
        }
        sleepData = data
    }

    private func calculateActivityBreakdown(entries: [LifeLogEntry]) {
        var breakdown: [ActivityType: Int] = [:]
        for entry in entries {
            if let type = entry.activityType {
                breakdown[type, default: 0] += 1
            }
        }
        activityBreakdown = breakdown
    }
}
