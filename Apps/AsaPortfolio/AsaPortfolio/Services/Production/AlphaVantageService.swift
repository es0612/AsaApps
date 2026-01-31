import Foundation

/// Alpha Vantage API サービス
/// 無料プラン: 1分5リクエスト、1日500リクエスト
@MainActor
final class AlphaVantageService: StockAPIServiceProtocol {
    // MARK: - Properties

    private let baseURL = "https://www.alphavantage.co/query"
    private var apiKey: String
    private let session: URLSession

    /// キャッシュ（15分間有効）
    private var quoteCache: [String: CacheEntry<StockQuote>] = [:]
    private var timeSeriesCache: [String: CacheEntry<[TimeSeriesData]>] = [:]
    private var overviewCache: [String: CacheEntry<CompanyOverview>] = [:]

    /// APIリクエストカウンター（概算）
    private(set) var remainingRequests: Int = 500

    /// 最後のリクエスト時刻（レート制限用）
    private var lastRequestTime: Date?

    // MARK: - Initializer

    init(apiKey: String = "") {
        self.apiKey = apiKey.isEmpty ? Self.loadAPIKeyFromUserDefaults() : apiKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    func fetchQuote(symbol: String) async throws -> StockQuote {
        let upperSymbol = symbol.uppercased()

        // キャッシュチェック
        if let cached = quoteCache[upperSymbol], !cached.isExpired {
            return cached.value
        }

        try await respectRateLimit()

        let url = try buildURL(function: "GLOBAL_QUOTE", symbol: upperSymbol)
        let quote = try await fetchAndDecode(StockQuote.self, from: url)

        quoteCache[upperSymbol] = CacheEntry(value: quote, timestamp: Date())
        remainingRequests -= 1

        return quote
    }

    func fetchBulkQuotes(symbols: [String]) async throws -> [StockQuote] {
        var quotes: [StockQuote] = []
        var symbolsToFetch: [String] = []

        // キャッシュされているものとそうでないものを分離
        for symbol in symbols {
            let upperSymbol = symbol.uppercased()
            if let cached = quoteCache[upperSymbol], !cached.isExpired {
                quotes.append(cached.value)
            } else {
                symbolsToFetch.append(upperSymbol)
            }
        }

        // キャッシュにないものを取得（レート制限を考慮してシーケンシャルに）
        for symbol in symbolsToFetch {
            do {
                let quote = try await fetchQuote(symbol: symbol)
                quotes.append(quote)
            } catch StockAPIError.symbolNotFound {
                // 銘柄が見つからない場合はスキップ
                continue
            }
        }

        return quotes
    }

    func fetchDailyTimeSeries(symbol: String) async throws -> [TimeSeriesData] {
        let upperSymbol = symbol.uppercased()

        // キャッシュチェック
        if let cached = timeSeriesCache[upperSymbol], !cached.isExpired {
            return cached.value
        }

        try await respectRateLimit()

        let url = try buildURL(
            function: "TIME_SERIES_DAILY",
            symbol: upperSymbol,
            additionalParams: ["outputsize": "compact"]
        )

        let response = try await fetchAndDecode(TimeSeriesResponse.self, from: url)
        timeSeriesCache[upperSymbol] = CacheEntry(value: response.timeSeries, timestamp: Date())
        remainingRequests -= 1

        return response.timeSeries
    }

    func fetchCompanyOverview(symbol: String) async throws -> CompanyOverview {
        let upperSymbol = symbol.uppercased()

        // キャッシュチェック
        if let cached = overviewCache[upperSymbol], !cached.isExpired {
            return cached.value
        }

        try await respectRateLimit()

        let url = try buildURL(function: "OVERVIEW", symbol: upperSymbol)
        let overview = try await fetchAndDecode(CompanyOverview.self, from: url)

        overviewCache[upperSymbol] = CacheEntry(value: overview, timestamp: Date())
        remainingRequests -= 1

        return overview
    }

    func searchSymbol(keywords: String) async throws -> [SymbolSearchResult] {
        try await respectRateLimit()

        let url = try buildURL(
            function: "SYMBOL_SEARCH",
            additionalParams: ["keywords": keywords]
        )

        let response = try await fetchAndDecode(SymbolSearchResponse.self, from: url)
        remainingRequests -= 1

        return response.bestMatches
    }

    func clearCache() {
        quoteCache.removeAll()
        timeSeriesCache.removeAll()
        overviewCache.removeAll()
    }

    // MARK: - API Key Management

    func updateAPIKey(_ newKey: String) {
        apiKey = newKey
        UserDefaults.standard.set(newKey, forKey: "AlphaVantageAPIKey")
        clearCache()
    }

    static func loadAPIKeyFromUserDefaults() -> String {
        UserDefaults.standard.string(forKey: "AlphaVantageAPIKey") ?? ""
    }

    var hasValidAPIKey: Bool {
        !apiKey.isEmpty
    }

    // MARK: - Private Methods

    private func buildURL(
        function: String,
        symbol: String? = nil,
        additionalParams: [String: String] = [:]
    ) throws -> URL {
        guard !apiKey.isEmpty else {
            throw StockAPIError.invalidAPIKey
        }

        var components = URLComponents(string: baseURL)
        var queryItems = [
            URLQueryItem(name: "function", value: function),
            URLQueryItem(name: "apikey", value: apiKey)
        ]

        if let symbol = symbol {
            queryItems.append(URLQueryItem(name: "symbol", value: symbol))
        }

        for (key, value) in additionalParams {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw StockAPIError.invalidURL
        }

        return url
    }

    private func fetchAndDecode<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StockAPIError.unknown
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw StockAPIError.invalidAPIKey
        case 429:
            throw StockAPIError.rateLimitExceeded
        case 500...599:
            throw StockAPIError.serverError(httpResponse.statusCode)
        default:
            throw StockAPIError.serverError(httpResponse.statusCode)
        }

        // Alpha Vantageのエラーレスポンスをチェック
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let note = json["Note"] as? String, note.contains("API call frequency") {
                throw StockAPIError.rateLimitExceeded
            }
            if let error = json["Error Message"] as? String {
                if error.contains("Invalid API call") {
                    throw StockAPIError.symbolNotFound("")
                }
                throw StockAPIError.unknown
            }
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw StockAPIError.decodingError(error)
        }
    }

    private func respectRateLimit() async throws {
        // 1分5リクエスト制限を考慮（12秒間隔）
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < 12 {
                try await Task.sleep(nanoseconds: UInt64((12 - elapsed) * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
}
