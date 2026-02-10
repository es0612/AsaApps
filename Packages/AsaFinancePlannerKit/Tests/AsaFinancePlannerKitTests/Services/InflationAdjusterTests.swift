import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - InflationAdjusterTests

@Suite("InflationAdjuster テスト")
struct InflationAdjusterTests {
    let adjuster = InflationAdjuster()

    // MARK: - adjustForInflation

    @Test("インフレ調整計算の正確性")
    func testInflationAdjustment() {
        // 1000万円を2%インフレで20年割引
        // 10,000,000 / (1.02)^20 ≈ 6,729,713
        let result = adjuster.adjustForInflation(
            nominalValue: Decimal(10_000_000),
            inflationRate: Decimal(string: "0.02")!,
            years: 20
        )

        let expected = Decimal(6_729_713)
        let tolerance = expected * Decimal(string: "0.01")! // 1%許容
        #expect(abs(result - expected) < tolerance)
    }

    @Test("ゼロインフレ率の場合は変化なし")
    func testZeroInflationNoChange() {
        let result = adjuster.adjustForInflation(
            nominalValue: Decimal(5_000_000),
            inflationRate: Decimal.zero,
            years: 10
        )

        #expect(result == Decimal(5_000_000))
    }

    @Test("0年目は変化なし")
    func testZeroYearsNoChange() {
        let result = adjuster.adjustForInflation(
            nominalValue: Decimal(3_000_000),
            inflationRate: Decimal(string: "0.03")!,
            years: 0
        )

        #expect(result == Decimal(3_000_000))
    }

    // MARK: - inflationAdjustedTarget

    @Test("インフレ調整後の目標額が増加する")
    func testInflationAdjustedTargetIncrease() {
        // 1000万円を2%インフレで20年
        // 10,000,000 * (1.02)^20 ≈ 14,859,474
        let result = adjuster.inflationAdjustedTarget(
            currentTarget: Decimal(10_000_000),
            inflationRate: Decimal(string: "0.02")!,
            years: 20
        )

        let expected = Decimal(14_859_474)
        let tolerance = expected * Decimal(string: "0.01")!
        #expect(abs(result - expected) < tolerance)
    }

    @Test("ゼロインフレなら目標額は変わらない")
    func testZeroInflationTargetUnchanged() {
        let result = adjuster.inflationAdjustedTarget(
            currentTarget: Decimal(5_000_000),
            inflationRate: Decimal.zero,
            years: 15
        )

        #expect(result == Decimal(5_000_000))
    }

    @Test("0年後は目標額そのまま")
    func testZeroYearsTargetUnchanged() {
        let result = adjuster.inflationAdjustedTarget(
            currentTarget: Decimal(8_000_000),
            inflationRate: Decimal(string: "0.03")!,
            years: 0
        )

        #expect(result == Decimal(8_000_000))
    }
}
