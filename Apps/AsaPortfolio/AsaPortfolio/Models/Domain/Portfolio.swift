import Foundation
import SwiftData

/// ポートフォリオモデル - 複数の保有資産をグループ化
@Model
final class Portfolio {
    @Attribute(.unique) var id: UUID
    var name: String
    var note: String
    var colorHex: String
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Holding.portfolio)
    var holdings: [Holding] = []

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String,
        note: String = "",
        colorHex: String = "#C68C53",
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// ポートフォリオの時価総額
    var totalValue: Decimal {
        holdings.reduce(Decimal.zero) { $0 + $1.marketValue }
    }

    /// ポートフォリオの取得原価合計
    var totalCost: Decimal {
        holdings.reduce(Decimal.zero) { $0 + $1.totalCost }
    }

    /// 含み損益額
    var totalGain: Decimal {
        totalValue - totalCost
    }

    /// 含み損益率（％）
    var gainPercentage: Double {
        guard totalCost > 0 else { return 0 }
        let gain = NSDecimalNumber(decimal: totalGain)
        let cost = NSDecimalNumber(decimal: totalCost)
        return gain.doubleValue / cost.doubleValue * 100
    }

    /// 保有銘柄数
    var holdingsCount: Int {
        holdings.count
    }

    /// 利益が出ているかどうか
    var isProfit: Bool {
        totalGain >= 0
    }
}
