import Foundation

// MARK: - InsightsEngine

/// ヒューリスティック分析エンジン
///
/// 朝活スコア計算、気分と活動の相関分析、パターン検出などを行う。
@MainActor
@Observable
public final class InsightsEngine: InsightsEngineProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - InsightsEngineProtocol

    public func generateDailyInsight(
        entries: [LifeLogEntry],
        date: Date,
        preferences: UserPreferences
    ) -> DailyInsightResult {
        let morningScore = calculateMorningScore(entries: entries, preferences: preferences)
        let summaryText = buildDailySummaryText(entries: entries, morningScore: morningScore)
        let highlightEntry = findHighlightEntry(entries: entries)
        let suggestions = generateSuggestions(entries: entries, morningScore: morningScore)

        return DailyInsightResult(
            date: date,
            summaryText: summaryText,
            morningScore: morningScore,
            highlightEntryId: highlightEntry?.id,
            suggestions: suggestions
        )
    }

    public func generateWeeklyInsight(
        entries: [LifeLogEntry],
        weekStart: Date
    ) -> WeeklyInsightResult {
        let topTags = extractTopTags(entries: entries, limit: 5)
        let moodTrend = analyzeMoodTrend(entries: entries)
        let summaryText = buildWeeklySummaryText(
            entries: entries,
            topTags: topTags,
            moodTrend: moodTrend
        )

        return WeeklyInsightResult(
            weekStartDate: weekStart,
            summaryText: summaryText,
            topTags: topTags,
            moodTrend: moodTrend
        )
    }

    public func calculateMorningScore(
        entries: [LifeLogEntry],
        preferences: UserPreferences
    ) -> Int {
        let calendar = Calendar.current
        let startHour = preferences.morningRoutineStartHour
        let endHour = preferences.morningRoutineEndHour

        // 朝活時間帯のエントリーを抽出
        let morningEntries = entries.filter { entry in
            let hour = calendar.component(.hour, from: entry.timestamp)
            return hour >= startHour && hour < endHour
        }

        guard !morningEntries.isEmpty else { return 0 }

        // エントリー密度スコア（最大50点）
        let densityScore = min(morningEntries.count * 15, 50)

        // 気分スコア（最大30点）
        let moodValues = morningEntries.compactMap { $0.moodScore?.numericValue }
        let moodScore: Int
        if !moodValues.isEmpty {
            let average = Double(moodValues.reduce(0, +)) / Double(moodValues.count)
            moodScore = Int(average * 6.0) // 最大30点
        } else {
            moodScore = 15 // デフォルト中間値
        }

        // 多様性スコア（最大20点）
        let uniqueTypes = Set(morningEntries.map { $0.entryType })
        let diversityScore = min(uniqueTypes.count * 5, 20)

        return min(densityScore + moodScore + diversityScore, 100)
    }

    public func detectPatterns(entries: [LifeLogEntry]) -> [PatternResult] {
        var patterns: [PatternResult] = []

        // パターン1: 気分と活動量の相関
        if let moodActivityPattern = detectMoodActivityCorrelation(entries: entries) {
            patterns.append(moodActivityPattern)
        }

        // パターン2: よく使うタグパターン
        if let tagPattern = detectFrequentTagPattern(entries: entries) {
            patterns.append(tagPattern)
        }

        // パターン3: 時間帯パターン
        if let timePattern = detectTimePattern(entries: entries) {
            patterns.append(timePattern)
        }

        // パターン4: 場所パターン
        if let placePattern = detectPlacePattern(entries: entries) {
            patterns.append(placePattern)
        }

        return patterns
    }

    // MARK: - Private: 日次インサイト

    private func buildDailySummaryText(entries: [LifeLogEntry], morningScore: Int) -> String {
        let entryCount = entries.count
        let moodEntries = entries.compactMap { $0.moodScore }
        let averageMood = moodEntries.isEmpty ? nil :
            Double(moodEntries.map { $0.numericValue }.reduce(0, +)) / Double(moodEntries.count)

        var parts: [String] = []
        parts.append("本日は\(entryCount)件の記録があります")

        if let mood = averageMood {
            let moodText = mood >= 4.0 ? "良好" : mood >= 3.0 ? "普通" : "やや低め"
            parts.append("気分は\(moodText)です")
        }

        if morningScore >= 70 {
            parts.append("朝活スコアが高く、充実した朝を過ごせました")
        } else if morningScore >= 40 {
            parts.append("朝の活動はまずまずです")
        }

        return parts.joined(separator: "。") + "。"
    }

    private func findHighlightEntry(entries: [LifeLogEntry]) -> LifeLogEntry? {
        // お気に入りのエントリーを優先
        if let favorite = entries.first(where: { $0.isFavorite }) {
            return favorite
        }
        // 気分が最高のエントリーを選択
        return entries.filter { $0.moodScore != nil }
            .max { ($0.moodScore?.numericValue ?? 0) < ($1.moodScore?.numericValue ?? 0) }
    }

    private func generateSuggestions(entries: [LifeLogEntry], morningScore: Int) -> [String] {
        var suggestions: [String] = []

        if morningScore < 30 {
            suggestions.append("明日は早起きして朝活に挑戦してみましょう")
        }

        let moodEntries = entries.compactMap { $0.moodScore }
        if moodEntries.isEmpty {
            suggestions.append("気分を記録して、自分の調子を把握しましょう")
        }

        if entries.filter({ $0.entryType == .photo }).isEmpty {
            suggestions.append("写真を撮って思い出を残しましょう")
        }

        return suggestions
    }

    // MARK: - Private: 週次インサイト

    private func extractTopTags(entries: [LifeLogEntry], limit: Int) -> [String] {
        var tagCounts: [String: Int] = [:]
        for entry in entries {
            for tag in entry.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        return tagCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    private func analyzeMoodTrend(entries: [LifeLogEntry]) -> String {
        let moodEntries = entries.compactMap { $0.moodScore }
        guard moodEntries.count >= 2 else { return "データ不足" }

        let midpoint = moodEntries.count / 2
        let firstHalf = Array(moodEntries.prefix(midpoint))
        let secondHalf = Array(moodEntries.suffix(from: midpoint))

        let firstAvg = Double(firstHalf.map { $0.numericValue }.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.map { $0.numericValue }.reduce(0, +)) / Double(secondHalf.count)

        if secondAvg - firstAvg > 0.5 {
            return "上昇傾向"
        } else if firstAvg - secondAvg > 0.5 {
            return "下降傾向"
        } else {
            return "安定"
        }
    }

    private func buildWeeklySummaryText(
        entries: [LifeLogEntry],
        topTags: [String],
        moodTrend: String
    ) -> String {
        var parts: [String] = []
        parts.append("今週は\(entries.count)件の記録がありました")
        parts.append("気分のトレンドは「\(moodTrend)」です")

        if !topTags.isEmpty {
            let tagText = topTags.prefix(3).joined(separator: "、")
            parts.append("よく使われたタグ: \(tagText)")
        }

        return parts.joined(separator: "。") + "。"
    }

    // MARK: - Private: パターン検出

    private func detectMoodActivityCorrelation(entries: [LifeLogEntry]) -> PatternResult? {
        let activityEntries = entries.filter { $0.activityType != nil && $0.moodScore != nil }
        guard activityEntries.count >= 3 else { return nil }

        let activeEntries = activityEntries.filter { $0.activityType != .stationary }
        let activeMoodAvg = activeEntries.isEmpty ? 0.0 :
            Double(activeEntries.compactMap { $0.moodScore?.numericValue }.reduce(0, +)) /
            Double(activeEntries.count)

        let stationaryEntries = activityEntries.filter { $0.activityType == .stationary }
        let stationaryMoodAvg = stationaryEntries.isEmpty ? 0.0 :
            Double(stationaryEntries.compactMap { $0.moodScore?.numericValue }.reduce(0, +)) /
            Double(stationaryEntries.count)

        guard activeMoodAvg > stationaryMoodAvg + 0.3 else { return nil }

        return PatternResult(
            patternType: "mood_activity",
            description: "体を動かしている時の方が気分が良い傾向があります",
            confidence: 0.7
        )
    }

    private func detectFrequentTagPattern(entries: [LifeLogEntry]) -> PatternResult? {
        let topTags = extractTopTags(entries: entries, limit: 3)
        guard !topTags.isEmpty else { return nil }

        return PatternResult(
            patternType: "frequent_tags",
            description: "よく使うタグ: \(topTags.joined(separator: "、"))",
            confidence: 0.8,
            relatedTags: topTags
        )
    }

    private func detectTimePattern(entries: [LifeLogEntry]) -> PatternResult? {
        guard entries.count >= 5 else { return nil }

        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        for entry in entries {
            let hour = calendar.component(.hour, from: entry.timestamp)
            hourCounts[hour, default: 0] += 1
        }

        guard let peakHour = hourCounts.max(by: { $0.value < $1.value }) else { return nil }

        return PatternResult(
            patternType: "time_pattern",
            description: "\(peakHour.key)時台の記録が最も多いです（\(peakHour.value)件）",
            confidence: 0.6
        )
    }

    private func detectPlacePattern(entries: [LifeLogEntry]) -> PatternResult? {
        let locationEntries = entries.filter { $0.locationName != nil }
        guard locationEntries.count >= 3 else { return nil }

        var placeCounts: [String: Int] = [:]
        for entry in locationEntries {
            if let name = entry.locationName {
                placeCounts[name, default: 0] += 1
            }
        }

        guard let topPlace = placeCounts.max(by: { $0.value < $1.value }) else { return nil }

        return PatternResult(
            patternType: "place_pattern",
            description: "「\(topPlace.key)」で最も多く記録しています（\(topPlace.value)件）",
            confidence: 0.7
        )
    }
}
