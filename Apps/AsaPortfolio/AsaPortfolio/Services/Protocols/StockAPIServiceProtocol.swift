import Foundation

/// 株価API取得エラー
enum StockAPIError: Error, LocalizedError, Sendable {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case rateLimitExceeded
    case invalidAPIKey
    case symbolNotFound(String)
    case serverError(Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .decodingError(let error):
            return "データ解析エラー: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "APIリクエスト上限に達しました（1分5回、1日500回）"
        case .invalidAPIKey:
            return "無効なAPIキーです"
        case .symbolNotFound(let symbol):
            return "銘柄が見つかりません: \(symbol)"
        case .serverError(let code):
            return "サーバーエラー: \(code)"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}

/// 株価APIサービスプロトコル
/// Alpha Vantage APIをラップし、テスト時にモックを注入可能にする
@MainActor
protocol StockAPIServiceProtocol: AnyObject, Sendable {
    /// 残りAPIリクエスト数（概算）
    var remainingRequests: Int { get }

    /// 単一銘柄の株価を取得
    /// - Parameter symbol: ティッカーシンボル（例: AAPL）
    /// - Returns: 株価クォート
    func fetchQuote(symbol: String) async throws -> StockQuote

    /// 複数銘柄の株価を一括取得
    /// - Parameter symbols: ティッカーシンボルの配列
    /// - Returns: 株価クォートの配列
    func fetchBulkQuotes(symbols: [String]) async throws -> [StockQuote]

    /// 日次時系列データを取得
    /// - Parameter symbol: ティッカーシンボル
    /// - Returns: 時系列データの配列
    func fetchDailyTimeSeries(symbol: String) async throws -> [TimeSeriesData]

    /// 企業概要を取得
    /// - Parameter symbol: ティッカーシンボル
    /// - Returns: 企業概要
    func fetchCompanyOverview(symbol: String) async throws -> CompanyOverview

    /// 銘柄を検索
    /// - Parameter keywords: 検索キーワード
    /// - Returns: 検索結果の配列
    func searchSymbol(keywords: String) async throws -> [SymbolSearchResult]

    /// キャッシュをクリア
    func clearCache()
}

/// キャッシュエントリ
struct CacheEntry<T: Sendable>: Sendable {
    let value: T
    let timestamp: Date

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 15 * 60 // 15分
    }
}
