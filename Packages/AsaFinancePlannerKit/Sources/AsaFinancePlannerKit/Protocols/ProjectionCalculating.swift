import Foundation

// MARK: - ProjectionCalculating

/// 将来予測計算プロトコル
public protocol ProjectionCalculating: Sendable {
    /// 複利計算で将来価値を算出
    /// - Parameters:
    ///   - presentValue: 現在価値
    ///   - monthlyContribution: 月額積立額
    ///   - annualRate: 年間利率（例: 0.05 = 5%）
    ///   - years: 運用年数
    /// - Returns: 将来価値
    func calculateFutureValue(
        presentValue: Decimal,
        monthlyContribution: Decimal,
        annualRate: Decimal,
        years: Int
    ) -> Decimal

    /// 年次の将来予測データを生成
    /// - Parameters:
    ///   - presentValue: 現在価値
    ///   - monthlyContribution: 月額積立額
    ///   - annualRate: 年間利率
    ///   - inflationRate: インフレ率
    ///   - years: 予測年数
    /// - Returns: 年次予測データの配列
    func generateProjection(
        presentValue: Decimal,
        monthlyContribution: Decimal,
        annualRate: Decimal,
        inflationRate: Decimal,
        years: Int
    ) -> [ProjectionPoint]
}
