import Foundation

// MARK: - RiskTolerance

/// リスク許容度
public enum RiskTolerance: String, CaseIterable, Codable, Sendable {
    case conservative = "conservative"
    case moderatelyConservative = "moderately_conservative"
    case moderate = "moderate"
    case moderatelyAggressive = "moderately_aggressive"
    case aggressive = "aggressive"

    public var displayName: String {
        switch self {
        case .conservative: return "保守的"
        case .moderatelyConservative: return "やや保守的"
        case .moderate: return "中立"
        case .moderatelyAggressive: return "やや積極的"
        case .aggressive: return "積極的"
        }
    }
}

// MARK: - RebalanceSuggestion

/// リバランス提案データ
public struct RebalanceSuggestion: Identifiable, Sendable {
    public var id: String { assetClass.rawValue }
    public let assetClass: AssetClass
    public let currentPercentage: Double
    public let targetPercentage: Double
    public let adjustmentAmount: Decimal
    public let action: RebalanceAction

    public init(
        assetClass: AssetClass,
        currentPercentage: Double,
        targetPercentage: Double,
        adjustmentAmount: Decimal,
        action: RebalanceAction
    ) {
        self.assetClass = assetClass
        self.currentPercentage = currentPercentage
        self.targetPercentage = targetPercentage
        self.adjustmentAmount = adjustmentAmount
        self.action = action
    }
}

// MARK: - RebalanceAction

/// リバランスアクション種別
public enum RebalanceAction: String, Codable, Sendable {
    case buy = "buy"
    case sell = "sell"
    case hold = "hold"

    public var displayName: String {
        switch self {
        case .buy: return "買い増し"
        case .sell: return "売却"
        case .hold: return "維持"
        }
    }
}

// MARK: - AllocationOptimizing

/// 資産配分最適化プロトコル
public protocol AllocationOptimizing: Sendable {
    /// 現在の資産配分を計算
    func calculateCurrentAllocation(assets: [Asset]) -> [AssetAllocation]

    /// 年齢とリスク許容度に基づく推奨配分を生成
    func suggestTargetAllocation(age: Int, riskTolerance: RiskTolerance) -> [AssetAllocation]

    /// リバランス提案を生成
    func generateRebalanceSuggestions(
        current: [AssetAllocation],
        target: [AssetAllocation]
    ) -> [RebalanceSuggestion]
}
