//
//  WatchListViewModel.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import Foundation
import SwiftUI
import Observation

// MARK: - WatchList View Model
@Observable
@MainActor
final class WatchListViewModel {
    // MARK: - Properties
    var watchList: WatchList = WatchList.load()
    var favoriteSymbols: Set<String> = []
    var isEditing = false
    var showingAddStock = false
    var sortOption: StockViewModel.SortOption = .symbol
    
    private let apiService = StockAPIService.shared
    
    // MARK: - Computed Properties
    var sortedStocks: [Stock] {
        var stocks = watchList.stocks
        
        // お気に入りを上位に表示
        let favorites = stocks.filter { favoriteSymbols.contains($0.symbol) }
        let others = stocks.filter { !favoriteSymbols.contains($0.symbol) }
        
        // それぞれをソート
        let sortedFavorites = sortStocks(favorites, by: sortOption)
        let sortedOthers = sortStocks(others, by: sortOption)
        
        return sortedFavorites + sortedOthers
    }
    
    var watchListCount: Int {
        watchList.stocks.count
    }
    
    var canAddMoreStocks: Bool {
        watchListCount < Constants.UI.maxStocksInWatchlist
    }
    
    // MARK: - Initialization
    init() {
        loadFavorites()
        refreshWatchList()
    }
    
    // MARK: - Public Methods
    
    // ウォッチリストに銘柄を追加
    func addToWatchList(_ stock: Stock) {
        guard canAddMoreStocks else { return }
        
        watchList.addStock(stock)
        saveWatchList()
        
        Task {
            await refreshStock(stock.symbol)
        }
    }
    
    // ウォッチリストから銘柄を削除
    func removeFromWatchList(_ stock: Stock) {
        watchList.removeStock(withSymbol: stock.symbol)
        favoriteSymbols.remove(stock.symbol)
        saveWatchList()
        saveFavorites()
    }
    
    // 銘柄をお気に入りに追加/削除
    func toggleFavorite(_ stock: Stock) {
        if favoriteSymbols.contains(stock.symbol) {
            favoriteSymbols.remove(stock.symbol)
        } else {
            favoriteSymbols.insert(stock.symbol)
        }
        saveFavorites()
    }
    
    // 銘柄がお気に入りかどうか
    func isFavorite(_ stock: Stock) -> Bool {
        favoriteSymbols.contains(stock.symbol)
    }
    
    // ウォッチリストをリフレッシュ
    func refreshWatchList() {
        Task {
            let symbols = watchList.stocks.map { $0.symbol }
            guard !symbols.isEmpty else { return }
            
            let updatedStocks = await apiService.fetchQuotes(for: symbols)
            
            for stock in updatedStocks {
                watchList.updateStock(stock)
            }
            
            saveWatchList()
        }
    }
    
    // 特定の銘柄をリフレッシュ
    func refreshStock(_ symbol: String) async {
        do {
            let stock = try await apiService.fetchQuote(for: symbol)
            watchList.updateStock(stock)
            saveWatchList()
        } catch {
            print("Error refreshing stock \(symbol): \(error)")
        }
    }
    
    // 検索結果から銘柄を追加
    func addFromSearch(_ searchResult: SearchResult) async {
        do {
            let stock = try await apiService.fetchQuote(for: searchResult.symbol)
            addToWatchList(stock)
        } catch {
            print("Error adding stock from search: \(error)")
        }
    }
    
    // 並び替え
    func setSortOption(_ option: StockViewModel.SortOption) {
        sortOption = option
    }
    
    // MARK: - Private Methods
    
    private func sortStocks(_ stocks: [Stock], by option: StockViewModel.SortOption) -> [Stock] {
        switch option {
        case .symbol:
            return stocks.sorted { $0.symbol < $1.symbol }
        case .name:
            return stocks.sorted { $0.name < $1.name }
        case .price:
            return stocks.sorted { $0.currentPrice > $1.currentPrice }
        case .change:
            return stocks.sorted { $0.changePercent > $1.changePercent }
        case .volume:
            return stocks.sorted { $0.volume > $1.volume }
        }
    }
    
    private func saveWatchList() {
        watchList.save()
    }
    
    private func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.stringArray(forKey: Constants.UserDefaultsKeys.favoriteSymbols) {
            favoriteSymbols = Set(savedFavorites)
        }
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteSymbols), forKey: Constants.UserDefaultsKeys.favoriteSymbols)
    }
    
    // MARK: - Demo Data
    func loadDemoData() {
        let demoStocks = Stock.sampleData
        for stock in demoStocks {
            watchList.addStock(stock)
        }
        
        // いくつかをお気に入りに設定
        favoriteSymbols = Set(["AAPL", "GOOGL", "MSFT"])
        
        saveWatchList()
        saveFavorites()
    }
}