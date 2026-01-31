import Foundation
import SwiftData

/// 配当モデル - 配当金の記録
@Model
final class Dividend {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var perShare: Decimal
    var sharesOwned: Decimal
    var exDividendDate: Date
    var paymentDate: Date
    var currency: String
    var isReinvested: Bool
    var note: String?

    var holding: Holding?

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        amount: Decimal,
        perShare: Decimal,
        sharesOwned: Decimal,
        exDividendDate: Date,
        paymentDate: Date,
        currency: String = "USD",
        isReinvested: Bool = false,
        note: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.perShare = perShare
        self.sharesOwned = sharesOwned
        self.exDividendDate = exDividendDate
        self.paymentDate = paymentDate
        self.currency = currency
        self.isReinvested = isReinvested
        self.note = note
    }

    // MARK: - Computed Properties

    /// 配当利回り（年率想定）
    func dividendYield(currentPrice: Decimal) -> Double {
        guard currentPrice > 0 else { return 0 }
        let annualizedDividend = perShare * 4 // 四半期配当を想定
        let yield = NSDecimalNumber(decimal: annualizedDividend / currentPrice)
        return yield.doubleValue * 100
    }

    /// 支払日のフォーマット済み文字列
    var formattedPaymentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: paymentDate)
    }

    /// 権利落ち日のフォーマット済み文字列
    var formattedExDividendDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: exDividendDate)
    }

    /// 配当額のフォーマット済み文字列
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? ""
    }

    /// 配当が支払い済みかどうか
    var isPaid: Bool {
        paymentDate <= Date()
    }

    /// 配当が予定中かどうか
    var isUpcoming: Bool {
        paymentDate > Date()
    }
}
