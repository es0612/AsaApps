import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - AllocationOptimizerTests

@Suite("AllocationOptimizer テスト")
struct AllocationOptimizerTests {
    let optimizer = AllocationOptimizer()

    // MARK: - calculateCurrentAllocation

    @Test("現在配分の計算（assets → percentages）")
    func testCurrentAllocation() {
        let assets = [
            Asset(name: "国内株式", assetClass: .domesticStock, currentValue: Decimal(3_000_000)),
            Asset(name: "海外株式", assetClass: .internationalStock, currentValue: Decimal(2_000_000)),
            Asset(name: "現金", assetClass: .cash, currentValue: Decimal(5_000_000)),
        ]

        let allocations = optimizer.calculateCurrentAllocation(assets: assets)

        // 合計1000万円
        #expect(allocations.count == 3)

        let totalPercentage = allocations.reduce(0.0) { $0 + $1.currentPercentage }
        #expect(abs(totalPercentage - 1.0) < 0.001)

        // 現金50%, 国内株式30%, 海外株式20%
        let cashAlloc = allocations.first { $0.assetClass == .cash }
        #expect(cashAlloc != nil)
        #expect(abs((cashAlloc?.currentPercentage ?? 0) - 0.5) < 0.001)
    }

    @Test("空の資産リストは空配分")
    func testEmptyAssets() {
        let allocations = optimizer.calculateCurrentAllocation(assets: [])
        #expect(allocations.isEmpty)
    }

    @Test("同じ資産クラスが集約される")
    func testSameAssetClassAggregated() {
        let assets = [
            Asset(name: "株式A", assetClass: .domesticStock, currentValue: Decimal(1_000_000)),
            Asset(name: "株式B", assetClass: .domesticStock, currentValue: Decimal(2_000_000)),
            Asset(name: "現金", assetClass: .cash, currentValue: Decimal(2_000_000)),
        ]

        let allocations = optimizer.calculateCurrentAllocation(assets: assets)

        // 2クラスに集約
        #expect(allocations.count == 2)

        let stockAlloc = allocations.first { $0.assetClass == .domesticStock }
        #expect(stockAlloc?.currentValue == Decimal(3_000_000))
        #expect(abs((stockAlloc?.currentPercentage ?? 0) - 0.6) < 0.001)
    }

    // MARK: - suggestTargetAllocation

    @Test("推奨配分の生成（moderate）")
    func testTargetAllocationModerate() {
        let allocations = optimizer.suggestTargetAllocation(
            age: 35,
            riskTolerance: .moderate
        )

        #expect(!allocations.isEmpty)

        // 合計が100%
        let totalTarget = allocations.reduce(0.0) { $0 + $1.targetPercentage }
        #expect(abs(totalTarget - 1.0) < 0.01)
    }

    @Test("推奨配分の生成（conservative）")
    func testTargetAllocationConservative() {
        let allocations = optimizer.suggestTargetAllocation(
            age: 55,
            riskTolerance: .conservative
        )

        #expect(!allocations.isEmpty)

        // 保守的配分は債券比率が高い
        let bondPercentage = allocations
            .filter { $0.assetClass == .domesticBond || $0.assetClass == .internationalBond }
            .reduce(0.0) { $0 + $1.targetPercentage }

        #expect(bondPercentage > 0.4)
    }

    @Test("推奨配分の生成（aggressive）")
    func testTargetAllocationAggressive() {
        let allocations = optimizer.suggestTargetAllocation(
            age: 25,
            riskTolerance: .aggressive
        )

        #expect(!allocations.isEmpty)

        // 積極的配分は株式・リスク資産の比率が高い
        let stockPercentage = allocations
            .filter { $0.assetClass == .domesticStock || $0.assetClass == .internationalStock }
            .reduce(0.0) { $0 + $1.targetPercentage }

        #expect(stockPercentage > 0.4)
    }

    // MARK: - generateRebalanceSuggestions

    @Test("リバランス提案（乖離5%以上 → buy/sell）")
    func testRebalanceSuggestions() {
        let current = [
            AssetAllocation(assetClass: .domesticStock, currentPercentage: 0.60, currentValue: Decimal(6_000_000)),
            AssetAllocation(assetClass: .cash, currentPercentage: 0.40, currentValue: Decimal(4_000_000)),
        ]

        let target = [
            AssetAllocation(assetClass: .domesticStock, targetPercentage: 0.30),
            AssetAllocation(assetClass: .cash, targetPercentage: 0.20),
            AssetAllocation(assetClass: .domesticBond, targetPercentage: 0.30),
            AssetAllocation(assetClass: .internationalStock, targetPercentage: 0.20),
        ]

        let suggestions = optimizer.generateRebalanceSuggestions(
            current: current,
            target: target
        )

        // 乖離5%以上のクラスについて提案がある
        #expect(!suggestions.isEmpty)

        // 国内株式は売り（60% → 30%）
        let stockSuggestion = suggestions.first { $0.assetClass == .domesticStock }
        #expect(stockSuggestion?.action == .sell)

        // 国内債券は買い（0% → 30%）
        let bondSuggestion = suggestions.first { $0.assetClass == .domesticBond }
        #expect(bondSuggestion?.action == .buy)
    }

    @Test("乖離が小さい場合はリバランス不要")
    func testNoRebalanceNeeded() {
        let current = [
            AssetAllocation(assetClass: .domesticStock, currentPercentage: 0.52, currentValue: Decimal(5_200_000)),
            AssetAllocation(assetClass: .cash, currentPercentage: 0.48, currentValue: Decimal(4_800_000)),
        ]

        let target = [
            AssetAllocation(assetClass: .domesticStock, targetPercentage: 0.50),
            AssetAllocation(assetClass: .cash, targetPercentage: 0.50),
        ]

        let suggestions = optimizer.generateRebalanceSuggestions(
            current: current,
            target: target
        )

        // 乖離2%なので提案なし
        #expect(suggestions.isEmpty)
    }
}
