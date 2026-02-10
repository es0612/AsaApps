import Foundation

// MARK: - RetirementAnalysis

/// 退職資金分析の結果
public struct RetirementAnalysis: Sendable {
    /// 4%ルールに基づく必要退職資金
    public let requiredFund: Decimal
    /// 退職時の予測資産額
    public let projectedFund: Decimal
    /// 不足額（マイナスの場合は余裕）
    public let gap: Decimal
    /// 資金が十分かどうか
    public let isSufficient: Bool
    /// 不足を埋めるための追加月額積立額
    public let additionalMonthlyNeeded: Decimal
    /// 分析メッセージ
    public let message: String

    public init(
        requiredFund: Decimal,
        projectedFund: Decimal,
        gap: Decimal,
        isSufficient: Bool,
        additionalMonthlyNeeded: Decimal,
        message: String
    ) {
        self.requiredFund = requiredFund
        self.projectedFund = projectedFund
        self.gap = gap
        self.isSufficient = isSufficient
        self.additionalMonthlyNeeded = additionalMonthlyNeeded
        self.message = message
    }
}

// MARK: - RetirementCalculator

/// 退職資金計算エンジン
///
/// 4%ルール（年間生活費 × 25 = 必要退職資金）に基づき、
/// 現在の積立ペースで退職資金が十分か分析する。
public struct RetirementCalculator: Sendable {
    private let calculator: ProjectionCalculating

    public init(calculator: ProjectionCalculating = CompoundInterestCalculator()) {
        self.calculator = calculator
    }

    // MARK: - Methods

    /// 4%ルールに基づく必要退職資金（年間生活費 × 25）
    /// - Parameter annualExpense: 年間生活費
    /// - Returns: 必要退職資金
    public func requiredRetirementFund(annualExpense: Decimal) -> Decimal {
        annualExpense * Decimal(25)
    }

    /// 退職までのギャップ分析
    /// - Parameters:
    ///   - currentAssets: 現在の総資産額
    ///   - monthlyContribution: 月額積立額
    ///   - currentAge: 現在の年齢
    ///   - retirementAge: 退職予定年齢
    ///   - annualReturnRate: 年間リターン率
    ///   - annualExpense: 年間生活費
    /// - Returns: 退職資金分析結果
    public func analyzeRetirementGap(
        currentAssets: Decimal,
        monthlyContribution: Decimal,
        currentAge: Int,
        retirementAge: Int,
        annualReturnRate: Decimal,
        annualExpense: Decimal
    ) -> RetirementAnalysis {
        let yearsToRetirement = max(retirementAge - currentAge, 0)

        let required = requiredRetirementFund(annualExpense: annualExpense)

        let projected = calculator.calculateFutureValue(
            presentValue: currentAssets,
            monthlyContribution: monthlyContribution,
            annualRate: annualReturnRate,
            years: yearsToRetirement
        )

        let gap = required - projected
        let isSufficient = projected >= required

        // 不足分を埋めるための追加月額
        let additionalMonthly: Decimal
        if gap > .zero, yearsToRetirement > 0 {
            additionalMonthly = calculateAdditionalMonthly(
                shortfall: gap,
                annualRate: annualReturnRate,
                years: yearsToRetirement
            )
        } else {
            additionalMonthly = Decimal.zero
        }

        let message = generateMessage(
            isSufficient: isSufficient,
            gap: gap,
            projected: projected,
            required: required,
            yearsToRetirement: yearsToRetirement,
            additionalMonthly: additionalMonthly
        )

        return RetirementAnalysis(
            requiredFund: required,
            projectedFund: projected,
            gap: gap,
            isSufficient: isSufficient,
            additionalMonthlyNeeded: additionalMonthly,
            message: message
        )
    }

    // MARK: - Private

    private func calculateAdditionalMonthly(
        shortfall: Decimal,
        annualRate: Decimal,
        years: Int
    ) -> Decimal {
        let s = NSDecimalNumber(decimal: shortfall).doubleValue
        let r = NSDecimalNumber(decimal: annualRate).doubleValue

        guard r > 0.0 else {
            let months = Double(years * 12)
            return Decimal(Int64((s / months).rounded(.up)))
        }

        let monthlyRate = r / 12.0
        let totalMonths = Double(years * 12)
        let compoundFactor = pow(1.0 + monthlyRate, totalMonths)

        let pmt = s * monthlyRate / (compoundFactor - 1.0)
        return Decimal(Int64(pmt.rounded(.up)))
    }

    private func generateMessage(
        isSufficient: Bool,
        gap: Decimal,
        projected: Decimal,
        required: Decimal,
        yearsToRetirement: Int,
        additionalMonthly: Decimal
    ) -> String {
        if isSufficient {
            let surplus = NSDecimalNumber(decimal: projected - required).intValue
            return "退職資金は十分です。予測余裕額: \(surplus)円"
        } else {
            let gapInt = NSDecimalNumber(decimal: gap).intValue
            let monthlyInt = NSDecimalNumber(decimal: additionalMonthly).intValue
            return "退職資金が\(gapInt)円不足する見込みです。月額\(monthlyInt)円の追加積立を検討してください"
        }
    }
}
