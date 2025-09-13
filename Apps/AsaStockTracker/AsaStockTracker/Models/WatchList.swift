//
//  WatchList.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import Foundation

// MARK: - WatchList Model
struct WatchList: Codable {
    var stocks: [Stock]
    var lastUpdated: Date
    
    init(stocks: [Stock] = [], lastUpdated: Date = Date()) {
        self.stocks = stocks
        self.lastUpdated = lastUpdated
    }
    
    // MARK: - Methods
    mutating func addStock(_ stock: Stock) {
        if !stocks.contains(where: { $0.symbol == stock.symbol }) {
            stocks.append(stock)
            lastUpdated = Date()
        }
    }
    
    mutating func removeStock(withSymbol symbol: String) {
        stocks.removeAll { $0.symbol == symbol }
        lastUpdated = Date()
    }
    
    mutating func updateStock(_ stock: Stock) {
        if let index = stocks.firstIndex(where: { $0.symbol == stock.symbol }) {
            stocks[index] = stock
            lastUpdated = Date()
        }
    }
    
    func contains(symbol: String) -> Bool {
        stocks.contains { $0.symbol == symbol }
    }
    
    // MARK: - Persistence
    static let userDefaultsKey = "AsaStockTrackerWatchList"
    
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }
    
    static func load() -> WatchList {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let watchList = try? JSONDecoder().decode(WatchList.self, from: data) else {
            return WatchList()
        }
        return watchList
    }
}

// MARK: - WatchList Item for Display
struct WatchListItem: Identifiable {
    let id: UUID
    let symbol: String
    let name: String
    var isFavorite: Bool
    var sortOrder: Int
    
    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        isFavorite: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
    }
}