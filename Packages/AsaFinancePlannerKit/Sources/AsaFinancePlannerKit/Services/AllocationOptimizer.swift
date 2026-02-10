import Foundation

// MARK: - AllocationOptimizer

/// 資産配分最適化エンジン
///
/// 年齢・リスク許容度に基づくモデルポートフォリオの提案と、
/// 現在配分との乖離分析・リバランス提案を行う。
public struct AllocationOptimizer: AllocationOptimizing {
    public init() {}

    // MARK: - AllocationOptimizing

    public func calculateCurrentAllocation(assets: [Asset]) -> [AssetAllocation] {
        guard !assets.isEmpty else { return [] }

        let totalValue = assets.reduce(Decimal.zero) { $0 + $1.currentValue }
        guard totalValue > .zero else { return [] }

        let totalDouble = NSDecimalNumber(decimal: totalValue).doubleValue

        // 資産クラスごとに集約
        var classTotals: [AssetClass: Decimal] = [:]
        for asset in assets {
            classTotals[asset.assetClass, default: Decimal.zero] += asset.currentValue
        }

        return classTotals.map { assetClass, value in
            let percentage = NSDecimalNumber(decimal: value).doubleValue / totalDouble
            return AssetAllocation(
                assetClass: assetClass,
                currentPercentage: percentage,
                targetPercentage: 0.0,
                currentValue: value
            )
        }
        .sorted { $0.currentPercentage > $1.currentPercentage }
    }

    public func suggestTargetAllocation(
        age: Int,
        riskTolerance: RiskTolerance
    ) -> [AssetAllocation] {
        let model = targetModel(for: riskTolerance, age: age)
        return model.map { assetClass, percentage in
            AssetAllocation(
                assetClass: assetClass,
                currentPercentage: 0.0,
                targetPercentage: percentage,
                currentValue: .zero
            )
        }
        .sorted { $0.targetPercentage > $1.targetPercentage }
    }

    public func generateRebalanceSuggestions(
        current: [AssetAllocation],
        target: [AssetAllocation]
    ) -> [RebalanceSuggestion] {
        let totalValue = current.reduce(Decimal.zero) { $0 + $1.currentValue }
        guard totalValue > .zero else { return [] }

        let currentMap = Dictionary(
            current.map { ($0.assetClass, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let targetMap = Dictionary(
            target.map { ($0.assetClass, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // 全てのクラスについてチェック
        let allClasses = Set(currentMap.keys).union(Set(targetMap.keys))

        return allClasses.compactMap { assetClass in
            let currentPct = currentMap[assetClass]?.currentPercentage ?? 0.0
            let targetPct = targetMap[assetClass]?.targetPercentage ?? 0.0
            let deviation = currentPct - targetPct

            // 乖離5%未満は無視
            guard abs(deviation) >= 0.05 else { return nil }

            let adjustmentDouble = abs(deviation) * NSDecimalNumber(decimal: totalValue).doubleValue
            let adjustmentAmount = Decimal(Int64(adjustmentDouble.rounded()))

            let action: RebalanceAction
            if deviation > 0.05 {
                action = .sell
            } else if deviation < -0.05 {
                action = .buy
            } else {
                action = .hold
            }

            return RebalanceSuggestion(
                assetClass: assetClass,
                currentPercentage: currentPct,
                targetPercentage: targetPct,
                adjustmentAmount: adjustmentAmount,
                action: action
            )
        }
        .sorted { $0.adjustmentAmount > $1.adjustmentAmount }
    }

    // MARK: - Private

    /// リスク許容度と年齢に基づくモデルポートフォリオ
    private func targetModel(
        for riskTolerance: RiskTolerance,
        age: Int
    ) -> [(AssetClass, Double)] {
        // 年齢による債券比率の調整（高齢ほど債券を増やす）
        let ageAdjustment = min(max(Double(age - 30) * 0.005, 0.0), 0.10)

        switch riskTolerance {
        case .conservative:
            return [
                (.domesticBond, 0.40 + ageAdjustment),
                (.internationalBond, 0.20),
                (.domesticStock, 0.10 - ageAdjustment / 2),
                (.internationalStock, 0.10 - ageAdjustment / 2),
                (.cash, 0.20),
            ]
        case .moderatelyConservative:
            return [
                (.domesticBond, 0.30 + ageAdjustment),
                (.internationalBond, 0.15),
                (.domesticStock, 0.20 - ageAdjustment / 2),
                (.internationalStock, 0.10 - ageAdjustment / 2),
                (.reit, 0.10),
                (.cash, 0.15),
            ]
        case .moderate:
            return [
                (.domesticStock, 0.25 - ageAdjustment / 2),
                (.internationalStock, 0.15 - ageAdjustment / 2),
                (.domesticBond, 0.20 + ageAdjustment),
                (.internationalBond, 0.10),
                (.reit, 0.15),
                (.cash, 0.15),
            ]
        case .moderatelyAggressive:
            return [
                (.domesticStock, 0.30 - ageAdjustment / 2),
                (.internationalStock, 0.25 - ageAdjustment / 2),
                (.domesticBond, 0.10 + ageAdjustment),
                (.reit, 0.15),
                (.commodity, 0.10),
                (.cash, 0.10),
            ]
        case .aggressive:
            return [
                (.domesticStock, 0.35 - ageAdjustment / 2),
                (.internationalStock, 0.25 - ageAdjustment / 2),
                (.reit, 0.15),
                (.commodity, 0.10),
                (.crypto, 0.05),
                (.cash, 0.10 + ageAdjustment),
            ]
        }
    }
}
