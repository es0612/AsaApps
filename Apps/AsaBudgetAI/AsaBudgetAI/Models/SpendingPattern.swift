import Foundation

// MARK: - SpendingPattern

/// 支出パターンの分析結果を表す構造体
struct SpendingPattern: Codable, Sendable, Identifiable {
    let id: UUID
    let patternType: PatternType
    let description: String
    let confidence: Double
    let affectedCategories: [UUID]
    let detectedAt: Date
    let metrics: PatternMetrics

    init(
        id: UUID = UUID(),
        patternType: PatternType,
        description: String,
        confidence: Double,
        affectedCategories: [UUID] = [],
        detectedAt: Date = Date(),
        metrics: PatternMetrics = PatternMetrics()
    ) {
        self.id = id
        self.patternType = patternType
        self.description = description
        self.confidence = confidence
        self.affectedCategories = affectedCategories
        self.detectedAt = detectedAt
        self.metrics = metrics
    }
}

// MARK: - PatternType

enum PatternType: String, Codable, CaseIterable, Sendable {
    case increasing = "increasing"          // 増加傾向
    case decreasing = "decreasing"          // 減少傾向
    case stable = "stable"                  // 安定
    case seasonal = "seasonal"              // 季節性
    case irregular = "irregular"            // 不規則
    case weekendHeavy = "weekend_heavy"     // 週末集中
    case weekdayHeavy = "weekday_heavy"     // 平日集中
    case endOfMonth = "end_of_month"        // 月末集中

    var displayName: String {
        switch self {
        case .increasing: return "増加傾向"
        case .decreasing: return "減少傾向"
        case .stable: return "安定"
        case .seasonal: return "季節変動"
        case .irregular: return "不規則"
        case .weekendHeavy: return "週末集中型"
        case .weekdayHeavy: return "平日集中型"
        case .endOfMonth: return "月末集中型"
        }
    }

    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .seasonal: return "leaf.fill"
        case .irregular: return "waveform.path.ecg"
        case .weekendHeavy: return "calendar.badge.clock"
        case .weekdayHeavy: return "briefcase.fill"
        case .endOfMonth: return "calendar.badge.exclamationmark"
        }
    }

    var severity: PatternSeverity {
        switch self {
        case .increasing: return .warning
        case .decreasing: return .positive
        case .stable: return .neutral
        case .seasonal: return .neutral
        case .irregular: return .warning
        case .weekendHeavy: return .neutral
        case .weekdayHeavy: return .neutral
        case .endOfMonth: return .warning
        }
    }
}

// MARK: - PatternSeverity

enum PatternSeverity: String, Codable, Sendable {
    case positive = "positive"
    case neutral = "neutral"
    case warning = "warning"
    case critical = "critical"

    var colorName: String {
        switch self {
        case .positive: return "green"
        case .neutral: return "blue"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - PatternMetrics

struct PatternMetrics: Codable, Sendable {
    var averageAmount: Double
    var standardDeviation: Double
    var trendSlope: Double
    var volatility: Double
    var peakDay: Int?           // 1-31
    var peakHour: Int?          // 0-23
    var sampleSize: Int

    init(
        averageAmount: Double = 0,
        standardDeviation: Double = 0,
        trendSlope: Double = 0,
        volatility: Double = 0,
        peakDay: Int? = nil,
        peakHour: Int? = nil,
        sampleSize: Int = 0
    ) {
        self.averageAmount = averageAmount
        self.standardDeviation = standardDeviation
        self.trendSlope = trendSlope
        self.volatility = volatility
        self.peakDay = peakDay
        self.peakHour = peakHour
        self.sampleSize = sampleSize
    }
}

// MARK: - SpendingFeatures

/// 支出の特徴量を表す構造体（AI分析用）
struct SpendingFeatures: Codable, Sendable {
    let categoryPatternScore: Double      // カテゴリパターンスコア (0.0-1.0)
    let amountDeviationScore: Double      // 金額偏差スコア (0.0-1.0)
    let timePatternScore: Double          // 時間パターンスコア (0.0-1.0)
    let frequencyScore: Double            // 頻度スコア (0.0-1.0)
    let historicalTrendScore: Double      // 履歴トレンドスコア (0.0-1.0)
    let seasonalScore: Double             // 季節変動スコア (0.0-1.0)

    var totalScore: Double {
        categoryPatternScore + amountDeviationScore + timePatternScore +
        frequencyScore + historicalTrendScore + seasonalScore
    }

    init(
        categoryPatternScore: Double = 0,
        amountDeviationScore: Double = 0,
        timePatternScore: Double = 0,
        frequencyScore: Double = 0,
        historicalTrendScore: Double = 0,
        seasonalScore: Double = 0
    ) {
        self.categoryPatternScore = min(max(categoryPatternScore, 0), 1)
        self.amountDeviationScore = min(max(amountDeviationScore, 0), 1)
        self.timePatternScore = min(max(timePatternScore, 0), 1)
        self.frequencyScore = min(max(frequencyScore, 0), 1)
        self.historicalTrendScore = min(max(historicalTrendScore, 0), 1)
        self.seasonalScore = min(max(seasonalScore, 0), 1)
    }
}

// MARK: - CategorySpendingStats

/// カテゴリ別の支出統計
struct CategorySpendingStats: Codable, Sendable, Identifiable {
    var id: UUID { categoryId }
    let categoryId: UUID
    let categoryName: String
    let totalAmount: Double
    let transactionCount: Int
    let averageAmount: Double
    let percentageOfTotal: Double
    let trend: TrendDirection
    let comparedToLastMonth: Double  // -1.0 to +1.0 (前月比)

    enum TrendDirection: String, Codable, Sendable {
        case up = "up"
        case down = "down"
        case stable = "stable"

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            }
        }
    }
}
