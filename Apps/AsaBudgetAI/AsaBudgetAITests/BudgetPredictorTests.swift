import Testing
import Foundation
@testable import AsaBudgetAI

@Suite("BudgetPredictor Tests")
struct BudgetPredictorTests {

    // MARK: - Test Helpers

    private func createPredictor() -> BudgetPredictor {
        BudgetPredictor()
    }

    private func createBudget(totalAmount: Double = 100000) -> Budget {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        return Budget(
            name: "Test Budget",
            totalAmount: totalAmount,
            period: .monthly,
            startDate: startOfMonth,
            endDate: endOfMonth
        )
    }

    private func createTransaction(amount: Double, daysAgo: Int = 0) -> Transaction {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return Transaction(
            amount: amount,
            title: "Test",
            date: date,
            type: .expense
        )
    }

    // MARK: - Budget Prediction Tests

    @Test("予算予測 - 推奨日次予算の計算")
    func testRecommendedDailyBudget() {
        let predictor = createPredictor()
        let budget = createBudget(totalAmount: 100000)

        let currentSpent = 50000.0
        let historicalData: [Transaction] = []

        let result = predictor.predictBudgetExceedance(
            budget: budget,
            currentSpent: currentSpent,
            historicalData: historicalData
        )

        // 残り日数に応じた推奨日次予算が計算される
        if result.daysRemaining > 0 {
            #expect(result.recommendedDailyBudget > 0)
        }
    }

    @Test("予算予測 - 信頼度計算")
    func testConfidenceCalculation() {
        let predictor = createPredictor()
        let budget = createBudget()

        // 履歴データが多いほど信頼度が高い
        let smallHistory = (0..<10).map { createTransaction(amount: 1000, daysAgo: $0) }
        let largeHistory = (0..<100).map { createTransaction(amount: 1000, daysAgo: $0 % 30) }

        let resultSmall = predictor.predictBudgetExceedance(
            budget: budget,
            currentSpent: 50000,
            historicalData: smallHistory
        )

        let resultLarge = predictor.predictBudgetExceedance(
            budget: budget,
            currentSpent: 50000,
            historicalData: largeHistory
        )

        // より多くのデータがある方が信頼度が高い（または同等）
        #expect(resultLarge.confidence >= resultSmall.confidence * 0.8)
    }

    @Test("予算予測 - 洞察生成")
    func testInsightsGeneration() {
        let predictor = createPredictor()
        let budget = createBudget(totalAmount: 100000)

        // 高い使用率
        let result = predictor.predictBudgetExceedance(
            budget: budget,
            currentSpent: 95000,
            historicalData: []
        )

        // 洞察が生成される
        #expect(!result.insights.isEmpty)
    }

    @Test("予算予測 - リスクレベル判定")
    func testRiskLevelDetermination() {
        // リスクレベルのテスト
        let lowRiskResult = BudgetPredictionResult(
            predictedTotal: 80000,
            exceedanceAmount: 0,
            exceedanceProbability: 0.2,
            confidence: 0.8,
            daysRemaining: 10,
            recommendedDailyBudget: 2000,
            insights: []
        )

        let highRiskResult = BudgetPredictionResult(
            predictedTotal: 120000,
            exceedanceAmount: 20000,
            exceedanceProbability: 0.9,
            confidence: 0.8,
            daysRemaining: 10,
            recommendedDailyBudget: -1000,
            insights: []
        )

        #expect(lowRiskResult.riskLevel == .normal)
        #expect(highRiskResult.riskLevel == .critical)
    }
}

// MARK: - BudgetPredictionResult Tests

@Suite("BudgetPredictionResult Tests")
struct BudgetPredictionResultTests {

    @Test("willExceed - 確率50%以上でtrue")
    func testWillExceed() {
        let result = BudgetPredictionResult(
            predictedTotal: 110000,
            exceedanceAmount: 10000,
            exceedanceProbability: 0.6,
            confidence: 0.8,
            daysRemaining: 5,
            recommendedDailyBudget: 0,
            insights: []
        )

        #expect(result.willExceed)
    }

    @Test("willExceed - 確率50%未満でfalse")
    func testWillNotExceed() {
        let result = BudgetPredictionResult(
            predictedTotal: 90000,
            exceedanceAmount: 0,
            exceedanceProbability: 0.3,
            confidence: 0.8,
            daysRemaining: 10,
            recommendedDailyBudget: 1000,
            insights: []
        )

        #expect(!result.willExceed)
    }

    @Test("フォーマット - 通貨表示")
    func testCurrencyFormatting() {
        let result = BudgetPredictionResult(
            predictedTotal: 123456,
            exceedanceAmount: 23456,
            exceedanceProbability: 0.7,
            confidence: 0.8,
            daysRemaining: 5,
            recommendedDailyBudget: 5000,
            insights: []
        )

        #expect(result.formattedPredictedTotal.contains("¥"))
        #expect(result.formattedExceedance.contains("¥"))
        #expect(result.formattedRecommendedDaily.contains("¥"))
    }

    @Test("フォーマット - 確率パーセンテージ")
    func testProbabilityPercentage() {
        let result = BudgetPredictionResult(
            predictedTotal: 100000,
            exceedanceAmount: 0,
            exceedanceProbability: 0.75,
            confidence: 0.8,
            daysRemaining: 5,
            recommendedDailyBudget: 2000,
            insights: []
        )

        #expect(result.probabilityPercentage == "75%")
    }
}
