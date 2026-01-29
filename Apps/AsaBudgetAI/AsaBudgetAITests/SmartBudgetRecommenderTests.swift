import Testing
import Foundation
@testable import AsaBudgetAI

@Suite("SmartBudgetRecommender Tests")
struct SmartBudgetRecommenderTests {

    // MARK: - Test Helpers

    private func createRecommender() -> SmartBudgetRecommender {
        SmartBudgetRecommender()
    }

    private func createTransactions(months: Int, avgMonthlyExpense: Double) -> [Transaction] {
        var transactions: [Transaction] = []
        let calendar = Calendar.current
        let now = Date()

        for monthOffset in 0..<months {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else {
                continue
            }

            // 月に10-15件の取引を生成
            let transactionCount = Int.random(in: 10...15)
            let avgPerTransaction = avgMonthlyExpense / Double(transactionCount)

            for _ in 0..<transactionCount {
                let dayOffset = Int.random(in: 0..<28)
                guard let transactionDate = calendar.date(byAdding: .day, value: dayOffset, to: monthDate) else {
                    continue
                }

                let amount = avgPerTransaction * Double.random(in: 0.5...1.5)
                let transaction = Transaction(
                    amount: amount,
                    title: "Test Expense",
                    date: transactionDate,
                    type: .expense
                )
                transactions.append(transaction)
            }
        }

        return transactions
    }

    // MARK: - Monthly Budget Recommendation Tests

    @Test("月次予算推奨 - 正常データ")
    func testMonthlyBudgetRecommendation() {
        let recommender = createRecommender()
        let transactions = createTransactions(months: 6, avgMonthlyExpense: 100000)

        let recommendation = recommender.recommendMonthlyBudget(
            historicalData: transactions,
            targetSavingsRate: 0.2
        )

        // 推奨予算が正の値
        #expect(recommendation.recommendedAmount > 0)
        // 平均支出が計算されている
        #expect(recommendation.averageExpense > 0)
        // 信頼度が0-1の範囲
        #expect(recommendation.confidence >= 0 && recommendation.confidence <= 1)
    }

    @Test("月次予算推奨 - データ不足")
    func testMonthlyBudgetRecommendationWithInsufficientData() {
        let recommender = createRecommender()
        let transactions: [Transaction] = []

        let recommendation = recommender.recommendMonthlyBudget(
            historicalData: transactions,
            targetSavingsRate: 0.2
        )

        // データがなくてもエラーなく動作
        #expect(recommendation.recommendedAmount >= 0)
        #expect(recommendation.dataMonths == 0)
    }

    @Test("月次予算推奨 - 推奨タイプの決定")
    func testRecommendationType() {
        let recommender = createRecommender()
        let transactions = createTransactions(months: 6, avgMonthlyExpense: 100000)

        let recommendation = recommender.recommendMonthlyBudget(
            historicalData: transactions
        )

        // いずれかの推奨タイプが設定されている
        let validTypes: [MonthlyBudgetRecommendation.RecommendationType] = [
            .conservative, .savingsTarget, .historyBased
        ]
        #expect(validTypes.contains(recommendation.recommendationType))
    }

    // MARK: - Category Budget Recommendation Tests

    @Test("カテゴリ別予算推奨 - 正常データ")
    func testCategoryBudgetRecommendation() {
        let recommender = createRecommender()
        let transactions = createTransactions(months: 3, avgMonthlyExpense: 100000)
        let categories = Category.defaultCategories()

        let recommendations = recommender.recommendCategoryBudgets(
            historicalData: transactions,
            totalBudget: 100000,
            categories: categories
        )

        // 各カテゴリに推奨予算がある
        #expect(recommendations.count == categories.count)
    }

    @Test("カテゴリ別予算推奨 - データなしの場合は均等配分")
    func testCategoryBudgetRecommendationWithNoData() {
        let recommender = createRecommender()
        let transactions: [Transaction] = []
        let categories = Category.defaultCategories()

        let recommendations = recommender.recommendCategoryBudgets(
            historicalData: transactions,
            totalBudget: 100000,
            categories: categories
        )

        // データがない場合は均等配分
        if !recommendations.isEmpty {
            let expectedShare = 100000.0 / Double(categories.count)
            for rec in recommendations {
                #expect(abs(rec.recommendedAmount - expectedShare) < 100)
            }
        }
    }

    // MARK: - Savings Recommendation Tests

    @Test("節約提案 - 優先度でソート")
    func testSavingsRecommendationsSortedByPriority() {
        let recommender = createRecommender()
        let transactions = createTransactions(months: 3, avgMonthlyExpense: 100000)
        let categories = Category.defaultCategories()

        let recommendations = recommender.generateSavingsRecommendations(
            historicalData: transactions,
            categories: categories,
            currentBudget: nil
        )

        // 優先度順にソートされている
        for i in 0..<max(recommendations.count - 1, 0) {
            let current = recommendations[i].priority.rawValue
            let next = recommendations[i + 1].priority.rawValue
            // 高い優先度が先（または同等）
            #expect(current >= next || current == next)
        }
    }
}

// MARK: - MonthlyBudgetRecommendation Tests

@Suite("MonthlyBudgetRecommendation Tests")
struct MonthlyBudgetRecommendationTests {

    @Test("フォーマット - 通貨表示")
    func testCurrencyFormatting() {
        let recommendation = MonthlyBudgetRecommendation(
            recommendedAmount: 150000,
            averageExpense: 120000,
            averageIncome: 300000,
            standardDeviation: 20000,
            targetSavingsRate: 0.2,
            potentialSavings: 60000,
            recommendationType: .savingsTarget,
            confidence: 0.85,
            dataMonths: 6
        )

        #expect(recommendation.formattedRecommendation.contains("¥"))
        #expect(recommendation.formattedAverageExpense.contains("¥"))
        #expect(recommendation.formattedPotentialSavings.contains("¥"))
    }

    @Test("フォーマット - 信頼度パーセンテージ")
    func testConfidencePercentage() {
        let recommendation = MonthlyBudgetRecommendation(
            recommendedAmount: 150000,
            averageExpense: 120000,
            averageIncome: 300000,
            standardDeviation: 20000,
            targetSavingsRate: 0.2,
            potentialSavings: 60000,
            recommendationType: .conservative,
            confidence: 0.85,
            dataMonths: 6
        )

        #expect(recommendation.confidencePercentage == "85%")
    }

    @Test("推奨タイプ - 表示名")
    func testRecommendationTypeDisplayNames() {
        #expect(MonthlyBudgetRecommendation.RecommendationType.conservative.displayName == "保守的")
        #expect(MonthlyBudgetRecommendation.RecommendationType.savingsTarget.displayName == "貯蓄重視")
        #expect(MonthlyBudgetRecommendation.RecommendationType.historyBased.displayName == "履歴ベース")
    }
}
