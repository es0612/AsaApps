import Foundation
import SwiftData

/// 取引モデル - 購入・売却・配当等の記録
@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var transactionTypeRawValue: String
    var quantity: Decimal
    var pricePerShare: Decimal
    var totalAmount: Decimal
    var fees: Decimal
    var executedAt: Date
    var note: String?

    var holding: Holding?

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        transactionType: TransactionType,
        quantity: Decimal,
        pricePerShare: Decimal,
        fees: Decimal = 0,
        executedAt: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.transactionTypeRawValue = transactionType.rawValue
        self.quantity = quantity
        self.pricePerShare = pricePerShare
        self.totalAmount = quantity * pricePerShare + fees
        self.fees = fees
        self.executedAt = executedAt
        self.note = note
    }

    // MARK: - Computed Properties

    /// 取引タイプ（Enum）
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRawValue) ?? .buy }
        set { transactionTypeRawValue = newValue.rawValue }
    }

    /// 手数料込みの実質単価
    var effectivePricePerShare: Decimal {
        guard quantity > 0 else { return pricePerShare }
        return totalAmount / quantity
    }

    /// 取引日のフォーマット済み文字列
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: executedAt)
    }

    /// 取引金額のフォーマット済み文字列
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = holding?.currency ?? "USD"
        return formatter.string(from: NSDecimalNumber(decimal: totalAmount)) ?? ""
    }
}
