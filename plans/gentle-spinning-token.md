# AsaPortfolio アイコン非表示バグ修正計画

## Context

AsaPortfolioアプリで、タブバーの選択中アイコン（ウォッチリスト）やナビゲーションバーのボタンアイコンが透明になり見えない問題が発生。

**根本原因**: アプリに `Assets.xcassets` が存在せず、`Color("AsaCoffeeBrown")` 等の文字列ベースカラー参照が全て失敗し `Color.clear`（透明）を返している。AsaUIKitパッケージは依存関係にあるが、どのファイルでも `import AsaUIKit` されておらず、`AsaColors.coffeeBrown` 等のSwift定数が未使用。

## 修正方針

全10ファイル・70箇所の `Color("Asa...")` を `AsaColors.*` 定数に置換し、`import AsaUIKit` を追加する。

### カラーマッピング

| 変更前 | 変更後 |
|--------|--------|
| `Color("AsaCoffeeBrown")` | `AsaColors.coffeeBrown` |
| `Color("AsaMocha")` | `AsaColors.mocha` |
| `Color("AsaSoftCream")` | `AsaColors.softCream` |
| `Color("AsaDarkSlate")` | `AsaColors.darkSlate` |
| `Color("AsaMutedSage")` | `AsaColors.mutedSage` |

### 対象ファイル（10ファイル・70箇所）

| ファイル | 箇所数 |
|----------|--------|
| `ContentView.swift` | 1 |
| `Views/Dashboard/DashboardView.swift` | 10 |
| `Views/Watchlist/WatchlistView.swift` | 7 |
| `Views/Portfolio/PortfolioListView.swift` | 7 |
| `Views/Analytics/AnalyticsView.swift` | 10 |
| `Views/Holdings/HoldingDetailView.swift` | 6 |
| `Views/Holdings/AddHoldingSheet.swift` | 2 |
| `Views/Charts/AllocationPieChart.swift` | 16 |
| `Views/Charts/PerformanceLineChart.swift` | 8 |
| `Views/Settings/SettingsView.swift` | 3 |

### 作業手順

1. 各ファイルに `import AsaUIKit` を追加
2. `Color("AsaCoffeeBrown")` → `AsaColors.coffeeBrown` に一括置換
3. `Color("AsaMocha")` → `AsaColors.mocha` に一括置換
4. `Color("AsaDarkSlate")` → `AsaColors.darkSlate` に一括置換
5. `Color("AsaMutedSage")` → `AsaColors.mutedSage` に一括置換
6. `Color("AsaSoftCream")` があれば → `AsaColors.softCream` に置換

### 検証

```bash
cd Apps/AsaPortfolio
xcodegen generate
xcodebuild -project AsaPortfolio.xcodeproj -scheme AsaPortfolio \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

- ビルド成功を確認
- `Color("Asa` が残っていないことをgrepで確認
