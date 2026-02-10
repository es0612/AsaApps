import Foundation
import Testing
@testable import AsaFinancePlannerKit

@Suite("AssetAllocation テスト")
struct AssetAllocationTests {

    @Test("初期化とID")
    func testInit() {
        let allocation = AssetAllocation(
            assetClass: .domesticStock,
            currentPercentage: 0.40,
            targetPercentage: 0.35,
            currentValue: Decimal(4000000)
        )
        #expect(allocation.id == "domestic_stock")
        #expect(allocation.assetClass == .domesticStock)
        #expect(allocation.currentPercentage == 0.40)
        #expect(allocation.targetPercentage == 0.35)
        #expect(allocation.currentValue == Decimal(4000000))
    }

    @Test("乖離率の計算")
    func testDeviationPercentage() {
        let allocation = AssetAllocation(
            assetClass: .cash,
            currentPercentage: 0.30,
            targetPercentage: 0.20
        )
        #expect(abs(allocation.deviationPercentage - 0.10) < 0.0001)
    }

    @Test("リバランスが必要（5%以上乖離）")
    func testNeedsRebalancingTrue() {
        let allocation = AssetAllocation(
            assetClass: .internationalStock,
            currentPercentage: 0.25,
            targetPercentage: 0.35
        )
        #expect(abs(allocation.deviationPercentage - (-0.10)) < 0.0001)
        #expect(allocation.needsRebalancing == true)
    }

    @Test("リバランス不要（5%未満乖離）")
    func testNeedsRebalancingFalse() {
        let allocation = AssetAllocation(
            assetClass: .domesticBond,
            currentPercentage: 0.12,
            targetPercentage: 0.10
        )
        #expect(allocation.needsRebalancing == false)
    }

    @Test("大きな乖離はリバランス必要")
    func testLargeDeviation() {
        let allocation = AssetAllocation(
            assetClass: .reit,
            currentPercentage: 0.20,
            targetPercentage: 0.10
        )
        #expect(abs(allocation.deviationPercentage) > 0.05)
        #expect(allocation.needsRebalancing == true)
    }
}
