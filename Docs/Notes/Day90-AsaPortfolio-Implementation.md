# Day 90 - AsaPortfolio 実装ノート

## アプリ概要

**AsaPortfolio**は、朝活時間に家族の資産状況をサクッとチェックできる投資ポートフォリオ管理アプリです。Alpha Vantage APIを活用してリアルタイム株価を取得し、Swift Chartsで資産配分や推移を美しく可視化します。

### 主要機能
- 複数ポートフォリオの作成・管理
- 株式、ETF、投資信託の保有資産管理
- Alpha Vantage APIによるリアルタイム株価取得
- 時価総額、損益計算、損益率表示
- Swift Chartsによる資産配分・推移のグラフ可視化
- ウォッチリスト機能
- 取引履歴・配当トラッキング

## 技術スタック

| 技術 | 用途 |
|------|------|
| SwiftUI | UI構築 |
| SwiftData | データ永続化（@Model） |
| Swift Charts | グラフ可視化 |
| Alpha Vantage API | 株価データ取得 |
| @Observable | 状態管理 |
| async/await | 非同期処理 |

## アーキテクチャ

### MVVM + Protocol-Driven Design

```
┌─────────────────────────────────────────────────┐
│                    Views                         │
│  Dashboard / Portfolio / Watchlist / Analytics   │
└───────────────────────┬─────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────┐
│              ViewModels (@Observable)            │
│         PortfolioViewModel (メインVM)            │
└───────────────────────┬─────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────┐
│                   Services                       │
│  StockAPIServiceProtocol / PortfolioDataService  │
└───────────────────────┬─────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────┐
│              Models (@Model / Codable)           │
│  Portfolio / Holding / Transaction / Dividend    │
└─────────────────────────────────────────────────┘
```

### Protocol-Driven Design

テスト容易性のため、API呼び出しをプロトコルで抽象化：

```swift
@MainActor
protocol StockAPIServiceProtocol: AnyObject, Sendable {
    var remainingRequests: Int { get }
    func fetchQuote(symbol: String) async throws -> StockQuote
    func fetchBulkQuotes(symbols: [String]) async throws -> [StockQuote]
    // ...
}
```

本番環境では `AlphaVantageService`、テスト環境では `MockStockAPIService` を注入。

## 主要実装ポイント

### 1. 金融計算にDecimal型を使用

```swift
// ✅ 正しい: Decimal型で精度を保証
var marketValue: Decimal {
    quantity * currentPrice
}

// ❌ 誤り: Doubleは浮動小数点誤差が発生
var marketValue: Double {
    Double(quantity) * Double(currentPrice)
}
```

### 2. Alpha Vantage API制限対策

```swift
// 15分間のキャッシュ
private var quoteCache: [String: CacheEntry<StockQuote>] = [:]

// 1分5リクエスト制限を考慮したレート制限
private func respectRateLimit() async throws {
    if let lastTime = lastRequestTime {
        let elapsed = Date().timeIntervalSince(lastTime)
        if elapsed < 12 {
            try await Task.sleep(nanoseconds: UInt64((12 - elapsed) * 1_000_000_000))
        }
    }
    lastRequestTime = Date()
}
```

### 3. Swift Chartsによる可視化

```swift
// 資産配分円グラフ
Chart(allocations) { item in
    SectorMark(
        angle: .value("Value", item.percentage),
        innerRadius: .ratio(0.6),
        angularInset: 1.5
    )
    .foregroundStyle(item.color)
}

// 資産推移折れ線グラフ
Chart(data) { point in
    LineMark(
        x: .value("Date", point.date),
        y: .value("Value", NSDecimalNumber(decimal: point.value).doubleValue)
    )
    .foregroundStyle(color)

    AreaMark(...)
        .foregroundStyle(LinearGradient(...))
}
```

### 4. SwiftData リレーション

```swift
@Model
final class Portfolio {
    @Relationship(deleteRule: .cascade, inverse: \Holding.portfolio)
    var holdings: [Holding] = []
}
```

## ディレクトリ構造

```
AsaPortfolio/
├── project.yml
├── AsaPortfolio/
│   ├── AsaPortfolioApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── Domain/           # SwiftData @Model
│   │   │   ├── Portfolio.swift
│   │   │   ├── Holding.swift
│   │   │   ├── Transaction.swift
│   │   │   ├── Dividend.swift
│   │   │   └── WatchlistItem.swift
│   │   ├── API/              # API応答モデル
│   │   │   ├── StockQuote.swift
│   │   │   ├── CompanyOverview.swift
│   │   │   └── TimeSeriesData.swift
│   │   └── Enums/
│   │       ├── AssetType.swift
│   │       ├── TransactionType.swift
│   │       └── TimeRange.swift
│   ├── ViewModels/
│   │   └── PortfolioViewModel.swift
│   ├── Services/
│   │   ├── Protocols/
│   │   │   └── StockAPIServiceProtocol.swift
│   │   ├── Production/
│   │   │   └── AlphaVantageService.swift
│   │   ├── Mock/
│   │   │   └── MockStockAPIService.swift
│   │   ├── Data/
│   │   │   └── PortfolioDataService.swift
│   │   └── Utilities/
│   │       ├── PerformanceCalculator.swift
│   │       └── CurrencyFormatter.swift
│   └── Views/
│       ├── Dashboard/
│       ├── Portfolio/
│       ├── Holdings/
│       ├── Charts/
│       ├── Analytics/
│       ├── Watchlist/
│       └── Settings/
└── AsaPortfolioTests/
    ├── PerformanceCalculatorTests.swift
    ├── CurrencyFormatterTests.swift
    └── ModelTests.swift
```

## 学んだこと

### 1. 金融アプリでのDecimal型の重要性
Doubleの浮動小数点誤差は金融計算では致命的。Decimalを使用することで精度を保証。

### 2. API制限への対応パターン
- キャッシュによるリクエスト削減
- レート制限による自動待機
- バッチ処理による効率化

### 3. Swift Chartsの柔軟性
円グラフ、折れ線グラフ、棒グラフなど多様なチャートを宣言的に記述可能。

### 4. Protocol-Driven Designの利点
テスト時にモックを注入できるため、API呼び出しを含むViewModelのテストが容易。

## 今後の改善点

1. **履歴データの保存**: 日次の資産総額を記録し、実際の資産推移グラフを表示
2. **配当カレンダー**: 予定配当を月別カレンダーで表示
3. **アラート機能**: ターゲット価格到達時のプッシュ通知
4. **CSVインポート/エクスポート**: 他のツールとのデータ連携
5. **Widget対応**: ホーム画面で資産状況をクイック確認

## ビルド・実行方法

```bash
cd Apps/AsaPortfolio
xcodegen generate
open AsaPortfolio.xcodeproj

# テスト実行
xcodebuild test -project AsaPortfolio.xcodeproj -scheme AsaPortfolio -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 参考資料

- [Alpha Vantage API Documentation](https://www.alphavantage.co/documentation/)
- [Swift Charts | Apple Developer](https://developer.apple.com/documentation/Charts)
- [SwiftData | Apple Developer](https://developer.apple.com/documentation/swiftdata)

---

**AsaApps #90** - 朝活パパエンジニアの100アプリプロジェクト
