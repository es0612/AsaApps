import Foundation

/// 時系列データモデル - Alpha Vantage TIME_SERIES_DAILY応答
struct TimeSeriesData: Codable, Sendable, Identifiable {
    let date: Date
    let open: Decimal
    let high: Decimal
    let low: Decimal
    let close: Decimal
    let volume: Int

    var id: Date { date }

    // MARK: - Convenience Initializer

    init(
        date: Date,
        open: Decimal,
        high: Decimal,
        low: Decimal,
        close: Decimal,
        volume: Int
    ) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

/// 時系列データ応答のラッパー
struct TimeSeriesResponse: Codable, Sendable {
    let metaData: MetaData
    let timeSeries: [TimeSeriesData]

    struct MetaData: Codable, Sendable {
        let symbol: String
        let lastRefreshed: Date
        let outputSize: String
        let timeZone: String
    }

    // MARK: - Alpha Vantage API Decoding

    enum CodingKeys: String, CodingKey {
        case metaData = "Meta Data"
        case timeSeries = "Time Series (Daily)"
    }

    enum MetaDataKeys: String, CodingKey {
        case symbol = "2. Symbol"
        case lastRefreshed = "3. Last Refreshed"
        case outputSize = "4. Output Size"
        case timeZone = "5. Time Zone"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // メタデータのデコード
        let metaDataContainer = try container.nestedContainer(keyedBy: MetaDataKeys.self, forKey: .metaData)
        let symbol = try metaDataContainer.decode(String.self, forKey: .symbol)
        let lastRefreshedString = try metaDataContainer.decode(String.self, forKey: .lastRefreshed)
        let outputSize = try metaDataContainer.decodeIfPresent(String.self, forKey: .outputSize) ?? "Compact"
        let timeZone = try metaDataContainer.decode(String.self, forKey: .timeZone)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let lastRefreshed = dateFormatter.date(from: lastRefreshedString) ?? Date()

        metaData = MetaData(
            symbol: symbol,
            lastRefreshed: lastRefreshed,
            outputSize: outputSize,
            timeZone: timeZone
        )

        // 時系列データのデコード
        let timeSeriesContainer = try container.decode([String: [String: String]].self, forKey: .timeSeries)
        var series: [TimeSeriesData] = []

        for (dateString, values) in timeSeriesContainer {
            guard let date = dateFormatter.date(from: dateString) else { continue }

            let open = Decimal(string: values["1. open"] ?? "0") ?? 0
            let high = Decimal(string: values["2. high"] ?? "0") ?? 0
            let low = Decimal(string: values["3. low"] ?? "0") ?? 0
            let close = Decimal(string: values["4. close"] ?? "0") ?? 0
            let volume = Int(values["5. volume"] ?? "0") ?? 0

            series.append(TimeSeriesData(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }

        // 日付順にソート（新しい順）
        timeSeries = series.sorted { $0.date > $1.date }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // 簡略化したエンコード
        var metaDataContainer = container.nestedContainer(keyedBy: MetaDataKeys.self, forKey: .metaData)
        try metaDataContainer.encode(metaData.symbol, forKey: .symbol)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        try metaDataContainer.encode(dateFormatter.string(from: metaData.lastRefreshed), forKey: .lastRefreshed)
        try metaDataContainer.encode(metaData.outputSize, forKey: .outputSize)
        try metaDataContainer.encode(metaData.timeZone, forKey: .timeZone)
    }

    // MARK: - Convenience Initializer

    init(metaData: MetaData, timeSeries: [TimeSeriesData]) {
        self.metaData = metaData
        self.timeSeries = timeSeries
    }
}

/// 銘柄検索結果
struct SymbolSearchResult: Codable, Sendable, Identifiable {
    let symbol: String
    let name: String
    let type: String
    let region: String
    let marketOpen: String
    let marketClose: String
    let timezone: String
    let currency: String
    let matchScore: Double

    var id: String { symbol }

    // MARK: - Alpha Vantage API Decoding

    enum CodingKeys: String, CodingKey {
        case symbol = "1. symbol"
        case name = "2. name"
        case type = "3. type"
        case region = "4. region"
        case marketOpen = "5. marketOpen"
        case marketClose = "6. marketClose"
        case timezone = "7. timezone"
        case currency = "8. currency"
        case matchScore = "9. matchScore"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        region = try container.decode(String.self, forKey: .region)
        marketOpen = try container.decode(String.self, forKey: .marketOpen)
        marketClose = try container.decode(String.self, forKey: .marketClose)
        timezone = try container.decode(String.self, forKey: .timezone)
        currency = try container.decode(String.self, forKey: .currency)
        let matchScoreString = try container.decode(String.self, forKey: .matchScore)
        matchScore = Double(matchScoreString) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(region, forKey: .region)
        try container.encode(marketOpen, forKey: .marketOpen)
        try container.encode(marketClose, forKey: .marketClose)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(currency, forKey: .currency)
        try container.encode("\(matchScore)", forKey: .matchScore)
    }

    // MARK: - Convenience Initializer

    init(
        symbol: String,
        name: String,
        type: String = "Equity",
        region: String = "United States",
        marketOpen: String = "09:30",
        marketClose: String = "16:00",
        timezone: String = "UTC-04",
        currency: String = "USD",
        matchScore: Double = 1.0
    ) {
        self.symbol = symbol
        self.name = name
        self.type = type
        self.region = region
        self.marketOpen = marketOpen
        self.marketClose = marketClose
        self.timezone = timezone
        self.currency = currency
        self.matchScore = matchScore
    }
}

/// 銘柄検索応答
struct SymbolSearchResponse: Codable, Sendable {
    let bestMatches: [SymbolSearchResult]

    enum CodingKeys: String, CodingKey {
        case bestMatches = "bestMatches"
    }
}
