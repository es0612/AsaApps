import Foundation

// MARK: - InflationAdjuster

/// インフレ調整計算サービス
///
/// 名目価値をインフレ率で割引いて実質価値に変換する。
/// 実質価値 = 名目価値 / (1 + インフレ率)^年数
public struct InflationAdjuster: Sendable {
    public init() {}

    // MARK: - Methods

    /// インフレ調整後の実質価値を計算
    /// - Parameters:
    ///   - nominalValue: 名目価値
    ///   - inflationRate: 年間インフレ率（例: 0.02 = 2%）
    ///   - years: 年数
    /// - Returns: 実質価値（現在の購買力ベース）
    public func adjustForInflation(
        nominalValue: Decimal,
        inflationRate: Decimal,
        years: Int
    ) -> Decimal {
        guard years > 0 else { return nominalValue }

        let nominal = NSDecimalNumber(decimal: nominalValue).doubleValue
        let inflation = NSDecimalNumber(decimal: inflationRate).doubleValue

        // ゼロインフレなら変化なし
        guard inflation != 0.0 else { return nominalValue }

        let deflator = pow(1.0 + inflation, Double(years))
        let result = nominal / deflator

        return Decimal(Int64(result.rounded()))
    }

    /// インフレ調整後の目標額を計算
    ///
    /// 将来必要な金額をインフレ率で増加させる。
    /// 例: 現在1000万円必要 → 2%インフレ × 20年後 = 約1486万円必要
    /// - Parameters:
    ///   - currentTarget: 現在価値ベースの目標額
    ///   - inflationRate: 年間インフレ率
    ///   - years: 年数
    /// - Returns: インフレ調整後の目標額
    public func inflationAdjustedTarget(
        currentTarget: Decimal,
        inflationRate: Decimal,
        years: Int
    ) -> Decimal {
        guard years > 0 else { return currentTarget }

        let target = NSDecimalNumber(decimal: currentTarget).doubleValue
        let inflation = NSDecimalNumber(decimal: inflationRate).doubleValue

        guard inflation != 0.0 else { return currentTarget }

        let inflationFactor = pow(1.0 + inflation, Double(years))
        let result = target * inflationFactor

        return Decimal(Int64(result.rounded()))
    }
}
