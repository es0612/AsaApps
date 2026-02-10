import Foundation
import SwiftData

// MARK: - Scenario

/// シミュレーションシナリオモデル
@Model
public final class Scenario {
    public var id: UUID = UUID()
    public var name: String = ""
    public var annualReturnRate: Decimal = Decimal(sign: .plus, exponent: -2, significand: 5) // 0.05 = 5%
    public var inflationRate: Decimal = Decimal(sign: .plus, exponent: -2, significand: 2) // 0.02 = 2%
    public var projectionYears: Int = 30
    public var isDefault: Bool = false
    public var plan: FinancialPlan?

    public init(
        name: String,
        annualReturnRate: Decimal = Decimal(sign: .plus, exponent: -2, significand: 5),
        inflationRate: Decimal = Decimal(sign: .plus, exponent: -2, significand: 2),
        projectionYears: Int = 30,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.annualReturnRate = annualReturnRate
        self.inflationRate = inflationRate
        self.projectionYears = projectionYears
        self.isDefault = isDefault
    }

    // MARK: - Computed Properties

    /// 実質リターン率（名目リターン率 - インフレ率）
    public var realReturnRate: Decimal {
        annualReturnRate - inflationRate
    }
}
