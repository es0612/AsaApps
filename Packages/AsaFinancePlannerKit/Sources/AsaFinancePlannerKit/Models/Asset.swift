import Foundation
import SwiftData

// MARK: - Asset

/// 保有資産モデル
@Model
public final class Asset {
    public var id: UUID = UUID()
    public var name: String = ""
    public var assetClassRawValue: String = AssetClass.cash.rawValue
    public var currentValue: Decimal = Decimal.zero
    public var acquisitionCost: Decimal = Decimal.zero
    public var acquisitionDate: Date = Date()
    public var note: String = ""
    public var plan: FinancialPlan?

    public init(
        name: String,
        assetClass: AssetClass = .cash,
        currentValue: Decimal,
        acquisitionCost: Decimal = .zero,
        acquisitionDate: Date = Date(),
        note: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.assetClassRawValue = assetClass.rawValue
        self.currentValue = currentValue
        self.acquisitionCost = acquisitionCost
        self.acquisitionDate = acquisitionDate
        self.note = note
    }

    // MARK: - AssetClass Accessor

    /// AssetClass への変換アクセサ（SwiftData enum保存パターン）
    public var assetClass: AssetClass {
        get { AssetClass(rawValue: assetClassRawValue) ?? .cash }
        set { assetClassRawValue = newValue.rawValue }
    }

    // MARK: - Computed Properties

    /// 含み損益
    public var unrealizedGain: Decimal {
        currentValue - acquisitionCost
    }

    /// 含み損益率
    public var gainPercentage: Double {
        guard acquisitionCost > .zero else { return 0.0 }
        let gain = NSDecimalNumber(decimal: unrealizedGain).doubleValue
        let cost = NSDecimalNumber(decimal: acquisitionCost).doubleValue
        return gain / cost
    }
}
