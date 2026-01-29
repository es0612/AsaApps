import Foundation

// MARK: - AnomalyDetector

/// 6要因重み付けスコアリングによる異常検知サービス
final class AnomalyDetector: @unchecked Sendable {

    private let featureExtractor: SpendingFeatureExtractor
    private var weights: AnalysisWeights

    // MARK: - Initialization

    init(
        featureExtractor: SpendingFeatureExtractor = SpendingFeatureExtractor(),
        weights: AnalysisWeights = .default
    ) {
        self.featureExtractor = featureExtractor
        self.weights = weights
    }

    // MARK: - Configuration

    func updateWeights(_ newWeights: AnalysisWeights) {
        self.weights = newWeights
    }

    // MARK: - Anomaly Detection

    /// 単一取引の異常検知
    func detectAnomaly(
        transaction: Transaction,
        historicalData: [Transaction],
        categoryStats: [UUID: CategoryHistoricalStats]
    ) -> AnomalyResult {
        // 特徴量を抽出
        let features = featureExtractor.extractFeatures(
            transaction: transaction,
            historicalData: historicalData,
            categoryStats: categoryStats
        )

        // 重み付けスコアを計算
        let anomalyScore = weights.weightedScore(features: features)

        // 異常の理由を生成
        let reasons = generateAnomalyReasons(features: features, score: anomalyScore)

        // 重大度を判定
        let severity = determineSeverity(score: anomalyScore)

        return AnomalyResult(
            transactionId: transaction.id,
            anomalyScore: anomalyScore,
            severity: severity,
            reasons: reasons,
            features: features
        )
    }

    /// 複数取引の一括異常検知
    func detectAnomalies(
        transactions: [Transaction],
        historicalData: [Transaction],
        threshold: Double = 0.6
    ) -> [AnomalyResult] {
        let categoryStats = featureExtractor.generateCategoryStats(from: historicalData)

        return transactions.compactMap { transaction in
            let result = detectAnomaly(
                transaction: transaction,
                historicalData: historicalData,
                categoryStats: categoryStats
            )

            // 閾値以上のみ返す
            return result.anomalyScore >= threshold ? result : nil
        }
    }

    // MARK: - Severity Determination

    /// 異常スコアから重大度を判定
    ///
    /// 判定基準:
    /// - 0.9以上: 緊急（critical）
    /// - 0.75-0.9: 危険（warning）
    /// - 0.6-0.75: 注意（caution）
    /// - 0.6未満: 正常（normal）
    private func determineSeverity(score: Double) -> AlertLevel {
        switch score {
        case 0.9...:
            return .critical
        case 0.75..<0.9:
            return .warning
        case 0.6..<0.75:
            return .caution
        default:
            return .normal
        }
    }

    // MARK: - Reason Generation

    /// 異常の理由を生成
    private func generateAnomalyReasons(features: SpendingFeatures, score: Double) -> [String] {
        var reasons: [String] = []

        // 高スコアの要因を特定
        if features.amountDeviationScore >= 0.7 {
            reasons.append("通常の支出額から大きく逸脱しています")
        }

        if features.categoryPatternScore >= 0.7 {
            reasons.append("このカテゴリの通常パターンと異なります")
        }

        if features.timePatternScore >= 0.7 {
            reasons.append("通常と異なる時間帯の支出です")
        }

        if features.frequencyScore >= 0.7 {
            reasons.append("支出頻度が通常より高くなっています")
        }

        if features.historicalTrendScore >= 0.7 {
            reasons.append("過去のトレンドから逸脱しています")
        }

        if features.seasonalScore >= 0.7 {
            reasons.append("季節的なパターンと一致しません")
        }

        // 理由がない場合のデフォルト
        if reasons.isEmpty && score >= 0.6 {
            reasons.append("複数の要因が組み合わさって異常と判定されました")
        }

        return reasons
    }

    // MARK: - Batch Analysis

    /// 期間内の異常を分析
    func analyzeAnomaliesInPeriod(
        startDate: Date,
        endDate: Date,
        transactions: [Transaction],
        historicalData: [Transaction],
        threshold: Double = 0.6
    ) -> AnomalyAnalysisSummary {
        let periodTransactions = transactions.filter { t in
            t.date >= startDate && t.date <= endDate && t.type == .expense
        }

        let anomalies = detectAnomalies(
            transactions: periodTransactions,
            historicalData: historicalData,
            threshold: threshold
        )

        // カテゴリ別の異常をグループ化
        var categoryAnomalies: [UUID: Int] = [:]
        for anomaly in anomalies {
            if let transaction = transactions.first(where: { $0.id == anomaly.transactionId }),
               let categoryId = transaction.category?.id {
                categoryAnomalies[categoryId, default: 0] += 1
            }
        }

        // 平均異常スコア
        let averageScore = anomalies.isEmpty ? 0 :
            anomalies.map { $0.anomalyScore }.reduce(0, +) / Double(anomalies.count)

        // 最高異常スコアの取引
        let highestAnomaly = anomalies.max { $0.anomalyScore < $1.anomalyScore }

        return AnomalyAnalysisSummary(
            totalTransactions: periodTransactions.count,
            anomalyCount: anomalies.count,
            averageAnomalyScore: averageScore,
            categoryAnomalyCounts: categoryAnomalies,
            highestAnomaly: highestAnomaly,
            alertLevel: determineOverallAlertLevel(anomalies: anomalies)
        )
    }

    /// 全体のアラートレベルを判定
    private func determineOverallAlertLevel(anomalies: [AnomalyResult]) -> AlertLevel {
        guard !anomalies.isEmpty else { return .normal }

        // 最も高い重大度を返す
        let maxSeverity = anomalies.map { $0.severity.priority }.max() ?? 0

        switch maxSeverity {
        case 3: return .critical
        case 2: return .warning
        case 1: return .caution
        default: return .normal
        }
    }
}

// MARK: - AnomalyAnalysisSummary

/// 異常分析のサマリー
struct AnomalyAnalysisSummary: Sendable {
    let totalTransactions: Int
    let anomalyCount: Int
    let averageAnomalyScore: Double
    let categoryAnomalyCounts: [UUID: Int]
    let highestAnomaly: AnomalyResult?
    let alertLevel: AlertLevel

    var anomalyRate: Double {
        guard totalTransactions > 0 else { return 0 }
        return Double(anomalyCount) / Double(totalTransactions)
    }

    var formattedAnomalyRate: String {
        String(format: "%.1f%%", anomalyRate * 100)
    }
}

// MARK: - AnomalyDetector Extensions

extension AnomalyDetector {
    /// リアルタイム異常検知（新規取引追加時）
    func checkNewTransaction(
        transaction: Transaction,
        recentTransactions: [Transaction]
    ) -> (isAnomaly: Bool, result: AnomalyResult?) {
        let categoryStats = featureExtractor.generateCategoryStats(from: recentTransactions)

        let result = detectAnomaly(
            transaction: transaction,
            historicalData: recentTransactions,
            categoryStats: categoryStats
        )

        let isAnomaly = result.anomalyScore >= 0.6

        return (isAnomaly, isAnomaly ? result : nil)
    }

    /// 異常トレンドを分析
    func analyzeAnomalyTrend(
        anomalies: [AnomalyResult],
        periodDays: Int = 30
    ) -> AnomalyTrend {
        guard !anomalies.isEmpty else {
            return AnomalyTrend(direction: .stable, changeRate: 0, message: "異常は検出されていません")
        }

        let calendar = Calendar.current
        let now = Date()

        // 期間を2分割して比較
        let halfPeriod = periodDays / 2

        guard let midPoint = calendar.date(byAdding: .day, value: -halfPeriod, to: now),
              let startPoint = calendar.date(byAdding: .day, value: -periodDays, to: now) else {
            return AnomalyTrend(direction: .stable, changeRate: 0, message: "データが不足しています")
        }

        let recentAnomalies = anomalies.filter { $0.detectedAt >= midPoint }
        let olderAnomalies = anomalies.filter { $0.detectedAt >= startPoint && $0.detectedAt < midPoint }

        let recentCount = Double(recentAnomalies.count)
        let olderCount = Double(olderAnomalies.count)

        guard olderCount > 0 else {
            if recentCount > 0 {
                return AnomalyTrend(direction: .increasing, changeRate: 1.0, message: "異常が新たに検出され始めています")
            }
            return AnomalyTrend(direction: .stable, changeRate: 0, message: "異常は検出されていません")
        }

        let changeRate = (recentCount - olderCount) / olderCount

        let direction: AnomalyTrend.Direction
        let message: String

        if changeRate > 0.2 {
            direction = .increasing
            message = "異常の発生が増加傾向にあります"
        } else if changeRate < -0.2 {
            direction = .decreasing
            message = "異常の発生が減少傾向にあります"
        } else {
            direction = .stable
            message = "異常の発生は安定しています"
        }

        return AnomalyTrend(direction: direction, changeRate: changeRate, message: message)
    }
}

// MARK: - AnomalyTrend

struct AnomalyTrend: Sendable {
    enum Direction: String, Sendable {
        case increasing = "increasing"
        case decreasing = "decreasing"
        case stable = "stable"

        var icon: String {
            switch self {
            case .increasing: return "arrow.up.right"
            case .decreasing: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
    }

    let direction: Direction
    let changeRate: Double
    let message: String
}
