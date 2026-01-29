import Foundation

// MARK: - AIInsightsViewModel

/// AI洞察画面のViewModel
@Observable
@MainActor
final class AIInsightsViewModel {

    // MARK: - Properties

    var analysisResult: AIAnalysisResult?
    var budgetPrediction: BudgetPredictionResult?
    var budgetRecommendation: MonthlyBudgetRecommendation?
    var categoryRecommendations: [CategoryBudgetRecommendation] = []
    var anomalyTrend: AnomalyTrend?
    var isAnalyzing = false
    var lastAnalyzedAt: Date?
    var errorMessage: String?

    // MARK: - Dependencies

    private let dataService: DataService
    private let analyzer: EnhancedSpendingAnalyzer
    private let predictor: BudgetPredictor
    private let recommender: SmartBudgetRecommender

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
        self.analyzer = EnhancedSpendingAnalyzer()
        self.predictor = BudgetPredictor()
        self.recommender = SmartBudgetRecommender()
    }

    // MARK: - Analysis

    /// 総合AI分析を実行
    func runComprehensiveAnalysis() async {
        isAnalyzing = true
        errorMessage = nil

        do {
            let transactions = dataService.fetchTransactions()
            let categories = dataService.fetchCategories()
            let budget = dataService.fetchCurrentBudget()
            let settings = dataService.fetchUserSettings()

            // 総合分析を実行
            analysisResult = await analyzer.performComprehensiveAnalysis(
                transactions: transactions,
                budget: budget,
                categories: categories,
                settings: settings
            )

            // 予算予測
            if let budget = budget {
                budgetPrediction = predictor.predictBudgetExceedance(
                    budget: budget,
                    currentSpent: budget.spentAmount,
                    historicalData: transactions
                )
            }

            // 予算推奨
            budgetRecommendation = recommender.recommendMonthlyBudget(
                historicalData: transactions
            )

            // カテゴリ別推奨
            if let budget = budget {
                categoryRecommendations = recommender.recommendCategoryBudgets(
                    historicalData: transactions,
                    totalBudget: budget.totalAmount,
                    categories: categories
                )
            }

            // 異常トレンド
            if let anomalies = analysisResult?.detectedAnomalies {
                let anomalyDetector = AnomalyDetector()
                anomalyTrend = anomalyDetector.analyzeAnomalyTrend(anomalies: anomalies)
            }

            lastAnalyzedAt = Date()

        } catch {
            errorMessage = "分析中にエラーが発生しました: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    /// クイック分析（軽量版）
    func runQuickAnalysis() async {
        isAnalyzing = true

        let transactions = dataService.fetchTransactions()
        let budget = dataService.fetchCurrentBudget()

        // 予算予測のみ
        if let budget = budget {
            budgetPrediction = predictor.predictBudgetExceedance(
                budget: budget,
                currentSpent: budget.spentAmount,
                historicalData: transactions
            )
        }

        isAnalyzing = false
    }

    // MARK: - Computed Properties

    var hasAnalysisResult: Bool {
        analysisResult != nil
    }

    var alertLevel: AlertLevel {
        analysisResult?.alertLevel ?? .normal
    }

    var topInsights: [AIInsight] {
        Array((analysisResult?.insights ?? []).prefix(5))
    }

    var topRecommendations: [BudgetRecommendation] {
        Array((analysisResult?.recommendations ?? []).prefix(3))
    }

    var anomalyCount: Int {
        analysisResult?.detectedAnomalies.count ?? 0
    }

    var overallScore: Double {
        analysisResult?.overallScore ?? 0
    }

    var confidence: Double {
        analysisResult?.confidence ?? 0
    }

    var formattedLastAnalyzedAt: String {
        guard let date = lastAnalyzedAt else { return "未分析" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var budgetRiskLevel: AlertLevel {
        budgetPrediction?.riskLevel ?? .normal
    }

    var willExceedBudget: Bool {
        budgetPrediction?.willExceed ?? false
    }

    // MARK: - Insight Helpers

    func insights(for category: InsightCategory) -> [AIInsight] {
        analysisResult?.insights.filter { $0.category == category } ?? []
    }

    var actionableInsights: [AIInsight] {
        analysisResult?.insights.filter { $0.actionable } ?? []
    }

    var highPriorityRecommendations: [BudgetRecommendation] {
        analysisResult?.recommendations.filter { $0.priority == .high } ?? []
    }
}

// MARK: - Analysis Status

extension AIInsightsViewModel {
    enum AnalysisStatus {
        case notAnalyzed
        case analyzing
        case completed
        case error(String)

        var displayName: String {
            switch self {
            case .notAnalyzed: return "未分析"
            case .analyzing: return "分析中..."
            case .completed: return "分析完了"
            case .error(let message): return "エラー: \(message)"
            }
        }
    }

    var status: AnalysisStatus {
        if let error = errorMessage {
            return .error(error)
        }
        if isAnalyzing {
            return .analyzing
        }
        if hasAnalysisResult {
            return .completed
        }
        return .notAnalyzed
    }
}
