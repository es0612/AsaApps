import Foundation

/// パフォーマンス計算結果
struct GainLossResult: Sendable {
    let amount: Decimal
    let percentage: Double
    let isProfit: Bool

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let sign = isProfit ? "+" : ""
        return sign + (formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "")
    }

    var formattedPercentage: String {
        let sign = isProfit ? "+" : ""
        return String(format: "%@%.2f%%", sign, percentage)
    }
}

/// 期間別パフォーマンス
struct PeriodPerformance: Sendable, Identifiable {
    let period: TimeRange
    let startValue: Decimal
    let endValue: Decimal
    let gainLoss: GainLossResult

    var id: String { period.rawValue }
}

/// セクター別配分
struct SectorAllocation: Sendable, Identifiable {
    let sectorName: String
    let value: Decimal
    let percentage: Double
    let holdingsCount: Int

    var id: String { sectorName }
}

/// 資産タイプ別配分
struct AssetTypeAllocation: Sendable, Identifiable {
    let assetType: AssetType
    let value: Decimal
    let percentage: Double
    let holdingsCount: Int

    var id: String { assetType.rawValue }
}

/// パフォーマンス計算ユーティリティ
struct PerformanceCalculator {

    // MARK: - Gain/Loss Calculation

    /// 損益を計算
    static func calculateGain(currentValue: Decimal, costBasis: Decimal) -> GainLossResult {
        let gain = currentValue - costBasis
        let percentage: Double

        if costBasis > 0 {
            let gainNumber = NSDecimalNumber(decimal: gain)
            let costNumber = NSDecimalNumber(decimal: costBasis)
            percentage = gainNumber.doubleValue / costNumber.doubleValue * 100
        } else {
            percentage = 0
        }

        return GainLossResult(
            amount: gain,
            percentage: percentage,
            isProfit: gain >= 0
        )
    }

    /// 保有資産の損益を計算
    static func calculateGain(for holding: Holding) -> GainLossResult {
        calculateGain(currentValue: holding.marketValue, costBasis: holding.totalCost)
    }

    /// ポートフォリオの損益を計算
    static func calculateGain(for portfolio: Portfolio) -> GainLossResult {
        calculateGain(currentValue: portfolio.totalValue, costBasis: portfolio.totalCost)
    }

    // MARK: - Allocation Analysis

    /// セクター別配分を計算
    static func calculateSectorAllocation(holdings: [Holding]) -> [SectorAllocation] {
        let totalValue = holdings.reduce(Decimal.zero) { $0 + $1.marketValue }
        guard totalValue > 0 else { return [] }

        var sectorMap: [String: (value: Decimal, count: Int)] = [:]

        for holding in holdings {
            let sector = holding.sectorName ?? "その他"
            let current = sectorMap[sector] ?? (value: 0, count: 0)
            sectorMap[sector] = (value: current.value + holding.marketValue, count: current.count + 1)
        }

        return sectorMap.map { sector, data in
            let percentage = NSDecimalNumber(decimal: data.value / totalValue).doubleValue * 100
            return SectorAllocation(
                sectorName: sector,
                value: data.value,
                percentage: percentage,
                holdingsCount: data.count
            )
        }.sorted { $0.value > $1.value }
    }

    /// 資産タイプ別配分を計算
    static func calculateAssetTypeAllocation(holdings: [Holding]) -> [AssetTypeAllocation] {
        let totalValue = holdings.reduce(Decimal.zero) { $0 + $1.marketValue }
        guard totalValue > 0 else { return [] }

        var typeMap: [AssetType: (value: Decimal, count: Int)] = [:]

        for holding in holdings {
            let current = typeMap[holding.assetType] ?? (value: 0, count: 0)
            typeMap[holding.assetType] = (value: current.value + holding.marketValue, count: current.count + 1)
        }

        return typeMap.map { type, data in
            let percentage = NSDecimalNumber(decimal: data.value / totalValue).doubleValue * 100
            return AssetTypeAllocation(
                assetType: type,
                value: data.value,
                percentage: percentage,
                holdingsCount: data.count
            )
        }.sorted { $0.value > $1.value }
    }

    // MARK: - Top Performers

    /// 上位値上がり銘柄を取得
    static func topGainers(holdings: [Holding], limit: Int = 5) -> [Holding] {
        holdings
            .filter { $0.gainPercentage > 0 }
            .sorted { $0.gainPercentage > $1.gainPercentage }
            .prefix(limit)
            .map { $0 }
    }

    /// 上位値下がり銘柄を取得
    static func topLosers(holdings: [Holding], limit: Int = 5) -> [Holding] {
        holdings
            .filter { $0.gainPercentage < 0 }
            .sorted { $0.gainPercentage < $1.gainPercentage }
            .prefix(limit)
            .map { $0 }
    }

    /// 保有額上位銘柄を取得
    static func topHoldings(holdings: [Holding], limit: Int = 5) -> [Holding] {
        holdings
            .sorted { $0.marketValue > $1.marketValue }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Time Series Analysis

    /// 時系列データから期間パフォーマンスを計算
    static func calculatePeriodPerformance(
        timeSeries: [TimeSeriesData],
        period: TimeRange
    ) -> PeriodPerformance? {
        guard !timeSeries.isEmpty else { return nil }

        let sortedSeries = timeSeries.sorted { $0.date < $1.date }
        let startDate = period.startDate

        guard let startData = sortedSeries.first(where: { $0.date >= startDate }),
              let endData = sortedSeries.last else {
            return nil
        }

        let gainLoss = calculateGain(currentValue: endData.close, costBasis: startData.close)

        return PeriodPerformance(
            period: period,
            startValue: startData.close,
            endValue: endData.close,
            gainLoss: gainLoss
        )
    }

    // MARK: - Dividend Analysis

    /// 年間配当利回りを計算
    static func calculateDividendYield(
        annualDividend: Decimal,
        currentPrice: Decimal
    ) -> Double {
        guard currentPrice > 0 else { return 0 }
        let yield = NSDecimalNumber(decimal: annualDividend / currentPrice)
        return yield.doubleValue * 100
    }

    /// 配当金合計を計算
    static func totalDividends(dividends: [Dividend]) -> Decimal {
        dividends.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// 年別配当金を計算
    static func dividendsByYear(dividends: [Dividend]) -> [Int: Decimal] {
        var result: [Int: Decimal] = [:]
        let calendar = Calendar.current

        for dividend in dividends {
            let year = calendar.component(.year, from: dividend.paymentDate)
            result[year, default: 0] += dividend.amount
        }

        return result
    }
}
