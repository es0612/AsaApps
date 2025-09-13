//
//  StockQuote.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import Foundation

// MARK: - Alpha Vantage API Response Models

// Global Quote Response
struct GlobalQuoteResponse: Codable {
    let globalQuote: GlobalQuote
    
    enum CodingKeys: String, CodingKey {
        case globalQuote = "Global Quote"
    }
}

struct GlobalQuote: Codable {
    let symbol: String
    let open: String
    let high: String
    let low: String
    let price: String
    let volume: String
    let latestTradingDay: String
    let previousClose: String
    let change: String
    let changePercent: String
    
    enum CodingKeys: String, CodingKey {
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
    
    // Convert to Stock model
    func toStock(name: String) -> Stock {
        let currentPrice = Double(price) ?? 0.0
        let prevClose = Double(previousClose) ?? 0.0
        let changeValue = Double(change) ?? 0.0
        let changePercentValue = Double(changePercent.replacingOccurrences(of: "%", with: "")) ?? 0.0
        let volumeValue = Int(volume) ?? 0
        
        return Stock(
            symbol: symbol,
            name: name,
            currentPrice: currentPrice,
            previousClose: prevClose,
            change: changeValue,
            changePercent: changePercentValue,
            volume: volumeValue,
            lastUpdated: Date()
        )
    }
}

// Time Series Response for Charts
struct TimeSeriesResponse: Codable {
    let metaData: MetaData
    let timeSeries: [String: TimeSeriesData]
    
    enum CodingKeys: String, CodingKey {
        case metaData = "Meta Data"
        case timeSeries = "Time Series (5min)"
    }
}

struct MetaData: Codable {
    let information: String
    let symbol: String
    let lastRefreshed: String
    let interval: String
    let outputSize: String
    let timeZone: String
    
    enum CodingKeys: String, CodingKey {
        case information = "1. Information"
        case symbol = "2. Symbol"
        case lastRefreshed = "3. Last Refreshed"
        case interval = "4. Interval"
        case outputSize = "5. Output Size"
        case timeZone = "6. Time Zone"
    }
}

struct TimeSeriesData: Codable {
    let open: String
    let high: String
    let low: String
    let close: String
    let volume: String
    
    enum CodingKeys: String, CodingKey {
        case open = "1. open"
        case high = "2. high"
        case low = "3. low"
        case close = "4. close"
        case volume = "5. volume"
    }
}

// Symbol Search Response
struct SymbolSearchResponse: Codable {
    let bestMatches: [SearchResult]
    
    enum CodingKeys: String, CodingKey {
        case bestMatches = "bestMatches"
    }
}

struct SearchResult: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let type: String
    let region: String
    let marketOpen: String
    let marketClose: String
    let timezone: String
    let currency: String
    let matchScore: String
    
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
}

// Chart Data Model
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
    let volume: Int
}

// API Error Response
struct APIError: Codable {
    let note: String?
    let information: String?
    
    enum CodingKeys: String, CodingKey {
        case note = "Note"
        case information = "Information"
    }
}