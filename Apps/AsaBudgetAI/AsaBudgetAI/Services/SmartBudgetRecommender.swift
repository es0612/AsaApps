import Foundation

// MARK: - SmartBudgetRecommender

/// 過去データから最適な予算を提案するサービス
final class SmartBudgetRecommender: Sendable {

    // MARK: - Budget Recommendation

    /// 月次予算の推奨値を計算
    func recommendMonthlyBudget(
        historicalData: [Transaction],
        targetSavingsRate: Double = 0.2  // 目標貯蓄率 20%
    ) -> MonthlyBudgetRecommendation {
        let calendar = Calendar.current

        // 過去6ヶ月のデータを分析
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let relevantData = historicalData.filter { $0.date >= sixMonthsAgo }

        // 月別の支出を集計
        var monthlyExpenses: [String: Double] = [:]
        var monthlyIncomes: [String: Double] = [:]

        for transaction in relevantData {
            let monthKey = transaction.monthKey

            if transaction.type == .expense {
                monthlyExpenses[monthKey, default: 0] += transaction.amount
            } else {
                monthlyIncomes[monthKey, default: 0] += transaction.amount
            }
        }

        // 統計を計算
        let expenseValues = Array(monthlyExpenses.values)
        let incomeValues = Array(monthlyIncomes.values)

        let avgExpense = expenseValues.isEmpty ? 0 : expenseValues.reduce(0, +) / Double(expenseValues.count)
        let avgIncome = incomeValues.isEmpty ? 0 : incomeValues.reduce(0, +) / Double(incomeValues.count)

        let stdDevExpense = calculateStdDev(expenseValues)

        // 推奨予算を計算
        // 基本: 平均支出 + 1σのバッファ
        let baseRecommendation = avgExpense + stdDevExpense

        // 収入ベースの推奨: 収入 × (1 - 目標貯蓄率)
        let incomeBasedRecommendation = avgIncome * (1 - targetSavingsRate)

        // 両方を考慮した推奨値
        let recommendedBudget: Double
        let recommendationType: MonthlyBudgetRecommendation.RecommendationType

        if avgIncome > 0 {
            // 収入がある場合は収入ベースを優先
            if baseRecommendation <= incomeBasedRecommendation {
                recommendedBudget = baseRecommendation
                recommendationType = .conservative
            } else {
                recommendedBudget = incomeBasedRecommendation
                recommendationType = .savingsTarget
            }
        } else {
            recommendedBudget = baseRecommendation
            recommendationType = .historyBased
        }

        // 信頼度
        let confidence = calculateRecommendationConfidence(
            dataMonths: monthlyExpenses.count,
            variance: stdDevExpense / max(avgExpense, 1)
        )

        return MonthlyBudgetRecommendation(
            recommendedAmount: recommendedBudget,
            averageExpense: avgExpense,
            averageIncome: avgIncome,
            standardDeviation: stdDevExpense,
            targetSavingsRate: targetSavingsRate,
            potentialSavings: max(avgIncome - recommendedBudget, 0),
            recommendationType: recommendationType,
            confidence: confidence,
            dataMonths: monthlyExpenses.count
        )
    }

    // MARK: - Category Budget Recommendation

    /// カテゴリ別予算の推奨
    func recommendCategoryBudgets(
        historicalData: [Transaction],
        totalBudget: Double,
        categories: [Category]
    ) -> [CategoryBudgetRecommendation] {
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()

        // 過去3ヶ月の支出データ
        let relevantData = historicalData.filter {
            $0.date >= threeMonthsAgo && $0.type == .expense
        }

        // カテゴリ別に集計
        var categoryTotals: [UUID: Double] = [:]
        var categoryTransactionCounts: [UUID: Int] = [:]

        for transaction in relevantData {
            guard let categoryId = transaction.category?.id else { continue }
            categoryTotals[categoryId, default: 0] += transaction.amount
            categoryTransactionCounts[categoryId, default: 0] += 1
        }

        let totalSpent = categoryTotals.values.reduce(0, +)
        guard totalSpent > 0 else {
            // データがない場合は均等配分
            let equalShare = totalBudget / Double(max(categories.count, 1))
            return categories.map { category in
                CategoryBudgetRecommendation(
                    categoryId: category.id,
                    categoryName: category.name,
                    recommendedAmount: equalShare,
                    averageSpending: 0,
                    percentageOfTotal: 100 / Double(max(categories.count, 1)),
                    priority: .medium,
                    rationale: "データ不足のため均等配分"
                )
            }
        }

        // 各カテゴリの推奨予算を計算
        return categories.map { category in
            let categorySpent = categoryTotals[category.id] ?? 0
            let percentage = (categorySpent / totalSpent) * 100
            let recommendedAmount = totalBudget * (categorySpent / totalSpent)

            // 月平均
            let monthlyAverage = categorySpent / 3.0

            // 優先度を判定
            let priority = determineCategoryPriority(
                percentage: percentage,
                transactionCount: categoryTransactionCounts[category.id] ?? 0
            )

            let rationale = generateCategoryRationale(
                categoryName: category.name,
                percentage: percentage,
                priority: priority
            )

            return CategoryBudgetRecommendation(
                categoryId: category.id,
                categoryName: category.name,
                recommendedAmount: recommendedAmount,
                averageSpending: monthlyAverage,
                percentageOfTotal: percentage,
                priority: priority,
                rationale: rationale
            )
        }.sorted { $0.recommendedAmount > $1.recommendedAmount }
    }

    // MARK: - Savings Recommendations

    /// 節約提案を生成
    func generateSavingsRecommendations(
        historicalData: [Transaction],
        categories: [Category],
        currentBudget: Budget?
    ) -> [BudgetRecommendation] {
        var recommendations: [BudgetRecommendation] = []

        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: Date()) ?? Date()

        // 先月と先々月のデータ
        let lastMonthData = historicalData.filter {
            $0.date >= oneMonthAgo && $0.type == .expense
        }
        let previousMonthData = historicalData.filter {
            $0.date >= twoMonthsAgo && $0.date < oneMonthAgo && $0.type == .expense
        }

        // カテゴリ別の増加をチェック
        for category in categories {
            let lastMonthSpent = lastMonthData
                .filter { $0.category?.id == category.id }
                .reduce(0) { $0 + $1.amount }

            let previousMonthSpent = previousMonthData
                .filter { $0.category?.id == category.id }
                .reduce(0) { $0 + $1.amount }

            // 20%以上増加しているカテゴリを特定
            if previousMonthSpent > 0 {
                let increaseRate = (lastMonthSpent - previousMonthSpent) / previousMonthSpent

                if increaseRate >= 0.2 {
                    let potentialSaving = lastMonthSpent - previousMonthSpent

                    recommendations.append(BudgetRecommendation(
                        type: .reviewSpending,
                        title: "\(category.name)の支出見直し",
                        description: "先月比\(Int(increaseRate * 100))%増加しています。見直しを検討してください。",
                        suggestedAmount: previousMonthSpent,
                        potentialSaving: potentialSaving,
                        categoryId: category.id,
                        priority: increaseRate >= 0.5 ? .high : .medium,
                        confidence: 0.8
                    ))
                }
            }
        }

        // 高額支出のアラート
        let avgTransaction = lastMonthData.isEmpty ? 0 :
            lastMonthData.map { $0.amount }.reduce(0, +) / Double(lastMonthData.count)

        let highValueTransactions = lastMonthData.filter { $0.amount > avgTransaction * 3 }

        if !highValueTransactions.isEmpty {
            let totalHighValue = highValueTransactions.reduce(0) { $0 + $1.amount }

            recommendations.append(BudgetRecommendation(
                type: .setAlert,
                title: "高額支出のアラート設定",
                description: "\(highValueTransactions.count)件の高額支出がありました。アラートを設定しましょう。",
                suggestedAmount: avgTransaction * 2,
                potentialSaving: totalHighValue * 0.3,
                priority: .medium,
                confidence: 0.7
            ))
        }

        // 予算超過リスク
        if let budget = currentBudget, budget.spentPercentage >= 80 {
            let daysRemaining = budget.daysRemaining
            let projectedOverage = budget.spentAmount + (budget.dailyBudget * Double(daysRemaining)) - budget.totalAmount

            if projectedOverage > 0 {
                recommendations.append(BudgetRecommendation(
                    type: .decreaseBudget,
                    title: "日次支出の抑制",
                    description: "残り\(daysRemaining)日で予算超過の可能性があります。",
                    suggestedAmount: budget.remainingAmount / Double(max(daysRemaining, 1)),
                    potentialSaving: projectedOverage,
                    priority: .high,
                    confidence: 0.85
                ))
            }
        }

        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    // MARK: - Helper Methods

    private func calculateStdDev(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }

    private func calculateRecommendationConfidence(dataMonths: Int, variance: Double) -> Double {
        // データ量による信頼度
        let dataConfidence = min(Double(dataMonths) / 6.0, 1.0)

        // 分散による信頼度（分散が大きいほど信頼度が下がる）
        let varianceConfidence = max(1.0 - variance, 0.3)

        return dataConfidence * 0.6 + varianceConfidence * 0.4
    }

    private func determineCategoryPriority(percentage: Double, transactionCount: Int) -> RecommendationPriority {
        if percentage >= 30 || transactionCount >= 20 {
            return .high
        } else if percentage >= 15 || transactionCount >= 10 {
            return .medium
        } else {
            return .low
        }
    }

    private func generateCategoryRationale(
        categoryName: String,
        percentage: Double,
        priority: RecommendationPriority
    ) -> String {
        switch priority {
        case .high:
            return "\(categoryName)は支出の\(Int(percentage))%を占める主要カテゴリです"
        case .medium:
            return "\(categoryName)は平均的な支出カテゴリです"
        case .low:
            return "\(categoryName)の支出は比較的少額です"
        }
    }
}

// MARK: - MonthlyBudgetRecommendation

struct MonthlyBudgetRecommendation: Sendable {
    enum RecommendationType: String, Sendable {
        case conservative = "conservative"      // 保守的（履歴+バッファ）
        case savingsTarget = "savings_target"   // 貯蓄目標ベース
        case historyBased = "history_based"     // 履歴ベースのみ

        var displayName: String {
            switch self {
            case .conservative: return "保守的"
            case .savingsTarget: return "貯蓄重視"
            case .historyBased: return "履歴ベース"
            }
        }
    }

    let recommendedAmount: Double
    let averageExpense: Double
    let averageIncome: Double
    let standardDeviation: Double
    let targetSavingsRate: Double
    let potentialSavings: Double
    let recommendationType: RecommendationType
    let confidence: Double
    let dataMonths: Int

    var formattedRecommendation: String {
        formatCurrency(recommendedAmount)
    }

    var formattedAverageExpense: String {
        formatCurrency(averageExpense)
    }

    var formattedPotentialSavings: String {
        formatCurrency(potentialSavings)
    }

    var confidencePercentage: String {
        String(format: "%.0f%%", confidence * 100)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

// MARK: - CategoryBudgetRecommendation

struct CategoryBudgetRecommendation: Sendable, Identifiable {
    var id: UUID { categoryId }
    let categoryId: UUID
    let categoryName: String
    let recommendedAmount: Double
    let averageSpending: Double
    let percentageOfTotal: Double
    let priority: RecommendationPriority
    let rationale: String

    var formattedRecommendation: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: recommendedAmount)) ?? "¥0"
    }
}
