import Testing
import Foundation
@testable import AsaPortfolio

/// PerformanceCalculator テスト
struct PerformanceCalculatorTests {

    // MARK: - Gain/Loss Calculation Tests

    @Test("損益計算 - 利益ケース")
    func testGainCalculationProfit() {
        let result = PerformanceCalculator.calculateGain(
            currentValue: Decimal(1200),
            costBasis: Decimal(1000)
        )

        #expect(result.amount == Decimal(200))
        #expect(abs(result.percentage - 20.0) < 0.01)
        #expect(result.isProfit == true)
    }

    @Test("損益計算 - 損失ケース")
    func testGainCalculationLoss() {
        let result = PerformanceCalculator.calculateGain(
            currentValue: Decimal(800),
            costBasis: Decimal(1000)
        )

        #expect(result.amount == Decimal(-200))
        #expect(abs(result.percentage - (-20.0)) < 0.01)
        #expect(result.isProfit == false)
    }

    @Test("損益計算 - ゼロコストケース")
    func testGainCalculationZeroCost() {
        let result = PerformanceCalculator.calculateGain(
            currentValue: Decimal(1000),
            costBasis: Decimal(0)
        )

        #expect(result.amount == Decimal(1000))
        #expect(result.percentage == 0)
        #expect(result.isProfit == true)
    }

    @Test("損益計算 - 同額ケース")
    func testGainCalculationBreakEven() {
        let result = PerformanceCalculator.calculateGain(
            currentValue: Decimal(1000),
            costBasis: Decimal(1000)
        )

        #expect(result.amount == Decimal(0))
        #expect(result.percentage == 0)
        #expect(result.isProfit == true)
    }

    // MARK: - Dividend Analysis Tests

    @Test("配当利回り計算")
    func testDividendYield() {
        let yield = PerformanceCalculator.calculateDividendYield(
            annualDividend: Decimal(4),
            currentPrice: Decimal(100)
        )

        #expect(abs(yield - 4.0) < 0.01)
    }

    @Test("配当利回り計算 - ゼロ価格")
    func testDividendYieldZeroPrice() {
        let yield = PerformanceCalculator.calculateDividendYield(
            annualDividend: Decimal(4),
            currentPrice: Decimal(0)
        )

        #expect(yield == 0)
    }

    // MARK: - Format Tests

    @Test("損益額フォーマット - 利益")
    func testFormattedAmountProfit() {
        let result = PerformanceCalculator.calculateGain(
            currentValue: Decimal(1100),
            costBasis: Decimal(1000)
        )

        #expect(result.formattedAmount.contains("+"))
    }

    @Test("損益率フォーマット")
    func testFormattedPercentage() {
        let result = PerformanceCalculator.calculateGain(
            currentValue: Decimal(1200),
            costBasis: Decimal(1000)
        )

        #expect(result.formattedPercentage.contains("+"))
        #expect(result.formattedPercentage.contains("%"))
    }
}
