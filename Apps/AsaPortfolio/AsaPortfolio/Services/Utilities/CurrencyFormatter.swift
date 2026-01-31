import Foundation

/// 通貨フォーマッターユーティリティ
struct CurrencyFormatter {
    /// デフォルトの通貨コード
    static var defaultCurrencyCode: String = "USD"

    /// 金額をフォーマット
    static func format(_ amount: Decimal, currencyCode: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? defaultCurrencyCode
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? ""
    }

    /// 金額をコンパクト形式でフォーマット（1.2M, 3.5Bなど）
    static func formatCompact(_ amount: Decimal, currencyCode: String? = nil) -> String {
        let doubleValue = NSDecimalNumber(decimal: amount).doubleValue
        let absValue = abs(doubleValue)
        let sign = doubleValue < 0 ? "-" : ""
        let currencySymbol = currencySymbol(for: currencyCode ?? defaultCurrencyCode)

        if absValue >= 1_000_000_000_000 {
            return String(format: "%@%@%.2fT", sign, currencySymbol, absValue / 1_000_000_000_000)
        } else if absValue >= 1_000_000_000 {
            return String(format: "%@%@%.2fB", sign, currencySymbol, absValue / 1_000_000_000)
        } else if absValue >= 1_000_000 {
            return String(format: "%@%@%.2fM", sign, currencySymbol, absValue / 1_000_000)
        } else if absValue >= 1_000 {
            return String(format: "%@%@%.1fK", sign, currencySymbol, absValue / 1_000)
        } else {
            return format(amount, currencyCode: currencyCode)
        }
    }

    /// パーセンテージをフォーマット
    static func formatPercentage(_ value: Double, includeSign: Bool = true) -> String {
        let sign = includeSign && value > 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, value)
    }

    /// 数量をフォーマット（小数点以下の桁数を調整）
    static func formatQuantity(_ quantity: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSDecimalNumber(decimal: quantity)) ?? ""
    }

    /// 株価をフォーマット
    static func formatPrice(_ price: Decimal, currencyCode: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? defaultCurrencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? ""
    }

    /// 出来高をフォーマット
    static func formatVolume(_ volume: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: volume)) ?? ""
    }

    /// 出来高をコンパクト形式でフォーマット
    static func formatVolumeCompact(_ volume: Int) -> String {
        if volume >= 1_000_000_000 {
            return String(format: "%.2fB", Double(volume) / 1_000_000_000)
        } else if volume >= 1_000_000 {
            return String(format: "%.2fM", Double(volume) / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", Double(volume) / 1_000)
        } else {
            return "\(volume)"
        }
    }

    // MARK: - Private Helpers

    private static func currencySymbol(for currencyCode: String) -> String {
        let locale = NSLocale(localeIdentifier: currencyCode)
        return locale.displayName(forKey: .currencySymbol, value: currencyCode) ?? "$"
    }
}

// MARK: - Decimal Extensions

extension Decimal {
    /// 通貨形式でフォーマット
    var formattedCurrency: String {
        CurrencyFormatter.format(self)
    }

    /// コンパクト形式でフォーマット
    var formattedCompact: String {
        CurrencyFormatter.formatCompact(self)
    }

    /// 株価形式でフォーマット
    var formattedPrice: String {
        CurrencyFormatter.formatPrice(self)
    }
}

// MARK: - Double Extensions

extension Double {
    /// パーセンテージ形式でフォーマット
    var formattedPercentage: String {
        CurrencyFormatter.formatPercentage(self)
    }

    /// 符号なしパーセンテージ形式でフォーマット
    var formattedPercentageNoSign: String {
        CurrencyFormatter.formatPercentage(self, includeSign: false)
    }
}
