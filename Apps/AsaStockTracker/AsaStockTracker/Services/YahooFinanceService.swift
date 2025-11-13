//
//  YahooFinanceService.swift
//  AsaStockTracker
//
//  Yahoo Finance APIを使用した株価取得サービス
//  無料・登録不要で利用可能
//

import Foundation

// MARK: - Yahoo Finance Service
@MainActor
class YahooFinanceService: ObservableObject {
    static let shared = YahooFinanceService()
    private let networkManager = NetworkManager.shared

    private init() {}

    // MARK: - Public Methods

    /// 株価の取得
    /// - Parameter symbol: 銘柄シンボル（例: "AAPL", "7203.T"）
    /// - Returns: Stock オブジェクト
    func fetchQuote(for symbol: String) async throws -> Stock {
        print("📡 [YahooFinanceService] fetchQuote開始: \(symbol)")
        let urlString = "\(Constants.API.chartURL)/\(symbol)?interval=1d&range=1d"

        guard let url = URL(string: urlString) else {
            print("❌ [YahooFinanceService] 無効なURL: \(urlString)")
            throw NetworkError.invalidURL
        }

        print("🌐 [YahooFinanceService] APIリクエスト: \(url.absoluteString)")
        let response = try await networkManager.fetch(YahooChartResponse.self, from: url)

        print("📦 [YahooFinanceService] APIレスポンス受信")
        print("   - result数: \(response.chart.result.count)")
        print("   - error: \(response.chart.error?.description ?? "なし")")

        guard let result = response.chart.result.first else {
            print("❌ [YahooFinanceService] resultが空です")
            throw NetworkError.noData
        }

        print("🔍 [YahooFinanceService] result取得成功: \(result.meta.symbol)")
        return try result.toStock()
    }

    /// 複数銘柄の株価を一括取得
    /// - Parameter symbols: 銘柄シンボル配列
    /// - Returns: Stock オブジェクト配列
    func fetchQuotes(for symbols: [String]) async -> [Stock] {
        await withTaskGroup(of: Stock?.self) { group in
            for symbol in symbols {
                group.addTask {
                    do {
                        return try await self.fetchQuote(for: symbol)
                    } catch {
                        print("⚠️ Error fetching quote for \(symbol): \(error.localizedDescription)")
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

    /// 銘柄検索
    /// - Parameter query: 検索クエリ
    /// - Returns: SearchResult 配列
    func searchSymbols(query: String) async throws -> [SearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(Constants.API.searchURL)?q=\(encodedQuery)"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let response = try await networkManager.fetch(YahooSearchResponse.self, from: url)
        return response.quotes.map { $0.toSearchResult() }
    }

    /// チャートデータの取得
    /// - Parameters:
    ///   - symbol: 銘柄シンボル
    ///   - range: データ範囲（1d, 5d, 1mo, 3mo, 1y, 5y）
    ///   - interval: データ間隔（1m, 5m, 15m, 1d, 1wk, 1mo）
    /// - Returns: ChartDataPoint 配列
    func fetchChartData(for symbol: String, range: String = "1d", interval: String = "5m") async throws -> [ChartDataPoint] {
        let urlString = "\(Constants.API.chartURL)/\(symbol)?interval=\(interval)&range=\(range)"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let response = try await networkManager.fetch(YahooChartResponse.self, from: url)

        guard let result = response.chart.result.first else {
            throw NetworkError.noData
        }

        return result.toChartDataPoints()
    }
}

// MARK: - Yahoo Finance Response Models

/// Yahoo Finance Chart APIレスポンス
struct YahooChartResponse: Codable {
    let chart: Chart

    struct Chart: Codable {
        let result: [Result]
        let error: ErrorInfo?
    }

    struct Result: Codable {
        let meta: Meta
        let timestamp: [Int]?
        let indicators: Indicators

        struct Meta: Codable {
            let symbol: String
            let regularMarketPrice: Double?
            let previousClose: Double?
            let postMarketPrice: Double?        // アフターマーケット価格
            let preMarketPrice: Double?         // プレマーケット価格
            let fiftyTwoWeekHigh: Double?       // 52週高値
            let fiftyTwoWeekLow: Double?        // 52週安値
            let currency: String?
            let longName: String?
            let shortName: String?
        }

        struct Indicators: Codable {
            let quote: [Quote]

            struct Quote: Codable {
                let close: [Double?]?
                let open: [Double?]?
                let high: [Double?]?
                let low: [Double?]?
                let volume: [Int?]?
            }
        }

        /// StockモデルUへ変換
        func toStock() throws -> Stock {
            print("🔄 [toStock] 変換開始: \(meta.symbol)")
            print("   - symbol: \(meta.symbol)")
            print("   - longName: \(meta.longName ?? "nil")")
            print("   - shortName: \(meta.shortName ?? "nil")")
            print("   - currency: \(meta.currency ?? "nil")")
            print("   - regularMarketPrice: \(meta.regularMarketPrice?.description ?? "nil")")
            print("   - postMarketPrice: \(meta.postMarketPrice?.description ?? "nil")")
            print("   - preMarketPrice: \(meta.preMarketPrice?.description ?? "nil")")
            print("   - previousClose: \(meta.previousClose?.description ?? "nil")")

            // 価格データのフォールバック処理
            // 1. regularMarketPrice（通常時）
            // 2. postMarketPrice（アフターマーケット）
            // 3. preMarketPrice（プレマーケット）
            // 4. previousClose（前日終値）
            let currentPrice: Double
            if let regularPrice = meta.regularMarketPrice {
                currentPrice = regularPrice
                print("💰 [toStock] 価格取得: regularMarketPrice = $\(regularPrice)")
            } else if let postPrice = meta.postMarketPrice {
                currentPrice = postPrice
                print("🌙 [toStock] 価格取得: postMarketPrice (アフターマーケット) = $\(postPrice)")
            } else if let prePrice = meta.preMarketPrice {
                currentPrice = prePrice
                print("🌅 [toStock] 価格取得: preMarketPrice (プレマーケット) = $\(prePrice)")
            } else if let prevClose = meta.previousClose {
                currentPrice = prevClose
                print("📅 [toStock] 価格取得: previousClose (前日終値) = $\(prevClose)")
            } else {
                print("❌ [toStock] エラー: すべての価格データが nil です")
                print("   - regularMarketPrice: nil")
                print("   - postMarketPrice: nil")
                print("   - preMarketPrice: nil")
                print("   - previousClose: nil")
                throw NetworkError.noData
            }

            // previousCloseのフォールバック処理（nil の場合は currentPrice を使用）
            let previousClose = meta.previousClose ?? currentPrice
            if meta.previousClose == nil {
                print("⚠️ [toStock] 警告: previousClose が nil のため currentPrice を使用")
                print("   結果: 変動額・変動率は 0.0 になります")
            }

            let change = currentPrice - previousClose
            let changePercent = previousClose != 0 ? (change / previousClose) * 100 : 0.0

            print("💰 [toStock] 価格計算完了")
            print("   - currentPrice: $\(currentPrice)")
            print("   - previousClose: $\(previousClose)")
            print("   - change: $\(change)")
            print("   - changePercent: \(changePercent)%")

            // 出来高を取得（最新のデータ）
            let volume: Int
            if let quotes = indicators.quote.first,
               let volumes = quotes.volume,
               let lastVolume = volumes.last,
               let validVolume = lastVolume {
                volume = validVolume
            } else {
                volume = 0
            }

            print("📊 [toStock] 出来高: \(volume)")

            let stock = Stock(
                symbol: meta.symbol,
                name: meta.longName ?? meta.shortName ?? meta.symbol,
                currentPrice: currentPrice,
                previousClose: previousClose,
                change: change,
                changePercent: changePercent,
                volume: volume,
                currency: meta.currency
            )

            print("✅ [toStock] Stock変換成功: \(stock.symbol) - $\(stock.currentPrice)")
            return stock
        }

        /// ChartDataPointへ変換
        func toChartDataPoints() -> [ChartDataPoint] {
            guard let timestamps = timestamp,
                  let quote = indicators.quote.first,
                  let closes = quote.close else {
                return []
            }

            var chartData: [ChartDataPoint] = []

            for (index, timestamp) in timestamps.enumerated() {
                guard index < closes.count,
                      let closePrice = closes[index] else {
                    continue
                }

                let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                let volume = quote.volume?[safe: index] ?? nil

                let point = ChartDataPoint(
                    date: date,
                    price: closePrice,
                    volume: volume ?? 0
                )
                chartData.append(point)
            }

            return chartData
        }
    }

    struct ErrorInfo: Codable {
        let code: String
        let description: String
    }
}

/// Yahoo Finance Search APIレスポンス
struct YahooSearchResponse: Codable {
    let quotes: [Quote]

    struct Quote: Codable {
        let symbol: String
        let shortname: String?
        let longname: String?
        let exchDisp: String?
        let typeDisp: String?

        func toSearchResult() -> SearchResult {
            return SearchResult(
                symbol: symbol,
                name: longname ?? shortname ?? symbol,
                type: typeDisp ?? "Stock",
                region: exchDisp ?? "Unknown",
                marketOpen: "N/A",
                marketClose: "N/A",
                timezone: "N/A",
                currency: "USD",
                matchScore: "1.0"
            )
        }
    }
}

// MARK: - Helper Extensions

extension Array {
    /// 安全な配列アクセス
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
