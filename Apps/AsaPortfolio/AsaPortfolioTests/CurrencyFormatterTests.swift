import Testing
import Foundation
@testable import AsaPortfolio

/// CurrencyFormatter テスト
struct CurrencyFormatterTests {

    // MARK: - Currency Format Tests

    @Test("通貨フォーマット - 基本")
    func testBasicFormat() {
        let result = CurrencyFormatter.format(Decimal(1234.56))

        #expect(result.contains("1,234"))
        #expect(result.contains("$"))
    }

    @Test("通貨フォーマット - 日本円")
    func testJPYFormat() {
        let result = CurrencyFormatter.format(Decimal(1234), currencyCode: "JPY")

        #expect(result.contains("1,234"))
        #expect(result.contains("¥") || result.contains("JP"))
    }

    // MARK: - Compact Format Tests

    @Test("コンパクトフォーマット - 兆単位")
    func testCompactFormatTrillion() {
        let result = CurrencyFormatter.formatCompact(Decimal(1_500_000_000_000))

        #expect(result.contains("T"))
        #expect(result.contains("1.5"))
    }

    @Test("コンパクトフォーマット - 十億単位")
    func testCompactFormatBillion() {
        let result = CurrencyFormatter.formatCompact(Decimal(2_500_000_000))

        #expect(result.contains("B"))
        #expect(result.contains("2.5"))
    }

    @Test("コンパクトフォーマット - 百万単位")
    func testCompactFormatMillion() {
        let result = CurrencyFormatter.formatCompact(Decimal(3_500_000))

        #expect(result.contains("M"))
        #expect(result.contains("3.5"))
    }

    @Test("コンパクトフォーマット - 千単位")
    func testCompactFormatThousand() {
        let result = CurrencyFormatter.formatCompact(Decimal(4_500))

        #expect(result.contains("K"))
        #expect(result.contains("4.5"))
    }

    // MARK: - Percentage Format Tests

    @Test("パーセンテージフォーマット - 正の値")
    func testPercentageFormatPositive() {
        let result = CurrencyFormatter.formatPercentage(12.34, includeSign: true)

        #expect(result.contains("+"))
        #expect(result.contains("12.34"))
        #expect(result.contains("%"))
    }

    @Test("パーセンテージフォーマット - 負の値")
    func testPercentageFormatNegative() {
        let result = CurrencyFormatter.formatPercentage(-5.67, includeSign: true)

        #expect(result.contains("-"))
        #expect(result.contains("5.67"))
        #expect(result.contains("%"))
    }

    @Test("パーセンテージフォーマット - 符号なし")
    func testPercentageFormatNoSign() {
        let result = CurrencyFormatter.formatPercentage(12.34, includeSign: false)

        #expect(!result.contains("+"))
        #expect(result.contains("12.34"))
    }

    // MARK: - Quantity Format Tests

    @Test("数量フォーマット - 整数")
    func testQuantityFormatInteger() {
        let result = CurrencyFormatter.formatQuantity(Decimal(100))

        #expect(result == "100")
    }

    @Test("数量フォーマット - 小数")
    func testQuantityFormatDecimal() {
        let result = CurrencyFormatter.formatQuantity(Decimal(string: "12.5")!)

        #expect(result.contains("12.5"))
    }

    // MARK: - Volume Format Tests

    @Test("出来高フォーマット - コンパクト")
    func testVolumeFormatCompact() {
        let result = CurrencyFormatter.formatVolumeCompact(52_000_000)

        #expect(result.contains("52"))
        #expect(result.contains("M"))
    }

    // MARK: - Extension Tests

    @Test("Decimal拡張 - formattedCurrency")
    func testDecimalFormattedCurrency() {
        let value = Decimal(1234.56)
        let result = value.formattedCurrency

        #expect(result.contains("1,234"))
    }

    @Test("Double拡張 - formattedPercentage")
    func testDoubleFormattedPercentage() {
        let value = 12.34
        let result = value.formattedPercentage

        #expect(result.contains("+"))
        #expect(result.contains("12.34"))
        #expect(result.contains("%"))
    }
}
