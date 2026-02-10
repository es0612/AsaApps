import Foundation

@testable import AsaFinancePlannerKit

// MARK: - MockDataService

/// テスト用のモックデータサービス
@MainActor
final class MockDataService: FinanceDataServiceProtocol {
    var plans: [FinancialPlan] = []
    var activePlan: FinancialPlan?
    var settingsToReturn: UserSettings = UserSettings()
    var shouldThrow: Bool = false

    func fetchPlans() throws -> [FinancialPlan] {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        return plans
    }

    func fetchActivePlan() throws -> FinancialPlan? {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        return activePlan
    }

    func savePlan(_ plan: FinancialPlan) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        plans.append(plan)
    }

    func deletePlan(_ plan: FinancialPlan) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        plans.removeAll { $0.id == plan.id }
    }

    func addGoal(_ goal: FinancialGoal, to plan: FinancialPlan) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        plan.goals.append(goal)
    }

    func deleteGoal(_ goal: FinancialGoal) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        if let plan = goal.plan {
            plan.goals.removeAll { $0.id == goal.id }
        }
    }

    func addAsset(_ asset: Asset, to plan: FinancialPlan) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        plan.assets.append(asset)
    }

    func deleteAsset(_ asset: Asset) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        if let plan = asset.plan {
            plan.assets.removeAll { $0.id == asset.id }
        }
    }

    func addContribution(_ contribution: Contribution, to plan: FinancialPlan) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        plan.contributions.append(contribution)
    }

    func deleteContribution(_ contribution: Contribution) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
    }

    func addScenario(_ scenario: Scenario, to plan: FinancialPlan) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        plan.scenarios.append(scenario)
    }

    func deleteScenario(_ scenario: Scenario) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        if let plan = scenario.plan {
            plan.scenarios.removeAll { $0.id == scenario.id }
        }
    }

    func fetchSettings() throws -> UserSettings {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        return settingsToReturn
    }

    func saveSettings(_ settings: UserSettings) throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
        settingsToReturn = settings
    }

    func save() throws {
        if shouldThrow { throw FinancePlannerError.dataServiceError("mock error") }
    }
}

// MARK: - MockProjectionCalculator

/// テスト用のモック将来予測計算器
struct MockProjectionCalculator: ProjectionCalculating {
    var futureValueToReturn: Decimal = Decimal(10_000_000)
    var projectionToReturn: [ProjectionPoint] = []

    func calculateFutureValue(
        presentValue: Decimal,
        monthlyContribution: Decimal,
        annualRate: Decimal,
        years: Int
    ) -> Decimal {
        futureValueToReturn
    }

    func generateProjection(
        presentValue: Decimal,
        monthlyContribution: Decimal,
        annualRate: Decimal,
        inflationRate: Decimal,
        years: Int
    ) -> [ProjectionPoint] {
        if projectionToReturn.isEmpty {
            return (0...years).map { year in
                ProjectionPoint(
                    year: year,
                    nominalValue: presentValue + monthlyContribution * Decimal(12 * year),
                    realValue: presentValue + monthlyContribution * Decimal(12 * year),
                    contributionTotal: presentValue + monthlyContribution * Decimal(12 * year)
                )
            }
        }
        return projectionToReturn
    }
}

// MARK: - MockInsightGenerator

/// テスト用のモックインサイト生成器
struct MockInsightGenerator: InsightGenerating {
    var insightsToReturn: [FinancialInsight] = []

    func generateInsights(
        plan: FinancialPlan,
        settings: UserSettings
    ) -> [FinancialInsight] {
        insightsToReturn
    }
}

// MARK: - MockGoalAnalyzer

/// テスト用のモック目標分析器
struct MockGoalAnalyzer: GoalAnalyzing {
    var resultToReturn: GoalFeasibilityResult

    init(resultToReturn: GoalFeasibilityResult? = nil) {
        self.resultToReturn = resultToReturn ?? GoalFeasibilityResult(
            goal: "テスト目標",
            isFeasible: true,
            projectedAmount: Decimal(5_000_000),
            shortfall: Decimal.zero,
            requiredMonthlyContribution: Decimal(50000),
            probabilityOfSuccess: 0.85,
            message: "達成可能です"
        )
    }

    func analyzeFeasibility(
        goal: FinancialGoal,
        currentAssets: Decimal,
        monthlyContribution: Decimal,
        annualReturnRate: Decimal,
        inflationRate: Decimal
    ) -> GoalFeasibilityResult {
        resultToReturn
    }
}

// MARK: - MockAllocationOptimizer

/// テスト用のモック配分最適化器
struct MockAllocationOptimizer: AllocationOptimizing {
    var currentAllocationsToReturn: [AssetAllocation] = []
    var targetAllocationsToReturn: [AssetAllocation] = []
    var suggestionsToReturn: [RebalanceSuggestion] = []

    func calculateCurrentAllocation(assets: [Asset]) -> [AssetAllocation] {
        currentAllocationsToReturn
    }

    func suggestTargetAllocation(age: Int, riskTolerance: RiskTolerance) -> [AssetAllocation] {
        targetAllocationsToReturn
    }

    func generateRebalanceSuggestions(
        current: [AssetAllocation],
        target: [AssetAllocation]
    ) -> [RebalanceSuggestion] {
        suggestionsToReturn
    }
}
