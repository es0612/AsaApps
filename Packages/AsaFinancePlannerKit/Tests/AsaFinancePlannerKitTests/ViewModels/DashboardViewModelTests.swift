import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - DashboardViewModelTests

@Suite("DashboardViewModel テスト")
struct DashboardViewModelTests {

    // MARK: - loadDashboard

    @MainActor
    @Test("loadDashboardでアクティブプランとインサイトを取得")
    func testLoadDashboard() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テストプラン")
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(1_000_000)))
        mockDataService.activePlan = plan

        let insight = FinancialInsight(
            type: .info,
            priority: .low,
            title: "テストインサイト",
            message: "テストメッセージ",
            iconName: "star.fill"
        )
        let mockInsight = MockInsightGenerator(insightsToReturn: [insight])

        let viewModel = DashboardViewModel(
            dataService: mockDataService,
            insightEngine: mockInsight
        )

        viewModel.loadDashboard()

        #expect(viewModel.plan != nil)
        #expect(viewModel.plan?.name == "テストプラン")
        #expect(viewModel.insights.count == 1)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test("loadDashboardでプランがない場合はインサイト空")
    func testLoadDashboardNoPlan() {
        let mockDataService = MockDataService()
        mockDataService.activePlan = nil

        let viewModel = DashboardViewModel(
            dataService: mockDataService,
            insightEngine: MockInsightGenerator()
        )

        viewModel.loadDashboard()

        #expect(viewModel.plan == nil)
        #expect(viewModel.insights.isEmpty)
    }

    @MainActor
    @Test("loadDashboardでエラー発生時にerrorMessageが設定される")
    func testLoadDashboardError() {
        let mockDataService = MockDataService()
        mockDataService.shouldThrow = true

        let viewModel = DashboardViewModel(
            dataService: mockDataService,
            insightEngine: MockInsightGenerator()
        )

        viewModel.loadDashboard()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Computed Properties

    @MainActor
    @Test("totalAssetValueがプランの総資産額を返す")
    func testTotalAssetValue() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "株式", assetClass: .domesticStock, currentValue: Decimal(500_000)))
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(300_000)))
        mockDataService.activePlan = plan

        let viewModel = DashboardViewModel(
            dataService: mockDataService,
            insightEngine: MockInsightGenerator()
        )
        viewModel.loadDashboard()

        #expect(viewModel.totalAssetValue == Decimal(800_000))
    }

    @MainActor
    @Test("プランがない場合totalAssetValueはゼロ")
    func testTotalAssetValueNoPlan() {
        let mockDataService = MockDataService()
        let viewModel = DashboardViewModel(
            dataService: mockDataService,
            insightEngine: MockInsightGenerator()
        )

        #expect(viewModel.totalAssetValue == Decimal.zero)
    }

    @MainActor
    @Test("topGoalsが上位3件を優先度順で返す")
    func testTopGoals() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        let targetDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())!
        plan.goals.append(FinancialGoal(name: "目標A", targetAmount: Decimal(1_000_000), targetDate: targetDate, priority: 1))
        plan.goals.append(FinancialGoal(name: "目標B", targetAmount: Decimal(2_000_000), targetDate: targetDate, priority: 3))
        plan.goals.append(FinancialGoal(name: "目標C", targetAmount: Decimal(500_000), targetDate: targetDate, priority: 2))
        plan.goals.append(FinancialGoal(name: "目標D", targetAmount: Decimal(300_000), targetDate: targetDate, priority: 0))
        mockDataService.activePlan = plan

        let viewModel = DashboardViewModel(
            dataService: mockDataService,
            insightEngine: MockInsightGenerator()
        )
        viewModel.loadDashboard()

        #expect(viewModel.topGoals.count == 3)
        #expect(viewModel.topGoals[0].name == "目標B")
        #expect(viewModel.topGoals[1].name == "目標C")
        #expect(viewModel.topGoals[2].name == "目標A")
    }

    @MainActor
    @Test("monthlyContributionが月額積立合計を返す")
    func testMonthlyContribution() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.contributions.append(Contribution(name: "積立A", monthlyAmount: Decimal(50000)))
        plan.contributions.append(Contribution(name: "積立B", monthlyAmount: Decimal(30000)))
        plan.contributions.append(Contribution(name: "停止中", monthlyAmount: Decimal(10000), isActive: false))
        mockDataService.activePlan = plan

        let viewModel = DashboardViewModel(
            dataService: mockDataService,
            insightEngine: MockInsightGenerator()
        )
        viewModel.loadDashboard()

        #expect(viewModel.monthlyContribution == Decimal(80000))
    }
}
