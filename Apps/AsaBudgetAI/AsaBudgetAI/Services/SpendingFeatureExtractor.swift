import Foundation

// MARK: - SpendingFeatureExtractor

/// 支出データから特徴量を抽出するサービス
final class SpendingFeatureExtractor: Sendable {

    // MARK: - Feature Extraction

    /// 単一取引の特徴量を抽出
    func extractFeatures(
        transaction: Transaction,
        historicalData: [Transaction],
        categoryStats: [UUID: CategoryHistoricalStats]
    ) -> SpendingFeatures {
        let categoryScore = calculateCategoryPatternScore(
            transaction: transaction,
            categoryStats: categoryStats
        )

        let amountScore = calculateAmountDeviationScore(
            transaction: transaction,
            historicalData: historicalData
        )

        let timeScore = calculateTimePatternScore(
            transaction: transaction,
            historicalData: historicalData
        )

        let frequencyScore = calculateFrequencyScore(
            transaction: transaction,
            historicalData: historicalData
        )

        let trendScore = calculateHistoricalTrendScore(
            transaction: transaction,
            historicalData: historicalData
        )

        let seasonalScore = calculateSeasonalScore(
            transaction: transaction,
            historicalData: historicalData
        )

        return SpendingFeatures(
            categoryPatternScore: categoryScore,
            amountDeviationScore: amountScore,
            timePatternScore: timeScore,
            frequencyScore: frequencyScore,
            historicalTrendScore: trendScore,
            seasonalScore: seasonalScore
        )
    }

    // MARK: - Category Pattern Score

    /// カテゴリパターンスコア：カテゴリ別の通常支出との乖離度
    private func calculateCategoryPatternScore(
        transaction: Transaction,
        categoryStats: [UUID: CategoryHistoricalStats]
    ) -> Double {
        guard let categoryId = transaction.category?.id,
              let stats = categoryStats[categoryId] else {
            // カテゴリ情報がない場合は中程度のスコア
            return 0.5
        }

        // Zスコアを計算
        let zScore = stats.standardDeviation > 0
            ? abs(transaction.amount - stats.averageAmount) / stats.standardDeviation
            : 0

        // Zスコアを0-1に正規化（3σ以上を1.0とする）
        return min(zScore / 3.0, 1.0)
    }

    // MARK: - Amount Deviation Score

    /// 金額偏差スコア：過去平均からの金額乖離（Zスコア）
    private func calculateAmountDeviationScore(
        transaction: Transaction,
        historicalData: [Transaction]
    ) -> Double {
        let expenseData = historicalData.filter { $0.type == .expense }
        guard expenseData.count >= 5 else { return 0.3 }

        let amounts = expenseData.map { $0.amount }
        let mean = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)
        let stdDev = sqrt(variance)

        guard stdDev > 0 else { return 0 }

        let zScore = abs(transaction.amount - mean) / stdDev

        // 高額支出ほど高スコア（Zスコア2以上で0.7、3以上で1.0）
        if zScore >= 3.0 { return 1.0 }
        if zScore >= 2.0 { return 0.7 + (zScore - 2.0) * 0.3 }
        if zScore >= 1.0 { return 0.4 + (zScore - 1.0) * 0.3 }
        return zScore * 0.4
    }

    // MARK: - Time Pattern Score

    /// 時間パターンスコア：通常の支出時間帯との乖離
    private func calculateTimePatternScore(
        transaction: Transaction,
        historicalData: [Transaction]
    ) -> Double {
        let hour = transaction.hourOfDay
        let dayOfWeek = transaction.dayOfWeek

        // 時間帯別の支出頻度を計算
        var hourFrequency = Array(repeating: 0, count: 24)
        var dayFrequency = Array(repeating: 0, count: 7)

        for t in historicalData where t.type == .expense {
            hourFrequency[t.hourOfDay] += 1
            dayFrequency[t.dayOfWeek - 1] += 1  // 1-7 → 0-6
        }

        let totalTransactions = historicalData.filter { $0.type == .expense }.count
        guard totalTransactions > 0 else { return 0.3 }

        // 通常時間帯からの乖離度を計算
        let hourProbability = Double(hourFrequency[hour]) / Double(totalTransactions)
        let dayProbability = Double(dayFrequency[dayOfWeek - 1]) / Double(totalTransactions)

        // 低頻度の時間帯ほど高スコア
        let hourScore = 1.0 - min(hourProbability * 10, 1.0)
        let dayScore = 1.0 - min(dayProbability * 5, 1.0)

        return (hourScore * 0.6 + dayScore * 0.4)
    }

    // MARK: - Frequency Score

    /// 頻度スコア：通常の支出頻度との乖離
    private func calculateFrequencyScore(
        transaction: Transaction,
        historicalData: [Transaction]
    ) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: transaction.date)

        // 過去7日間の支出回数を計算
        let recentTransactions = historicalData.filter { t in
            guard t.type == .expense else { return false }
            let transactionDate = calendar.startOfDay(for: t.date)
            let daysDiff = calendar.dateComponents([.day], from: transactionDate, to: today).day ?? 0
            return daysDiff >= 0 && daysDiff < 7
        }

        // 1日あたりの平均支出回数
        let dailyAverage = Double(recentTransactions.count) / 7.0

        // 今日の支出回数
        let todayCount = historicalData.filter { t in
            guard t.type == .expense else { return false }
            return calendar.isDate(t.date, inSameDayAs: transaction.date)
        }.count

        // 平均からの乖離度
        guard dailyAverage > 0 else { return 0.3 }
        let deviation = Double(todayCount) / dailyAverage

        // 通常の2倍以上の頻度で高スコア
        if deviation >= 3.0 { return 1.0 }
        if deviation >= 2.0 { return 0.7 + (deviation - 2.0) * 0.3 }
        if deviation >= 1.5 { return 0.4 + (deviation - 1.5) * 0.6 }
        return deviation * 0.3
    }

    // MARK: - Historical Trend Score

    /// 履歴トレンドスコア：過去の支出傾向との整合性
    private func calculateHistoricalTrendScore(
        transaction: Transaction,
        historicalData: [Transaction]
    ) -> Double {
        guard transaction.type == .expense else { return 0 }

        // 過去3ヶ月のトレンドを計算
        let calendar = Calendar.current
        let now = transaction.date

        var monthlyTotals: [Double] = []
        for monthOffset in 1...3 {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                continue
            }

            let monthTotal = historicalData
                .filter { t in
                    t.type == .expense &&
                    t.date >= monthStart &&
                    t.date < monthEnd
                }
                .reduce(0) { $0 + $1.amount }

            monthlyTotals.append(monthTotal)
        }

        guard monthlyTotals.count >= 2 else { return 0.3 }

        // トレンドの傾き（月次変化率）を計算
        let averageChange = zip(monthlyTotals.dropFirst(), monthlyTotals).map { $0 - $1 }.reduce(0, +) / Double(monthlyTotals.count - 1)

        let averageMonthly = monthlyTotals.reduce(0, +) / Double(monthlyTotals.count)
        guard averageMonthly > 0 else { return 0.3 }

        let trendRate = averageChange / averageMonthly

        // 増加トレンドで高スコア（20%以上の増加で0.7、50%以上で1.0）
        if trendRate >= 0.5 { return 1.0 }
        if trendRate >= 0.2 { return 0.7 + (trendRate - 0.2) }
        if trendRate >= 0 { return 0.3 + trendRate * 2.0 }
        return max(0, 0.3 + trendRate)  // 減少トレンドは低スコア
    }

    // MARK: - Seasonal Score

    /// 季節変動スコア：季節的な支出パターンの考慮
    private func calculateSeasonalScore(
        transaction: Transaction,
        historicalData: [Transaction]
    ) -> Double {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: transaction.date)

        // 同じ月の過去の支出を取得
        let sameMonthTransactions = historicalData.filter { t in
            t.type == .expense &&
            calendar.component(.month, from: t.date) == currentMonth
        }

        guard sameMonthTransactions.count >= 3 else { return 0.3 }

        // 季節の平均支出
        let seasonalAverage = sameMonthTransactions.map { $0.amount }.reduce(0, +) / Double(sameMonthTransactions.count)

        // 全期間の平均支出
        let allExpenses = historicalData.filter { $0.type == .expense }
        guard allExpenses.count > 0 else { return 0.3 }
        let overallAverage = allExpenses.map { $0.amount }.reduce(0, +) / Double(allExpenses.count)

        guard overallAverage > 0 else { return 0.3 }

        // 季節性の影響度（季節平均が全体平均からどれだけ乖離しているか）
        let seasonalImpact = abs(seasonalAverage - overallAverage) / overallAverage

        // 取引が季節平均からどれだけ乖離しているか
        let transactionDeviation = abs(transaction.amount - seasonalAverage) / max(seasonalAverage, 1)

        // 季節性が高い月で平均から大きく外れている場合に高スコア
        return min(seasonalImpact * transactionDeviation, 1.0)
    }
}

// MARK: - CategoryHistoricalStats

/// カテゴリ別の履歴統計
struct CategoryHistoricalStats: Sendable {
    let categoryId: UUID
    let transactionCount: Int
    let totalAmount: Double
    let averageAmount: Double
    let standardDeviation: Double
    let minAmount: Double
    let maxAmount: Double

    init(categoryId: UUID, transactions: [Transaction]) {
        self.categoryId = categoryId
        self.transactionCount = transactions.count

        let amounts = transactions.map { $0.amount }
        let total = amounts.reduce(0, +)
        let average = amounts.isEmpty ? 0 : total / Double(amounts.count)

        self.totalAmount = total
        self.averageAmount = average
        self.minAmount = amounts.min() ?? 0
        self.maxAmount = amounts.max() ?? 0

        // 標準偏差を計算（ローカル変数を使用してselfのキャプチャを避ける）
        if amounts.count > 1 {
            let variance = amounts.map { pow($0 - average, 2) }.reduce(0, +) / Double(amounts.count)
            self.standardDeviation = sqrt(variance)
        } else {
            self.standardDeviation = 0
        }
    }
}

// MARK: - SpendingFeatureExtractor Extension

extension SpendingFeatureExtractor {
    /// カテゴリ別統計を生成
    func generateCategoryStats(from transactions: [Transaction]) -> [UUID: CategoryHistoricalStats] {
        var stats: [UUID: CategoryHistoricalStats] = [:]

        // カテゴリごとにグループ化
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expense }) { t in
            t.category?.id ?? UUID()
        }

        for (categoryId, categoryTransactions) in grouped {
            stats[categoryId] = CategoryHistoricalStats(
                categoryId: categoryId,
                transactions: categoryTransactions
            )
        }

        return stats
    }
}
