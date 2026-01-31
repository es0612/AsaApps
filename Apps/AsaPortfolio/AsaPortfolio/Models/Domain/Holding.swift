import Foundation
import SwiftData

/// 保有資産モデル - 個別の株式・ETF等
@Model
final class Holding {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var name: String
    var assetTypeRawValue: String
    var quantity: Decimal
    var averageCost: Decimal
    var currentPrice: Decimal
    var lastUpdated: Date
    var currency: String
    var sectorName: String?
    var exchange: String?
    var logoURL: String?

    var portfolio: Portfolio?

    @Relationship(deleteRule: .cascade, inverse: \Transaction.holding)
    var transactions: [Transaction] = []

    @Relationship(deleteRule: .cascade, inverse: \Dividend.holding)
    var dividends: [Dividend] = []

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        assetType: AssetType = .stock,
        quantity: Decimal,
        averageCost: Decimal,
        currentPrice: Decimal = 0,
        lastUpdated: Date = Date(),
        currency: String = "USD",
        sectorName: String? = nil,
        exchange: String? = nil,
        logoURL: String? = nil
    ) {
        self.id = id
        self.symbol = symbol.uppercased()
        self.name = name
        self.assetTypeRawValue = assetType.rawValue
        self.quantity = quantity
        self.averageCost = averageCost
        self.currentPrice = currentPrice
        self.lastUpdated = lastUpdated
        self.currency = currency
        self.sectorName = sectorName
        self.exchange = exchange
        self.logoURL = logoURL
    }

    // MARK: - Computed Properties

    /// 資産タイプ（Enum）
    var assetType: AssetType {
        get { AssetType(rawValue: assetTypeRawValue) ?? .stock }
        set { assetTypeRawValue = newValue.rawValue }
    }

    /// 時価評価額
    var marketValue: Decimal {
        quantity * currentPrice
    }

    /// 取得原価合計
    var totalCost: Decimal {
        quantity * averageCost
    }

    /// 含み損益額
    var unrealizedGain: Decimal {
        marketValue - totalCost
    }

    /// 含み損益率（％）
    var gainPercentage: Double {
        guard averageCost > 0 else { return 0 }
        let gain = NSDecimalNumber(decimal: currentPrice - averageCost)
        let cost = NSDecimalNumber(decimal: averageCost)
        return gain.doubleValue / cost.doubleValue * 100
    }

    /// 利益が出ているかどうか
    var isProfit: Bool {
        unrealizedGain >= 0
    }

    /// 配当金合計
    var totalDividends: Decimal {
        dividends.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// 最終更新からの経過時間（分）
    var minutesSinceLastUpdate: Int {
        Int(Date().timeIntervalSince(lastUpdated) / 60)
    }

    /// 価格の更新が必要かどうか（15分以上経過）
    var needsUpdate: Bool {
        minutesSinceLastUpdate >= 15
    }
}
