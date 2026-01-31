import Foundation
import SwiftData

/// ウォッチリストアイテム - 監視中の銘柄
@Model
final class WatchlistItem {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var name: String
    var assetTypeRawValue: String
    var currentPrice: Decimal
    var previousClose: Decimal
    var targetPrice: Decimal?
    var alertEnabled: Bool
    var lastUpdated: Date
    var note: String?
    var addedAt: Date

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        assetType: AssetType = .stock,
        currentPrice: Decimal = 0,
        previousClose: Decimal = 0,
        targetPrice: Decimal? = nil,
        alertEnabled: Bool = false,
        note: String? = nil
    ) {
        self.id = id
        self.symbol = symbol.uppercased()
        self.name = name
        self.assetTypeRawValue = assetType.rawValue
        self.currentPrice = currentPrice
        self.previousClose = previousClose
        self.targetPrice = targetPrice
        self.alertEnabled = alertEnabled
        self.lastUpdated = Date()
        self.note = note
        self.addedAt = Date()
    }

    // MARK: - Computed Properties

    /// 資産タイプ（Enum）
    var assetType: AssetType {
        get { AssetType(rawValue: assetTypeRawValue) ?? .stock }
        set { assetTypeRawValue = newValue.rawValue }
    }

    /// 日次変動額
    var dailyChange: Decimal {
        currentPrice - previousClose
    }

    /// 日次変動率（％）
    var dailyChangePercentage: Double {
        guard previousClose > 0 else { return 0 }
        let change = NSDecimalNumber(decimal: dailyChange)
        let close = NSDecimalNumber(decimal: previousClose)
        return change.doubleValue / close.doubleValue * 100
    }

    /// 価格が上昇しているかどうか
    var isUp: Bool {
        dailyChange > 0
    }

    /// ターゲット価格に達したかどうか
    var targetReached: Bool {
        guard let target = targetPrice else { return false }
        return currentPrice >= target
    }

    /// ターゲット価格までの距離（％）
    var distanceToTarget: Double? {
        guard let target = targetPrice, currentPrice > 0 else { return nil }
        let distance = NSDecimalNumber(decimal: (target - currentPrice) / currentPrice)
        return distance.doubleValue * 100
    }

    /// 価格の更新が必要かどうか（15分以上経過）
    var needsUpdate: Bool {
        Int(Date().timeIntervalSince(lastUpdated) / 60) >= 15
    }
}
