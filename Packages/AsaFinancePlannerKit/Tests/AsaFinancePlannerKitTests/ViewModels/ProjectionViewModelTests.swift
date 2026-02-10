import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - ProjectionViewModelTests

@Suite("ProjectionViewModel テスト")
struct ProjectionViewModelTests {

    // MARK: - loadProjection

    @MainActor
    @Test("loadProjectionでシナリオ一覧と予測データを取得")
    func testLoadProjection() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(1_000_000)))
        plan.contributions.append(Contribution(name: "積立", monthlyAmount: Decimal(50000)))
        let scenario = Scenario(name: "標準", isDefault: true)
        plan.scenarios.append(scenario)
        mockDataService.activePlan = plan

        let mockCalc = MockProjectionCalculator()
        let viewModel = ProjectionViewModel(
            dataService: mockDataService,
            calculator: mockCalc
        )

        viewModel.loadProjection()

        #expect(viewModel.plan != nil)
        #expect(viewModel.scenarios.count == 1)
        #expect(viewModel.selectedScenario != nil)
        #expect(viewModel.selectedScenario?.name == "標準")
        #expect(!viewModel.projectionPoints.isEmpty)
        #expect(viewModel.isLoading == false)
    }

    @MainActor
    @Test("loadProjectionでプランがない場合は空データ")
    func testLoadProjectionNoPlan() {
        let mockDataService = MockDataService()
        mockDataService.activePlan = nil

        let viewModel = ProjectionViewModel(
            dataService: mockDataService,
            calculator: MockProjectionCalculator()
        )

        viewModel.loadProjection()

        #expect(viewModel.plan == nil)
        #expect(viewModel.scenarios.isEmpty)
        #expect(viewModel.projectionPoints.isEmpty)
    }

    // MARK: - selectScenario

    @MainActor
    @Test("selectScenarioで選択シナリオの予測が生成される")
    func testSelectScenario() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(500_000)))
        plan.contributions.append(Contribution(name: "積立", monthlyAmount: Decimal(30000)))
        mockDataService.activePlan = plan

        let scenario = Scenario(
            name: "積極的",
            annualReturnRate: Decimal(string: "0.07")!,
            inflationRate: Decimal(string: "0.02")!,
            projectionYears: 20
        )

        let mockCalc = MockProjectionCalculator()
        let viewModel = ProjectionViewModel(
            dataService: mockDataService,
            calculator: mockCalc
        )
        viewModel.loadProjection()

        viewModel.selectScenario(scenario)

        #expect(viewModel.selectedScenario?.name == "積極的")
        #expect(viewModel.projectionPoints.count == 21) // 0〜20年
    }

    // MARK: - generateComparison

    @MainActor
    @Test("generateComparisonで全シナリオの比較データが生成される")
    func testGenerateComparison() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(1_000_000)))
        plan.contributions.append(Contribution(name: "積立", monthlyAmount: Decimal(50000)))
        plan.scenarios.append(Scenario(name: "保守的", annualReturnRate: Decimal(string: "0.03")!, projectionYears: 10))
        plan.scenarios.append(Scenario(name: "積極的", annualReturnRate: Decimal(string: "0.07")!, projectionYears: 10))
        mockDataService.activePlan = plan

        let mockCalc = MockProjectionCalculator()
        let viewModel = ProjectionViewModel(
            dataService: mockDataService,
            calculator: mockCalc
        )
        viewModel.loadProjection()

        viewModel.generateComparison()

        #expect(viewModel.comparisonData.count == 2)
        #expect(viewModel.comparisonData[0].scenarioName == "保守的")
        #expect(viewModel.comparisonData[1].scenarioName == "積極的")
        #expect(!viewModel.comparisonData[0].points.isEmpty)
    }

    // MARK: - addScenario

    @MainActor
    @Test("addScenarioで新規シナリオが追加される")
    func testAddScenario() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        mockDataService.activePlan = plan

        let viewModel = ProjectionViewModel(
            dataService: mockDataService,
            calculator: MockProjectionCalculator()
        )
        viewModel.loadProjection()

        viewModel.addScenario(
            name: "楽観的",
            returnRate: Decimal(string: "0.08")!,
            inflationRate: Decimal(string: "0.01")!,
            years: 25
        )

        #expect(plan.scenarios.count == 1)
        #expect(plan.scenarios.first?.name == "楽観的")
        #expect(viewModel.scenarios.count == 1)
    }

    @MainActor
    @Test("addScenarioでプランがない場合はエラーメッセージ")
    func testAddScenarioNoPlan() {
        let mockDataService = MockDataService()
        let viewModel = ProjectionViewModel(
            dataService: mockDataService,
            calculator: MockProjectionCalculator()
        )

        viewModel.addScenario(
            name: "テスト",
            returnRate: Decimal(string: "0.05")!,
            inflationRate: Decimal(string: "0.02")!,
            years: 10
        )

        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - deleteScenario

    @MainActor
    @Test("deleteScenarioでシナリオが削除される")
    func testDeleteScenario() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        let scenario = Scenario(name: "テスト")
        plan.scenarios.append(scenario)
        mockDataService.activePlan = plan

        let viewModel = ProjectionViewModel(
            dataService: mockDataService,
            calculator: MockProjectionCalculator()
        )
        viewModel.loadProjection()
        viewModel.selectScenario(scenario)

        viewModel.deleteScenario(scenario)

        // 選択中のシナリオが削除された場合、選択がクリアされる
        #expect(viewModel.selectedScenario == nil)
        #expect(viewModel.projectionPoints.isEmpty)
    }

    // MARK: - Error handling

    @MainActor
    @Test("loadProjectionでエラー時にerrorMessageが設定される")
    func testLoadProjectionError() {
        let mockDataService = MockDataService()
        mockDataService.shouldThrow = true

        let viewModel = ProjectionViewModel(
            dataService: mockDataService,
            calculator: MockProjectionCalculator()
        )

        viewModel.loadProjection()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }
}
