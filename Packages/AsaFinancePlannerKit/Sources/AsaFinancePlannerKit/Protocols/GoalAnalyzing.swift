import Foundation

// MARK: - GoalFeasibilityResult

/// 目標達成可能性の分析結果
public struct GoalFeasibilityResult: Sendable {
    public let goal: String
    public let isFeasible: Bool
    public let projectedAmount: Decimal
    public let shortfall: Decimal
    public let requiredMonthlyContribution: Decimal
    public let probabilityOfSuccess: Double
    public let message: String

    public init(
        goal: String,
        isFeasible: Bool,
        projectedAmount: Decimal,
        shortfall: Decimal,
        requiredMonthlyContribution: Decimal,
        probabilityOfSuccess: Double,
        message: String
    ) {
        self.goal = goal
        self.isFeasible = isFeasible
        self.projectedAmount = projectedAmount
        self.shortfall = shortfall
        self.requiredMonthlyContribution = requiredMonthlyContribution
        self.probabilityOfSuccess = probabilityOfSuccess
        self.message = message
    }
}

// MARK: - GoalAnalyzing

/// 目標達成分析プロトコル
public protocol GoalAnalyzing: Sendable {
    /// 目標の達成可能性を分析
    /// - Parameters:
    ///   - goal: 分析対象の目標
    ///   - currentAssets: 現在の総資産額
    ///   - monthlyContribution: 月額積立額
    ///   - annualReturnRate: 年間リターン率
    ///   - inflationRate: インフレ率
    /// - Returns: 達成可能性の分析結果
    func analyzeFeasibility(
        goal: FinancialGoal,
        currentAssets: Decimal,
        monthlyContribution: Decimal,
        annualReturnRate: Decimal,
        inflationRate: Decimal
    ) -> GoalFeasibilityResult
}
