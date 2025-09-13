//
//  StockAPIService.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import Foundation

// MARK: - Stock API Service
@MainActor
class StockAPIService: ObservableObject {
    static let shared = StockAPIService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    // 株価の取得
    func fetchQuote(for symbol: String) async throws -> Stock {
        let urlString = "\(Constants.API.baseURL)?function=GLOBAL_QUOTE&symbol=\(symbol)&apikey=\(Constants.API.apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let response = try await networkManager.fetch(GlobalQuoteResponse.self, from: url)
        
        // 会社名は別途取得する必要があるが、ここではシンボルを使用
        let name = await getCompanyName(for: symbol) ?? symbol
        return response.globalQuote.toStock(name: name)
    }
    
    // 複数銘柄の株価を一括取得
    func fetchQuotes(for symbols: [String]) async -> [Stock] {
        await withTaskGroup(of: Stock?.self) { group in
            for symbol in symbols {
                group.addTask {
                    do {
                        return try await self.fetchQuote(for: symbol)
                    } catch {
                        print("Error fetching quote for \(symbol): \(error)")
                        return nil
                    }
                }
            }
            
            var stocks: [Stock] = []
            for await stock in group {
                if let stock = stock {
                    stocks.append(stock)
                }
            }
            return stocks
        }
    }
    
    // 銘柄検索
    func searchSymbols(query: String) async throws -> [SearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(Constants.API.baseURL)?function=SYMBOL_SEARCH&keywords=\(encodedQuery)&apikey=\(Constants.API.apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let response = try await networkManager.fetch(SymbolSearchResponse.self, from: url)
        return response.bestMatches
    }
    
    // チャートデータの取得（5分足）
    func fetchIntradayData(for symbol: String, interval: String = "5min") async throws -> [ChartDataPoint] {
        let urlString = "\(Constants.API.baseURL)?function=TIME_SERIES_INTRADAY&symbol=\(symbol)&interval=\(interval)&apikey=\(Constants.API.apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let response = try await networkManager.fetch(TimeSeriesResponse.self, from: url)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var chartData: [ChartDataPoint] = []
        
        for (dateString, data) in response.timeSeries {
            if let date = dateFormatter.date(from: dateString),
               let price = Double(data.close),
               let volume = Int(data.volume) {
                let point = ChartDataPoint(date: date, price: price, volume: volume)
                chartData.append(point)
            }
        }
        
        // 日付順にソート
        chartData.sort { $0.date < $1.date }
        
        return chartData
    }
    
    // MARK: - Helper Methods
    
    private func getCompanyName(for symbol: String) async -> String? {
        // 会社名のマッピング（デモ用）
        let companyNames: [String: String] = [
            "AAPL": "Apple Inc.",
            "GOOGL": "Alphabet Inc.",
            "MSFT": "Microsoft Corporation",
            "AMZN": "Amazon.com Inc.",
            "TSLA": "Tesla Inc.",
            "META": "Meta Platforms Inc.",
            "NVDA": "NVIDIA Corporation",
            "JPM": "JPMorgan Chase & Co.",
            "V": "Visa Inc.",
            "JNJ": "Johnson & Johnson",
            "WMT": "Walmart Inc.",
            "PG": "Procter & Gamble Co.",
            "MA": "Mastercard Inc.",
            "UNH": "UnitedHealth Group Inc.",
            "HD": "The Home Depot Inc.",
            "DIS": "The Walt Disney Company",
            "BAC": "Bank of America Corp.",
            "NFLX": "Netflix Inc.",
            "ADBE": "Adobe Inc.",
            "CRM": "Salesforce Inc.",
            // 日本株
            "7203.T": "トヨタ自動車",
            "6758.T": "ソニーグループ",
            "9984.T": "ソフトバンクグループ",
            "6861.T": "キーエンス",
            "9433.T": "KDDI",
            "8306.T": "三菱UFJフィナンシャル・グループ",
            "9432.T": "日本電信電話",
            "4063.T": "信越化学工業",
            "6098.T": "リクルートホールディングス",
            "7267.T": "本田技研工業"
        ]
        
        return companyNames[symbol]
    }
    
    // デモデータを使用（API制限対策）
    func fetchDemoData() async -> [Stock] {
        // 実際のAPIコールの代わりにサンプルデータを返す
        return Stock.sampleData
    }
}