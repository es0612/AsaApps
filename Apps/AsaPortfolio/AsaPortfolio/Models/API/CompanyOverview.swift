import Foundation

/// 企業概要モデル - Alpha Vantage OVERVIEW応答
struct CompanyOverview: Codable, Sendable, Identifiable {
    let symbol: String
    let name: String
    let description: String
    let exchange: String
    let currency: String
    let country: String
    let sector: String
    let industry: String
    let marketCapitalization: Int64
    let peRatio: Double?
    let pegRatio: Double?
    let bookValue: Decimal?
    let dividendPerShare: Decimal?
    let dividendYield: Double?
    let eps: Decimal?
    let revenuePerShareTTM: Decimal?
    let profitMargin: Double?
    let operatingMarginTTM: Double?
    let returnOnAssetsTTM: Double?
    let returnOnEquityTTM: Double?
    let revenueTTM: Int64?
    let grossProfitTTM: Int64?
    let quarterlyEarningsGrowthYOY: Double?
    let quarterlyRevenueGrowthYOY: Double?
    let analystTargetPrice: Decimal?
    let week52High: Decimal?
    let week52Low: Decimal?
    let movingAverage50Day: Decimal?
    let movingAverage200Day: Decimal?

    var id: String { symbol }

    // MARK: - Computed Properties

    /// 時価総額のフォーマット済み文字列
    var formattedMarketCap: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0

        if marketCapitalization >= 1_000_000_000_000 {
            let value = Double(marketCapitalization) / 1_000_000_000_000
            return String(format: "%.2fT", value)
        } else if marketCapitalization >= 1_000_000_000 {
            let value = Double(marketCapitalization) / 1_000_000_000
            return String(format: "%.2fB", value)
        } else if marketCapitalization >= 1_000_000 {
            let value = Double(marketCapitalization) / 1_000_000
            return String(format: "%.2fM", value)
        } else {
            return formatter.string(from: NSNumber(value: marketCapitalization)) ?? ""
        }
    }

    // MARK: - Alpha Vantage API Decoding

    enum CodingKeys: String, CodingKey {
        case symbol = "Symbol"
        case name = "Name"
        case description = "Description"
        case exchange = "Exchange"
        case currency = "Currency"
        case country = "Country"
        case sector = "Sector"
        case industry = "Industry"
        case marketCapitalization = "MarketCapitalization"
        case peRatio = "PERatio"
        case pegRatio = "PEGRatio"
        case bookValue = "BookValue"
        case dividendPerShare = "DividendPerShare"
        case dividendYield = "DividendYield"
        case eps = "EPS"
        case revenuePerShareTTM = "RevenuePerShareTTM"
        case profitMargin = "ProfitMargin"
        case operatingMarginTTM = "OperatingMarginTTM"
        case returnOnAssetsTTM = "ReturnOnAssetsTTM"
        case returnOnEquityTTM = "ReturnOnEquityTTM"
        case revenueTTM = "RevenueTTM"
        case grossProfitTTM = "GrossProfitTTM"
        case quarterlyEarningsGrowthYOY = "QuarterlyEarningsGrowthYOY"
        case quarterlyRevenueGrowthYOY = "QuarterlyRevenueGrowthYOY"
        case analystTargetPrice = "AnalystTargetPrice"
        case week52High = "52WeekHigh"
        case week52Low = "52WeekLow"
        case movingAverage50Day = "50DayMovingAverage"
        case movingAverage200Day = "200DayMovingAverage"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        exchange = try container.decode(String.self, forKey: .exchange)
        currency = try container.decode(String.self, forKey: .currency)
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
        sector = try container.decodeIfPresent(String.self, forKey: .sector) ?? ""
        industry = try container.decodeIfPresent(String.self, forKey: .industry) ?? ""

        let marketCapString = try container.decodeIfPresent(String.self, forKey: .marketCapitalization) ?? "0"
        marketCapitalization = Int64(marketCapString) ?? 0

        let peString = try container.decodeIfPresent(String.self, forKey: .peRatio)
        peRatio = peString.flatMap { Double($0) }

        let pegString = try container.decodeIfPresent(String.self, forKey: .pegRatio)
        pegRatio = pegString.flatMap { Double($0) }

        let bookValueString = try container.decodeIfPresent(String.self, forKey: .bookValue)
        bookValue = bookValueString.flatMap { Decimal(string: $0) }

        let dividendPerShareString = try container.decodeIfPresent(String.self, forKey: .dividendPerShare)
        dividendPerShare = dividendPerShareString.flatMap { Decimal(string: $0) }

        let dividendYieldString = try container.decodeIfPresent(String.self, forKey: .dividendYield)
        dividendYield = dividendYieldString.flatMap { Double($0) }

        let epsString = try container.decodeIfPresent(String.self, forKey: .eps)
        eps = epsString.flatMap { Decimal(string: $0) }

        let revenuePerShareString = try container.decodeIfPresent(String.self, forKey: .revenuePerShareTTM)
        revenuePerShareTTM = revenuePerShareString.flatMap { Decimal(string: $0) }

        let profitMarginString = try container.decodeIfPresent(String.self, forKey: .profitMargin)
        profitMargin = profitMarginString.flatMap { Double($0) }

        let operatingMarginString = try container.decodeIfPresent(String.self, forKey: .operatingMarginTTM)
        operatingMarginTTM = operatingMarginString.flatMap { Double($0) }

        let roaString = try container.decodeIfPresent(String.self, forKey: .returnOnAssetsTTM)
        returnOnAssetsTTM = roaString.flatMap { Double($0) }

        let roeString = try container.decodeIfPresent(String.self, forKey: .returnOnEquityTTM)
        returnOnEquityTTM = roeString.flatMap { Double($0) }

        let revenueString = try container.decodeIfPresent(String.self, forKey: .revenueTTM)
        revenueTTM = revenueString.flatMap { Int64($0) }

        let grossProfitString = try container.decodeIfPresent(String.self, forKey: .grossProfitTTM)
        grossProfitTTM = grossProfitString.flatMap { Int64($0) }

        let earningsGrowthString = try container.decodeIfPresent(String.self, forKey: .quarterlyEarningsGrowthYOY)
        quarterlyEarningsGrowthYOY = earningsGrowthString.flatMap { Double($0) }

        let revenueGrowthString = try container.decodeIfPresent(String.self, forKey: .quarterlyRevenueGrowthYOY)
        quarterlyRevenueGrowthYOY = revenueGrowthString.flatMap { Double($0) }

        let targetPriceString = try container.decodeIfPresent(String.self, forKey: .analystTargetPrice)
        analystTargetPrice = targetPriceString.flatMap { Decimal(string: $0) }

        let week52HighString = try container.decodeIfPresent(String.self, forKey: .week52High)
        week52High = week52HighString.flatMap { Decimal(string: $0) }

        let week52LowString = try container.decodeIfPresent(String.self, forKey: .week52Low)
        week52Low = week52LowString.flatMap { Decimal(string: $0) }

        let ma50String = try container.decodeIfPresent(String.self, forKey: .movingAverage50Day)
        movingAverage50Day = ma50String.flatMap { Decimal(string: $0) }

        let ma200String = try container.decodeIfPresent(String.self, forKey: .movingAverage200Day)
        movingAverage200Day = ma200String.flatMap { Decimal(string: $0) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(exchange, forKey: .exchange)
        try container.encode(currency, forKey: .currency)
        try container.encode(country, forKey: .country)
        try container.encode(sector, forKey: .sector)
        try container.encode(industry, forKey: .industry)
        try container.encode("\(marketCapitalization)", forKey: .marketCapitalization)
    }
}
