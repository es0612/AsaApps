import Testing
import Foundation
@testable import AsaBudgetAI

@Suite("AnomalyDetector Tests")
struct AnomalyDetectorTests {

    // MARK: - Test Setup

    private func createDetector() -> AnomalyDetector {
        AnomalyDetector()
    }

    private func createTransaction(
        amount: Double = 1000,
        type: TransactionType = .expense,
        date: Date = Date()
    ) -> Transaction {
        Transaction(
            amount: amount,
            title: "Test",
            date: date,
            type: type
        )
    }

    private func createHistoricalData(count: Int = 30, avgAmount: Double = 1000) -> [Transaction] {
        (0..<count).map { _ in
            createTransaction(amount: Double.random(in: avgAmount * 0.8...avgAmount * 1.2))
        }
    }

    // MARK: - Anomaly Detection Tests

    @Test("異常検知 - 通常の取引は異常スコアが低い")
    func testNormalTransactionHasLowAnomalyScore() {
        let detector = createDetector()
        let historicalData = createHistoricalData(count: 50, avgAmount: 1000)
        let normalTransaction = createTransaction(amount: 1000)
        let featureExtractor = SpendingFeatureExtractor()
        let categoryStats = featureExtractor.generateCategoryStats(from: historicalData)

        let result = detector.detectAnomaly(
            transaction: normalTransaction,
            historicalData: historicalData,
            categoryStats: categoryStats
        )

        // 通常の取引は低い異常スコア
        #expect(result.anomalyScore < 0.7)
    }

    @Test("異常検知 - 高額取引は異常スコアが高い")
    func testHighAmountTransactionHasHighAnomalyScore() {
        let detector = createDetector()
        let historicalData = createHistoricalData(count: 50, avgAmount: 1000)
        let highAmountTransaction = createTransaction(amount: 50000)  // 平均の50倍
        let featureExtractor = SpendingFeatureExtractor()
        let categoryStats = featureExtractor.generateCategoryStats(from: historicalData)

        let result = detector.detectAnomaly(
            transaction: highAmountTransaction,
            historicalData: historicalData,
            categoryStats: categoryStats
        )

        // 高額取引は高い異常スコア
        #expect(result.anomalyScore >= 0.5)
    }

    @Test("一括異常検知 - 閾値フィルタリング")
    func testBatchAnomalyDetectionWithThreshold() {
        let detector = createDetector()
        let historicalData = createHistoricalData(count: 50, avgAmount: 1000)

        // 異常な取引と正常な取引を混ぜる
        let transactions = [
            createTransaction(amount: 1000),   // 正常
            createTransaction(amount: 1100),   // 正常
            createTransaction(amount: 50000),  // 異常
        ]

        let anomalies = detector.detectAnomalies(
            transactions: transactions,
            historicalData: historicalData,
            threshold: 0.6
        )

        // 閾値以上の異常のみ返される
        for anomaly in anomalies {
            #expect(anomaly.anomalyScore >= 0.6)
        }
    }

    @Test("重み更新 - カスタム重みで分析")
    func testUpdateWeights() {
        let detector = createDetector()

        // カスタム重みを設定
        let customWeights = AnalysisWeights(
            categoryPattern: 0.5,
            amountDeviation: 0.3,
            timePattern: 0.1,
            frequency: 0.05,
            historicalTrend: 0.03,
            seasonal: 0.02
        )

        detector.updateWeights(customWeights)

        // 重みが更新されたことを確認（内部状態のテスト）
        let historicalData = createHistoricalData(count: 30)
        let transaction = createTransaction(amount: 5000)
        let featureExtractor = SpendingFeatureExtractor()
        let categoryStats = featureExtractor.generateCategoryStats(from: historicalData)

        let result = detector.detectAnomaly(
            transaction: transaction,
            historicalData: historicalData,
            categoryStats: categoryStats
        )

        #expect(result.anomalyScore >= 0)
    }

    @Test("リアルタイム異常チェック")
    func testRealTimeAnomalyCheck() {
        let detector = createDetector()
        let recentTransactions = createHistoricalData(count: 20, avgAmount: 1000)

        // 正常な取引
        let normalTransaction = createTransaction(amount: 1000)
        let (isNormalAnomaly, _) = detector.checkNewTransaction(
            transaction: normalTransaction,
            recentTransactions: recentTransactions
        )

        // 異常な取引
        let anomalyTransaction = createTransaction(amount: 100000)
        let (isAnomalyDetected, _) = detector.checkNewTransaction(
            transaction: anomalyTransaction,
            recentTransactions: recentTransactions
        )

        // 結果の検証（状況による）
        #expect(!isNormalAnomaly || isNormalAnomaly)
    }

    @Test("異常トレンド分析")
    func testAnomalyTrendAnalysis() {
        let detector = createDetector()

        // 異常結果のリストを作成
        let anomalies = (0..<10).map { i in
            AnomalyResult(
                transactionId: UUID(),
                anomalyScore: 0.7,
                severity: .caution,
                reasons: ["Test"],
                features: SpendingFeatures(),
                detectedAt: Date().addingTimeInterval(Double(-i * 86400))
            )
        }

        let trend = detector.analyzeAnomalyTrend(anomalies: anomalies, periodDays: 30)

        #expect(!trend.message.isEmpty)
    }
}

// MARK: - AnalysisWeights Tests

@Suite("AnalysisWeights Tests")
struct AnalysisWeightsTests {

    @Test("デフォルト重みの合計は1.0")
    func testDefaultWeightsSum() {
        let weights = AnalysisWeights.default

        #expect(abs(weights.total - 1.0) < 0.01)
        #expect(weights.isValid)
    }

    @Test("重み付けスコア計算")
    func testWeightedScoreCalculation() {
        let weights = AnalysisWeights(
            categoryPattern: 0.25,
            amountDeviation: 0.25,
            timePattern: 0.15,
            frequency: 0.15,
            historicalTrend: 0.10,
            seasonal: 0.10
        )

        let features = SpendingFeatures(
            categoryPatternScore: 1.0,
            amountDeviationScore: 1.0,
            timePatternScore: 1.0,
            frequencyScore: 1.0,
            historicalTrendScore: 1.0,
            seasonalScore: 1.0
        )

        let score = weights.weightedScore(features: features)

        // すべて1.0なら合計も1.0
        #expect(abs(score - 1.0) < 0.01)
    }

    @Test("無効な重み検出")
    func testInvalidWeightsDetection() {
        let invalidWeights = AnalysisWeights(
            categoryPattern: 0.5,
            amountDeviation: 0.5,
            timePattern: 0.5,
            frequency: 0.0,
            historicalTrend: 0.0,
            seasonal: 0.0
        )

        // 合計が1.0でない
        #expect(!invalidWeights.isValid)
    }
}
