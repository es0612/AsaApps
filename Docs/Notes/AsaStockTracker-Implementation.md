# AsaStockTracker 実装ドキュメント

**作成日**: 2025年1月
**バージョン**: 1.0
**API**: Yahoo Finance（無料・登録不要）

## 📋 アプリ概要

AsaStockTrackerは、リアルタイム株価データを表示するiOSアプリです。米国株・日本株に対応し、ウォッチリスト管理、銘柄検索、価格チャート表示機能を提供します。

### 主な機能

- ✅ リアルタイム株価表示（60秒自動更新）
- ✅ ウォッチリスト管理（追加/削除/お気に入り）
- ✅ 銘柄検索機能
- ✅ 価格チャート表示（Swift Charts使用）
- ✅ 複数の並び替えオプション（シンボル/名前/価格/変動率/出来高）
- ✅ 米国株・日本株対応

## 🏗️ 技術スタック

### アーキテクチャ

- **デザインパターン**: MVVM（Model-View-ViewModel）
- **状態管理**: `@Observable` パターン（Swift 5.9+）
- **UI フレームワーク**: SwiftUI
- **チャート**: Swift Charts
- **データ永続化**: UserDefaults
- **非同期処理**: async/await + TaskGroup

### 主要コンポーネント

#### Models

| ファイル | 説明 |
|---------|------|
| `Stock.swift` | 株価データモデル（価格、変動率、出来高等） |
| `WatchList.swift` | ウォッチリストモデル（最大50銘柄） |
| `SearchResult.swift` | 検索結果モデル |
| `ChartDataPoint.swift` | チャートデータポイント |
| `StockQuote.swift` | Alpha Vantageレスポンスモデル（旧実装・参考用） |

#### ViewModels

| ファイル | 説明 |
|---------|------|
| `StockViewModel.swift` | 株価データ管理、検索、チャートデータ取得 |
| `WatchListViewModel.swift` | ウォッチリスト管理、お気に入り機能 |

#### Services

| ファイル | 説明 |
|---------|------|
| `YahooFinanceService.swift` | **Yahoo Finance API統合（現在使用中）** |
| `NetworkManager.swift` | ネットワーク層（レート制限、キャッシング） |
| `StockAPIService.swift` | Alpha Vantage実装（DEPRECATED・参考用） |

#### Views

| ファイル | 説明 |
|---------|------|
| `ContentView.swift` | メインタブビュー（ウォッチリスト/検索/マーケット） |
| `StockListView.swift` | ウォッチリスト表示 |
| `StockRowView.swift` | 個別銘柄行表示 |
| `StockDetailView.swift` | 銘柄詳細画面 |
| `ChartView.swift` | 価格チャート表示 |
| `SearchView.swift` | 銘柄検索画面 |
| `MarketOverviewView.swift` | マーケット概要画面 |

## 🌐 Yahoo Finance API 統合

### API エンドポイント

#### 1. 株価取得（Chart API）
```
GET https://query1.finance.yahoo.com/v8/finance/chart/{symbol}
```

**パラメータ**:
- `symbol`: 銘柄シンボル（例: AAPL, 7203.T）
- `interval`: データ間隔（1m, 5m, 15m, 1d, 1wk, 1mo）
- `range`: データ範囲（1d, 5d, 1mo, 3mo, 1y, 5y）

**レスポンス例**:
```json
{
  "chart": {
    "result": [{
      "meta": {
        "symbol": "AAPL",
        "regularMarketPrice": 175.43,
        "previousClose": 173.50,
        "currency": "USD",
        "longName": "Apple Inc."
      },
      "timestamp": [1704103200, 1704103500, ...],
      "indicators": {
        "quote": [{
          "close": [175.10, 175.43, ...],
          "volume": [1234567, 2345678, ...]
        }]
      }
    }]
  }
}
```

#### 2. 銘柄検索（Search API）
```
GET https://query2.finance.yahoo.com/v1/finance/search?q={query}
```

**パラメータ**:
- `q`: 検索クエリ（シンボルまたは会社名）

### API制限

- **レート制限**: 2000リクエスト/時間（約33リクエスト/分）
- **登録**: 不要
- **APIキー**: 不要
- **費用**: 完全無料

### キャッシング戦略

`NetworkManager.swift`でキャッシング実装：

- **キャッシュ有効期限**: 5分
- **キャッシュサイズ**: 10MB（約100エントリ）
- **キャッシュキー**: URLの絶対パス
- **実装**: `NSCache`を使用

### レート制限管理

```swift
// NetworkManager.swift: checkRateLimit()
- 1分間のリクエスト数をカウント
- 33リクエスト/分を超えたら自動的に待機
- 待機時間は最大60秒
```

## 📱 主要機能の実装

### 1. ウォッチリスト管理

**保存方法**: UserDefaults（JSON形式）

```swift
// WatchList.swift
func save() {
    if let encoded = try? JSONEncoder().encode(self) {
        UserDefaults.standard.set(encoded, forKey: "AsaStockTrackerWatchList")
    }
}
```

**制限**:
- 最大50銘柄
- お気に入り機能（スター表示）
- スワイプアクション（削除/お気に入り切替）

### 2. 自動更新機能

**更新間隔**: 60秒（カスタマイズ可能）

```swift
// StockViewModel.swift: startAutoUpdate()
private func startAutoUpdate() {
    updateTimer = Timer.scheduledTimer(
        withTimeInterval: Constants.UpdateInterval.standard,  // 60秒
        repeats: true
    ) { _ in
        Task { @MainActor in
            await self.refresh()
        }
    }
}
```

### 3. 並列データ取得

**TaskGroup** を使用して複数銘柄を効率的に取得：

```swift
// YahooFinanceService.swift: fetchQuotes()
await withTaskGroup(of: Stock?.self) { group in
    for symbol in symbols {
        group.addTask {
            try? await self.fetchQuote(for: symbol)
        }
    }
    // 結果を集約
}
```

### 4. チャート表示

**Swift Charts** を使用した価格チャート：

```swift
// ChartView.swift
Chart(chartData) { point in
    LineMark(x: .value("時間", point.date),
             y: .value("価格", point.price))
    AreaMark(x: .value("時間", point.date),
             y: .value("価格", point.price))
        .foregroundStyle(.blue.opacity(0.1))
}
```

## 🔧 設定とカスタマイズ

### Constants.swift

```swift
enum Constants {
    enum API {
        // Yahoo Finance API URL
        static let chartURL = "https://query1.finance.yahoo.com/v8/finance/chart"
        static let searchURL = "https://query2.finance.yahoo.com/v1/finance/search"

        // レート制限
        static let requestsPerMinute = 33

        // キャッシュ設定
        static let cacheExpirationMinutes = 5
    }

    enum UpdateInterval {
        static let standard: TimeInterval = 60  // 1分
        // カスタマイズ可能
    }
}
```

### 銘柄シンボル形式

**米国株**: `AAPL`, `GOOGL`, `MSFT`
**日本株**: `7203.T`, `6758.T` （.T サフィックス）

## 🧪 テスト

### 単体テスト（未実装）

推奨テストケース：

```swift
// StockViewModelTests.swift
@Test("株価取得テスト")
func testFetchStock() async throws {
    let viewModel = StockViewModel()
    await viewModel.fetchStock(symbol: "AAPL")
    #expect(viewModel.stocks.count > 0)
}

// YahooFinanceServiceTests.swift
@Test("Yahoo Finance API統合テスト")
func testFetchQuote() async throws {
    let service = YahooFinanceService.shared
    let stock = try await service.fetchQuote(for: "AAPL")
    #expect(stock.symbol == "AAPL")
    #expect(stock.currentPrice > 0)
}
```

## 🐛 トラブルシューティング

### 問題1: 株価データが取得できない

**原因**:
- ネットワーク接続の問題
- 無効な銘柄シンボル
- Yahoo Finance APIの一時的な障害

**解決策**:
1. ネットワーク接続を確認
2. 銘柄シンボルの形式を確認（米国株: AAPL、日本株: 7203.T）
3. しばらく待ってから再試行

### 問題2: レート制限エラー

**原因**:
- 1分間に33リクエスト以上実行

**解決策**:
- 自動的に60秒待機
- キャッシュが有効な場合はキャッシュから取得

### 問題3: チャートが表示されない

**原因**:
- チャートデータが空
- 日付データの形式エラー

**解決策**:
1. デバッグコンソールでエラーメッセージ確認
2. 異なる時間範囲（range）を試す
3. 銘柄シンボルを変更して再試行

## 📊 パフォーマンス最適化

### 実装済み最適化

1. **キャッシング**: 5分間有効なキャッシュでAPI呼び出しを削減
2. **並列処理**: TaskGroupで複数銘柄を同時取得
3. **レート制限管理**: 自動待機でAPI制限違反を防止
4. **LazyVStack**: 大量データの効率的な表示

### 将来の最適化案

1. **永続化キャッシュ**: Core DataまたはSQLiteでオフラインアクセス
2. **WebSocket**: リアルタイム価格更新
3. **バックグラウンド更新**: Background Fetchで定期更新
4. **画像キャッシュ**: 企業ロゴ表示時の最適化

## 🔮 将来の拡張機能

### Phase 1: 基本機能強化

- [ ] エラーハンドリングUI改善（ErrorBannerView）
- [ ] オフライン対応（Reachability実装）
- [ ] 単体テスト実装（目標カバレッジ: 80%）

### Phase 2: 高度なチャート機能

- [ ] 時間軸切替（1日/1週間/1ヶ月/1年）
- [ ] ローソク足チャート
- [ ] 出来高表示
- [ ] 移動平均線（25日/75日/200日）

### Phase 3: 新機能

- [ ] ニュース機能（Yahoo Finance NEWS_SENTIMENT API）
- [ ] ポートフォリオ管理（保有銘柄・損益計算）
- [ ] アラート機能（目標価格・変動率通知）
- [ ] ウィジェット対応（ホーム画面・ロック画面）

## 🔐 セキュリティとプライバシー

### データ保護

- ユーザーデータはローカルのみ（UserDefaults）
- 外部サーバーへの個人情報送信なし
- Yahoo Finance APIは匿名アクセス

### Info.plist設定

```xml
<!-- NSAppTransportSecurity -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

## 📚 参考資料

### 公式ドキュメント

- [Yahoo Finance API（非公式ドキュメント）](https://www.yahoofinanceapi.com/)
- [Swift Charts ドキュメント](https://developer.apple.com/documentation/charts)
- [SwiftUI ドキュメント](https://developer.apple.com/documentation/swiftui)

### プロジェクト内リソース

- `Docs/BrandGuidelines.md` - ブランドカラーとUIガイドライン
- `Packages/AsaUIKit/` - 共有UIコンポーネントライブラリ
- `README.md` - プロジェクト全体のロードマップ

## 🤝 コントリビューション

このプロジェクトは学習目的で作成されています。改善提案やバグ報告は歓迎します。

### 開発環境

- **Xcode**: 15.0以上
- **iOS**: 17.0以上
- **Swift**: 5.9以上
- **ビルドツール**: XcodeGen

### ビルドコマンド

```bash
# プロジェクト生成
cd Apps/AsaStockTracker
xcodegen generate

# ビルド
xcodebuild -project AsaStockTracker.xcodeproj \
           -scheme AsaStockTracker \
           -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 📝 変更履歴

### v1.0（2025年1月）

- 🎉 **Yahoo Finance API統合**
  - Alpha Vantageから移行
  - 無料・登録不要で実データ取得
  - レート制限: 2000リクエスト/時間

- ✨ **新機能**
  - リアルタイム株価表示
  - ウォッチリスト管理
  - 銘柄検索
  - 価格チャート

- 🐛 **バグ修正**
  - 画面上下の黒い領域を修正（UILaunchScreen追加）
  - Stockモデルにcurrencyフィールド追加

---

**開発者**: Asa Apps
**ライセンス**: 学習目的
**連絡先**: プロジェクトREADMEを参照
