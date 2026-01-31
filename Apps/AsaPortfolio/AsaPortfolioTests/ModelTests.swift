import Testing
import Foundation
@testable import AsaPortfolio

/// ドメインモデル テスト
struct ModelTests {

    // MARK: - Holding Tests

    @Test("Holding - 時価評価額計算")
    func testHoldingMarketValue() {
        let holding = Holding(
            symbol: "AAPL",
            name: "Apple Inc.",
            assetType: .stock,
            quantity: Decimal(10),
            averageCost: Decimal(150),
            currentPrice: Decimal(180)
        )

        #expect(holding.marketValue == Decimal(1800))
    }

    @Test("Holding - 取得原価計算")
    func testHoldingTotalCost() {
        let holding = Holding(
            symbol: "AAPL",
            name: "Apple Inc.",
            assetType: .stock,
            quantity: Decimal(10),
            averageCost: Decimal(150),
            currentPrice: Decimal(180)
        )

        #expect(holding.totalCost == Decimal(1500))
    }

    @Test("Holding - 含み損益計算（利益）")
    func testHoldingUnrealizedGainProfit() {
        let holding = Holding(
            symbol: "AAPL",
            name: "Apple Inc.",
            assetType: .stock,
            quantity: Decimal(10),
            averageCost: Decimal(150),
            currentPrice: Decimal(180)
        )

        #expect(holding.unrealizedGain == Decimal(300))
        #expect(holding.isProfit == true)
    }

    @Test("Holding - 含み損益計算（損失）")
    func testHoldingUnrealizedGainLoss() {
        let holding = Holding(
            symbol: "AAPL",
            name: "Apple Inc.",
            assetType: .stock,
            quantity: Decimal(10),
            averageCost: Decimal(180),
            currentPrice: Decimal(150)
        )

        #expect(holding.unrealizedGain == Decimal(-300))
        #expect(holding.isProfit == false)
    }

    @Test("Holding - 損益率計算")
    func testHoldingGainPercentage() {
        let holding = Holding(
            symbol: "AAPL",
            name: "Apple Inc.",
            assetType: .stock,
            quantity: Decimal(10),
            averageCost: Decimal(100),
            currentPrice: Decimal(120)
        )

        #expect(abs(holding.gainPercentage - 20.0) < 0.01)
    }

    @Test("Holding - シンボル大文字化")
    func testHoldingSymbolUppercase() {
        let holding = Holding(
            symbol: "aapl",
            name: "Apple Inc.",
            quantity: Decimal(10),
            averageCost: Decimal(150)
        )

        #expect(holding.symbol == "AAPL")
    }

    // MARK: - WatchlistItem Tests

    @Test("WatchlistItem - 日次変動計算")
    func testWatchlistItemDailyChange() {
        let item = WatchlistItem(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: Decimal(182),
            previousClose: Decimal(180)
        )

        #expect(item.dailyChange == Decimal(2))
        #expect(item.isUp == true)
    }

    @Test("WatchlistItem - 日次変動率計算")
    func testWatchlistItemDailyChangePercentage() {
        let item = WatchlistItem(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: Decimal(110),
            previousClose: Decimal(100)
        )

        #expect(abs(item.dailyChangePercentage - 10.0) < 0.01)
    }

    @Test("WatchlistItem - ターゲット価格到達判定")
    func testWatchlistItemTargetReached() {
        let item = WatchlistItem(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: Decimal(200),
            previousClose: Decimal(180),
            targetPrice: Decimal(190)
        )

        #expect(item.targetReached == true)
    }

    @Test("WatchlistItem - ターゲット価格未到達判定")
    func testWatchlistItemTargetNotReached() {
        let item = WatchlistItem(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: Decimal(185),
            previousClose: Decimal(180),
            targetPrice: Decimal(200)
        )

        #expect(item.targetReached == false)
    }

    // MARK: - Transaction Tests

    @Test("Transaction - 取引金額計算")
    func testTransactionTotalAmount() {
        let transaction = Transaction(
            transactionType: .buy,
            quantity: Decimal(10),
            pricePerShare: Decimal(150),
            fees: Decimal(10)
        )

        #expect(transaction.totalAmount == Decimal(1510))
    }

    @Test("Transaction - 実質単価計算")
    func testTransactionEffectivePrice() {
        let transaction = Transaction(
            transactionType: .buy,
            quantity: Decimal(10),
            pricePerShare: Decimal(150),
            fees: Decimal(10)
        )

        #expect(transaction.effectivePricePerShare == Decimal(151))
    }

    // MARK: - Dividend Tests

    @Test("Dividend - 支払い済み判定")
    func testDividendIsPaid() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let dividend = Dividend(
            amount: Decimal(10),
            perShare: Decimal(1),
            sharesOwned: Decimal(10),
            exDividendDate: pastDate,
            paymentDate: pastDate
        )

        #expect(dividend.isPaid == true)
        #expect(dividend.isUpcoming == false)
    }

    @Test("Dividend - 予定判定")
    func testDividendIsUpcoming() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let dividend = Dividend(
            amount: Decimal(10),
            perShare: Decimal(1),
            sharesOwned: Decimal(10),
            exDividendDate: Date(),
            paymentDate: futureDate
        )

        #expect(dividend.isPaid == false)
        #expect(dividend.isUpcoming == true)
    }

    // MARK: - Enum Tests

    @Test("AssetType - 表示名")
    func testAssetTypeDisplayName() {
        #expect(AssetType.stock.displayName == "株式")
        #expect(AssetType.etf.displayName == "ETF")
        #expect(AssetType.mutualFund.displayName == "投資信託")
    }

    @Test("TransactionType - 表示名")
    func testTransactionTypeDisplayName() {
        #expect(TransactionType.buy.displayName == "購入")
        #expect(TransactionType.sell.displayName == "売却")
        #expect(TransactionType.dividend.displayName == "配当")
    }

    @Test("TimeRange - 開始日計算")
    func testTimeRangeStartDate() {
        let weekStart = TimeRange.week.startDate
        let now = Date()
        let diff = Calendar.current.dateComponents([.day], from: weekStart, to: now).day!

        #expect(diff >= 6 && diff <= 8)
    }
}
