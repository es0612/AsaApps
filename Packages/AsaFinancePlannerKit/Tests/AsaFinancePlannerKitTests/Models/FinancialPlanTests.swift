import Foundation
import Testing
@testable import AsaFinancePlannerKit

@Suite("FinancialPlan テスト")
struct FinancialPlanTests {

    @Test("プラン初期化")
    func testInit() {
        let plan = FinancialPlan(name: "マイプラン")
        #expect(plan.name == "マイプラン")
        #expect(plan.currencyCode == "JPY")
        #expect(plan.isActive == true)
        #expect(plan.goals.isEmpty)
        #expect(plan.assets.isEmpty)
        #expect(plan.contributions.isEmpty)
        #expect(plan.scenarios.isEmpty)
    }

    @Test("総資産額の計算")
    func testTotalAssetValue() {
        let plan = FinancialPlan(name: "テスト")
        let asset1 = Asset(name: "株式", assetClass: .domesticStock, currentValue: Decimal(1000000))
        let asset2 = Asset(name: "預金", assetClass: .cash, currentValue: Decimal(500000))
        plan.assets = [asset1, asset2]

        #expect(plan.totalAssetValue == Decimal(1500000))
    }

    @Test("月額積立合計の計算")
    func testMonthlyContributionTotal() {
        let plan = FinancialPlan(name: "テスト")
        let c1 = Contribution(name: "つみたてNISA", monthlyAmount: Decimal(33333), isActive: true)
        let c2 = Contribution(name: "iDeCo", monthlyAmount: Decimal(23000), isActive: true)
        let c3 = Contribution(name: "停止中", monthlyAmount: Decimal(10000), isActive: false)
        plan.contributions = [c1, c2, c3]

        #expect(plan.monthlyContributionTotal == Decimal(56333))
    }

    @Test("資産・積立が空の場合")
    func testEmptyState() {
        let plan = FinancialPlan(name: "空プラン")
        #expect(plan.totalAssetValue == .zero)
        #expect(plan.monthlyContributionTotal == .zero)
        #expect(plan.averageGoalProgress == 0.0)
    }
}
