import Foundation

// MARK: - BudgetPredictor

/// 予算超過予測サービス
final class BudgetPredictor: Sendable {

    // MARK: - Budget Prediction

    /// 月末までの予算超過を予測
    func predictBudgetExceedance(
        budget: Budget,
        currentSpent: Double,
        historicalData: [Transaction]
    ) -> BudgetPredictionResult {
        let calendar = Calendar.current
        let now = Date()

        // 残り日数を計算
        let daysRemaining = calendar.dateComponents([.day], from: now, to: budget.endDate).day ?? 0
        let totalDays = calendar.dateComponents([.day], from: budget.startDate, to: budget.endDate).day ?? 1
        let daysPassed = totalDays - daysRemaining

        guard daysPassed > 0 else {
            return BudgetPredictionResult(
                predictedTotal: currentSpent,
                exceedanceAmount: 0,
                exceedanceProbability: 0,
                confidence: 0.3,
                daysRemaining: daysRemaining,
                recommendedDailyBudget: budget.totalAmount / Double(max(totalDays, 1)),
                insights: ["予算期間が始まったばかりです"]
            )
        }

        // 現在のペースを計算
        let dailyAverage = currentSpent / Double(daysPassed)
        let projectedTotal = currentSpent + (dailyAverage * Double(daysRemaining))

        // 履歴データに基づく予測調整
        let historicalFactor = calculateHistoricalFactor(
            historicalData: historicalData,
            daysRemaining: daysRemaining
        )

        let adjustedProjection = projectedTotal * historicalFactor

        // 超過額と確率を計算
        let exceedanceAmount = max(adjustedProjection - budget.totalAmount, 0)
        let exceedanceProbability = calculateExceedanceProbability(
            projected: adjustedProjection,
            budget: budget.totalAmount,
            variance: calculateVariance(historicalData: historicalData)
        )

        // 推奨日次予算
        let remaining = max(budget.totalAmount - currentSpent, 0)
        let recommendedDaily = daysRemaining > 0 ? remaining / Double(daysRemaining) : 0

        // 信頼度
        let confidence = calculatePredictionConfidence(
            daysPassed: daysPassed,
            totalDays: totalDays,
            historicalDataCount: historicalData.count
        )

        // 洞察を生成
        let insights = generatePredictionInsights(
            currentSpent: currentSpent,
            budget: budget.totalAmount,
            projected: adjustedProjection,
            dailyAverage: dailyAverage,
            recommendedDaily: recommendedDaily,
            exceedanceProbability: exceedanceProbability
        )

        return BudgetPredictionResult(
            predictedTotal: adjustedProjection,
            exceedanceAmount: exceedanceAmount,
            exceedanceProbability: exceedanceProbability,
            confidence: confidence,
            daysRemaining: daysRemaining,
            recommendedDailyBudget: recommendedDaily,
            insights: insights
        )
    }

    // MARK: - Category Budget Prediction

    /// カテゴリ別予算予測
    func predictCategoryBudgets(
        budget: Budget,
        transactions: [Transaction],
        categories: [Category]
    ) -> [CategoryBudgetPrediction] {
        let calendar = Calendar.current
        let now = Date()

        let daysRemaining = calendar.dateComponents([.day], from: now, to: budget.endDate).day ?? 0
        let totalDays = calendar.dateComponents([.day], from: budget.startDate, to: budget.endDate).day ?? 1
        let daysPassed = max(totalDays - daysRemaining, 1)

        return categories.compactMap { category in
            let categoryTransactions = transactions.filter {
                $0.category?.id == category.id && $0.type == .expense
            }

            let currentSpent = categoryTransactions.reduce(0) { $0 + $1.amount }
            let categoryBudget = budget.getCategoryBudget(categoryId: category.id)

            guard categoryBudget > 0 else { return nil }

            let dailyAverage = currentSpent / Double(daysPassed)
            let projected = currentSpent + (dailyAverage * Double(daysRemaining))

            let exceedanceAmount = max(projected - categoryBudget, 0)
            let exceedanceProbability = calculateExceedanceProbability(
                projected: projected,
                budget: categoryBudget,
                variance: 0.2  // カテゴリ単位では固定値を使用
            )

            return CategoryBudgetPrediction(
                categoryId: category.id,
                categoryName: category.name,
                currentSpent: currentSpent,
                categoryBudget: categoryBudget,
                predictedTotal: projected,
                exceedanceAmount: exceedanceAmount,
                exceedanceProbability: exceedanceProbability
            )
        }
    }

    // MARK: - Helper Methods

    /// 履歴データに基づく調整係数
    private func calculateHistoricalFactor(
        historicalData: [Transaction],
        daysRemaining: Int
    ) -> Double {
        // 月末に支出が増加する傾向があるかをチェック
        let calendar = Calendar.current

        var endOfMonthSpending: [Double] = []
        var midMonthSpending: [Double] = []

        for transaction in historicalData where transaction.type == .expense {
            let day = calendar.component(.day, from: transaction.date)
            if day >= 25 {
                endOfMonthSpending.append(transaction.amount)
            } else if day >= 10 && day <= 20 {
                midMonthSpending.append(transaction.amount)
            }
        }

        guard !endOfMonthSpending.isEmpty && !midMonthSpending.isEmpty else {
            return 1.0
        }

        let endOfMonthAvg = endOfMonthSpending.reduce(0, +) / Double(endOfMonthSpending.count)
        let midMonthAvg = midMonthSpending.reduce(0, +) / Double(midMonthSpending.count)

        guard midMonthAvg > 0 else { return 1.0 }

        let factor = endOfMonthAvg / midMonthAvg

        // 月末まで残り7日以内で月末の支出増加傾向がある場合に調整
        if daysRemaining <= 7 && factor > 1.0 {
            return min(factor, 1.5)  // 最大50%増まで
        }

        return 1.0
    }

    /// 分散を計算
    private func calculateVariance(historicalData: [Transaction]) -> Double {
        let expenses = historicalData.filter { $0.type == .expense }.map { $0.amount }
        guard expenses.count > 1 else { return 0.2 }

        let mean = expenses.reduce(0, +) / Double(expenses.count)
        let variance = expenses.map { pow($0 - mean, 2) }.reduce(0, +) / Double(expenses.count)

        // 変動係数（CV）を返す
        guard mean > 0 else { return 0.2 }
        return sqrt(variance) / mean
    }

    /// 超過確率を計算
    private func calculateExceedanceProbability(
        projected: Double,
        budget: Double,
        variance: Double
    ) -> Double {
        guard budget > 0 else { return 0 }

        let ratio = projected / budget

        // シンプルなシグモイド関数で確率を計算
        // ratio = 1.0 で 50%、ratio > 1.0 で 50%以上
        let adjustedRatio = (ratio - 1.0) / max(variance, 0.1)
        let probability = 1.0 / (1.0 + exp(-adjustedRatio * 2.0))

        return min(max(probability, 0), 1.0)
    }

    /// 予測の信頼度を計算
    private func calculatePredictionConfidence(
        daysPassed: Int,
        totalDays: Int,
        historicalDataCount: Int
    ) -> Double {
        // 経過日数が多いほど信頼度が高い
        let timeConfidence = Double(daysPassed) / Double(totalDays)

        // 履歴データが多いほど信頼度が高い
        let dataConfidence = min(Double(historicalDataCount) / 100.0, 1.0)

        // 両方を組み合わせ
        return (timeConfidence * 0.6 + dataConfidence * 0.4)
    }

    /// 予測洞察を生成
    private func generatePredictionInsights(
        currentSpent: Double,
        budget: Double,
        projected: Double,
        dailyAverage: Double,
        recommendedDaily: Double,
        exceedanceProbability: Double
    ) -> [String] {
        var insights: [String] = []

        let percentUsed = (currentSpent / budget) * 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0

        // 現在の使用率
        if percentUsed >= 90 {
            insights.append("予算の\(Int(percentUsed))%を使用済みです")
        } else if percentUsed >= 70 {
            insights.append("予算の約\(Int(percentUsed))%を使用しています")
        }

        // 超過予測
        if exceedanceProbability >= 0.8 {
            let overAmount = formatter.string(from: NSNumber(value: projected - budget)) ?? ""
            insights.append("このペースでは約\(overAmount)の超過が予想されます")
        } else if exceedanceProbability >= 0.5 {
            insights.append("予算超過の可能性があります")
        }

        // 日次支出の推奨
        if dailyAverage > recommendedDaily * 1.2 {
            let recommendedStr = formatter.string(from: NSNumber(value: recommendedDaily)) ?? ""
            insights.append("日次支出を\(recommendedStr)以下に抑えることを推奨します")
        }

        if insights.isEmpty {
            insights.append("予算内で順調に推移しています")
        }

        return insights
    }
}

// MARK: - BudgetPredictionResult

struct BudgetPredictionResult: Sendable {
    let predictedTotal: Double
    let exceedanceAmount: Double
    let exceedanceProbability: Double
    let confidence: Double
    let daysRemaining: Int
    let recommendedDailyBudget: Double
    let insights: [String]

    var willExceed: Bool {
        exceedanceProbability >= 0.5
    }

    var riskLevel: AlertLevel {
        switch exceedanceProbability {
        case 0.8...: return .critical
        case 0.6..<0.8: return .warning
        case 0.4..<0.6: return .caution
        default: return .normal
        }
    }

    var formattedPredictedTotal: String {
        formatCurrency(predictedTotal)
    }

    var formattedExceedance: String {
        formatCurrency(exceedanceAmount)
    }

    var formattedRecommendedDaily: String {
        formatCurrency(recommendedDailyBudget)
    }

    var probabilityPercentage: String {
        String(format: "%.0f%%", exceedanceProbability * 100)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

// MARK: - CategoryBudgetPrediction

struct CategoryBudgetPrediction: Sendable, Identifiable {
    var id: UUID { categoryId }
    let categoryId: UUID
    let categoryName: String
    let currentSpent: Double
    let categoryBudget: Double
    let predictedTotal: Double
    let exceedanceAmount: Double
    let exceedanceProbability: Double

    var willExceed: Bool {
        exceedanceProbability >= 0.5
    }

    var usagePercentage: Double {
        guard categoryBudget > 0 else { return 0 }
        return (currentSpent / categoryBudget) * 100
    }

    var formattedCurrentSpent: String {
        formatCurrency(currentSpent)
    }

    var formattedBudget: String {
        formatCurrency(categoryBudget)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}
