import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - ReportViewModelTests

@Suite("ReportViewModel テスト")
struct ReportViewModelTests {

    // MARK: - loadReport

    @MainActor
    @Test("loadReportでプラン・設定・退職分析が取得される")
    func testLoadReport() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(2_000_000)))
        plan.assets.append(Asset(name: "株式", assetClass: .domesticStock, currentValue: Decimal(3_000_000), acquisitionCost: Decimal(2_500_000)))
        plan.contributions.append(Contribution(name: "積立", monthlyAmount: Decimal(50000)))
        mockDataService.activePlan = plan

        let viewModel = ReportViewModel(
            dataService: mockDataService,
            retirementCalc: RetirementCalculator(calculator: MockProjectionCalculator())
        )

        viewModel.loadReport()

        #expect(viewModel.plan != nil)
        #expect(viewModel.settings != nil)
        #expect(viewModel.retirementAnalysis != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test("loadReportでプランがない場合も設定は取得される")
    func testLoadReportNoPlan() {
        let mockDataService = MockDataService()
        mockDataService.activePlan = nil

        let viewModel = ReportViewModel(dataService: mockDataService)

        viewModel.loadReport()

        #expect(viewModel.plan == nil)
        #expect(viewModel.settings != nil)
        #expect(viewModel.retirementAnalysis == nil)
    }

    // MARK: - analyzeRetirement

    @MainActor
    @Test("analyzeRetirementで退職分析結果が生成される")
    func testAnalyzeRetirement() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(5_000_000)))
        plan.contributions.append(Contribution(name: "積立", monthlyAmount: Decimal(100000)))
        mockDataService.activePlan = plan
        mockDataService.settingsToReturn = UserSettings(
            currentAge: 30,
            retirementAge: 65,
            monthlyLivingExpense: Decimal(250000)
        )

        let mockCalc = MockProjectionCalculator(futureValueToReturn: Decimal(50_000_000))
        let viewModel = ReportViewModel(
            dataService: mockDataService,
            calculator: mockCalc,
            retirementCalc: RetirementCalculator(calculator: mockCalc)
        )

        viewModel.loadReport()

        #expect(viewModel.retirementAnalysis != nil)
        // 年間生活費300万 × 25 = 7500万、予測5000万なので不足
        #expect(viewModel.retirementAnalysis?.requiredFund == Decimal(75_000_000))
    }

    // MARK: - Computed Properties

    @MainActor
    @Test("totalAssetsが正しい総資産額を返す")
    func testTotalAssets() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "A", assetClass: .cash, currentValue: Decimal(1_000_000)))
        plan.assets.append(Asset(name: "B", assetClass: .domesticStock, currentValue: Decimal(2_000_000)))
        mockDataService.activePlan = plan

        let viewModel = ReportViewModel(dataService: mockDataService)
        viewModel.loadReport()

        #expect(viewModel.totalAssets == Decimal(3_000_000))
    }

    @MainActor
    @Test("totalGainsが正しい含み損益を返す")
    func testTotalGains() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "株A", assetClass: .domesticStock, currentValue: Decimal(1_500_000), acquisitionCost: Decimal(1_000_000)))
        plan.assets.append(Asset(name: "株B", assetClass: .internationalStock, currentValue: Decimal(800_000), acquisitionCost: Decimal(1_000_000)))
        mockDataService.activePlan = plan

        let viewModel = ReportViewModel(dataService: mockDataService)
        viewModel.loadReport()

        // (1,500,000 - 1,000,000) + (800,000 - 1,000,000) = 500,000 - 200,000 = 300,000
        #expect(viewModel.totalGains == Decimal(300_000))
    }

    @MainActor
    @Test("assetSummaryが資産クラス別にグループ化される")
    func testAssetSummary() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "国内株A", assetClass: .domesticStock, currentValue: Decimal(1_000_000)))
        plan.assets.append(Asset(name: "国内株B", assetClass: .domesticStock, currentValue: Decimal(500_000)))
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(2_000_000)))
        mockDataService.activePlan = plan

        let viewModel = ReportViewModel(dataService: mockDataService)
        viewModel.loadReport()

        let summary = viewModel.assetSummary
        #expect(summary.count == 2)

        // value降順なので預金(200万)が先、国内株(150万)が次
        #expect(summary[0].assetClass == .cash)
        #expect(summary[0].value == Decimal(2_000_000))
        #expect(summary[1].assetClass == .domesticStock)
        #expect(summary[1].value == Decimal(1_500_000))
    }

    @MainActor
    @Test("プランがない場合のcomputed propertiesはゼロ/空")
    func testComputedPropertiesNoPlan() {
        let mockDataService = MockDataService()
        let viewModel = ReportViewModel(dataService: mockDataService)

        #expect(viewModel.totalAssets == Decimal.zero)
        #expect(viewModel.totalGains == Decimal.zero)
        #expect(viewModel.assetSummary.isEmpty)
    }

    // MARK: - Error handling

    @MainActor
    @Test("loadReportでエラー時にerrorMessageが設定される")
    func testLoadReportError() {
        let mockDataService = MockDataService()
        mockDataService.shouldThrow = true

        let viewModel = ReportViewModel(dataService: mockDataService)

        viewModel.loadReport()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }
}
