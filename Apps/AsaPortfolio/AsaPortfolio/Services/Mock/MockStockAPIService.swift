import Foundation

/// モック株価APIサービス - テスト・プレビュー用
@MainActor
final class MockStockAPIService: StockAPIServiceProtocol {
    var remainingRequests: Int = 500

    /// シミュレートされた遅延（秒）
    var simulatedDelay: TimeInterval = 0.5

    /// エラーをシミュレートするかどうか
    var shouldSimulateError: Bool = false

    /// モックデータ
    private let mockQuotes: [String: StockQuote] = [
        "AAPL": StockQuote(
            symbol: "AAPL",
            open: 178.50,
            high: 182.30,
            low: 177.80,
            price: 181.25,
            volume: 52_436_780,
            latestTradingDay: Date(),
            previousClose: 178.90,
            change: 2.35,
            changePercent: 1.31
        ),
        "GOOGL": StockQuote(
            symbol: "GOOGL",
            open: 141.20,
            high: 143.80,
            low: 140.50,
            price: 142.65,
            volume: 28_945_230,
            latestTradingDay: Date(),
            previousClose: 141.80,
            change: 0.85,
            changePercent: 0.60
        ),
        "MSFT": StockQuote(
            symbol: "MSFT",
            open: 412.50,
            high: 418.20,
            low: 410.30,
            price: 416.80,
            volume: 18_234_560,
            latestTradingDay: Date(),
            previousClose: 413.20,
            change: 3.60,
            changePercent: 0.87
        ),
        "AMZN": StockQuote(
            symbol: "AMZN",
            open: 185.30,
            high: 188.50,
            low: 184.20,
            price: 187.45,
            volume: 35_678_900,
            latestTradingDay: Date(),
            previousClose: 186.10,
            change: 1.35,
            changePercent: 0.73
        ),
        "TSLA": StockQuote(
            symbol: "TSLA",
            open: 245.80,
            high: 252.30,
            low: 243.50,
            price: 248.90,
            volume: 89_234_560,
            latestTradingDay: Date(),
            previousClose: 250.20,
            change: -1.30,
            changePercent: -0.52
        ),
        "NVDA": StockQuote(
            symbol: "NVDA",
            open: 875.20,
            high: 892.50,
            low: 870.30,
            price: 888.75,
            volume: 45_678_900,
            latestTradingDay: Date(),
            previousClose: 872.40,
            change: 16.35,
            changePercent: 1.87
        ),
        "META": StockQuote(
            symbol: "META",
            open: 502.30,
            high: 512.80,
            low: 500.50,
            price: 508.45,
            volume: 12_345_670,
            latestTradingDay: Date(),
            previousClose: 504.20,
            change: 4.25,
            changePercent: 0.84
        ),
        "VOO": StockQuote(
            symbol: "VOO",
            open: 478.50,
            high: 482.30,
            low: 477.20,
            price: 480.85,
            volume: 3_456_780,
            latestTradingDay: Date(),
            previousClose: 479.10,
            change: 1.75,
            changePercent: 0.37
        ),
        "VTI": StockQuote(
            symbol: "VTI",
            open: 265.30,
            high: 268.50,
            low: 264.80,
            price: 267.25,
            volume: 2_345_670,
            latestTradingDay: Date(),
            previousClose: 266.40,
            change: 0.85,
            changePercent: 0.32
        ),
        "QQQ": StockQuote(
            symbol: "QQQ",
            open: 485.20,
            high: 492.80,
            low: 483.50,
            price: 490.35,
            volume: 28_456_780,
            latestTradingDay: Date(),
            previousClose: 486.90,
            change: 3.45,
            changePercent: 0.71
        )
    ]

    func fetchQuote(symbol: String) async throws -> StockQuote {
        try await simulateNetworkDelay()

        if shouldSimulateError {
            throw StockAPIError.networkError(URLError(.notConnectedToInternet))
        }

        guard let quote = mockQuotes[symbol.uppercased()] else {
            throw StockAPIError.symbolNotFound(symbol)
        }

        remainingRequests -= 1
        return quote
    }

    func fetchBulkQuotes(symbols: [String]) async throws -> [StockQuote] {
        try await simulateNetworkDelay()

        if shouldSimulateError {
            throw StockAPIError.networkError(URLError(.notConnectedToInternet))
        }

        var quotes: [StockQuote] = []
        for symbol in symbols {
            if let quote = mockQuotes[symbol.uppercased()] {
                quotes.append(quote)
            }
        }

        remainingRequests -= symbols.count
        return quotes
    }

    func fetchDailyTimeSeries(symbol: String) async throws -> [TimeSeriesData] {
        try await simulateNetworkDelay()

        if shouldSimulateError {
            throw StockAPIError.networkError(URLError(.notConnectedToInternet))
        }

        // モック時系列データを生成（過去30日分）
        var series: [TimeSeriesData] = []
        let calendar = Calendar.current
        var basePrice: Decimal = 180.0

        if let quote = mockQuotes[symbol.uppercased()] {
            basePrice = quote.price
        }

        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }

            // ランダムな変動を追加
            let variation = Decimal(Double.random(in: -5...5))
            let dayPrice = basePrice + variation

            series.append(TimeSeriesData(
                date: date,
                open: dayPrice - Decimal(Double.random(in: 0...2)),
                high: dayPrice + Decimal(Double.random(in: 0...3)),
                low: dayPrice - Decimal(Double.random(in: 0...3)),
                close: dayPrice,
                volume: Int.random(in: 10_000_000...100_000_000)
            ))
        }

        remainingRequests -= 1
        return series.sorted { $0.date > $1.date }
    }

    func fetchCompanyOverview(symbol: String) async throws -> CompanyOverview {
        try await simulateNetworkDelay()

        if shouldSimulateError {
            throw StockAPIError.networkError(URLError(.notConnectedToInternet))
        }

        // モック企業概要データ
        let overviews: [String: (name: String, sector: String, industry: String)] = [
            "AAPL": ("Apple Inc.", "Technology", "Consumer Electronics"),
            "GOOGL": ("Alphabet Inc.", "Technology", "Internet Content & Information"),
            "MSFT": ("Microsoft Corporation", "Technology", "Software - Infrastructure"),
            "AMZN": ("Amazon.com, Inc.", "Consumer Cyclical", "Internet Retail"),
            "TSLA": ("Tesla, Inc.", "Consumer Cyclical", "Auto Manufacturers"),
            "NVDA": ("NVIDIA Corporation", "Technology", "Semiconductors"),
            "META": ("Meta Platforms, Inc.", "Technology", "Internet Content & Information"),
            "VOO": ("Vanguard S&P 500 ETF", "ETF", "Large Blend"),
            "VTI": ("Vanguard Total Stock Market ETF", "ETF", "Large Blend"),
            "QQQ": ("Invesco QQQ Trust", "ETF", "Large Growth")
        ]

        guard let info = overviews[symbol.uppercased()] else {
            throw StockAPIError.symbolNotFound(symbol)
        }

        let decoder = JSONDecoder()
        let json = """
        {
            "Symbol": "\(symbol.uppercased())",
            "Name": "\(info.name)",
            "Description": "Mock company description for \(info.name)",
            "Exchange": "NASDAQ",
            "Currency": "USD",
            "Country": "USA",
            "Sector": "\(info.sector)",
            "Industry": "\(info.industry)",
            "MarketCapitalization": "2500000000000"
        }
        """

        remainingRequests -= 1

        do {
            return try decoder.decode(CompanyOverview.self, from: json.data(using: .utf8)!)
        } catch {
            throw StockAPIError.decodingError(error)
        }
    }

    func searchSymbol(keywords: String) async throws -> [SymbolSearchResult] {
        try await simulateNetworkDelay()

        if shouldSimulateError {
            throw StockAPIError.networkError(URLError(.notConnectedToInternet))
        }

        // モック検索結果
        let allSymbols: [(symbol: String, name: String)] = [
            ("AAPL", "Apple Inc."),
            ("GOOGL", "Alphabet Inc."),
            ("MSFT", "Microsoft Corporation"),
            ("AMZN", "Amazon.com, Inc."),
            ("TSLA", "Tesla, Inc."),
            ("NVDA", "NVIDIA Corporation"),
            ("META", "Meta Platforms, Inc."),
            ("VOO", "Vanguard S&P 500 ETF"),
            ("VTI", "Vanguard Total Stock Market ETF"),
            ("QQQ", "Invesco QQQ Trust")
        ]

        let lowercasedKeywords = keywords.lowercased()
        let filtered = allSymbols.filter {
            $0.symbol.lowercased().contains(lowercasedKeywords) ||
            $0.name.lowercased().contains(lowercasedKeywords)
        }

        remainingRequests -= 1

        return filtered.map { item in
            SymbolSearchResult(
                symbol: item.symbol,
                name: item.name,
                type: "Equity",
                region: "United States",
                matchScore: 1.0
            )
        }
    }

    func clearCache() {
        // モックでは何もしない
    }

    // MARK: - Private

    private func simulateNetworkDelay() async throws {
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
    }
}
