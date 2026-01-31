import Foundation

/// 株価クォートモデル - Alpha Vantage GLOBAL_QUOTE応答
struct StockQuote: Codable, Sendable, Identifiable {
    let symbol: String
    let open: Decimal
    let high: Decimal
    let low: Decimal
    let price: Decimal
    let volume: Int
    let latestTradingDay: Date
    let previousClose: Decimal
    let change: Decimal
    let changePercent: Double

    var id: String { symbol }

    // MARK: - Computed Properties

    /// 価格が上昇しているかどうか
    var isUp: Bool {
        change > 0
    }

    /// 変動率のフォーマット済み文字列
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, changePercent)
    }

    // MARK: - Alpha Vantage API Decoding

    enum CodingKeys: String, CodingKey {
        case globalQuote = "Global Quote"
    }

    enum QuoteKeys: String, CodingKey {
        case symbol = "01. symbol"
        case open = "02. open"
        case high = "03. high"
        case low = "04. low"
        case price = "05. price"
        case volume = "06. volume"
        case latestTradingDay = "07. latest trading day"
        case previousClose = "08. previous close"
        case change = "09. change"
        case changePercent = "10. change percent"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let quoteContainer = try container.nestedContainer(keyedBy: QuoteKeys.self, forKey: .globalQuote)

        symbol = try quoteContainer.decode(String.self, forKey: .symbol)

        let openString = try quoteContainer.decode(String.self, forKey: .open)
        open = Decimal(string: openString) ?? 0

        let highString = try quoteContainer.decode(String.self, forKey: .high)
        high = Decimal(string: highString) ?? 0

        let lowString = try quoteContainer.decode(String.self, forKey: .low)
        low = Decimal(string: lowString) ?? 0

        let priceString = try quoteContainer.decode(String.self, forKey: .price)
        price = Decimal(string: priceString) ?? 0

        let volumeString = try quoteContainer.decode(String.self, forKey: .volume)
        volume = Int(volumeString) ?? 0

        let dateString = try quoteContainer.decode(String.self, forKey: .latestTradingDay)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        latestTradingDay = dateFormatter.date(from: dateString) ?? Date()

        let previousCloseString = try quoteContainer.decode(String.self, forKey: .previousClose)
        previousClose = Decimal(string: previousCloseString) ?? 0

        let changeString = try quoteContainer.decode(String.self, forKey: .change)
        change = Decimal(string: changeString) ?? 0

        let changePercentString = try quoteContainer.decode(String.self, forKey: .changePercent)
        let cleanedPercent = changePercentString.replacingOccurrences(of: "%", with: "")
        changePercent = Double(cleanedPercent) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var quoteContainer = container.nestedContainer(keyedBy: QuoteKeys.self, forKey: .globalQuote)

        try quoteContainer.encode(symbol, forKey: .symbol)
        try quoteContainer.encode("\(open)", forKey: .open)
        try quoteContainer.encode("\(high)", forKey: .high)
        try quoteContainer.encode("\(low)", forKey: .low)
        try quoteContainer.encode("\(price)", forKey: .price)
        try quoteContainer.encode("\(volume)", forKey: .volume)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        try quoteContainer.encode(dateFormatter.string(from: latestTradingDay), forKey: .latestTradingDay)

        try quoteContainer.encode("\(previousClose)", forKey: .previousClose)
        try quoteContainer.encode("\(change)", forKey: .change)
        try quoteContainer.encode("\(changePercent)%", forKey: .changePercent)
    }

    // MARK: - Convenience Initializer

    init(
        symbol: String,
        open: Decimal,
        high: Decimal,
        low: Decimal,
        price: Decimal,
        volume: Int,
        latestTradingDay: Date,
        previousClose: Decimal,
        change: Decimal,
        changePercent: Double
    ) {
        self.symbol = symbol
        self.open = open
        self.high = high
        self.low = low
        self.price = price
        self.volume = volume
        self.latestTradingDay = latestTradingDay
        self.previousClose = previousClose
        self.change = change
        self.changePercent = changePercent
    }
}
