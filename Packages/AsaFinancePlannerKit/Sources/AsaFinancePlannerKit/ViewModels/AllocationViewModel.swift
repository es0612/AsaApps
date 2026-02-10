import Foundation

// MARK: - AllocationViewModel

/// 資産配分画面のViewModel
///
/// 現在の配分計算、推奨配分の提案、リバランス提案を担当する。
@MainActor @Observable
public final class AllocationViewModel {
    // MARK: - Dependencies

    private let dataService: FinanceDataServiceProtocol
    private let optimizer: AllocationOptimizing

    // MARK: - Properties

    public var plan: FinancialPlan?
    public var currentAllocations: [AssetAllocation] = []
    public var targetAllocations: [AssetAllocation] = []
    public var rebalanceSuggestions: [RebalanceSuggestion] = []
    public var riskTolerance: RiskTolerance = .moderate
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        dataService: FinanceDataServiceProtocol,
        optimizer: AllocationOptimizing = AllocationOptimizer()
    ) {
        self.dataService = dataService
        self.optimizer = optimizer
    }

    // MARK: - Methods

    /// 配分データを読み込み、現在配分・推奨配分・リバランス提案を生成
    public func loadAllocation() {
        isLoading = true
        errorMessage = nil
        do {
            plan = try dataService.fetchActivePlan()
            guard let plan else {
                isLoading = false
                return
            }
            let settings = try dataService.fetchSettings()
            currentAllocations = optimizer.calculateCurrentAllocation(assets: plan.assets)
            targetAllocations = optimizer.suggestTargetAllocation(
                age: settings.currentAge,
                riskTolerance: riskTolerance
            )
            rebalanceSuggestions = optimizer.generateRebalanceSuggestions(
                current: currentAllocations,
                target: targetAllocations
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// リスク許容度を更新し配分を再計算
    public func updateRiskTolerance(_ tolerance: RiskTolerance) {
        riskTolerance = tolerance
        guard let plan, !plan.assets.isEmpty else { return }
        do {
            let settings = try dataService.fetchSettings()
            targetAllocations = optimizer.suggestTargetAllocation(
                age: settings.currentAge,
                riskTolerance: tolerance
            )
            rebalanceSuggestions = optimizer.generateRebalanceSuggestions(
                current: currentAllocations,
                target: targetAllocations
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 新規資産を追加
    public func addAsset(
        name: String,
        assetClass: AssetClass,
        currentValue: Decimal,
        acquisitionCost: Decimal
    ) {
        guard let plan else {
            errorMessage = "プランが選択されていません"
            return
        }
        let asset = Asset(
            name: name,
            assetClass: assetClass,
            currentValue: currentValue,
            acquisitionCost: acquisitionCost
        )
        do {
            try dataService.addAsset(asset, to: plan)
            loadAllocation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 資産を削除
    public func deleteAsset(_ asset: Asset) {
        do {
            try dataService.deleteAsset(asset)
            loadAllocation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
