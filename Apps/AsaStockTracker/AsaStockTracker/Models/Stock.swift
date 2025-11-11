//
//  Stock.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import Foundation
import SwiftUI

// MARK: - Stock Model
struct Stock: Identifiable, Codable, Hashable {
    let id: UUID
    let symbol: String
    let name: String
    var currentPrice: Double
    var previousClose: Double
    var change: Double
    var changePercent: Double
    var volume: Int
    var marketCap: Double?
    var high52Week: Double?
    var low52Week: Double?
    var currency: String?
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        currentPrice: Double = 0.0,
        previousClose: Double = 0.0,
        change: Double = 0.0,
        changePercent: Double = 0.0,
        volume: Int = 0,
        marketCap: Double? = nil,
        high52Week: Double? = nil,
        low52Week: Double? = nil,
        currency: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.previousClose = previousClose
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.marketCap = marketCap
        self.high52Week = high52Week
        self.low52Week = low52Week
        self.currency = currency
        self.lastUpdated = lastUpdated
    }
    
    // MARK: - Computed Properties
    var isPositive: Bool {
        change >= 0
    }
    
    var changeColor: Color {
        isPositive ? .green : .red
    }
    
    var formattedPrice: String {
        String(format: "$%.2f", currentPrice)
    }
    
    var formattedChange: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", abs(change)))"
    }
    
    var formattedChangePercent: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.2f", abs(changePercent)))%"
    }
    
    var formattedVolume: String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", Double(volume) / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", Double(volume) / 1_000)
        }
        return "\(volume)"
    }
    
    var formattedMarketCap: String? {
        guard let marketCap = marketCap else { return nil }
        if marketCap >= 1_000_000_000_000 {
            return String(format: "$%.2fT", marketCap / 1_000_000_000_000)
        } else if marketCap >= 1_000_000_000 {
            return String(format: "$%.2fB", marketCap / 1_000_000_000)
        } else if marketCap >= 1_000_000 {
            return String(format: "$%.2fM", marketCap / 1_000_000)
        }
        return String(format: "$%.0f", marketCap)
    }

    var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: lastUpdated)
    }

    var dataSourceLabel: String {
        "Yahoo Finance • \(formattedLastUpdated)更新"
    }
}

// MARK: - Sample Data
extension Stock {
    static var sampleData: [Stock] {
        [
            Stock(
                symbol: "AAPL",
                name: "Apple Inc.",
                currentPrice: 175.43,
                previousClose: 173.50,
                change: 1.93,
                changePercent: 1.11,
                volume: 52_345_678,
                marketCap: 2_720_000_000_000,
                high52Week: 198.23,
                low52Week: 124.17
            ),
            Stock(
                symbol: "GOOGL",
                name: "Alphabet Inc.",
                currentPrice: 139.76,
                previousClose: 141.23,
                change: -1.47,
                changePercent: -1.04,
                volume: 21_456_789,
                marketCap: 1_750_000_000_000,
                high52Week: 155.00,
                low52Week: 101.88
            ),
            Stock(
                symbol: "MSFT",
                name: "Microsoft Corporation",
                currentPrice: 378.91,
                previousClose: 375.28,
                change: 3.63,
                changePercent: 0.97,
                volume: 19_876_543,
                marketCap: 2_810_000_000_000,
                high52Week: 384.52,
                low52Week: 245.61
            ),
            Stock(
                symbol: "AMZN",
                name: "Amazon.com Inc.",
                currentPrice: 153.38,
                previousClose: 152.11,
                change: 1.27,
                changePercent: 0.83,
                volume: 38_234_567,
                marketCap: 1_590_000_000_000,
                high52Week: 188.65,
                low52Week: 88.12
            ),
            Stock(
                symbol: "TSLA",
                name: "Tesla Inc.",
                currentPrice: 242.84,
                previousClose: 248.23,
                change: -5.39,
                changePercent: -2.17,
                volume: 102_345_678,
                marketCap: 771_000_000_000,
                high52Week: 299.29,
                low52Week: 152.37
            )
        ]
    }
}