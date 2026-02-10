import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - AllocationViewModelTests

@Suite("AllocationViewModel テスト")
struct AllocationViewModelTests {

    // MARK: - loadAllocation

    @MainActor
    @Test("loadAllocationで配分データが生成される")
    func testLoadAllocation() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "国内株", assetClass: .domesticStock, currentValue: Decimal(1_000_000)))
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(500_000)))
        mockDataService.activePlan = plan

        let mockOptimizer = MockAllocationOptimizer(
            currentAllocationsToReturn: [
                AssetAllocation(assetClass: .domesticStock, currentPercentage: 0.67, currentValue: Decimal(1_000_000)),
                AssetAllocation(assetClass: .cash, currentPercentage: 0.33, currentValue: Decimal(500_000)),
            ],
            targetAllocationsToReturn: [
                AssetAllocation(assetClass: .domesticStock, targetPercentage: 0.50),
                AssetAllocation(assetClass: .cash, targetPercentage: 0.50),
            ],
            suggestionsToReturn: [
                RebalanceSuggestion(
                    assetClass: .domesticStock,
                    currentPercentage: 0.67,
                    targetPercentage: 0.50,
                    adjustmentAmount: Decimal(250_000),
                    action: .sell
                ),
            ]
        )

        let viewModel = AllocationViewModel(
            dataService: mockDataService,
            optimizer: mockOptimizer
        )

        viewModel.loadAllocation()

        #expect(viewModel.plan != nil)
        #expect(viewModel.currentAllocations.count == 2)
        #expect(viewModel.targetAllocations.count == 2)
        #expect(viewModel.rebalanceSuggestions.count == 1)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test("loadAllocationでプランがない場合は空データ")
    func testLoadAllocationNoPlan() {
        let mockDataService = MockDataService()
        mockDataService.activePlan = nil

        let viewModel = AllocationViewModel(
            dataService: mockDataService,
            optimizer: MockAllocationOptimizer()
        )

        viewModel.loadAllocation()

        #expect(viewModel.plan == nil)
        #expect(viewModel.currentAllocations.isEmpty)
    }

    // MARK: - updateRiskTolerance

    @MainActor
    @Test("updateRiskToleranceで推奨配分が再計算される")
    func testUpdateRiskTolerance() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "株", assetClass: .domesticStock, currentValue: Decimal(1_000_000)))
        mockDataService.activePlan = plan

        let aggressiveTarget = [
            AssetAllocation(assetClass: .domesticStock, targetPercentage: 0.80),
            AssetAllocation(assetClass: .cash, targetPercentage: 0.20),
        ]

        let mockOptimizer = MockAllocationOptimizer(
            currentAllocationsToReturn: [
                AssetAllocation(assetClass: .domesticStock, currentPercentage: 1.0, currentValue: Decimal(1_000_000)),
            ],
            targetAllocationsToReturn: aggressiveTarget,
            suggestionsToReturn: []
        )

        let viewModel = AllocationViewModel(
            dataService: mockDataService,
            optimizer: mockOptimizer
        )

        viewModel.loadAllocation()
        viewModel.updateRiskTolerance(.aggressive)

        #expect(viewModel.riskTolerance == .aggressive)
        #expect(viewModel.targetAllocations.count == 2)
    }

    // MARK: - addAsset

    @MainActor
    @Test("addAssetで新規資産が追加される")
    func testAddAsset() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        mockDataService.activePlan = plan

        let viewModel = AllocationViewModel(
            dataService: mockDataService,
            optimizer: MockAllocationOptimizer()
        )
        viewModel.loadAllocation()

        viewModel.addAsset(
            name: "海外株式ETF",
            assetClass: .internationalStock,
            currentValue: Decimal(2_000_000),
            acquisitionCost: Decimal(1_800_000)
        )

        #expect(plan.assets.count == 1)
        #expect(plan.assets.first?.name == "海外株式ETF")
        #expect(plan.assets.first?.assetClass == .internationalStock)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test("addAssetでプランがない場合はエラーメッセージ")
    func testAddAssetNoPlan() {
        let mockDataService = MockDataService()
        let viewModel = AllocationViewModel(
            dataService: mockDataService,
            optimizer: MockAllocationOptimizer()
        )

        viewModel.addAsset(
            name: "テスト",
            assetClass: .cash,
            currentValue: Decimal(100),
            acquisitionCost: Decimal(100)
        )

        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - deleteAsset

    @MainActor
    @Test("deleteAssetで資産が削除される")
    func testDeleteAsset() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        let asset = Asset(name: "預金", assetClass: .cash, currentValue: Decimal(500_000))
        plan.assets.append(asset)
        mockDataService.activePlan = plan

        let viewModel = AllocationViewModel(
            dataService: mockDataService,
            optimizer: MockAllocationOptimizer()
        )
        viewModel.loadAllocation()

        viewModel.deleteAsset(asset)

        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Error handling

    @MainActor
    @Test("loadAllocationでエラー時にerrorMessageが設定される")
    func testLoadAllocationError() {
        let mockDataService = MockDataService()
        mockDataService.shouldThrow = true

        let viewModel = AllocationViewModel(
            dataService: mockDataService,
            optimizer: MockAllocationOptimizer()
        )

        viewModel.loadAllocation()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }
}
