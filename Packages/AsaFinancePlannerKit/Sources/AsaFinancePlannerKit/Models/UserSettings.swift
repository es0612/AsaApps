import Foundation
import SwiftData

// MARK: - UserSettings

/// ユーザー設定モデル
@Model
public final class UserSettings {
    public var id: UUID = UUID()
    public var currencyCode: String = "JPY"
    public var currentAge: Int = 30
    public var retirementAge: Int = 65
    public var defaultInflationRate: Decimal = Decimal(sign: .plus, exponent: -2, significand: 2) // 0.02
    public var isBiometricEnabled: Bool = false
    public var monthlyLivingExpense: Decimal = Decimal(250000)

    public init(
        currencyCode: String = "JPY",
        currentAge: Int = 30,
        retirementAge: Int = 65,
        defaultInflationRate: Decimal = Decimal(sign: .plus, exponent: -2, significand: 2),
        isBiometricEnabled: Bool = false,
        monthlyLivingExpense: Decimal = Decimal(250000)
    ) {
        self.id = UUID()
        self.currencyCode = currencyCode
        self.currentAge = currentAge
        self.retirementAge = retirementAge
        self.defaultInflationRate = defaultInflationRate
        self.isBiometricEnabled = isBiometricEnabled
        self.monthlyLivingExpense = monthlyLivingExpense
    }
}
