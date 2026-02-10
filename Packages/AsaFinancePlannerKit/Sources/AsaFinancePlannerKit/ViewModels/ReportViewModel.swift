import Foundation

// MARK: - AssetSummaryItem

/// 資産クラス別サマリー（Sendable対応のstruct）
public struct AssetSummaryItem: Identifiable, Sendable {
    public var id: String { assetClass.rawValue }
    public let assetClass: AssetClass
    public let value: Decimal

    public init(assetClass: AssetClass, value: Decimal) {
        self.assetClass = assetClass
        self.value = value
    }
}

// MARK: - ReportViewModel

/// レポート画面のViewModel
///
/// 総資産レポート、退職資金分析を担当する。
@MainActor @Observable
public final class ReportViewModel {
    // MARK: - Dependencies

    private let dataService: FinanceDataServiceProtocol
    private let calculator: ProjectionCalculating
    private let retirementCalc: RetirementCalculator

    // MARK: - Properties

    public var plan: FinancialPlan?
    public var settings: UserSettings?
    public var retirementAnalysis: RetirementAnalysis?
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        dataService: FinanceDataServiceProtocol,
        calculator: ProjectionCalculating = CompoundInterestCalculator(),
        retirementCalc: RetirementCalculator = RetirementCalculator()
    ) {
        self.dataService = dataService
        self.calculator = calculator
        self.retirementCalc = retirementCalc
    }

    // MARK: - Methods

    /// プランと設定を読み込み、退職分析を実行
    public func loadReport() {
        isLoading = true
        errorMessage = nil
        do {
            plan = try dataService.fetchActivePlan()
            settings = try dataService.fetchSettings()
            analyzeRetirement()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 退職資金ギャップ分析を実行
    public func analyzeRetirement() {
        guard let plan, let settings else { return }
        retirementAnalysis = retirementCalc.analyzeRetirementGap(
            currentAssets: plan.totalAssetValue,
            monthlyContribution: plan.monthlyContributionTotal,
            currentAge: settings.currentAge,
            retirementAge: settings.retirementAge,
            annualReturnRate: Decimal(string: "0.05") ?? Decimal(5) / Decimal(100),
            annualExpense: settings.monthlyLivingExpense * Decimal(12)
        )
    }

    // MARK: - Computed Properties

    /// 総資産額
    public var totalAssets: Decimal {
        plan?.totalAssetValue ?? Decimal.zero
    }

    /// 総含み損益
    public var totalGains: Decimal {
        guard let plan else { return Decimal.zero }
        return plan.assets.reduce(Decimal.zero) { $0 + $1.unrealizedGain }
    }

    /// 資産クラス別サマリー
    public var assetSummary: [AssetSummaryItem] {
        guard let plan else { return [] }
        var dict: [AssetClass: Decimal] = [:]
        for asset in plan.assets {
            dict[asset.assetClass, default: Decimal.zero] += asset.currentValue
        }
        return dict.map { AssetSummaryItem(assetClass: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }
}
