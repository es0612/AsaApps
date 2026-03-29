//
//  SampleDataGenerator.swift
//  AsaPortfolio
//
//  デモ動画撮影用のサンプルデータ投入
//

import Foundation
import SwiftData

@MainActor
final class SampleDataGenerator {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public

    func insertSampleData() throws {
        // ポートフォリオ1: 米国個別株
        let usStocks = Portfolio(
            name: "米国個別株",
            note: "長期保有の成長株ポートフォリオ",
            colorHex: "#C68C53",
            sortOrder: 0
        )

        let usHoldings: [(symbol: String, name: String, type: AssetType, qty: Decimal, cost: Decimal, price: Decimal, sector: String)] = [
            ("AAPL",  "Apple Inc.",         .stock, 15, 145.50, 189.84, "Technology"),
            ("GOOGL", "Alphabet Inc.",      .stock,  8, 125.30, 141.80, "Technology"),
            ("MSFT",  "Microsoft Corp.",    .stock, 10, 310.00, 378.91, "Technology"),
            ("AMZN",  "Amazon.com Inc.",    .stock,  5, 128.00, 178.25, "Consumer Cyclical"),
            ("NVDA",  "NVIDIA Corp.",       .stock,  6, 450.00, 721.33, "Technology"),
        ]

        for h in usHoldings {
            let holding = Holding(
                symbol: h.symbol,
                name: h.name,
                assetType: h.type,
                quantity: h.qty,
                averageCost: h.cost,
                currentPrice: h.price,
                sectorName: h.sector
            )
            holding.portfolio = usStocks
            usStocks.holdings.append(holding)
        }

        modelContext.insert(usStocks)

        // ポートフォリオ2: ETF・インデックス
        let etfPortfolio = Portfolio(
            name: "ETF・インデックス",
            note: "コア資産としての分散投資",
            colorHex: "#7A918D",
            sortOrder: 1
        )

        let etfHoldings: [(symbol: String, name: String, type: AssetType, qty: Decimal, cost: Decimal, price: Decimal, sector: String)] = [
            ("VOO", "Vanguard S&P 500 ETF",    .etf, 20, 380.00, 462.17, "Broad Market"),
            ("VTI", "Vanguard Total Stock ETF", .etf, 25, 210.50, 243.82, "Broad Market"),
            ("QQQ", "Invesco QQQ Trust",        .etf, 10, 350.00, 421.55, "Technology"),
        ]

        for h in etfHoldings {
            let holding = Holding(
                symbol: h.symbol,
                name: h.name,
                assetType: h.type,
                quantity: h.qty,
                averageCost: h.cost,
                currentPrice: h.price,
                sectorName: h.sector
            )
            holding.portfolio = etfPortfolio
            etfPortfolio.holdings.append(holding)
        }

        modelContext.insert(etfPortfolio)

        // ウォッチリスト
        let watchlistItems: [(symbol: String, name: String, price: Decimal, prevClose: Decimal, target: Decimal?)] = [
            ("TSLA", "Tesla Inc.",     178.02, 175.50, 200.00),
            ("META", "Meta Platforms", 493.50, 488.20, 550.00),
            ("DIS",  "Walt Disney Co.", 112.30, 110.85, nil),
        ]

        for w in watchlistItems {
            let item = WatchlistItem(
                symbol: w.symbol,
                name: w.name,
                currentPrice: w.price,
                previousClose: w.prevClose,
                targetPrice: w.target,
                alertEnabled: w.target != nil
            )
            modelContext.insert(item)
        }

        try modelContext.save()
    }
}
