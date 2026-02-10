import Foundation
import SwiftData

// MARK: - FinancialPlan

/// 金融プランの最上位エンティティ
@Model
public final class FinancialPlan {
    public var id: UUID = UUID()
    public var name: String = ""
    public var currencyCode: String = "JPY"
    public var isActive: Bool = true
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \FinancialGoal.plan)
    public var goals: [FinancialGoal] = []

    @Relationship(deleteRule: .cascade, inverse: \Asset.plan)
    public var assets: [Asset] = []

    @Relationship(deleteRule: .cascade, inverse: \Contribution.plan)
    public var contributions: [Contribution] = []

    @Relationship(deleteRule: .cascade, inverse: \Scenario.plan)
    public var scenarios: [Scenario] = []

    public init(
        name: String,
        currencyCode: String = "JPY"
    ) {
        self.id = UUID()
        self.name = name
        self.currencyCode = currencyCode
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// 総資産額
    public var totalAssetValue: Decimal {
        assets.reduce(.zero) { $0 + $1.currentValue }
    }

    /// 月額積立合計
    public var monthlyContributionTotal: Decimal {
        contributions
            .filter(\.isActive)
            .reduce(.zero) { $0 + $1.monthlyAmount }
    }

    /// 目標達成率の平均
    public var averageGoalProgress: Double {
        guard !goals.isEmpty else { return 0.0 }
        let totalProgress = goals.reduce(0.0) { $0 + $1.progressPercentage }
        return totalProgress / Double(goals.count)
    }
}
