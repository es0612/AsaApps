//
//  StockViewModel.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import Foundation
import SwiftUI
import Observation

// MARK: - Stock View Model
@Observable
@MainActor
final class StockViewModel {
    // MARK: - Properties
    var stocks: [Stock] = []
    var selectedStock: Stock?
    var chartData: [ChartDataPoint] = []
    var searchResults: [SearchResult] = []
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var searchText = ""
    
    private let apiService = StockAPIService.shared
    private var updateTimer: Timer?
    
    // MARK: - Initialization
    init() {
        loadInitialData()
        startAutoUpdate()
    }
    
    deinit {
        stopAutoUpdate()
    }
    
    // MARK: - Public Methods
    
    // 初期データの読み込み
    func loadInitialData() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // デモモードでサンプルデータを使用
            stocks = await apiService.fetchDemoData()
            
            // 実際のAPI使用時は以下をコメントアウト解除
            // await fetchStocks(symbols: Constants.SampleSymbols.defaultSymbols)
        }
    }
    
    // 株価データの取得
    func fetchStock(symbol: String) async {
        do {
            let stock = try await apiService.fetchQuote(for: symbol)
            updateStock(stock)
        } catch {
            handleError(error)
        }
    }
    
    // 複数銘柄の一括取得
    func fetchStocks(symbols: [String]) async {
        isLoading = true
        defer { isLoading = false }
        
        let fetchedStocks = await apiService.fetchQuotes(for: symbols)
        stocks = fetchedStocks
    }
    
    // リフレッシュ
    func refresh() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        let symbols = stocks.map { $0.symbol }
        let fetchedStocks = await apiService.fetchQuotes(for: symbols)
        stocks = fetchedStocks
    }
    
    // 銘柄検索
    func searchSymbols() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        do {
            searchResults = try await apiService.searchSymbols(query: searchText)
        } catch {
            handleError(error)
            searchResults = []
        }
    }
    
    // チャートデータの取得
    func fetchChartData(for stock: Stock) async {
        selectedStock = stock
        
        do {
            chartData = try await apiService.fetchIntradayData(for: stock.symbol)
        } catch {
            handleError(error)
            chartData = []
        }
    }
    
    // 銘柄の追加
    func addStock(_ stock: Stock) {
        if !stocks.contains(where: { $0.symbol == stock.symbol }) {
            stocks.append(stock)
        }
    }
    
    // 銘柄の削除
    func removeStock(_ stock: Stock) {
        stocks.removeAll { $0.symbol == stock.symbol }
    }
    
    // MARK: - Private Methods
    
    private func updateStock(_ stock: Stock) {
        if let index = stocks.firstIndex(where: { $0.symbol == stock.symbol }) {
            stocks[index] = stock
        } else {
            stocks.append(stock)
        }
    }
    
    private func startAutoUpdate() {
        stopAutoUpdate()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: Constants.UpdateInterval.standard, repeats: true) { _ in
            Task { @MainActor in
                await self.refresh()
            }
        }
    }
    
    private func stopAutoUpdate() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            errorMessage = networkError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        // エラーメッセージを3秒後にクリア
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.errorMessage = nil
        }
    }
    
    // MARK: - Sorting and Filtering
    
    func sortStocks(by option: SortOption) {
        switch option {
        case .symbol:
            stocks.sort { $0.symbol < $1.symbol }
        case .name:
            stocks.sort { $0.name < $1.name }
        case .price:
            stocks.sort { $0.currentPrice > $1.currentPrice }
        case .change:
            stocks.sort { $0.changePercent > $1.changePercent }
        case .volume:
            stocks.sort { $0.volume > $1.volume }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case symbol = "シンボル"
        case name = "名前"
        case price = "価格"
        case change = "変動率"
        case volume = "出来高"
    }
}