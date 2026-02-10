import Foundation

// MARK: - GoalViewModel

/// 目標管理画面のViewModel
///
/// 目標のCRUD操作と達成可能性分析を担当する。
/// フォーム状態を内包し、追加・編集をサポートする。
@MainActor @Observable
public final class GoalViewModel {
    // MARK: - Dependencies

    private let dataService: FinanceDataServiceProtocol
    private let goalAnalyzer: GoalAnalyzing
    private let calculator: ProjectionCalculating

    // MARK: - Properties

    public var plan: FinancialPlan?
    public var selectedGoal: FinancialGoal?
    public var feasibilityResult: GoalFeasibilityResult?
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Form State

    public var goalName: String = ""
    public var goalCategory: GoalCategory = .other
    public var goalTargetAmount: Decimal = Decimal.zero
    public var goalCurrentAmount: Decimal = Decimal.zero
    public var goalTargetDate: Date = Date()
    public var goalPriority: Int = 0
    public var goalNote: String = ""

    // MARK: - Initialization

    public init(
        dataService: FinanceDataServiceProtocol,
        goalAnalyzer: GoalAnalyzing = GoalFeasibilityAnalyzer(),
        calculator: ProjectionCalculating = CompoundInterestCalculator()
    ) {
        self.dataService = dataService
        self.goalAnalyzer = goalAnalyzer
        self.calculator = calculator
    }

    // MARK: - Methods

    /// アクティブプランから目標一覧を取得
    public func loadGoals() {
        isLoading = true
        errorMessage = nil
        do {
            plan = try dataService.fetchActivePlan()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// フォーム状態から新規目標を追加
    public func addGoal() {
        guard let plan else {
            errorMessage = "プランが選択されていません"
            return
        }
        let goal = FinancialGoal(
            name: goalName,
            category: goalCategory,
            targetAmount: goalTargetAmount,
            currentAmount: goalCurrentAmount,
            targetDate: goalTargetDate,
            priority: goalPriority,
            note: goalNote
        )
        do {
            try dataService.addGoal(goal, to: plan)
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 既存目標を更新
    public func updateGoal(_ goal: FinancialGoal) {
        goal.name = goalName
        goal.category = goalCategory
        goal.targetAmount = goalTargetAmount
        goal.currentAmount = goalCurrentAmount
        goal.targetDate = goalTargetDate
        goal.priority = goalPriority
        goal.note = goalNote
        do {
            try dataService.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 目標を削除
    public func deleteGoal(_ goal: FinancialGoal) {
        do {
            try dataService.deleteGoal(goal)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 目標の達成可能性を分析
    public func analyzeFeasibility(for goal: FinancialGoal) {
        guard let plan else { return }
        let settings: UserSettings
        do {
            settings = try dataService.fetchSettings()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        feasibilityResult = goalAnalyzer.analyzeFeasibility(
            goal: goal,
            currentAssets: plan.totalAssetValue,
            monthlyContribution: plan.monthlyContributionTotal,
            annualReturnRate: Decimal(string: "0.05") ?? Decimal(5) / Decimal(100),
            inflationRate: settings.defaultInflationRate
        )
    }

    /// フォーム状態をリセット
    public func resetForm() {
        goalName = ""
        goalCategory = .other
        goalTargetAmount = Decimal.zero
        goalCurrentAmount = Decimal.zero
        goalTargetDate = Date()
        goalPriority = 0
        goalNote = ""
        selectedGoal = nil
        feasibilityResult = nil
    }

    /// 編集用にフォームを準備
    public func prepareForEditing(_ goal: FinancialGoal) {
        selectedGoal = goal
        goalName = goal.name
        goalCategory = goal.category
        goalTargetAmount = goal.targetAmount
        goalCurrentAmount = goal.currentAmount
        goalTargetDate = goal.targetDate
        goalPriority = goal.priority
        goalNote = goal.note
    }
}
