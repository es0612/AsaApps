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
        // Alpha Vantage API設定
        // 注意: 本番環境では、APIキーを安全に管理してください
        // デモ用のキーを使用しています
        static let apiKey = "demo"
        static let baseURL = "https://www.alphavantage.co/query"
        
        // APIレート制限
        static let requestsPerMinute = 5
        static let requestsPerDay = 500
        
        // キャッシュ設定
        static let cacheExpirationMinutes = 5
        
        // タイムアウト設定
        static let timeoutInterval: TimeInterval = 30
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