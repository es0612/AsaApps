import Foundation
import SwiftData

// MARK: - UserSettings Model

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - AI分析重み設定（合計100%）

    /// カテゴリパターン重み（通常支出との乖離度）
    var categoryPatternWeight: Double

    /// 金額偏差重み（過去平均からの乖離）
    var amountDeviationWeight: Double

    /// 時間パターン重み（通常の支出時間帯との乖離）
    var timePatternWeight: Double

    /// 支出頻度重み（通常の頻度との乖離）
    var frequencyWeight: Double

    /// 履歴トレンド重み（過去の傾向との整合性）
    var historicalTrendWeight: Double

    /// 季節変動重み（季節的パターンの考慮）
    var seasonalWeight: Double

    // MARK: - 予算警告設定

    /// 70%到達時の警告
    var budgetWarningAt70: Bool

    /// 90%到達時の警告
    var budgetWarningAt90: Bool

    /// 100%到達時の警告
    var budgetWarningAt100: Bool

    /// カスタム警告閾値（%）
    var customWarningThreshold: Double?

    // MARK: - 通知設定

    /// 日次レポート通知
    var dailyReportEnabled: Bool

    /// 日次レポート時間（時）
    var dailyReportHour: Int

    /// 異常検知通知
    var anomalyNotificationEnabled: Bool

    /// 予算超過通知
    var budgetExceededNotificationEnabled: Bool

    // MARK: - 表示設定

    /// 通貨コード
    var currencyCode: String

    /// デフォルト表示期間
    var defaultPeriodRawValue: String

    /// ダークモード自動切替
    var autoThemeEnabled: Bool

    // MARK: - AI設定

    /// LLM分析を有効化（iOS 18+）
    var llmAnalysisEnabled: Bool

    /// 自動異常検知
    var autoAnomalyDetection: Bool

    /// 異常スコア閾値（この値以上を異常とみなす）
    var anomalyThreshold: Double

    // MARK: - Computed Properties

    var defaultPeriod: BudgetPeriod {
        get { BudgetPeriod(rawValue: defaultPeriodRawValue) ?? .monthly }
        set { defaultPeriodRawValue = newValue.rawValue }
    }

    /// 重みの合計
    var totalWeights: Double {
        categoryPatternWeight + amountDeviationWeight +
        timePatternWeight + frequencyWeight +
        historicalTrendWeight + seasonalWeight
    }

    /// 重みが有効か（合計が約1.0）
    var isWeightsValid: Bool {
        abs(totalWeights - 1.0) < 0.01
    }

    /// AI分析重みをPriorityWeightsとして取得
    var analysisWeights: AnalysisWeights {
        AnalysisWeights(
            categoryPattern: categoryPatternWeight,
            amountDeviation: amountDeviationWeight,
            timePattern: timePatternWeight,
            frequency: frequencyWeight,
            historicalTrend: historicalTrendWeight,
            seasonal: seasonalWeight
        )
    }

    // MARK: - Initializers

    init(id: UUID = UUID()) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()

        // デフォルト重み設定
        self.categoryPatternWeight = 0.25
        self.amountDeviationWeight = 0.25
        self.timePatternWeight = 0.15
        self.frequencyWeight = 0.15
        self.historicalTrendWeight = 0.10
        self.seasonalWeight = 0.10

        // 予算警告設定
        self.budgetWarningAt70 = true
        self.budgetWarningAt90 = true
        self.budgetWarningAt100 = true
        self.customWarningThreshold = nil

        // 通知設定
        self.dailyReportEnabled = true
        self.dailyReportHour = 20
        self.anomalyNotificationEnabled = true
        self.budgetExceededNotificationEnabled = true

        // 表示設定
        self.currencyCode = "JPY"
        self.defaultPeriodRawValue = BudgetPeriod.monthly.rawValue
        self.autoThemeEnabled = true

        // AI設定
        self.llmAnalysisEnabled = true
        self.autoAnomalyDetection = true
        self.anomalyThreshold = 0.6
    }

    // MARK: - Methods

    func resetWeightsToDefault() {
        categoryPatternWeight = 0.25
        amountDeviationWeight = 0.25
        timePatternWeight = 0.15
        frequencyWeight = 0.15
        historicalTrendWeight = 0.10
        seasonalWeight = 0.10
        updatedAt = Date()
    }

    func normalizeWeights() {
        let total = totalWeights
        guard total > 0 else {
            resetWeightsToDefault()
            return
        }

        categoryPatternWeight /= total
        amountDeviationWeight /= total
        timePatternWeight /= total
        frequencyWeight /= total
        historicalTrendWeight /= total
        seasonalWeight /= total
        updatedAt = Date()
    }
}

// MARK: - AnalysisWeights

/// AI分析で使用する重み設定
struct AnalysisWeights: Codable, Sendable {
    let categoryPattern: Double
    let amountDeviation: Double
    let timePattern: Double
    let frequency: Double
    let historicalTrend: Double
    let seasonal: Double

    static let `default` = AnalysisWeights(
        categoryPattern: 0.25,
        amountDeviation: 0.25,
        timePattern: 0.15,
        frequency: 0.15,
        historicalTrend: 0.10,
        seasonal: 0.10
    )

    var total: Double {
        categoryPattern + amountDeviation + timePattern +
        frequency + historicalTrend + seasonal
    }

    var isValid: Bool {
        abs(total - 1.0) < 0.01
    }

    func weightedScore(features: SpendingFeatures) -> Double {
        features.categoryPatternScore * categoryPattern +
        features.amountDeviationScore * amountDeviation +
        features.timePatternScore * timePattern +
        features.frequencyScore * frequency +
        features.historicalTrendScore * historicalTrend +
        features.seasonalScore * seasonal
    }
}
