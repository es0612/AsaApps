import Foundation

// MARK: - SpendingPatternAnalyzer

/// 支出パターンを分析するサービス
final class SpendingPatternAnalyzer: Sendable {

    // MARK: - Pattern Analysis

    /// 支出パターンを分析
    func analyzePatterns(transactions: [Transaction]) -> [SpendingPattern] {
        var patterns: [SpendingPattern] = []

        let expenses = transactions.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return patterns }

        // トレンドパターンを検出
        if let trendPattern = detectTrendPattern(expenses: expenses) {
            patterns.append(trendPattern)
        }

        // 時間帯パターンを検出
        if let timePattern = detectTimePattern(expenses: expenses) {
            patterns.append(timePattern)
        }

        // 曜日パターンを検出
        if let weekdayPattern = detectWeekdayPattern(expenses: expenses) {
            patterns.append(weekdayPattern)
        }

        // 月内パターンを検出
        if let monthPattern = detectMonthPattern(expenses: expenses) {
            patterns.append(monthPattern)
        }

        return patterns.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Trend Detection

    /// トレンド（増加/減少/安定）を検出
    private func detectTrendPattern(expenses: [Transaction]) -> SpendingPattern? {
        let calendar = Calendar.current
        let now = Date()

        // 週別に集計
        var weeklyTotals: [(week: Int, total: Double)] = []

        for weekOffset in 0..<8 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }
            let weekKey = calendar.component(.weekOfYear, from: weekStart)

            let weekTotal = expenses
                .filter { calendar.component(.weekOfYear, from: $0.date) == weekKey }
                .reduce(0) { $0 + $1.amount }

            weeklyTotals.append((weekKey, weekTotal))
        }

        guard weeklyTotals.count >= 4 else { return nil }

        // トレンドの傾きを計算
        let totals = weeklyTotals.map { $0.total }
        let slope = calculateTrendSlope(values: totals)
        let average = totals.reduce(0, +) / Double(totals.count)

        guard average > 0 else { return nil }

        let normalizedSlope = slope / average

        let patternType: PatternType
        let description: String
        let confidence: Double

        if normalizedSlope > 0.1 {
            patternType = .increasing
            description = "支出が週ごとに増加傾向にあります（約\(Int(normalizedSlope * 100))%/週）"
            confidence = min(abs(normalizedSlope) * 3, 0.95)
        } else if normalizedSlope < -0.1 {
            patternType = .decreasing
            description = "支出が週ごとに減少傾向にあります（約\(Int(abs(normalizedSlope) * 100))%/週）"
            confidence = min(abs(normalizedSlope) * 3, 0.95)
        } else {
            patternType = .stable
            description = "支出は安定しています"
            confidence = 0.7
        }

        let stdDev = calculateStdDev(totals)
        let volatility = average > 0 ? stdDev / average : 0

        return SpendingPattern(
            patternType: patternType,
            description: description,
            confidence: confidence,
            metrics: PatternMetrics(
                averageAmount: average,
                standardDeviation: stdDev,
                trendSlope: slope,
                volatility: volatility,
                sampleSize: expenses.count
            )
        )
    }

    // MARK: - Time Pattern Detection

    /// 時間帯パターンを検出
    private func detectTimePattern(expenses: [Transaction]) -> SpendingPattern? {
        var hourCounts = Array(repeating: 0, count: 24)
        var hourAmounts = Array(repeating: 0.0, count: 24)

        for expense in expenses {
            let hour = expense.hourOfDay
            hourCounts[hour] += 1
            hourAmounts[hour] += expense.amount
        }

        // ピーク時間帯を特定
        let peakHour = hourAmounts.enumerated().max { $0.element < $1.element }?.offset ?? 12
        let totalAmount = hourAmounts.reduce(0, +)
        let peakPercentage = totalAmount > 0 ? (hourAmounts[peakHour] / totalAmount) * 100 : 0

        guard peakPercentage >= 20 else { return nil }

        let timeDescription: String
        switch peakHour {
        case 6..<9:
            timeDescription = "朝（\(peakHour)時台）"
        case 9..<12:
            timeDescription = "午前（\(peakHour)時台）"
        case 12..<14:
            timeDescription = "昼食時（\(peakHour)時台）"
        case 14..<17:
            timeDescription = "午後（\(peakHour)時台）"
        case 17..<20:
            timeDescription = "夕方（\(peakHour)時台）"
        case 20..<24:
            timeDescription = "夜（\(peakHour)時台）"
        default:
            timeDescription = "深夜・早朝（\(peakHour)時台）"
        }

        return SpendingPattern(
            patternType: .irregular,
            description: "支出は\(timeDescription)に集中しています（\(Int(peakPercentage))%）",
            confidence: min(peakPercentage / 50, 0.9),
            metrics: PatternMetrics(
                averageAmount: hourAmounts[peakHour] / max(Double(hourCounts[peakHour]), 1),
                peakHour: peakHour,
                sampleSize: expenses.count
            )
        )
    }

    // MARK: - Weekday Pattern Detection

    /// 曜日パターン（週末/平日集中）を検出
    private func detectWeekdayPattern(expenses: [Transaction]) -> SpendingPattern? {
        var weekdayTotal = 0.0
        var weekendTotal = 0.0

        for expense in expenses {
            let dayOfWeek = expense.dayOfWeek  // 1=日曜, 7=土曜
            if dayOfWeek == 1 || dayOfWeek == 7 {
                weekendTotal += expense.amount
            } else {
                weekdayTotal += expense.amount
            }
        }

        let total = weekdayTotal + weekendTotal
        guard total > 0 else { return nil }

        let weekendPercentage = (weekendTotal / total) * 100
        let weekdayPercentage = (weekdayTotal / total) * 100

        // 正規化（平日5日、週末2日）
        let normalizedWeekday = weekdayTotal / 5
        let normalizedWeekend = weekendTotal / 2

        let patternType: PatternType
        let description: String
        let confidence: Double

        if normalizedWeekend > normalizedWeekday * 1.5 {
            patternType = .weekendHeavy
            description = "週末の支出が平日より\(Int((normalizedWeekend / normalizedWeekday - 1) * 100))%多くなっています"
            confidence = min((normalizedWeekend / normalizedWeekday - 1) * 0.5 + 0.5, 0.9)
        } else if normalizedWeekday > normalizedWeekend * 1.5 {
            patternType = .weekdayHeavy
            description = "平日の支出が週末より\(Int((normalizedWeekday / normalizedWeekend - 1) * 100))%多くなっています"
            confidence = min((normalizedWeekday / normalizedWeekend - 1) * 0.5 + 0.5, 0.9)
        } else {
            return nil  // 特徴的なパターンなし
        }

        return SpendingPattern(
            patternType: patternType,
            description: description,
            confidence: confidence,
            metrics: PatternMetrics(
                averageAmount: total / Double(expenses.count),
                sampleSize: expenses.count
            )
        )
    }

    // MARK: - Month Pattern Detection

    /// 月内パターン（月末集中など）を検出
    private func detectMonthPattern(expenses: [Transaction]) -> SpendingPattern? {
        let calendar = Calendar.current

        var earlyMonth = 0.0      // 1-10日
        var midMonth = 0.0        // 11-20日
        var lateMonth = 0.0       // 21-31日

        for expense in expenses {
            let day = calendar.component(.day, from: expense.date)
            switch day {
            case 1...10:
                earlyMonth += expense.amount
            case 11...20:
                midMonth += expense.amount
            default:
                lateMonth += expense.amount
            }
        }

        let total = earlyMonth + midMonth + lateMonth
        guard total > 0 else { return nil }

        // 正規化（各期間の日数で割る）
        let normalizedEarly = earlyMonth / 10
        let normalizedMid = midMonth / 10
        let normalizedLate = lateMonth / 11

        let maxNormalized = max(normalizedEarly, normalizedMid, normalizedLate)
        let avgNormalized = (normalizedEarly + normalizedMid + normalizedLate) / 3

        guard avgNormalized > 0 else { return nil }

        let deviation = (maxNormalized - avgNormalized) / avgNormalized

        guard deviation >= 0.3 else { return nil }  // 30%以上の偏りがある場合のみ

        let patternType: PatternType
        let description: String

        if normalizedLate == maxNormalized {
            patternType = .endOfMonth
            description = "月末（21日以降）に支出が集中しています"
        } else if normalizedEarly == maxNormalized {
            description = "月初（1-10日）に支出が集中しています"
            patternType = .irregular
        } else {
            description = "月中（11-20日）に支出が集中しています"
            patternType = .irregular
        }

        let peakDay: Int
        if normalizedLate == maxNormalized {
            peakDay = 25
        } else if normalizedEarly == maxNormalized {
            peakDay = 5
        } else {
            peakDay = 15
        }

        return SpendingPattern(
            patternType: patternType,
            description: description,
            confidence: min(deviation + 0.5, 0.9),
            metrics: PatternMetrics(
                averageAmount: total / Double(expenses.count),
                peakDay: peakDay,
                sampleSize: expenses.count
            )
        )
    }

    // MARK: - Helper Methods

    private func calculateTrendSlope(values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }

        let n = Double(values.count)
        let indices = Array(0..<values.count).map { Double($0) }

        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map { $0 * $1 }.reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return 0 }

        return (n * sumXY - sumX * sumY) / denominator
    }

    private func calculateStdDev(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}

// MARK: - Heatmap Generation

extension SpendingPatternAnalyzer {
    /// 曜日×時間帯のヒートマップデータを生成
    func generateWeeklyHeatmap(transactions: [Transaction]) -> WeeklyHeatmapData {
        var data = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)
        var maxValue = 0.0
        var totalCount = 0

        for transaction in transactions where transaction.type == .expense {
            let weekday = transaction.dayOfWeek - 1  // 0-6に変換
            let hour = transaction.hourOfDay

            data[weekday][hour] += transaction.amount
            maxValue = max(maxValue, data[weekday][hour])
            totalCount += 1
        }

        return WeeklyHeatmapData(
            data: data,
            maxValue: maxValue,
            totalTransactions: totalCount
        )
    }
}
