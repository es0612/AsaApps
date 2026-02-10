import Foundation

// MARK: - CompoundInterestCalculator

/// 複利計算エンジン
///
/// 将来価値の計算式（月次複利）:
/// FV = PV * (1 + r/12)^(12n) + PMT * [((1 + r/12)^(12n) - 1) / (r/12)]
/// - PV: 現在価値
/// - PMT: 月額積立額
/// - r: 年間利率
/// - n: 運用年数
public struct CompoundInterestCalculator: ProjectionCalculating {
    public init() {}

    // MARK: - ProjectionCalculating

    public func calculateFutureValue(
        presentValue: Decimal,
        monthlyContribution: Decimal,
        annualRate: Decimal,
        years: Int
    ) -> Decimal {
        guard years >= 0 else { return presentValue }

        let pv = NSDecimalNumber(decimal: presentValue).doubleValue
        let pmt = NSDecimalNumber(decimal: monthlyContribution).doubleValue
        let r = NSDecimalNumber(decimal: annualRate).doubleValue
        let n = Double(years)

        // 利率ゼロの場合は単純積立
        guard r != 0.0 else {
            let result = pv + pmt * 12.0 * n
            return Decimal(result)
        }

        let monthlyRate = r / 12.0
        let totalMonths = 12.0 * n
        let compoundFactor = pow(1.0 + monthlyRate, totalMonths)

        // PV部分: PV * (1 + r/12)^(12n)
        let pvFuture = pv * compoundFactor

        // PMT部分: PMT * [((1 + r/12)^(12n) - 1) / (r/12)]
        let pmtFuture = pmt * ((compoundFactor - 1.0) / monthlyRate)

        let result = pvFuture + pmtFuture
        // 小数点以下を丸めてDecimalに変換
        return Decimal(Int64(result.rounded()))
    }

    public func generateProjection(
        presentValue: Decimal,
        monthlyContribution: Decimal,
        annualRate: Decimal,
        inflationRate: Decimal,
        years: Int
    ) -> [ProjectionPoint] {
        guard years >= 0 else { return [] }

        var points: [ProjectionPoint] = []

        for year in 0...years {
            let nominalValue = calculateFutureValue(
                presentValue: presentValue,
                monthlyContribution: monthlyContribution,
                annualRate: annualRate,
                years: year
            )

            let realValue = adjustForInflation(
                nominalValue: nominalValue,
                inflationRate: inflationRate,
                years: year
            )

            let contributionTotal = presentValue + monthlyContribution * Decimal(12 * year)

            points.append(ProjectionPoint(
                year: year,
                nominalValue: nominalValue,
                realValue: realValue,
                contributionTotal: contributionTotal
            ))
        }

        return points
    }

    // MARK: - Private

    private func adjustForInflation(
        nominalValue: Decimal,
        inflationRate: Decimal,
        years: Int
    ) -> Decimal {
        guard years > 0 else { return nominalValue }

        let nominal = NSDecimalNumber(decimal: nominalValue).doubleValue
        let inflation = NSDecimalNumber(decimal: inflationRate).doubleValue
        let deflator = pow(1.0 + inflation, Double(years))
        let result = nominal / deflator

        return Decimal(Int64(result.rounded()))
    }
}
