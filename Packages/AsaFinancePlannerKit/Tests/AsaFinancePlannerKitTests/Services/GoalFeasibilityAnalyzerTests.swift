import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - GoalFeasibilityAnalyzerTests

@Suite("GoalFeasibilityAnalyzer テスト")
struct GoalFeasibilityAnalyzerTests {
    let analyzer = GoalFeasibilityAnalyzer()

    // MARK: - Helpers

    private func makeGoal(
        name: String = "テスト目標",
        targetAmount: Decimal,
        currentAmount: Decimal = .zero,
        targetDate: Date? = nil
    ) -> FinancialGoal {
        FinancialGoal(
            name: name,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: targetDate ?? Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        )
    }

    // MARK: - Tests

    @Test("達成可能な目標（余裕あり）")
    func testFeasibleGoal() {
        let goal = makeGoal(
            name: "教育資金",
            targetAmount: Decimal(5_000_000)
        )

        let result = analyzer.analyzeFeasibility(
            goal: goal,
            currentAssets: Decimal(2_000_000),
            monthlyContribution: Decimal(50000),
            annualReturnRate: Decimal(string: "0.05")!,
            inflationRate: Decimal(string: "0.02")!
        )

        #expect(result.isFeasible == true)
        #expect(result.probabilityOfSuccess > 0.8)
        #expect(result.shortfall == Decimal.zero)
        #expect(result.goal == "教育資金")
    }

    @Test("達成困難な目標")
    func testInfeasibleGoal() {
        let goal = makeGoal(
            name: "高額目標",
            targetAmount: Decimal(100_000_000),
            targetDate: Calendar.current.date(byAdding: .year, value: 5, to: Date())!
        )

        let result = analyzer.analyzeFeasibility(
            goal: goal,
            currentAssets: Decimal(1_000_000),
            monthlyContribution: Decimal(30000),
            annualReturnRate: Decimal(string: "0.03")!,
            inflationRate: Decimal(string: "0.02")!
        )

        #expect(result.isFeasible == false)
        #expect(result.shortfall > Decimal.zero)
        #expect(result.requiredMonthlyContribution > Decimal.zero)
    }

    @Test("必要月額追加の逆算が正の値")
    func testRequiredMonthlyContribution() {
        let goal = makeGoal(
            name: "住宅頭金",
            targetAmount: Decimal(30_000_000),
            targetDate: Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        )

        let result = analyzer.analyzeFeasibility(
            goal: goal,
            currentAssets: Decimal(500000),
            monthlyContribution: Decimal(20000),
            annualReturnRate: Decimal(string: "0.04")!,
            inflationRate: Decimal(string: "0.02")!
        )

        if !result.isFeasible {
            #expect(result.requiredMonthlyContribution > Decimal.zero)
        }
    }

    @Test("達成確率は0.0〜1.0の範囲")
    func testProbabilityRange() {
        let goal = makeGoal(targetAmount: Decimal(10_000_000))

        let result = analyzer.analyzeFeasibility(
            goal: goal,
            currentAssets: Decimal(3_000_000),
            monthlyContribution: Decimal(40000),
            annualReturnRate: Decimal(string: "0.05")!,
            inflationRate: Decimal(string: "0.02")!
        )

        #expect(result.probabilityOfSuccess >= 0.0)
        #expect(result.probabilityOfSuccess <= 1.0)
    }

    @Test("メッセージが空でない")
    func testMessageNotEmpty() {
        let goal = makeGoal(name: "テスト", targetAmount: Decimal(5_000_000))

        let result = analyzer.analyzeFeasibility(
            goal: goal,
            currentAssets: Decimal(1_000_000),
            monthlyContribution: Decimal(30000),
            annualReturnRate: Decimal(string: "0.04")!,
            inflationRate: Decimal(string: "0.01")!
        )

        #expect(!result.message.isEmpty)
    }
}
