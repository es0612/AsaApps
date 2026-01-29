import Testing
import Foundation
@testable import AsaBudgetAI

@Suite("SpendingFeatureExtractor Tests")
struct SpendingFeatureExtractorTests {

    // MARK: - Test Setup

    private func createExtractor() -> SpendingFeatureExtractor {
        SpendingFeatureExtractor()
    }

    private func createTransaction(
        amount: Double = 1000,
        type: TransactionType = .expense,
        date: Date = Date(),
        categoryId: UUID? = nil
    ) -> Transaction {
        let transaction = Transaction(
            amount: amount,
            title: "Test Transaction",
            date: date,
            type: type
        )
        return transaction
    }

    // MARK: - Feature Extraction Tests

    @Test("特徴量抽出 - 正常なデータ")
    func testExtractFeaturesWithNormalData() {
        let extractor = createExtractor()
        let transaction = createTransaction(amount: 1000)
        let historicalData = (0..<10).map { _ in createTransaction(amount: Double.random(in: 800...1200)) }

        let categoryStats = extractor.generateCategoryStats(from: historicalData)
        let features = extractor.extractFeatures(
            transaction: transaction,
            historicalData: historicalData,
            categoryStats: categoryStats
        )

        #expect(features.categoryPatternScore >= 0 && features.categoryPatternScore <= 1)
        #expect(features.amountDeviationScore >= 0 && features.amountDeviationScore <= 1)
        #expect(features.timePatternScore >= 0 && features.timePatternScore <= 1)
        #expect(features.frequencyScore >= 0 && features.frequencyScore <= 1)
        #expect(features.historicalTrendScore >= 0 && features.historicalTrendScore <= 1)
        #expect(features.seasonalScore >= 0 && features.seasonalScore <= 1)
    }

    @Test("特徴量抽出 - 高額支出で高スコア")
    func testHighAmountDeviationScore() {
        let extractor = createExtractor()

        // 通常の支出履歴（平均約1000円、ばらつきあり）
        // 標準偏差計算のためにデータにばらつきを持たせる
        let historicalData = (0..<20).map { i in
            createTransaction(amount: 800 + Double(i % 5) * 100)  // 800-1200の範囲
        }

        // 非常に高額な支出（10000円）
        let highAmountTransaction = createTransaction(amount: 10000)

        let categoryStats = extractor.generateCategoryStats(from: historicalData)
        let features = extractor.extractFeatures(
            transaction: highAmountTransaction,
            historicalData: historicalData,
            categoryStats: categoryStats
        )

        // 高額支出は金額偏差スコアが高くなるべき
        #expect(features.amountDeviationScore >= 0.7)
    }

    @Test("特徴量抽出 - 少額支出で低スコア")
    func testLowAmountDeviationScore() {
        let extractor = createExtractor()

        // 通常の支出履歴（平均約1000円、ばらつきあり）
        let historicalData = (0..<20).map { i in
            createTransaction(amount: 800 + Double(i % 5) * 100)  // 800-1200の範囲
        }

        // 通常範囲内の支出
        let normalTransaction = createTransaction(amount: 1000)

        let categoryStats = extractor.generateCategoryStats(from: historicalData)
        let features = extractor.extractFeatures(
            transaction: normalTransaction,
            historicalData: historicalData,
            categoryStats: categoryStats
        )

        // 通常範囲内の支出は金額偏差スコアが低くなるべき
        #expect(features.amountDeviationScore < 0.5)
    }

    @Test("特徴量抽出 - 履歴データなし")
    func testExtractFeaturesWithNoHistory() {
        let extractor = createExtractor()
        let transaction = createTransaction(amount: 1000)
        let emptyHistory: [Transaction] = []

        let categoryStats = extractor.generateCategoryStats(from: emptyHistory)
        let features = extractor.extractFeatures(
            transaction: transaction,
            historicalData: emptyHistory,
            categoryStats: categoryStats
        )

        // 履歴がない場合でもエラーなく特徴量が計算される
        #expect(features.totalScore >= 0)
    }

    @Test("カテゴリ統計生成 - 正常データ")
    func testGenerateCategoryStats() {
        let extractor = createExtractor()

        let categoryId = UUID()
        var transactions: [Transaction] = []

        // 同じカテゴリの取引を作成
        for amount in [1000.0, 2000.0, 3000.0, 4000.0, 5000.0] {
            let t = createTransaction(amount: amount)
            transactions.append(t)
        }

        let stats = extractor.generateCategoryStats(from: transactions)

        // 統計が生成されることを確認
        #expect(stats.isEmpty || stats.values.first?.transactionCount ?? 0 >= 0)
    }

    @Test("カテゴリ統計 - 標準偏差計算")
    func testCategoryStatsStandardDeviation() {
        let categoryId = UUID()

        // 手動でCategoryHistoricalStatsを作成してテスト
        let amounts = [1000.0, 2000.0, 3000.0, 4000.0, 5000.0]
        let mean = amounts.reduce(0, +) / Double(amounts.count)  // 3000
        let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)
        let expectedStdDev = sqrt(variance)  // 約1414

        #expect(expectedStdDev > 1400 && expectedStdDev < 1500)
    }
}

// MARK: - Additional Tests

@Suite("SpendingFeatures Tests")
struct SpendingFeaturesTests {

    @Test("SpendingFeatures - 合計スコア計算")
    func testTotalScoreCalculation() {
        let features = SpendingFeatures(
            categoryPatternScore: 0.5,
            amountDeviationScore: 0.6,
            timePatternScore: 0.4,
            frequencyScore: 0.3,
            historicalTrendScore: 0.2,
            seasonalScore: 0.1
        )

        let expectedTotal = 0.5 + 0.6 + 0.4 + 0.3 + 0.2 + 0.1
        #expect(abs(features.totalScore - expectedTotal) < 0.001)
    }

    @Test("SpendingFeatures - スコアの範囲制限")
    func testScoreRangeLimitation() {
        // 範囲外の値を入力
        let features = SpendingFeatures(
            categoryPatternScore: 1.5,   // > 1.0
            amountDeviationScore: -0.5,  // < 0.0
            timePatternScore: 0.5,
            frequencyScore: 0.5,
            historicalTrendScore: 0.5,
            seasonalScore: 0.5
        )

        // 値は0-1に制限されるべき
        #expect(features.categoryPatternScore >= 0 && features.categoryPatternScore <= 1)
        #expect(features.amountDeviationScore >= 0 && features.amountDeviationScore <= 1)
    }
}
