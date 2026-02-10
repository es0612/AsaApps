import Foundation
import Testing
@testable import AsaFinancePlannerKit

@Suite("Scenario テスト")
struct ScenarioTests {

    @Test("シナリオ初期化")
    func testInit() {
        let scenario = Scenario(name: "標準シナリオ")
        #expect(scenario.name == "標準シナリオ")
        #expect(scenario.projectionYears == 30)
        #expect(scenario.isDefault == false)
    }

    @Test("実質リターン率の計算")
    func testRealReturnRate() {
        let scenario = Scenario(
            name: "テスト",
            annualReturnRate: Decimal(sign: .plus, exponent: -2, significand: 5), // 0.05
            inflationRate: Decimal(sign: .plus, exponent: -2, significand: 2) // 0.02
        )
        #expect(scenario.realReturnRate == Decimal(sign: .plus, exponent: -2, significand: 3)) // 0.03
    }

    @Test("カスタムシナリオ")
    func testCustomScenario() {
        let scenario = Scenario(
            name: "楽観シナリオ",
            annualReturnRate: Decimal(sign: .plus, exponent: -2, significand: 8), // 0.08
            inflationRate: Decimal(sign: .plus, exponent: -2, significand: 1), // 0.01
            projectionYears: 20,
            isDefault: true
        )
        #expect(scenario.annualReturnRate == Decimal(sign: .plus, exponent: -2, significand: 8))
        #expect(scenario.inflationRate == Decimal(sign: .plus, exponent: -2, significand: 1))
        #expect(scenario.projectionYears == 20)
        #expect(scenario.isDefault == true)
        #expect(scenario.realReturnRate == Decimal(sign: .plus, exponent: -2, significand: 7)) // 0.07
    }

    @Test("ゼロリターンシナリオ")
    func testZeroReturn() {
        let scenario = Scenario(
            name: "ゼロ成長",
            annualReturnRate: .zero,
            inflationRate: Decimal(sign: .plus, exponent: -2, significand: 2)
        )
        // 実質リターンがマイナス
        #expect(scenario.realReturnRate < .zero)
    }
}
