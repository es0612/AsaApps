import Foundation

// MARK: - AssetAllocation

/// 資産配分データ
public struct AssetAllocation: Identifiable, Sendable {
    public var id: String { assetClass.rawValue }
    public let assetClass: AssetClass
    public var currentPercentage: Double
    public var targetPercentage: Double
    public var currentValue: Decimal

    public init(
        assetClass: AssetClass,
        currentPercentage: Double = 0.0,
        targetPercentage: Double = 0.0,
        currentValue: Decimal = .zero
    ) {
        self.assetClass = assetClass
        self.currentPercentage = currentPercentage
        self.targetPercentage = targetPercentage
        self.currentValue = currentValue
    }

    // MARK: - Computed Properties

    /// 目標配分との乖離率
    public var deviationPercentage: Double {
        currentPercentage - targetPercentage
    }

    /// リバランスが必要か（乖離5%以上）
    public var needsRebalancing: Bool {
        abs(deviationPercentage) >= 0.05
    }
}
