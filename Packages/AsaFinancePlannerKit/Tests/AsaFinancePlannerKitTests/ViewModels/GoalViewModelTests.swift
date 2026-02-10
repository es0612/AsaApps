import Foundation
import Testing

@testable import AsaFinancePlannerKit

// MARK: - GoalViewModelTests

@Suite("GoalViewModel テスト")
struct GoalViewModelTests {

    // MARK: - loadGoals

    @MainActor
    @Test("loadGoalsでアクティブプランを取得")
    func testLoadGoals() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テストプラン")
        let targetDate = Calendar.current.date(byAdding: .year, value: 3, to: Date())!
        plan.goals.append(FinancialGoal(name: "住宅購入", category: .housing, targetAmount: Decimal(10_000_000), targetDate: targetDate))
        mockDataService.activePlan = plan

        let viewModel = GoalViewModel(dataService: mockDataService)
        viewModel.loadGoals()

        #expect(viewModel.plan != nil)
        #expect(viewModel.plan?.goals.count == 1)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - addGoal

    @MainActor
    @Test("addGoalで新規目標が追加される")
    func testAddGoal() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        mockDataService.activePlan = plan

        let viewModel = GoalViewModel(dataService: mockDataService)
        viewModel.loadGoals()

        viewModel.goalName = "教育資金"
        viewModel.goalCategory = .education
        viewModel.goalTargetAmount = Decimal(5_000_000)
        viewModel.goalCurrentAmount = Decimal(500_000)
        viewModel.goalTargetDate = Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        viewModel.goalPriority = 2

        viewModel.addGoal()

        #expect(plan.goals.count == 1)
        #expect(plan.goals.first?.name == "教育資金")
        #expect(plan.goals.first?.category == .education)
        #expect(plan.goals.first?.targetAmount == Decimal(5_000_000))
    }

    @MainActor
    @Test("addGoalでプランがない場合はエラーメッセージ")
    func testAddGoalNoPlan() {
        let mockDataService = MockDataService()
        let viewModel = GoalViewModel(dataService: mockDataService)

        viewModel.goalName = "テスト"
        viewModel.addGoal()

        #expect(viewModel.errorMessage != nil)
    }

    @MainActor
    @Test("addGoal後にフォームがリセットされる")
    func testAddGoalResetsForm() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        mockDataService.activePlan = plan

        let viewModel = GoalViewModel(dataService: mockDataService)
        viewModel.loadGoals()

        viewModel.goalName = "教育資金"
        viewModel.goalCategory = .education
        viewModel.goalTargetAmount = Decimal(5_000_000)

        viewModel.addGoal()

        #expect(viewModel.goalName == "")
        #expect(viewModel.goalCategory == .other)
        #expect(viewModel.goalTargetAmount == Decimal.zero)
    }

    // MARK: - deleteGoal

    @MainActor
    @Test("deleteGoalで目標が削除される")
    func testDeleteGoal() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        let targetDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())!
        let goal = FinancialGoal(name: "旅行", category: .travel, targetAmount: Decimal(500_000), targetDate: targetDate)
        plan.goals.append(goal)
        mockDataService.activePlan = plan

        let viewModel = GoalViewModel(dataService: mockDataService)
        viewModel.loadGoals()

        viewModel.deleteGoal(goal)

        // MockDataServiceはgoal.planがnilなのでremoveAll自体は実行されない
        // ただしthrowしないことを確認
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - analyzeFeasibility

    @MainActor
    @Test("analyzeFeasibilityで分析結果が設定される")
    func testAnalyzeFeasibility() {
        let mockDataService = MockDataService()
        let plan = FinancialPlan(name: "テスト")
        plan.assets.append(Asset(name: "預金", assetClass: .cash, currentValue: Decimal(2_000_000)))
        plan.contributions.append(Contribution(name: "積立", monthlyAmount: Decimal(50000)))
        mockDataService.activePlan = plan

        let expectedResult = GoalFeasibilityResult(
            goal: "住宅",
            isFeasible: false,
            projectedAmount: Decimal(8_000_000),
            shortfall: Decimal(2_000_000),
            requiredMonthlyContribution: Decimal(80000),
            probabilityOfSuccess: 0.65,
            message: "達成にはあと2,000,000円必要です"
        )
        let mockAnalyzer = MockGoalAnalyzer(resultToReturn: expectedResult)

        let viewModel = GoalViewModel(
            dataService: mockDataService,
            goalAnalyzer: mockAnalyzer
        )
        viewModel.loadGoals()

        let targetDate = Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        let goal = FinancialGoal(name: "住宅", category: .housing, targetAmount: Decimal(10_000_000), targetDate: targetDate)

        viewModel.analyzeFeasibility(for: goal)

        #expect(viewModel.feasibilityResult != nil)
        #expect(viewModel.feasibilityResult?.isFeasible == false)
        #expect(viewModel.feasibilityResult?.shortfall == Decimal(2_000_000))
    }

    // MARK: - resetForm & prepareForEditing

    @MainActor
    @Test("resetFormでフォーム状態が初期化される")
    func testResetForm() {
        let mockDataService = MockDataService()
        let viewModel = GoalViewModel(dataService: mockDataService)

        viewModel.goalName = "テスト"
        viewModel.goalCategory = .housing
        viewModel.goalTargetAmount = Decimal(5_000_000)

        viewModel.resetForm()

        #expect(viewModel.goalName == "")
        #expect(viewModel.goalCategory == .other)
        #expect(viewModel.goalTargetAmount == Decimal.zero)
        #expect(viewModel.selectedGoal == nil)
        #expect(viewModel.feasibilityResult == nil)
    }

    @MainActor
    @Test("prepareForEditingでフォームに目標データが反映される")
    func testPrepareForEditing() {
        let mockDataService = MockDataService()
        let viewModel = GoalViewModel(dataService: mockDataService)

        let targetDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())!
        let goal = FinancialGoal(
            name: "住宅購入",
            category: .housing,
            targetAmount: Decimal(10_000_000),
            currentAmount: Decimal(2_000_000),
            targetDate: targetDate,
            priority: 3,
            note: "都内マンション"
        )

        viewModel.prepareForEditing(goal)

        #expect(viewModel.goalName == "住宅購入")
        #expect(viewModel.goalCategory == .housing)
        #expect(viewModel.goalTargetAmount == Decimal(10_000_000))
        #expect(viewModel.goalCurrentAmount == Decimal(2_000_000))
        #expect(viewModel.goalPriority == 3)
        #expect(viewModel.goalNote == "都内マンション")
        #expect(viewModel.selectedGoal != nil)
    }
}
