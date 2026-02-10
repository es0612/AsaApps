import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - CompoundInterestCalculatorTests

@Suite("CompoundInterestCalculator テスト")
struct CompoundInterestCalculatorTests {
    let calculator = CompoundInterestCalculator()

    // MARK: - calculateFutureValue

    @Test("月5万円 × 年利5% × 30年の複利計算精度")
    func testCompoundInterestAccuracy() {
        let result = calculator.calculateFutureValue(
            presentValue: Decimal.zero,
            monthlyContribution: Decimal(50000),
            annualRate: Decimal(string: "0.05")!,
            years: 30
        )

        // 期待値: 約41,612,932円（月次複利計算結果）
        let expected = Decimal(41612932)
        let tolerance = expected * Decimal(string: "0.01")! // 1%許容
        #expect(abs(result - expected) < tolerance)
    }

    @Test("初期投資ありの複利計算")
    func testCompoundInterestWithInitialInvestment() {
        let result = calculator.calculateFutureValue(
            presentValue: Decimal(1_000_000),
            monthlyContribution: Decimal(30000),
            annualRate: Decimal(string: "0.03")!,
            years: 20
        )

        // 初期100万円 + 月3万円 × 年利3% × 20年
        // PV部分: 1,000,000 * (1.0025)^240 ≈ 1,819,397
        // PMT部分: 30,000 * [((1.0025)^240 - 1) / 0.0025] ≈ 9,849,732
        // 合計: 約 11,669,129
        let expected = Decimal(11_669_000)
        let tolerance = expected * Decimal(string: "0.02")! // 2%許容
        #expect(abs(result - expected) < tolerance)
    }

    @Test("ゼロ利率の場合は単純積立")
    func testZeroRateSimpleAccumulation() {
        let result = calculator.calculateFutureValue(
            presentValue: Decimal.zero,
            monthlyContribution: Decimal(50000),
            annualRate: Decimal.zero,
            years: 10
        )

        // 月5万円 × 12ヶ月 × 10年 = 600万円
        let expected = Decimal(6_000_000)
        #expect(result == expected)
    }

    @Test("ゼロ年数の場合は現在価値をそのまま返す")
    func testZeroYears() {
        let result = calculator.calculateFutureValue(
            presentValue: Decimal(1_000_000),
            monthlyContribution: Decimal(50000),
            annualRate: Decimal(string: "0.05")!,
            years: 0
        )

        #expect(result == Decimal(1_000_000))
    }

    @Test("負の年数はガード")
    func testNegativeYears() {
        let result = calculator.calculateFutureValue(
            presentValue: Decimal(500000),
            monthlyContribution: Decimal(10000),
            annualRate: Decimal(string: "0.05")!,
            years: -1
        )

        #expect(result == Decimal(500000))
    }

    // MARK: - generateProjection

    @Test("予測データ生成のポイント数")
    func testProjectionPointCount() {
        let points = calculator.generateProjection(
            presentValue: Decimal(1_000_000),
            monthlyContribution: Decimal(50000),
            annualRate: Decimal(string: "0.05")!,
            inflationRate: Decimal(string: "0.02")!,
            years: 10
        )

        // 0年目〜10年目 = 11ポイント
        #expect(points.count == 11)
        #expect(points.first?.year == 0)
        #expect(points.last?.year == 10)
    }

    @Test("実質値は名目値より小さい（インフレ率 > 0）")
    func testRealValueLessThanNominal() {
        let points = calculator.generateProjection(
            presentValue: Decimal(1_000_000),
            monthlyContribution: Decimal(50000),
            annualRate: Decimal(string: "0.05")!,
            inflationRate: Decimal(string: "0.02")!,
            years: 20
        )

        // 0年目は同値
        #expect(points[0].realValue == points[0].nominalValue)

        // 1年目以降は実質値 < 名目値
        for point in points.dropFirst() {
            #expect(point.realValue < point.nominalValue)
        }
    }

    @Test("積立合計が正しく計算される")
    func testContributionTotal() {
        let points = calculator.generateProjection(
            presentValue: Decimal(100000),
            monthlyContribution: Decimal(10000),
            annualRate: Decimal(string: "0.03")!,
            inflationRate: Decimal(string: "0.01")!,
            years: 5
        )

        // 0年目: 初期投資のみ
        #expect(points[0].contributionTotal == Decimal(100000))

        // 5年目: 100,000 + 10,000 * 12 * 5 = 700,000
        #expect(points[5].contributionTotal == Decimal(700000))
    }

    @Test("名目値は年々増加する（正の利率）")
    func testNominalValueIncreases() {
        let points = calculator.generateProjection(
            presentValue: Decimal(1_000_000),
            monthlyContribution: Decimal(30000),
            annualRate: Decimal(string: "0.04")!,
            inflationRate: Decimal(string: "0.02")!,
            years: 5
        )

        for i in 1..<points.count {
            #expect(points[i].nominalValue > points[i - 1].nominalValue)
        }
    }
}
