import Foundation

// MARK: - WeeklySummaryGenerator

/// 週次サマリー生成サービス
///
/// InsightsEngine を使って1週間のエントリーからサマリーを生成する。
@MainActor
@Observable
public final class WeeklySummaryGenerator {
    private let insightsEngine: any InsightsEngineProtocol

    // MARK: - Init

    public init(insightsEngine: any InsightsEngineProtocol) {
        self.insightsEngine = insightsEngine
    }

    // MARK: - Methods

    /// 週次サマリーを生成する
    public func generate(
        entries: [LifeLogEntry],
        weekStartDate: Date,
        previousWeekEntries: [LifeLogEntry]? = nil
    ) -> WeeklySummary {
        let insight = insightsEngine.generateWeeklyInsight(
            entries: entries,
            weekStart: weekStartDate
        )

        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate

        // 気分平均
        let moodValues = entries.compactMap { $0.moodScore?.numericValue }
        let averageMood = moodValues.isEmpty ? nil :
            Double(moodValues.reduce(0, +)) / Double(moodValues.count)

        // 合計歩数
        let totalSteps = Int(entries
            .filter { $0.healthMetricTypeRawValue == "steps" }
            .compactMap { $0.healthMetricValue }
            .reduce(0.0, +))

        // 平均睡眠時間
        let sleepValues = entries
            .filter { $0.healthMetricTypeRawValue == "sleep" }
            .compactMap { $0.healthMetricValue }
        let averageSleep = sleepValues.isEmpty ? nil :
            sleepValues.reduce(0.0, +) / Double(sleepValues.count)

        // 前週比較テキスト
        let comparisonText = generateComparisonText(
            currentEntries: entries,
            previousEntries: previousWeekEntries
        )

        return WeeklySummary(
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            entryCount: entries.count,
            averageMood: averageMood,
            totalSteps: totalSteps,
            averageSleepHours: averageSleep,
            topTags: insight.topTags,
            trendInsight: insight.summaryText,
            comparisonWithPreviousWeek: comparisonText
        )
    }

    // MARK: - Private

    /// 前週との比較テキストを生成する
    private func generateComparisonText(
        currentEntries: [LifeLogEntry],
        previousEntries: [LifeLogEntry]?
    ) -> String? {
        guard let previous = previousEntries, !previous.isEmpty else { return nil }

        let currentCount = currentEntries.count
        let previousCount = previous.count
        let diff = currentCount - previousCount

        var parts: [String] = []

        if diff > 0 {
            parts.append("記録数が前週より\(diff)件増えました")
        } else if diff < 0 {
            parts.append("記録数が前週より\(abs(diff))件減りました")
        } else {
            parts.append("記録数は前週と同じです")
        }

        // 気分比較
        let currentMoods = currentEntries.compactMap { $0.moodScore?.numericValue }
        let previousMoods = previous.compactMap { $0.moodScore?.numericValue }

        if !currentMoods.isEmpty && !previousMoods.isEmpty {
            let currentAvg = Double(currentMoods.reduce(0, +)) / Double(currentMoods.count)
            let previousAvg = Double(previousMoods.reduce(0, +)) / Double(previousMoods.count)
            let moodDiff = currentAvg - previousAvg

            if moodDiff > 0.3 {
                parts.append("気分は前週より改善しています")
            } else if moodDiff < -0.3 {
                parts.append("気分はやや低下しています")
            }
        }

        return parts.joined(separator: "。") + "。"
    }
}
