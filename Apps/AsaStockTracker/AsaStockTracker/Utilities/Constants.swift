//
//  Constants.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import Foundation

enum Constants {
    // MARK: - API Configuration
    enum API {
        // Yahoo Finance API設定（無料・登録不要）
        static let baseURL = "https://query1.finance.yahoo.com"
        static let chartURL = "https://query1.finance.yahoo.com/v8/finance/chart"
        static let searchURL = "https://query2.finance.yahoo.com/v1/finance/search"

        // APIレート制限（Yahoo Finance: 2000リクエスト/時間 ≈ 33リクエスト/分）
        static let requestsPerHour = 2000
        static let requestsPerMinute = 33

        // キャッシュ設定
        static let cacheExpirationMinutes = 5

        // タイムアウト設定
        static let timeoutInterval: TimeInterval = 30

        // DEPRECATED: Alpha Vantage設定（参考用に保持）
        // static let alphaVantageBaseURL = "https://www.alphavantage.co/query"
        // static let alphaVantageAPIKey = "demo"
        // static let alphaVantageRequestsPerMinute = 5
    }
    
    // MARK: - Update Intervals
    enum UpdateInterval {
        static let realtime: TimeInterval = 30  // 30秒
        static let standard: TimeInterval = 60  // 1分
        static let background: TimeInterval = 300  // 5分
    }
    
    // MARK: - UI Configuration
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 4
        static let animationDuration: Double = 0.3
        static let maxStocksInWatchlist = 50
    }
    
    // MARK: - Sample Symbols
    enum SampleSymbols {
        static let defaultSymbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"]
        static let japaneseSymbols = ["7203.T", "6758.T", "9984.T", "6861.T", "9433.T"]  // トヨタ、ソニー、ソフトバンク、キーエンス、KDDI
    }
    
    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let watchList = "AsaStockTrackerWatchList"
        static let lastUpdateTime = "AsaStockTrackerLastUpdate"
        static let favoriteSymbols = "AsaStockTrackerFavorites"
        static let sortPreference = "AsaStockTrackerSortPreference"
        static let isFirstLaunch = "AsaStockTrackerFirstLaunch"
    }
    
    // MARK: - Notification Names
    enum Notifications {
        static let stockDataUpdated = Notification.Name("AsaStockTrackerDataUpdated")
        static let networkError = Notification.Name("AsaStockTrackerNetworkError")
        static let apiLimitReached = Notification.Name("AsaStockTrackerAPILimitReached")
    }
}