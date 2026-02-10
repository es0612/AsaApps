import Foundation

// MARK: - DashboardViewModel

/// ダッシュボード画面のViewModel
///
/// アクティブプランの概要表示、インサイト生成を担当する。
/// DI経由で `FinanceDataServiceProtocol` と `InsightGenerating` を受け取る。
@MainActor @Observable
public final class DashboardViewModel {
    // MARK: - Dependencies

    private let dataService: FinanceDataServiceProtocol
    private let insightEngine: InsightGenerating

    // MARK: - Properties

    public var plan: FinancialPlan?
    public var insights: [FinancialInsight] = []
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        dataService: FinanceDataServiceProtocol,
        insightEngine: InsightGenerating = InsightEngine()
    ) {
        self.dataService = dataService
        self.insightEngine = insightEngine
    }

    // MARK: - Methods

    /// アクティブプランを取得し、インサイトを生成する
    public func loadDashboard() {
        isLoading = true
        errorMessage = nil
        do {
            plan = try dataService.fetchActivePlan()
            if let plan {
                let settings = try dataService.fetchSettings()
                insights = insightEngine.generateInsights(plan: plan, settings: settings)
            } else {
                insights = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 総資産額
    public var totalAssetValue: Decimal {
        plan?.totalAssetValue ?? Decimal.zero
    }

    /// 月額積立合計
    public var monthlyContribution: Decimal {
        plan?.monthlyContributionTotal ?? Decimal.zero
    }

    /// 上位3件の目標
    public var topGoals: [FinancialGoal] {
        guard let plan else { return [] }
        return Array(plan.goals.sorted { $0.priority > $1.priority }.prefix(3))
    }

    /// 目標達成率の平均
    public var goalProgressSummary: Double {
        plan?.averageGoalProgress ?? 0.0
    }
}
