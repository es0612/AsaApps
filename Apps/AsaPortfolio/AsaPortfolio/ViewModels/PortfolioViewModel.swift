import Foundation
import SwiftUI

/// アプリの状態
enum AppState: Sendable, Equatable {
    case loading
    case loaded
    case error(String)
    case empty
}

/// ポートフォリオViewModel - メインの状態管理
@MainActor
@Observable
final class PortfolioViewModel {
    // MARK: - Dependencies

    private let stockAPIService: StockAPIServiceProtocol
    private let dataService: PortfolioDataService

    // MARK: - State

    private(set) var appState: AppState = .loading
    private(set) var portfolios: [Portfolio] = []
    private(set) var selectedPortfolio: Portfolio?
    private(set) var watchlistItems: [WatchlistItem] = []
    private(set) var isRefreshing = false
    private(set) var lastUpdated: Date?
    private(set) var errorMessage: String?

    // MARK: - Computed Properties

    /// 全ポートフォリオの合計時価総額
    var totalValue: Decimal {
        portfolios.reduce(Decimal.zero) { $0 + $1.totalValue }
    }

    /// 全ポートフォリオの合計取得原価
    var totalCost: Decimal {
        portfolios.reduce(Decimal.zero) { $0 + $1.totalCost }
    }

    /// 全ポートフォリオの合計損益
    var totalGain: Decimal {
        totalValue - totalCost
    }

    /// 全ポートフォリオの損益率
    var totalGainPercentage: Double {
        guard totalCost > 0 else { return 0 }
        let gain = NSDecimalNumber(decimal: totalGain)
        let cost = NSDecimalNumber(decimal: totalCost)
        return gain.doubleValue / cost.doubleValue * 100
    }

    /// 全ての保有資産
    var allHoldings: [Holding] {
        portfolios.flatMap { $0.holdings }
    }

    /// 値上がり上位銘柄
    var topGainers: [Holding] {
        PerformanceCalculator.topGainers(holdings: allHoldings, limit: 5)
    }

    /// 値下がり上位銘柄
    var topLosers: [Holding] {
        PerformanceCalculator.topLosers(holdings: allHoldings, limit: 5)
    }

    /// 保有額上位銘柄
    var topHoldings: [Holding] {
        PerformanceCalculator.topHoldings(holdings: allHoldings, limit: 5)
    }

    /// セクター別配分
    var sectorAllocation: [SectorAllocation] {
        PerformanceCalculator.calculateSectorAllocation(holdings: allHoldings)
    }

    /// 資産タイプ別配分
    var assetTypeAllocation: [AssetTypeAllocation] {
        PerformanceCalculator.calculateAssetTypeAllocation(holdings: allHoldings)
    }

    /// 残りAPIリクエスト数
    var remainingAPIRequests: Int {
        stockAPIService.remainingRequests
    }

    /// データが空かどうか
    var isEmpty: Bool {
        portfolios.isEmpty
    }

    // MARK: - Initializer

    init(
        stockAPIService: StockAPIServiceProtocol,
        dataService: PortfolioDataService
    ) {
        self.stockAPIService = stockAPIService
        self.dataService = dataService
    }

    // MARK: - Data Loading

    /// 初期データを読み込み
    func loadInitialData() async {
        appState = .loading

        do {
            portfolios = try dataService.fetchAllPortfolios()
            watchlistItems = try dataService.fetchWatchlist()

            if portfolios.isEmpty {
                appState = .empty
            } else {
                selectedPortfolio = portfolios.first
                await refreshQuotes()
                appState = .loaded
            }
        } catch {
            appState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    /// 株価を更新
    func refreshQuotes() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil

        do {
            // 全保有銘柄のシンボルを取得
            let holdingSymbols = allHoldings.map(\.symbol)
            let watchlistSymbols = watchlistItems.map(\.symbol)
            let allSymbols = Array(Set(holdingSymbols + watchlistSymbols))

            guard !allSymbols.isEmpty else {
                isRefreshing = false
                return
            }

            // 株価を取得
            let quotes = try await stockAPIService.fetchBulkQuotes(symbols: allSymbols)

            // 保有資産の価格を更新
            for holding in allHoldings {
                if let quote = quotes.first(where: { $0.symbol == holding.symbol }) {
                    try dataService.updateHoldingPrice(holding, price: quote.price)
                }
            }

            // ウォッチリストの価格を更新
            for item in watchlistItems {
                if let quote = quotes.first(where: { $0.symbol == item.symbol }) {
                    item.currentPrice = quote.price
                    item.previousClose = quote.previousClose
                    item.lastUpdated = Date()
                    try dataService.updateWatchlistItem(item)
                }
            }

            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

        isRefreshing = false
    }

    // MARK: - Portfolio Management

    /// ポートフォリオを作成
    func createPortfolio(name: String, note: String = "", colorHex: String = "#C68C53") async throws {
        let portfolio = try dataService.createPortfolio(name: name, note: note, colorHex: colorHex)
        portfolios.append(portfolio)

        if selectedPortfolio == nil {
            selectedPortfolio = portfolio
        }

        if appState == .empty {
            appState = .loaded
        }
    }

    /// ポートフォリオを選択
    func selectPortfolio(_ portfolio: Portfolio) {
        selectedPortfolio = portfolio
    }

    /// ポートフォリオを更新
    func updatePortfolio(_ portfolio: Portfolio) async throws {
        try dataService.updatePortfolio(portfolio)
    }

    /// ポートフォリオを削除
    func deletePortfolio(_ portfolio: Portfolio) async throws {
        try dataService.deletePortfolio(portfolio)
        portfolios.removeAll { $0.id == portfolio.id }

        if selectedPortfolio?.id == portfolio.id {
            selectedPortfolio = portfolios.first
        }

        if portfolios.isEmpty {
            appState = .empty
        }
    }

    // MARK: - Holding Management

    /// 保有資産を追加
    func addHolding(
        to portfolio: Portfolio,
        symbol: String,
        name: String,
        assetType: AssetType,
        quantity: Decimal,
        averageCost: Decimal,
        currency: String = "USD",
        sectorName: String? = nil
    ) async throws {
        // 現在の株価を取得
        var currentPrice: Decimal = 0
        do {
            let quote = try await stockAPIService.fetchQuote(symbol: symbol)
            currentPrice = quote.price
        } catch {
            // 株価取得に失敗しても保有資産は追加
        }

        _ = try dataService.addHolding(
            to: portfolio,
            symbol: symbol,
            name: name,
            assetType: assetType,
            quantity: quantity,
            averageCost: averageCost,
            currentPrice: currentPrice,
            currency: currency,
            sectorName: sectorName
        )
    }

    /// 保有資産を削除
    func deleteHolding(_ holding: Holding) async throws {
        try dataService.deleteHolding(holding)
    }

    // MARK: - Transaction Management

    /// 取引を追加
    func addTransaction(
        to holding: Holding,
        type: TransactionType,
        quantity: Decimal,
        pricePerShare: Decimal,
        fees: Decimal = 0,
        executedAt: Date = Date(),
        note: String? = nil
    ) async throws {
        _ = try dataService.addTransaction(
            to: holding,
            type: type,
            quantity: quantity,
            pricePerShare: pricePerShare,
            fees: fees,
            executedAt: executedAt,
            note: note
        )
    }

    // MARK: - Watchlist Management

    /// ウォッチリストに追加
    func addToWatchlist(
        symbol: String,
        name: String,
        assetType: AssetType = .stock,
        targetPrice: Decimal? = nil,
        note: String? = nil
    ) async throws {
        // 現在の株価を取得
        var currentPrice: Decimal = 0
        var previousClose: Decimal = 0

        do {
            let quote = try await stockAPIService.fetchQuote(symbol: symbol)
            currentPrice = quote.price
            previousClose = quote.previousClose
        } catch {
            // 株価取得に失敗してもウォッチリストには追加
        }

        let item = try dataService.addToWatchlist(
            symbol: symbol,
            name: name,
            assetType: assetType,
            currentPrice: currentPrice,
            previousClose: previousClose,
            targetPrice: targetPrice,
            note: note
        )

        watchlistItems.append(item)
    }

    /// ウォッチリストから削除
    func removeFromWatchlist(_ item: WatchlistItem) async throws {
        try dataService.removeFromWatchlist(item)
        watchlistItems.removeAll { $0.id == item.id }
    }

    // MARK: - Symbol Search

    /// 銘柄を検索
    func searchSymbols(keywords: String) async throws -> [SymbolSearchResult] {
        try await stockAPIService.searchSymbol(keywords: keywords)
    }

    // MARK: - Error Handling

    /// エラーをクリア
    func clearError() {
        errorMessage = nil
    }
}
