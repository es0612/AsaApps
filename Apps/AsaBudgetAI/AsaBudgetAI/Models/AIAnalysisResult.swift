import Foundation

// MARK: - AIAnalysisResult

/// AI分析の総合結果
struct AIAnalysisResult: Codable, Sendable, Identifiable {
    let id: UUID
    let analyzedAt: Date
    let analysisType: AnalysisType
    let overallScore: Double              // 総合スコア (0.0-1.0)
    let confidence: Double                // 信頼度 (0.0-1.0)
    let alertLevel: AlertLevel
    let insights: [AIInsight]
    let predictions: [SpendingPrediction]
    let recommendations: [BudgetRecommendation]
    let detectedAnomalies: [AnomalyResult]

    init(
        id: UUID = UUID(),
        analyzedAt: Date = Date(),
        analysisType: AnalysisType = .comprehensive,
        overallScore: Double,
        confidence: Double,
        alertLevel: AlertLevel,
        insights: [AIInsight] = [],
        predictions: [SpendingPrediction] = [],
        recommendations: [BudgetRecommendation] = [],
        detectedAnomalies: [AnomalyResult] = []
    ) {
        self.id = id
        self.analyzedAt = analyzedAt
        self.analysisType = analysisType
        self.overallScore = overallScore
        self.confidence = confidence
        self.alertLevel = alertLevel
        self.insights = insights
        self.predictions = predictions
        self.recommendations = recommendations
        self.detectedAnomalies = detectedAnomalies
    }
}

// MARK: - AnalysisType

enum AnalysisType: String, Codable, CaseIterable, Sendable {
    case comprehensive = "comprehensive"    // 総合分析
    case anomalyDetection = "anomaly"       // 異常検知
    case trendAnalysis = "trend"            // トレンド分析
    case prediction = "prediction"          // 予測分析
    case budgetOptimization = "optimization" // 予算最適化

    var displayName: String {
        switch self {
        case .comprehensive: return "総合分析"
        case .anomalyDetection: return "異常検知"
        case .trendAnalysis: return "トレンド分析"
        case .prediction: return "予測分析"
        case .budgetOptimization: return "予算最適化"
        }
    }
}

// MARK: - AlertLevel

enum AlertLevel: String, Codable, CaseIterable, Sendable {
    case normal = "normal"
    case caution = "caution"
    case warning = "warning"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .normal: return "正常"
        case .caution: return "注意"
        case .warning: return "警告"
        case .critical: return "緊急"
        }
    }

    var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .caution: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    var colorName: String {
        switch self {
        case .normal: return "green"
        case .caution: return "yellow"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }

    var priority: Int {
        switch self {
        case .normal: return 0
        case .caution: return 1
        case .warning: return 2
        case .critical: return 3
        }
    }
}

// MARK: - AIInsight

/// AI分析から得られた洞察
struct AIInsight: Codable, Sendable, Identifiable {
    let id: UUID
    let category: InsightCategory
    let title: String
    let description: String
    let importance: Double              // 重要度 (0.0-1.0)
    let actionable: Bool                // 行動可能かどうか
    let relatedCategoryIds: [UUID]

    init(
        id: UUID = UUID(),
        category: InsightCategory,
        title: String,
        description: String,
        importance: Double,
        actionable: Bool = false,
        relatedCategoryIds: [UUID] = []
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.importance = importance
        self.actionable = actionable
        self.relatedCategoryIds = relatedCategoryIds
    }
}

enum InsightCategory: String, Codable, CaseIterable, Sendable {
    case spending = "spending"
    case saving = "saving"
    case pattern = "pattern"
    case budget = "budget"
    case anomaly = "anomaly"

    var displayName: String {
        switch self {
        case .spending: return "支出"
        case .saving: return "節約"
        case .pattern: return "パターン"
        case .budget: return "予算"
        case .anomaly: return "異常"
        }
    }

    var icon: String {
        switch self {
        case .spending: return "creditcard.fill"
        case .saving: return "banknote.fill"
        case .pattern: return "chart.line.uptrend.xyaxis"
        case .budget: return "chart.pie.fill"
        case .anomaly: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - SpendingPrediction

/// 支出予測
struct SpendingPrediction: Codable, Sendable, Identifiable {
    let id: UUID
    let predictedAmount: Double
    let predictedDate: Date
    let categoryId: UUID?
    let confidence: Double
    let basis: PredictionBasis

    init(
        id: UUID = UUID(),
        predictedAmount: Double,
        predictedDate: Date,
        categoryId: UUID? = nil,
        confidence: Double,
        basis: PredictionBasis
    ) {
        self.id = id
        self.predictedAmount = predictedAmount
        self.predictedDate = predictedDate
        self.categoryId = categoryId
        self.confidence = confidence
        self.basis = basis
    }
}

enum PredictionBasis: String, Codable, Sendable {
    case historical = "historical"          // 過去データに基づく
    case trend = "trend"                    // トレンドに基づく
    case seasonal = "seasonal"              // 季節性に基づく
    case hybrid = "hybrid"                  // 複合

    var displayName: String {
        switch self {
        case .historical: return "過去データ"
        case .trend: return "トレンド"
        case .seasonal: return "季節性"
        case .hybrid: return "複合分析"
        }
    }
}

// MARK: - BudgetRecommendation

/// 予算の提案
struct BudgetRecommendation: Codable, Sendable, Identifiable {
    let id: UUID
    let type: RecommendationType
    let title: String
    let description: String
    let suggestedAmount: Double?
    let potentialSaving: Double?
    let categoryId: UUID?
    let priority: RecommendationPriority
    let confidence: Double

    init(
        id: UUID = UUID(),
        type: RecommendationType,
        title: String,
        description: String,
        suggestedAmount: Double? = nil,
        potentialSaving: Double? = nil,
        categoryId: UUID? = nil,
        priority: RecommendationPriority = .medium,
        confidence: Double
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.suggestedAmount = suggestedAmount
        self.potentialSaving = potentialSaving
        self.categoryId = categoryId
        self.priority = priority
        self.confidence = confidence
    }
}

enum RecommendationType: String, Codable, CaseIterable, Sendable {
    case increaseBudget = "increase"
    case decreaseBudget = "decrease"
    case createCategory = "create_category"
    case mergeCategories = "merge"
    case setAlert = "alert"
    case reviewSpending = "review"

    var displayName: String {
        switch self {
        case .increaseBudget: return "予算増額"
        case .decreaseBudget: return "予算削減"
        case .createCategory: return "カテゴリ作成"
        case .mergeCategories: return "カテゴリ統合"
        case .setAlert: return "アラート設定"
        case .reviewSpending: return "支出見直し"
        }
    }

    var icon: String {
        switch self {
        case .increaseBudget: return "arrow.up.circle.fill"
        case .decreaseBudget: return "arrow.down.circle.fill"
        case .createCategory: return "plus.circle.fill"
        case .mergeCategories: return "arrow.triangle.merge"
        case .setAlert: return "bell.badge.fill"
        case .reviewSpending: return "magnifyingglass.circle.fill"
        }
    }
}

enum RecommendationPriority: String, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
}

// MARK: - AnomalyResult

/// 異常検知結果
struct AnomalyResult: Codable, Sendable, Identifiable {
    let id: UUID
    let transactionId: UUID
    let anomalyScore: Double            // 異常スコア (0.0-1.0)
    let severity: AlertLevel
    let reasons: [String]
    let features: SpendingFeatures
    let detectedAt: Date

    init(
        id: UUID = UUID(),
        transactionId: UUID,
        anomalyScore: Double,
        severity: AlertLevel,
        reasons: [String],
        features: SpendingFeatures,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.transactionId = transactionId
        self.anomalyScore = anomalyScore
        self.severity = severity
        self.reasons = reasons
        self.features = features
        self.detectedAt = detectedAt
    }
}
