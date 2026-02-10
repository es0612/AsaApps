import Foundation

// MARK: - GoalFeasibilityAnalyzer

/// 目標達成可能性の分析エンジン
///
/// インフレ調整後の目標額と予測到達額を比較し、
/// 達成確率・不足額・必要月額を算出する。
public struct GoalFeasibilityAnalyzer: GoalAnalyzing {
    private let calculator: ProjectionCalculating
    private let inflationAdjuster: InflationAdjuster

    public init(
        calculator: ProjectionCalculating = CompoundInterestCalculator(),
        inflationAdjuster: InflationAdjuster = InflationAdjuster()
    ) {
        self.calculator = calculator
        self.inflationAdjuster = inflationAdjuster
    }

    // MARK: - GoalAnalyzing

    public func analyzeFeasibility(
        goal: FinancialGoal,
        currentAssets: Decimal,
        monthlyContribution: Decimal,
        annualReturnRate: Decimal,
        inflationRate: Decimal
    ) -> GoalFeasibilityResult {
        let remainingMonths = goal.remainingMonths
        let years = max(remainingMonths / 12, 1)

        // インフレ調整後の目標額
        let adjustedTarget = inflationAdjuster.inflationAdjustedTarget(
            currentTarget: goal.targetAmount,
            inflationRate: inflationRate,
            years: years
        )

        // 予測到達額（現在資産 + 積立の複利運用）
        let projectedAmount = calculator.calculateFutureValue(
            presentValue: currentAssets,
            monthlyContribution: monthlyContribution,
            annualRate: annualReturnRate,
            years: years
        )

        // 不足額
        let shortfall = max(adjustedTarget - projectedAmount, Decimal.zero)
        let isFeasible = projectedAmount >= adjustedTarget

        // 達成確率（0.0〜1.0）
        let probability = calculateProbability(
            projected: projectedAmount,
            target: adjustedTarget
        )

        // 不足時の必要月額追加
        let requiredMonthly = calculateRequiredMonthly(
            shortfall: shortfall,
            annualRate: annualReturnRate,
            years: years
        )

        // メッセージ生成
        let message = generateMessage(
            goalName: goal.name,
            isFeasible: isFeasible,
            probability: probability,
            shortfall: shortfall,
            requiredMonthly: requiredMonthly
        )

        return GoalFeasibilityResult(
            goal: goal.name,
            isFeasible: isFeasible,
            projectedAmount: projectedAmount,
            shortfall: shortfall,
            requiredMonthlyContribution: requiredMonthly,
            probabilityOfSuccess: probability,
            message: message
        )
    }

    // MARK: - Private

    private func calculateProbability(
        projected: Decimal,
        target: Decimal
    ) -> Double {
        guard target > .zero else { return 1.0 }

        let ratio = NSDecimalNumber(decimal: projected).doubleValue
            / NSDecimalNumber(decimal: target).doubleValue

        // 比率に基づく達成確率（線形マッピング）
        // ratio >= 1.2 → 1.0, ratio <= 0.5 → 0.0
        if ratio >= 1.2 { return 1.0 }
        if ratio <= 0.5 { return 0.0 }
        return min(max((ratio - 0.5) / 0.7, 0.0), 1.0)
    }

    private func calculateRequiredMonthly(
        shortfall: Decimal,
        annualRate: Decimal,
        years: Int
    ) -> Decimal {
        guard shortfall > .zero, years > 0 else { return Decimal.zero }

        let s = NSDecimalNumber(decimal: shortfall).doubleValue
        let r = NSDecimalNumber(decimal: annualRate).doubleValue

        // 利率ゼロなら単純割り算
        guard r > 0.0 else {
            let months = Double(years * 12)
            return Decimal(Int64((s / months).rounded(.up)))
        }

        let monthlyRate = r / 12.0
        let totalMonths = Double(years * 12)
        let compoundFactor = pow(1.0 + monthlyRate, totalMonths)

        // PMT = FV * (r/12) / ((1 + r/12)^n - 1)
        let pmt = s * monthlyRate / (compoundFactor - 1.0)

        return Decimal(Int64(pmt.rounded(.up)))
    }

    private func generateMessage(
        goalName: String,
        isFeasible: Bool,
        probability: Double,
        shortfall: Decimal,
        requiredMonthly: Decimal
    ) -> String {
        if isFeasible {
            let percentStr = String(format: "%.0f", probability * 100)
            return "\(goalName)は達成可能です（成功確率: \(percentStr)%）"
        } else {
            let shortfallStr = NSDecimalNumber(decimal: shortfall).intValue
            let monthlyStr = NSDecimalNumber(decimal: requiredMonthly).intValue
            return "\(goalName)の達成には\(shortfallStr)円の不足が見込まれます。月額\(monthlyStr)円の追加積立を検討してください"
        }
    }
}
