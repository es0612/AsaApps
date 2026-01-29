import Foundation

// MARK: - EnhancedSpendingAnalyzer

/// ハイブリッドAI分析（ルールベース40% + LLM60%）を提供するサービス
final class EnhancedSpendingAnalyzer: @unchecked Sendable {

    // MARK: - Dependencies

    private let anomalyDetector: AnomalyDetector
    private let budgetPredictor: BudgetPredictor
    private let patternAnalyzer: SpendingPatternAnalyzer
    private let recommender: SmartBudgetRecommender
    private let featureExtractor: SpendingFeatureExtractor

    // MARK: - Configuration

    private let ruleBasedWeight: Double = 0.4
    private let llmWeight: Double = 0.6

    // MARK: - Initialization

    init(
        anomalyDetector: AnomalyDetector = AnomalyDetector(),
        budgetPredictor: BudgetPredictor = BudgetPredictor(),
        patternAnalyzer: SpendingPatternAnalyzer = SpendingPatternAnalyzer(),
        recommender: SmartBudgetRecommender = SmartBudgetRecommender(),
        featureExtractor: SpendingFeatureExtractor = SpendingFeatureExtractor()
    ) {
        self.anomalyDetector = anomalyDetector
        self.budgetPredictor = budgetPredictor
        self.patternAnalyzer = patternAnalyzer
        self.recommender = recommender
        self.featureExtractor = featureExtractor
    }

    // MARK: - Comprehensive Analysis

    /// 総合的なAI分析を実行
    func performComprehensiveAnalysis(
        transactions: [Transaction],
        budget: Budget?,
        categories: [Category],
        settings: UserSettings
    ) async -> AIAnalysisResult {
        // 1. ルールベース分析（常に実行）
        let ruleBasedResult = await performRuleBasedAnalysis(
            transactions: transactions,
            budget: budget,
            categories: categories,
            settings: settings
        )

        // 2. LLM分析を試行（iOS 18+のみ）
        var llmResult: LLMAnalysisResult?
        if settings.llmAnalysisEnabled {
            llmResult = await performLLMAnalysis(
                transactions: transactions,
                budget: budget,
                ruleBasedResult: ruleBasedResult
            )
        }

        // 3. ハイブリッドスコアを計算
        let hybridScore: Double
        let hybridConfidence: Double

        if let llm = llmResult {
            hybridScore = ruleBasedResult.score * ruleBasedWeight + llm.score * llmWeight
            hybridConfidence = ruleBasedResult.confidence * ruleBasedWeight + llm.confidence * llmWeight
        } else {
            // LLM利用不可の場合はルールベースのみ
            hybridScore = ruleBasedResult.score
            hybridConfidence = ruleBasedResult.confidence
        }

        // 4. 洞察を統合
        var insights = ruleBasedResult.insights
        if let llmInsights = llmResult?.insights {
            insights.append(contentsOf: llmInsights)
        }

        // 重複を除去してソート
        insights = Array(Set(insights.map { $0.id.uuidString }))
            .compactMap { idStr in insights.first { $0.id.uuidString == idStr } }
            .sorted { $0.importance > $1.importance }

        // 5. アラートレベルを判定
        let alertLevel = determineAlertLevel(score: hybridScore, anomalies: ruleBasedResult.anomalies)

        return AIAnalysisResult(
            analysisType: .comprehensive,
            overallScore: hybridScore,
            confidence: hybridConfidence,
            alertLevel: alertLevel,
            insights: Array(insights.prefix(10)),  // 最大10件
            predictions: ruleBasedResult.predictions,
            recommendations: ruleBasedResult.recommendations,
            detectedAnomalies: ruleBasedResult.anomalies
        )
    }

    // MARK: - Rule-Based Analysis

    /// ルールベース分析を実行
    private func performRuleBasedAnalysis(
        transactions: [Transaction],
        budget: Budget?,
        categories: [Category],
        settings: UserSettings
    ) async -> RuleBasedAnalysisResult {
        let weights = settings.analysisWeights

        // 異常検知
        anomalyDetector.updateWeights(weights)
        let anomalies = anomalyDetector.detectAnomalies(
            transactions: transactions,
            historicalData: transactions,
            threshold: settings.anomalyThreshold
        )

        // パターン分析
        let patterns = patternAnalyzer.analyzePatterns(transactions: transactions)

        // 予算予測
        var predictions: [SpendingPrediction] = []
        if let budget = budget {
            let prediction = budgetPredictor.predictBudgetExceedance(
                budget: budget,
                currentSpent: budget.spentAmount,
                historicalData: transactions
            )

            if prediction.willExceed {
                predictions.append(SpendingPrediction(
                    predictedAmount: prediction.predictedTotal,
                    predictedDate: budget.endDate,
                    confidence: prediction.confidence,
                    basis: .hybrid
                ))
            }
        }

        // 推奨事項
        let recommendations = recommender.generateSavingsRecommendations(
            historicalData: transactions,
            categories: categories,
            currentBudget: budget
        )

        // 洞察を生成
        var insights: [AIInsight] = []

        // 異常に基づく洞察
        if !anomalies.isEmpty {
            insights.append(AIInsight(
                category: .anomaly,
                title: "異常な支出を検出",
                description: "\(anomalies.count)件の異常な支出が検出されました。確認をお勧めします。",
                importance: 0.9,
                actionable: true
            ))
        }

        // パターンに基づく洞察
        for pattern in patterns.prefix(3) {
            insights.append(AIInsight(
                category: .pattern,
                title: pattern.patternType.displayName,
                description: pattern.description,
                importance: pattern.confidence,
                actionable: pattern.patternType.severity == .warning
            ))
        }

        // 予算状況に基づく洞察
        if let budget = budget {
            if budget.spentPercentage >= 90 {
                insights.append(AIInsight(
                    category: .budget,
                    title: "予算残高注意",
                    description: "予算の\(Int(budget.spentPercentage))%を使用済みです。",
                    importance: 0.95,
                    actionable: true
                ))
            } else if budget.spentPercentage >= 70 {
                insights.append(AIInsight(
                    category: .budget,
                    title: "予算消化進行中",
                    description: "予算の約\(Int(budget.spentPercentage))%を使用しています。",
                    importance: 0.7,
                    actionable: false
                ))
            }
        }

        // スコアを計算
        let anomalyScore = anomalies.isEmpty ? 0 : anomalies.map { $0.anomalyScore }.reduce(0, +) / Double(anomalies.count)
        let patternScore = patterns.isEmpty ? 0.5 : patterns.map { $0.confidence }.reduce(0, +) / Double(patterns.count)
        let budgetScore = budget.map { $0.spentPercentage / 100 } ?? 0.5

        let overallScore = (anomalyScore * 0.4 + patternScore * 0.3 + budgetScore * 0.3)

        return RuleBasedAnalysisResult(
            score: overallScore,
            confidence: 0.8,
            anomalies: anomalies,
            patterns: patterns,
            predictions: predictions,
            recommendations: recommendations,
            insights: insights
        )
    }

    // MARK: - LLM Analysis

    /// LLM分析を実行（iOS 18+）
    private func performLLMAnalysis(
        transactions: [Transaction],
        budget: Budget?,
        ruleBasedResult: RuleBasedAnalysisResult
    ) async -> LLMAnalysisResult? {
        // iOS 18の可用性チェック
        guard #available(iOS 18.0, *) else {
            return nil
        }

        // 注: 実際のLLM実装はFoundation Modelsフレームワークを使用
        // ここではスタブ実装を提供

        // 分析用のサマリーを作成
        let summary = createAnalysisSummary(
            transactions: transactions,
            budget: budget,
            ruleBasedResult: ruleBasedResult
        )

        // LLM分析をシミュレート（実際の実装ではFoundation Modelsを使用）
        return await simulateLLMAnalysis(summary: summary)
    }

    /// 分析サマリーを作成
    private func createAnalysisSummary(
        transactions: [Transaction],
        budget: Budget?,
        ruleBasedResult: RuleBasedAnalysisResult
    ) -> AnalysisSummary {
        let expenses = transactions.filter { $0.type == .expense }
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        let avgExpense = expenses.isEmpty ? 0 : totalExpense / Double(expenses.count)

        return AnalysisSummary(
            transactionCount: transactions.count,
            totalExpense: totalExpense,
            averageExpense: avgExpense,
            budgetUsage: budget?.spentPercentage ?? 0,
            anomalyCount: ruleBasedResult.anomalies.count,
            topPatterns: ruleBasedResult.patterns.prefix(3).map { $0.patternType.displayName }
        )
    }

    /// LLM分析のシミュレーション
    @available(iOS 18.0, *)
    private func simulateLLMAnalysis(summary: AnalysisSummary) async -> LLMAnalysisResult {
        // 実際の実装では以下のようなコードになる:
        // let session = LanguageModelSession(instructions: "...")
        // let output = try await session.respond(to: prompt, generating: BudgetAnalysisOutput.self)

        // スタブ: ルールベースの結果を補強する洞察を生成
        var insights: [AIInsight] = []

        if summary.anomalyCount > 0 {
            insights.append(AIInsight(
                category: .anomaly,
                title: "支出パターンの変化",
                description: "最近の支出パターンに変化が見られます。新しい習慣や一時的な出費の可能性があります。",
                importance: 0.75,
                actionable: true
            ))
        }

        if summary.budgetUsage > 80 {
            insights.append(AIInsight(
                category: .saving,
                title: "節約の機会",
                description: "予算消化が進んでいます。外食や娯楽費を一時的に抑えることで、月末の余裕が生まれます。",
                importance: 0.8,
                actionable: true
            ))
        }

        // スコアを計算（ルールベースの補正）
        let score = min(summary.budgetUsage / 100 + Double(summary.anomalyCount) * 0.1, 1.0)

        return LLMAnalysisResult(
            score: score,
            confidence: 0.7,
            insights: insights,
            rawResponse: nil
        )
    }

    // MARK: - Alert Level Determination

    private func determineAlertLevel(score: Double, anomalies: [AnomalyResult]) -> AlertLevel {
        // 緊急レベルの異常がある場合
        if anomalies.contains(where: { $0.severity == .critical }) {
            return .critical
        }

        // スコアに基づく判定
        switch score {
        case 0.8...:
            return .critical
        case 0.6..<0.8:
            return .warning
        case 0.4..<0.6:
            return .caution
        default:
            return .normal
        }
    }
}

// MARK: - Supporting Types

private struct RuleBasedAnalysisResult {
    let score: Double
    let confidence: Double
    let anomalies: [AnomalyResult]
    let patterns: [SpendingPattern]
    let predictions: [SpendingPrediction]
    let recommendations: [BudgetRecommendation]
    let insights: [AIInsight]
}

private struct LLMAnalysisResult {
    let score: Double
    let confidence: Double
    let insights: [AIInsight]
    let rawResponse: String?
}

private struct AnalysisSummary {
    let transactionCount: Int
    let totalExpense: Double
    let averageExpense: Double
    let budgetUsage: Double
    let anomalyCount: Int
    let topPatterns: [String]
}

// MARK: - Quick Analysis

extension EnhancedSpendingAnalyzer {
    /// クイック分析（新規取引追加時）
    func quickAnalysis(
        transaction: Transaction,
        recentTransactions: [Transaction],
        settings: UserSettings
    ) async -> QuickAnalysisResult {
        // 異常検知
        let (isAnomaly, anomalyResult) = anomalyDetector.checkNewTransaction(
            transaction: transaction,
            recentTransactions: recentTransactions
        )

        // アラートメッセージを生成
        var alerts: [String] = []

        if isAnomaly, let result = anomalyResult {
            alerts.append(contentsOf: result.reasons)
        }

        // 高額支出チェック
        let avgAmount = recentTransactions
            .filter { $0.type == .expense }
            .map { $0.amount }
            .reduce(0, +) / max(Double(recentTransactions.count), 1)

        if transaction.amount > avgAmount * 3 {
            alerts.append("この支出は通常の\(Int(transaction.amount / avgAmount))倍の金額です")
        }

        return QuickAnalysisResult(
            isAnomaly: isAnomaly,
            anomalyScore: anomalyResult?.anomalyScore ?? 0,
            alerts: alerts,
            alertLevel: anomalyResult?.severity ?? .normal
        )
    }
}

// MARK: - QuickAnalysisResult

struct QuickAnalysisResult: Sendable {
    let isAnomaly: Bool
    let anomalyScore: Double
    let alerts: [String]
    let alertLevel: AlertLevel

    var hasAlerts: Bool {
        !alerts.isEmpty
    }
}
