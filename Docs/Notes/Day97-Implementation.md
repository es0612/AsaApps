# Day 97 - AsaFinancePlanner（長期資産計画ツール）

## アプリ概要

AsaFinancePlannerは、長期的な資産形成と目標達成を支援するファイナンシャルプランニングアプリです。複利計算エンジン、インフレ調整、ポートフォリオ最適化、退職シミュレーション、AIインサイト生成を統合し、Swift ChartsとSwiftDataを活用した本格的な資産管理ツールです。

## 主な機能

### 5つのタブ画面
1. **ダッシュボード** 📊 - 総資産・月間拠出額・目標進捗・AIインサイト
2. **目標管理** 🎯 - 財務目標のCRUD・進捗追跡・実現可能性分析
3. **資産配分** 📈 - 現在/目標配分の円グラフ・リバランス提案
4. **成長予測** 📉 - 複利シミュレーション・シナリオ比較チャート
5. **設定** ⚙️ - 生体認証・年齢設定・通貨・インフレ率

### 計算エンジン
- **複利計算**: `FV = PV × (1 + r/12)^(12n) + PMT × [((1 + r/12)^(12n) - 1) / (r/12)]`
- **インフレ調整**: 名目値と実質値の同時表示
- **退職計算**: 4%ルール（年間支出 × 25）+ ギャップ分析
- **目標実現可能性**: 確率ベースの実現性判定

### ポートフォリオ管理
- **10種の資産クラス**: 国内株式/海外株式/国内債券/海外債券/不動産/コモディティ/現金/暗号資産/オルタナティブ/その他
- **年齢ベース配分最適化**: 5段階リスク許容度対応
- **リバランス提案**: 乖離5%以上の自動検出（売却/購入/維持）

### AIインサイトエンジン
- 緊急資金不足警告
- 配分乖離アラート
- 目標進捗サジェスション
- マイルストーン達成通知（50%/75%/100%）
- 資産成長レポート

### セキュリティ
- Face ID / Touch ID による生体認証保護

## アーキテクチャ

### パッケージ構成
```
Packages/AsaFinancePlannerKit/
├── Sources/AsaFinancePlannerKit/
│   ├── Errors/          (1ファイル)
│   │   └── FinancePlannerError.swift
│   ├── Models/          (11ファイル)
│   │   ├── FinancialPlan.swift     # @Model: トップレベルエンティティ
│   │   ├── FinancialGoal.swift     # @Model: 財務目標
│   │   ├── GoalCategory.swift      # enum: 8カテゴリ
│   │   ├── Asset.swift             # @Model: 資産
│   │   ├── AssetClass.swift        # enum: 10資産クラス
│   │   ├── AssetAllocation.swift   # struct: 配分データ
│   │   ├── Contribution.swift      # @Model: 拠出金
│   │   ├── Scenario.swift          # @Model: シナリオ
│   │   ├── ProjectionPoint.swift   # struct: 予測データポイント
│   │   ├── FinancialInsight.swift  # struct: AIインサイト
│   │   └── UserSettings.swift      # @Model: ユーザー設定
│   ├── Protocols/       (5ファイル)
│   │   ├── ProjectionCalculating.swift
│   │   ├── AllocationOptimizing.swift
│   │   ├── GoalAnalyzing.swift
│   │   ├── InsightGenerating.swift
│   │   └── FinanceDataServiceProtocol.swift
│   ├── Services/        (8ファイル)
│   │   ├── CompoundInterestCalculator.swift
│   │   ├── InflationAdjuster.swift
│   │   ├── GoalFeasibilityAnalyzer.swift
│   │   ├── AllocationOptimizer.swift
│   │   ├── RetirementCalculator.swift
│   │   ├── InsightEngine.swift
│   │   ├── BiometricAuthService.swift
│   │   └── FinanceDataService.swift
│   └── ViewModels/      (6ファイル)
│       ├── DashboardViewModel.swift
│       ├── GoalViewModel.swift
│       ├── AllocationViewModel.swift
│       ├── ProjectionViewModel.swift
│       ├── ReportViewModel.swift
│       └── SettingsViewModel.swift
└── Tests/               (16ファイル)
    ├── Models/           (4テスト)
    ├── Services/         (7テスト)
    └── ViewModels/       (5テスト + MockServices)

Apps/AsaFinancePlanner/
├── project.yml
├── Sources/
│   ├── AsaFinancePlannerApp.swift
│   ├── ContentView.swift
│   └── Views/
│       ├── Components/   (3ファイル)
│       │   ├── CurrencyTextField.swift
│       │   ├── PercentageSlider.swift
│       │   └── InsightCard.swift
│       ├── Charts/       (4ファイル)
│       │   ├── AllocationPieChart.swift    # SectorMark ドーナツチャート
│       │   ├── GrowthProjectionChart.swift # AreaMark + LineMark
│       │   ├── GoalProgressChart.swift     # BarMark 水平バー
│       │   └── ScenarioLineChart.swift     # 複数LineMark比較
│       ├── Dashboard/    (2ファイル)
│       │   ├── DashboardView.swift
│       │   └── GoalSummaryCard.swift
│       ├── Goals/        (3ファイル)
│       │   ├── GoalListView.swift
│       │   ├── GoalDetailView.swift
│       │   └── GoalFormSheet.swift
│       ├── Allocation/   (2ファイル)
│       │   ├── AllocationView.swift
│       │   └── RebalanceSheet.swift
│       ├── Projection/   (2ファイル)
│       │   ├── ProjectionView.swift
│       │   └── ScenarioComparisonView.swift
│       └── Settings/     (1ファイル)
│           └── SettingsView.swift
└── AsaFinancePlannerTests/
    └── AsaFinancePlannerTests.swift
```

### 技術スタック
- **SwiftUI**: 宣言的UI
- **SwiftData**: `@Model` によるデータ永続化（6つのモデルエンティティ）
- **Swift Charts**: 4種類のチャート（SectorMark/AreaMark/LineMark/BarMark）
- **LocalAuthentication**: Face ID / Touch ID
- **Decimal型**: 全ての金額計算に使用（精度保証）
- **Swift Testing**: 114テスト（@Test構文）
- **AsaUIKit**: ブランドカラー・共有UIコンポーネント
- **iOS 18.0+**: デプロイメントターゲット
- **swift-tools-version 6.0**: Swift 6対応

## 実装の特徴

### Decimal型による精度保証
金融計算では浮動小数点の誤差が致命的になるため、全ての金額をDecimal型で管理。pow()関数が必要な複利計算のみDouble経由で変換するアプローチを採用。

```swift
// CompoundInterestCalculator
let r = NSDecimalNumber(decimal: annualRate).doubleValue / 12.0
let n = Double(years * 12)
let futureValue = pow(1 + r, n) * pvDouble + pmt * ((pow(1 + r, n) - 1) / r)
return Decimal(futureValue)  // Decimal に戻す
```

### SwiftData enum rawValue パターン
SwiftDataの`@Model`はenumを直接保存できないため、rawValue Stringと計算プロパティの組み合わせで解決。

```swift
@Model final class FinancialGoal {
    var categoryRawValue: String = GoalCategory.other.rawValue
    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}
```

### プロトコル駆動のテスタビリティ
全サービスをプロトコル化し、MockServicesによるViewModel単体テストを実現。

```swift
// MockProjectionCalculator で CompoundInterestCalculator をモック
struct MockProjectionCalculator: ProjectionCalculating, Sendable { ... }
```

### 年齢ベース資産配分アルゴリズム
年齢に応じた自動配分調整。若年層はリスク資産多め、高齢層は安定資産多め。

```swift
let ageAdjustment = Decimal(max(0, min(40, age - 25))) / 40
// 株式比率 = baseEquityRatio × (1 - ageAdjustment × 0.5)
```

## テスト結果

```
114 tests in 16 suites passed
├── Models/           20 tests  ✅
├── Services/         56 tests  ✅
└── ViewModels/       38 tests  ✅
```

### 主要テストケース
- **複利計算精度**: 月5万円 × 年5% × 30年 ≈ 41,612,932円（±1%以内）
- **インフレ調整**: 1000万円 × 2% × 10年 = 8,203,483円（実質値）
- **退職計算**: 4%ルール検証（月30万円 → 必要額9,000万円）
- **SwiftData CRUD**: inMemory ModelContainerによる統合テスト

## 使用したSwiftUI機能

| 機能 | 用途 |
|------|------|
| `Chart` + `SectorMark` | 資産配分ドーナツチャート |
| `Chart` + `AreaMark` + `LineMark` | 成長予測グラフ |
| `Chart` + `BarMark` | 目標進捗バーチャート |
| `@Model` + `@Relationship` | SwiftDataエンティティ関連 |
| `NavigationStack` + `TabView` | 5タブナビゲーション |
| `Form` + `Stepper` + `Picker` | 設定画面 |
| `Sheet` | 追加/編集フォーム |
| `.swipeActions` | スワイプ削除 |
| `.refreshable` | プルトゥリフレッシュ |
| `LazyVGrid` | レジェンドレイアウト |
| `LocalAuthentication` | 生体認証 |

## ファイル数
- **パッケージ（AsaFinancePlannerKit）**: 47ファイル（ソース31 + テスト16）
- **アプリ（AsaFinancePlanner）**: 21ファイル
- **合計**: 68 Swiftファイル + project.yml + Assets

## 学んだこと

1. **Decimal vs Double**: 金融計算ではDecimalが必須。pow()関数との橋渡しにはNSDecimalNumberを使用
2. **SwiftData + enum**: rawValueパターンで永続化する設計パターンの確立
3. **Swift Charts多彩な表現**: SectorMark（円）、AreaMark（面積）、LineMark（折れ線）、BarMark（棒）の使い分け
4. **プロトコル駆動テスト**: Mock化による114テストの高速実行
5. **年齢ベースアルゴリズム**: ファイナンシャルプランニングのドメイン知識の実装
