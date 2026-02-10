import Foundation
import SwiftData

// MARK: - Contribution

/// 定期積立モデル
@Model
public final class Contribution {
    public var id: UUID = UUID()
    public var name: String = ""
    public var monthlyAmount: Decimal = Decimal.zero
    public var assetClassRawValue: String = AssetClass.cash.rawValue
    public var isActive: Bool = true
    public var startDate: Date = Date()
    public var endDate: Date?
    public var plan: FinancialPlan?

    public init(
        name: String,
        monthlyAmount: Decimal,
        assetClass: AssetClass = .cash,
        isActive: Bool = true,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.assetClassRawValue = assetClass.rawValue
        self.isActive = isActive
        self.startDate = startDate
        self.endDate = endDate
    }

    // MARK: - AssetClass Accessor

    /// AssetClass への変換アクセサ（SwiftData enum保存パターン）
    public var assetClass: AssetClass {
        get { AssetClass(rawValue: assetClassRawValue) ?? .cash }
        set { assetClassRawValue = newValue.rawValue }
    }
}
