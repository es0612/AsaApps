//
//  NetworkManager.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import Foundation

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case priceUnavailable
    case marketClosed
    case decodingError
    case serverError(String)
    case apiLimitReached
    case networkUnavailable
    case unauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データが取得できませんでした"
        case .priceUnavailable:
            return "この銘柄の価格データが現在利用できません"
        case .marketClosed:
            return "市場時間外のため、価格データが利用できません"
        case .decodingError:
            return "データの解析に失敗しました"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .apiLimitReached:
            return "APIのリクエスト制限に達しました。しばらくお待ちください"
        case .networkUnavailable:
            return "ネットワークに接続できません"
        case .unauthorized:
            return "認証エラーが発生しました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}

// MARK: - Network Manager
@MainActor
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private var requestCount = 0
    private var lastRequestTime = Date()
    private let cache = NSCache<NSString, CachedData>()
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Constants.API.timeoutInterval
        configuration.timeoutIntervalForResource = Constants.API.timeoutInterval * 2
        configuration.requestCachePolicy = .useProtocolCachePolicy
        self.session = URLSession(configuration: configuration)
        
        // キャッシュ設定
        cache.countLimit = 100
        cache.totalCostLimit = 10 * 1024 * 1024  // 10MB
    }
    
    // MARK: - Public Methods
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        // レート制限チェック
        try await checkRateLimit()
        
        // キャッシュチェック
        if let cachedData = getCachedData(for: url.absoluteString) {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(type, from: cachedData)
            } catch {
                // キャッシュが無効な場合は続行
                cache.removeObject(forKey: url.absoluteString as NSString)
            }
        }
        
        // ネットワークリクエスト
        let (data, response) = try await session.data(from: url)
        
        // レスポンスチェック
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 429:
            throw NetworkError.apiLimitReached
        case 500...599:
            throw NetworkError.serverError("Status: \(httpResponse.statusCode)")
        default:
            throw NetworkError.serverError("Status: \(httpResponse.statusCode)")
        }
        
        // APIエラーチェック（Alpha Vantage特有）
        if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
            if apiError.note?.contains("API call frequency") == true {
                throw NetworkError.apiLimitReached
            } else if let info = apiError.information {
                throw NetworkError.serverError(info)
            }
        }
        
        // デコード
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(type, from: data)
            
            // キャッシュに保存
            setCachedData(data, for: url.absoluteString)
            
            return result
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    // MARK: - Rate Limiting
    private func checkRateLimit() async throws {
        let now = Date()
        let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
        
        // 1分間のリクエスト数をリセット
        if timeSinceLastRequest > 60 {
            requestCount = 0
            lastRequestTime = now
        }
        
        // レート制限チェック
        if requestCount >= Constants.API.requestsPerMinute {
            let waitTime = 60 - timeSinceLastRequest
            if waitTime > 0 {
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
            requestCount = 0
            lastRequestTime = Date()
        }
        
        requestCount += 1
    }
    
    // MARK: - Cache Management
    private func getCachedData(for key: String) -> Data? {
        guard let cached = cache.object(forKey: key as NSString) else { return nil }
        
        let now = Date()
        let cacheAge = now.timeIntervalSince(cached.timestamp)
        
        // キャッシュ有効期限チェック
        if cacheAge < TimeInterval(Constants.API.cacheExpirationMinutes * 60) {
            return cached.data
        } else {
            cache.removeObject(forKey: key as NSString)
            return nil
        }
    }
    
    private func setCachedData(_ data: Data, for key: String) {
        let cached = CachedData(data: data, timestamp: Date())
        cache.setObject(cached, forKey: key as NSString, cost: data.count)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Cached Data Model
private class CachedData: NSObject {
    let data: Data
    let timestamp: Date
    
    init(data: Data, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
    }
}