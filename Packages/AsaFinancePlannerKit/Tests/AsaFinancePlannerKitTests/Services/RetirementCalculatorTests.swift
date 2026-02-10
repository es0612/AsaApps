import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - RetirementCalculatorTests

@Suite("RetirementCalculator テスト")
struct RetirementCalculatorTests {
    let calculator = RetirementCalculator()

    // MARK: - requiredRetirementFund

    @Test("4%ルール計算（年間300万円 → 7500万円必要）")
    func testFourPercentRule() {
        let result = calculator.requiredRetirementFund(
            annualExpense: Decimal(3_000_000)
        )

        #expect(result == Decimal(75_000_000))
    }

    @Test("4%ルール計算（年間500万円 → 1億2500万円必要）")
    func testFourPercentRuleLarger() {
        let result = calculator.requiredRetirementFund(
            annualExpense: Decimal(5_000_000)
        )

        #expect(result == Decimal(125_000_000))
    }

    // MARK: - analyzeRetirementGap

    @Test("退職資金が十分な場合")
    func testSufficientRetirementFund() {
        let analysis = calculator.analyzeRetirementGap(
            currentAssets: Decimal(30_000_000),
            monthlyContribution: Decimal(200_000),
            currentAge: 35,
            retirementAge: 65,
            annualReturnRate: Decimal(string: "0.05")!,
            annualExpense: Decimal(3_000_000)
        )

        // 月20万円 × 年利5% × 30年 は相当大きな額になる
        #expect(analysis.isSufficient == true)
        #expect(analysis.gap <= Decimal.zero)
        #expect(analysis.additionalMonthlyNeeded == Decimal.zero)
    }

    @Test("退職資金が不足する場合")
    func testInsufficientRetirementFund() {
        let analysis = calculator.analyzeRetirementGap(
            currentAssets: Decimal(1_000_000),
            monthlyContribution: Decimal(10000),
            currentAge: 50,
            retirementAge: 65,
            annualReturnRate: Decimal(string: "0.03")!,
            annualExpense: Decimal(4_000_000) // 年間400万円 → 必要1億円
        )

        #expect(analysis.isSufficient == false)
        #expect(analysis.gap > Decimal.zero)
        #expect(analysis.additionalMonthlyNeeded > Decimal.zero)
        #expect(analysis.requiredFund == Decimal(100_000_000))
    }

    @Test("すでに退職年齢に達している場合")
    func testAlreadyRetirementAge() {
        let analysis = calculator.analyzeRetirementGap(
            currentAssets: Decimal(50_000_000),
            monthlyContribution: Decimal.zero,
            currentAge: 65,
            retirementAge: 65,
            annualReturnRate: Decimal(string: "0.03")!,
            annualExpense: Decimal(3_000_000)
        )

        // 退職まで0年、現在資産がそのまま予測値
        #expect(analysis.projectedFund == Decimal(50_000_000))
    }

    @Test("メッセージが空でない")
    func testMessageNotEmpty() {
        let analysis = calculator.analyzeRetirementGap(
            currentAssets: Decimal(5_000_000),
            monthlyContribution: Decimal(50000),
            currentAge: 40,
            retirementAge: 65,
            annualReturnRate: Decimal(string: "0.04")!,
            annualExpense: Decimal(3_000_000)
        )

        #expect(!analysis.message.isEmpty)
    }
}
