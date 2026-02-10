import Foundation

// MARK: - ScenarioProjection

/// シナリオ別の将来予測データ（Sendable対応のstruct）
public struct ScenarioProjection: Identifiable, Sendable {
    public var id: String { scenarioName }
    public let scenarioName: String
    public let points: [ProjectionPoint]

    public init(scenarioName: String, points: [ProjectionPoint]) {
        self.scenarioName = scenarioName
        self.points = points
    }
}

// MARK: - ProjectionViewModel

/// 将来予測画面のViewModel
///
/// シナリオベースの将来予測とシナリオ間の比較を担当する。
@MainActor @Observable
public final class ProjectionViewModel {
    // MARK: - Dependencies

    private let dataService: FinanceDataServiceProtocol
    private let calculator: ProjectionCalculating

    // MARK: - Properties

    public var plan: FinancialPlan?
    public var scenarios: [Scenario] = []
    public var selectedScenario: Scenario?
    public var projectionPoints: [ProjectionPoint] = []
    public var comparisonData: [ScenarioProjection] = []
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        dataService: FinanceDataServiceProtocol,
        calculator: ProjectionCalculating = CompoundInterestCalculator()
    ) {
        self.dataService = dataService
        self.calculator = calculator
    }

    // MARK: - Methods

    /// プランとシナリオ一覧を読み込み、デフォルトシナリオを選択
    public func loadProjection() {
        isLoading = true
        errorMessage = nil
        do {
            plan = try dataService.fetchActivePlan()
            guard let plan else {
                isLoading = false
                return
            }
            scenarios = plan.scenarios
            if let defaultScenario = scenarios.first(where: \.isDefault) ?? scenarios.first {
                selectScenario(defaultScenario)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// シナリオを選択し、将来予測を生成
    public func selectScenario(_ scenario: Scenario) {
        selectedScenario = scenario
        guard let plan else { return }
        projectionPoints = calculator.generateProjection(
            presentValue: plan.totalAssetValue,
            monthlyContribution: plan.monthlyContributionTotal,
            annualRate: scenario.annualReturnRate,
            inflationRate: scenario.inflationRate,
            years: scenario.projectionYears
        )
    }

    /// 全シナリオの比較データを生成
    public func generateComparison() {
        guard let plan else { return }
        comparisonData = scenarios.map { scenario in
            let points = calculator.generateProjection(
                presentValue: plan.totalAssetValue,
                monthlyContribution: plan.monthlyContributionTotal,
                annualRate: scenario.annualReturnRate,
                inflationRate: scenario.inflationRate,
                years: scenario.projectionYears
            )
            return ScenarioProjection(scenarioName: scenario.name, points: points)
        }
    }

    /// 新規シナリオを追加
    public func addScenario(
        name: String,
        returnRate: Decimal,
        inflationRate: Decimal,
        years: Int
    ) {
        guard let plan else {
            errorMessage = "プランが選択されていません"
            return
        }
        let scenario = Scenario(
            name: name,
            annualReturnRate: returnRate,
            inflationRate: inflationRate,
            projectionYears: years
        )
        do {
            try dataService.addScenario(scenario, to: plan)
            scenarios = plan.scenarios
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// シナリオを削除
    public func deleteScenario(_ scenario: Scenario) {
        do {
            try dataService.deleteScenario(scenario)
            if let plan {
                scenarios = plan.scenarios
            }
            if selectedScenario?.id == scenario.id {
                selectedScenario = nil
                projectionPoints = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
