# AsaPortfolio（投資ポートフォリオ管理アプリ）実装計画

## 概要

AsaPortfolioは、家族の資産管理を朝活時間でチェックできる投資ポートフォリオ管理アプリです。Alpha Vantage APIを活用してリアルタイム株価を取得し、Swift Chartsで資産配分や推移を可視化します。

- **アプリ番号**: #90（上級アプリ）
- **iOS**: 17.0+
- **Swift**: 5.9+
- **技術スタック**: SwiftUI + Swift Data + Swift Charts + Alpha Vantage API

---

## 主要機能

| 機能 | 説明 |
|------|------|
| ポートフォリオ管理 | 複数ポートフォリオの作成・管理 |
| 保有資産管理 | 株式、ETF、投資信託の追加・編集・削除 |
| リアルタイム価格 | Alpha Vantage APIで株価取得（無料500回/日） |
| 資産評価 | 時価総額、損益計算、損益率表示 |
| チャート可視化 | 資産配分（円グラフ）、資産推移（折れ線グラフ） |
| パフォーマンス分析 | 日次/週次/月次/年次リターン計算 |
| ウォッチリスト | 気になる銘柄の監視 |
| 配当トラッキング | 配当履歴・予定管理 |

---

## ディレクトリ構造

```
Apps/AsaPortfolio/
├── project.yml
├── AsaPortfolio/
│   ├── AsaPortfolioApp.swift
│   ├── ContentView.swift
│   │
│   ├── Models/
│   │   ├── Domain/              # SwiftData @Model
│   │   │   ├── Portfolio.swift
│   │   │   ├── Holding.swift
│   │   │   ├── Transaction.swift
│   │   │   ├── Dividend.swift
│   │   │   └── WatchlistItem.swift
│   │   ├── API/                 # API応答モデル
│   │   │   ├── StockQuote.swift
│   │   │   ├── CompanyOverview.swift
│   │   │   └── TimeSeriesData.swift
│   │   └── Enums/
│   │       ├── AssetType.swift
│   │       ├── TransactionType.swift
│   │       └── TimeRange.swift
│   │
│   ├── ViewModels/
│   │   ├── PortfolioViewModel.swift      # メインVM
│   │   ├── HoldingDetailViewModel.swift  # 保有資産詳細
│   │   ├── WatchlistViewModel.swift      # ウォッチリスト
│   │   ├── AnalyticsViewModel.swift      # パフォーマンス分析
│   │   └── TransactionViewModel.swift    # 取引管理
│   │
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
│   │
│   ├── Views/
│   │   ├── Dashboard/           # ダッシュボード
│   │   ├── Portfolio/           # ポートフォリオ一覧・詳細
│   │   ├── Holdings/            # 保有資産
│   │   ├── Charts/              # チャートコンポーネント
│   │   ├── Analytics/           # 分析画面
│   │   ├── Watchlist/           # ウォッチリスト
│   │   ├── Transactions/        # 取引履歴
│   │   ├── Dividends/           # 配当
│   │   ├── Components/          # 共通コンポーネント
│   │   └── Settings/            # 設定
│   │
│   └── Extensions/
│
├── AsaPortfolioTests/
└── AsaPortfolioUITests/
```

---

## Models設計

### Portfolio.swift（@Model）
```swift
@Model
final class Portfolio {
    @Attribute(.unique) var id: UUID
    var name: String
    var note: String
    var colorHex: String
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var holdings: [Holding]

    // Computed: totalValue, totalCost, totalGain, gainPercentage
}
```

### Holding.swift（@Model）
```swift
@Model
final class Holding {
    @Attribute(.unique) var id: UUID
    var symbol: String            // 例: AAPL
    var name: String
    var assetTypeRawValue: String // stock/etf/mutual_fund
    var quantity: Decimal
    var averageCost: Decimal
    var currentPrice: Decimal
    var lastUpdated: Date
    var currency: String          // USD/JPY
    var sectorName: String?

    var portfolio: Portfolio?
    @Relationship(deleteRule: .cascade) var transactions: [Transaction]
    @Relationship(deleteRule: .cascade) var dividends: [Dividend]

    // Computed: marketValue, unrealizedGain, gainPercentage
}
```

---

## ViewModels設計

### PortfolioViewModel（メインVM）
```swift
@MainActor
@Observable
final class PortfolioViewModel {
    private let stockAPIService: StockAPIServiceProtocol
    private let dataService: PortfolioDataService

    private(set) var portfolios: [Portfolio] = []
    private(set) var selectedPortfolio: Portfolio?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var totalValue: Decimal { ... }
    var topGainers: [Holding] { ... }
    var topLosers: [Holding] { ... }

    func loadInitialData() async { ... }
    func refreshQuotes() async { ... }
    func createPortfolio(...) async { ... }
    func addHolding(...) async { ... }
}
```

---

## Services設計

### StockAPIServiceProtocol
```swift
@MainActor
protocol StockAPIServiceProtocol: AnyObject {
    var remainingRequests: Int { get }

    func fetchQuote(symbol: String) async throws -> StockQuote
    func fetchBulkQuotes(symbols: [String]) async throws -> [StockQuote]
    func fetchDailyTimeSeries(symbol: String) async throws -> [TimeSeriesData]
    func searchSymbol(keywords: String) async throws -> [SymbolSearchResult]
}
```

### Alpha Vantage APIエンドポイント
| 機能 | エンドポイント |
|------|---------------|
| リアルタイム価格 | `GLOBAL_QUOTE` |
| 日次時系列 | `TIME_SERIES_DAILY` |
| 企業概要 | `OVERVIEW` |
| 銘柄検索 | `SYMBOL_SEARCH` |

### API制限対策
- 15分間インメモリキャッシュ
- 1分5リクエスト制限考慮したバッチ処理
- フォールバック: キャッシュデータ表示

---

## Charts設計（Swift Charts）

### AllocationPieChart（資産配分円グラフ）
```swift
Chart(data) { item in
    SectorMark(
        angle: .value("Value", item.percentage),
        innerRadius: .ratio(0.6)
    )
    .foregroundStyle(by: .value("Symbol", item.symbol))
}
```

### PerformanceLineChart（資産推移折れ線グラフ）
```swift
Chart(data) { point in
    LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
        .foregroundStyle(Color("AsaCoffeeBrown"))
    AreaMark(...)
        .foregroundStyle(.linearGradient(...))
}
```

---

## 実装フェーズ

### Phase 1: 基盤構築（2-3日）
- [ ] プロジェクト作成（XcodeGen + project.yml）
- [ ] Models層実装（Portfolio, Holding, Transaction, Dividend, WatchlistItem）
- [ ] Enums実装（AssetType, TransactionType, TimeRange）
- [ ] Services/Protocols定義
- [ ] MockStockAPIService実装
- [ ] 基本Unit Tests

### Phase 2: コア機能（3-4日）
- [ ] AlphaVantageService実装（APIキー管理含む）
- [ ] PortfolioViewModel実装
- [ ] PortfolioDataService実装（SwiftData CRUD）
- [ ] PerformanceCalculator実装
- [ ] Dashboard, PortfolioList, HoldingDetail Views

### Phase 3: チャート・分析（2-3日）
- [ ] AllocationPieChart（資産配分）
- [ ] PerformanceLineChart（資産推移）
- [ ] SectorBreakdownChart（セクター別内訳）
- [ ] AnalyticsView / AnalyticsViewModel
- [ ] GainLossBarChart（損益棒グラフ）

### Phase 4: 追加機能・仕上げ（2-3日）
- [ ] WatchlistView / WatchlistViewModel
- [ ] DividendListView / DividendCalendarView
- [ ] TransactionListView / AddTransactionSheet
- [ ] 設定画面（APIキー設定）
- [ ] UIテスト
- [ ] ドキュメント作成（Docs/Notes/）

---

## テスト戦略

### Unit Tests（Swift Testing）
```swift
@Test("損益計算 - 利益ケース")
func testGainCalculationProfit() {
    let result = calculator.calculateGain(currentValue: 1200, costBasis: 1000)
    #expect(result.amount == 200)
    #expect(result.percentage == 20.0)
}
```

### テストカバレッジ目標
| レイヤー | 目標 |
|---------|------|
| Models | 90%+ |
| Services/Utilities | 95%+ |
| ViewModels | 80%+ |

---

## project.yml

```yaml
name: AsaPortfolio
options:
  bundleIdPrefix: com.asapapa.apps
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"

settings:
  base:
    SWIFT_VERSION: "5.9"
    GENERATE_INFOPLIST_FILE: YES

packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit

targets:
  AsaPortfolio:
    type: application
    platform: iOS
    sources:
      - AsaPortfolio
    dependencies:
      - package: AsaUIKit

  AsaPortfolioTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - AsaPortfolioTests
    dependencies:
      - target: AsaPortfolio
```

---

## 参照パターン（Critical Files）

- `Apps/AsaSmartHome/AsaSmartHome/ViewModels/SmartHomeViewModel.swift` - @MainActor + @Observable
- `Apps/AsaLanguageLearn/AsaLanguageLearn/Services/Protocols/` - Protocol-Driven Design
- `Apps/AsaLanguageLearn/project.yml` - XcodeGen設定

---

## 検証方法

### ビルド確認
```bash
cd Apps/AsaPortfolio
xcodegen generate
xcodebuild -project AsaPortfolio.xcodeproj -scheme AsaPortfolio -destination 'platform=iOS Simulator,name=iPhone 16'
```

### テスト実行
```bash
swift test
```

### 動作確認
1. アプリ起動 → ダッシュボード表示
2. ポートフォリオ作成 → 保有資産追加
3. 株価更新 → 損益計算確認
4. チャート表示確認（円グラフ、折れ線グラフ）
5. ウォッチリスト追加・削除

---

## 技術的ポイント

- **Alpha Vantage無料枠**: 500リクエスト/日、キャッシュとバッチ処理で効率化
- **Swift Charts**: iOS 16+で利用可能、宣言的APIでグラフ描画
- **Decimal型**: 金融計算にはDouble ではなくDecimalを使用
- **@Observable + @MainActor**: モダンSwiftUI状態管理パターン

---

## Sources

- [Alpha Vantage API Documentation](https://www.alphavantage.co/documentation/)
- [Swift Charts | Apple Developer](https://developer.apple.com/documentation/Charts)
- [Top Free Financial Data APIs (DEV Community)](https://dev.to/williamsmithh/top-5-free-financial-data-apis-for-building-a-powerful-stock-portfolio-tracker-4dhj)
- [iOS Development Trends 2025-2026](https://www.developer-tech.com/news/5-ios-app-development-trends-for-2025-2026/)
