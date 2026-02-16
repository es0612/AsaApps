# AsaFinancePlanner (#97) 実装計画 - 長期資産計画ツール

## Context

100本ノックの97番目アプリ。上級レベル（71-100）として、SwiftData + Swift Charts + 複利計算エンジン + ルールベースAIインサイトを統合した本格的な資産計画ツールを設計する。AsaPortfolio(#90)の金融モデルパターン、AsaBudgetAI(#84)のAI分析パターン、AsaEduGame(#96)の最新パッケージ構造を組み合わせた集大成アプリ。

---

## 技術スタック

| 技術 | 用途 | 選定理由 |
|------|------|----------|
| SwiftUI | UI構築 | プロジェクト標準 |
| SwiftData | データ永続化 | @Model + Relationship、iOS 18+ |
| Swift Charts | グラフ描画 | SectorMark, LineMark, AreaMark |
| LocalAuthentication | 生体認証 | Face ID/Touch ID |
| Decimal型 | 全金額計算 | 浮動小数点誤差回避（Double不使用） |
| Swift Testing | テスト | @Test, #expect（プロジェクト標準） |
| AsaUIKit | 共有UI | AsaButton, AsaCard, ブランドカラー |
| iOS 18.0 | ターゲット | 最新Charts + SwiftData API |
| swift-tools-version: 6.0 | パッケージ | Swift Concurrency完全対応 |

**非採用**: FinanceKit（米国のみ対応、日本未対応のため）

---

## アーキテクチャ（ファイル構造）

```
Apps/AsaFinancePlanner/
├── project.yml
├── Sources/
│   ├── AsaFinancePlannerApp.swift        # @main エントリポイント
│   ├── ContentView.swift                 # TabView（Dashboard/Goals/Allocation/Projection/Settings）
│   ├── Assets.xcassets/
│   └── Views/
│       ├── Dashboard/
│       │   ├── DashboardView.swift       # 総資産、ゴール進捗、インサイト表示
│       │   └── GoalSummaryCard.swift     # ゴール進捗カード
│       ├── Goals/
│       │   ├── GoalListView.swift        # ゴール一覧（カテゴリアイコン、進捗バー）
│       │   ├── GoalDetailView.swift      # ゴール詳細＋達成可能性分析
│       │   └── GoalFormSheet.swift       # ゴール追加/編集シート
│       ├── Allocation/
│       │   ├── AllocationView.swift      # パイチャート＋目標vs現在配分
│       │   └── RebalanceSheet.swift      # リバランス提案
│       ├── Projection/
│       │   ├── ProjectionView.swift      # 成長予測チャート（AreaMark）
│       │   └── ScenarioComparisonView.swift  # 3シナリオ比較（LineMark）
│       ├── Charts/
│       │   ├── GrowthProjectionChart.swift   # 名目/実質成長AreaChart
│       │   ├── AllocationPieChart.swift       # 資産配分SectorMark
│       │   ├── GoalProgressChart.swift        # ゴール進捗BarMark
│       │   └── ScenarioLineChart.swift        # シナリオ比較LineMark
│       ├── Settings/
│       │   └── SettingsView.swift        # 認証、通貨、年齢、インフレ率
│       └── Components/
│           ├── CurrencyTextField.swift    # Decimal入力フィールド
│           ├── PercentageSlider.swift     # %スライダー
│           └── InsightCard.swift          # インサイト表示カード
├── AsaFinancePlannerTests/
│   └── AsaFinancePlannerTests.swift
└── AsaFinancePlannerUITests/
    └── AsaFinancePlannerUITests.swift

Packages/AsaFinancePlannerKit/
├── Package.swift
├── Sources/AsaFinancePlannerKit/
│   ├── Errors/
│   │   └── FinancePlannerError.swift
│   ├── Models/           # 11ファイル
│   │   ├── FinancialPlan.swift       # @Model: 最上位エンティティ（goals, assets, contributions, scenarios）
│   │   ├── FinancialGoal.swift       # @Model: 目標（退職/教育/住宅等）
│   │   ├── GoalCategory.swift        # enum: 8カテゴリ（retirement, education, housing...）
│   │   ├── Asset.swift               # @Model: 保有資産
│   │   ├── AssetClass.swift          # enum: 10クラス（国内株式, 海外株式, 債券, REIT, 現金...）
│   │   ├── AssetAllocation.swift     # struct: 配分比率（目標vs現在）
│   │   ├── Contribution.swift        # @Model: 積立設定（月額、資産クラス）
│   │   ├── Scenario.swift            # @Model: シミュレーション条件（リターン率、インフレ率、年数）
│   │   ├── ProjectionPoint.swift     # struct: チャート用時系列データ
│   │   ├── FinancialInsight.swift    # struct: AIインサイト（warning/suggestion/achievement）
│   │   └── UserSettings.swift        # @Model: 設定（通貨、年齢、認証、インフレ率）
│   ├── Protocols/         # 5ファイル
│   │   ├── FinanceDataServiceProtocol.swift   # CRUD操作インターフェース
│   │   ├── ProjectionCalculating.swift        # 複利計算インターフェース
│   │   ├── AllocationOptimizing.swift         # 配分最適化インターフェース
│   │   ├── GoalAnalyzing.swift                # 達成可能性分析インターフェース
│   │   └── InsightGenerating.swift            # インサイト生成インターフェース
│   ├── Services/          # 8ファイル
│   │   ├── FinanceDataService.swift           # SwiftData CRUD（Protocol準拠）
│   │   ├── CompoundInterestCalculator.swift   # 複利計算エンジン（核心）
│   │   ├── InflationAdjuster.swift            # インフレ調整
│   │   ├── GoalFeasibilityAnalyzer.swift      # ゴール達成可能性分析
│   │   ├── AllocationOptimizer.swift          # 配分最適化＋リバランス提案
│   │   ├── RetirementCalculator.swift         # 退職資金計算（4%ルール等）
│   │   ├── InsightEngine.swift                # ルールベースAIインサイト生成
│   │   └── BiometricAuthService.swift         # Face ID/Touch ID認証
│   └── ViewModels/        # 6ファイル
│       ├── DashboardViewModel.swift           # 総資産、トップゴール、インサイト
│       ├── GoalViewModel.swift                # ゴールCRUD＋達成可能性
│       ├── AllocationViewModel.swift          # 配分計算＋リバランス
│       ├── ProjectionViewModel.swift          # シナリオ管理＋チャートデータ
│       ├── ReportViewModel.swift              # レポート生成
│       └── SettingsViewModel.swift            # 設定管理＋生体認証
└── Tests/AsaFinancePlannerKitTests/  # 16ファイル
    ├── Models/
    │   ├── FinancialPlanTests.swift
    │   ├── FinancialGoalTests.swift
    │   ├── AssetAllocationTests.swift
    │   └── ScenarioTests.swift
    ├── Services/
    │   ├── CompoundInterestCalculatorTests.swift   # 最重要: 既知の値との精度検証
    │   ├── InflationAdjusterTests.swift
    │   ├── GoalFeasibilityAnalyzerTests.swift
    │   ├── AllocationOptimizerTests.swift
    │   ├── RetirementCalculatorTests.swift
    │   ├── InsightEngineTests.swift
    │   └── FinanceDataServiceTests.swift           # inMemory SwiftData
    └── ViewModels/
        ├── DashboardViewModelTests.swift
        ├── GoalViewModelTests.swift
        ├── AllocationViewModelTests.swift
        ├── ProjectionViewModelTests.swift
        └── ReportViewModelTests.swift
```

**ファイル数**: パッケージ30 + アプリUI18 + テスト16 + 設定3 = **約67ファイル**

---

## 主要データモデル

### FinancialPlan（最上位エンティティ）
```swift
@Model public final class FinancialPlan {
    public var id: UUID = UUID()
    public var name: String = ""
    public var currencyCode: String = "JPY"
    public var isActive: Bool = true
    @Relationship(deleteRule: .cascade, inverse: \FinancialGoal.plan)
    public var goals: [FinancialGoal] = []
    @Relationship(deleteRule: .cascade, inverse: \Asset.plan)
    public var assets: [Asset] = []
    @Relationship(deleteRule: .cascade, inverse: \Contribution.plan)
    public var contributions: [Contribution] = []
    @Relationship(deleteRule: .cascade, inverse: \Scenario.plan)
    public var scenarios: [Scenario] = []
    // computed: totalAssetValue, monthlyContributionTotal, averageGoalProgress
}
```

### FinancialGoal
```swift
@Model public final class FinancialGoal {
    public var id: UUID = UUID()
    public var name: String = ""
    public var categoryRawValue: String = "retirement"  // GoalCategory.rawValue
    public var targetAmount: Decimal = .zero
    public var currentAmount: Decimal = .zero
    public var targetDate: Date = Date()
    public var plan: FinancialPlan?
    // computed: progressPercentage, remainingAmount, remainingMonths, requiredMonthlyContribution
}
```

### GoalCategory（8カテゴリ）
退職・老後 / 教育費 / 住宅購入 / 緊急資金 / 旅行 / 車両購入 / 投資目標 / その他

### AssetClass（10クラス）
国内株式 / 海外株式 / 国内債券 / 海外債券 / REIT / 現金・預金 / 金・コモディティ / 暗号資産 / 保険 / その他
※各クラスにデフォルト期待リターン率・リスク値を定義

### Scenario（シミュレーション条件）
```swift
@Model public final class Scenario {
    public var annualReturnRate: Decimal  // 年間リターン率(%)
    public var inflationRate: Decimal     // インフレ率(%)
    public var projectionYears: Int       // 予測年数
    // computed: realReturnRate (= annualReturnRate - inflationRate)
}
```

**重要**: 全金額は`Decimal`型。`Double`は表示用パーセンテージ変換のみ。

---

## 計算エンジン（Services層の核心）

### CompoundInterestCalculator
```
FV = PV × (1 + r/12)^(12n) + PMT × [((1 + r/12)^(12n) - 1) / (r/12)]
```
- `calculateFutureValue()`: 複利による将来価値算出
- `generateProjection()`: 年次の時系列ProjectionPoint配列を生成（名目値 + 実質値）

### GoalFeasibilityAnalyzer
- インフレ調整後の目標額と予測到達額を比較
- 0.0〜1.0の達成可能性スコアを算出
- 不足額から必要月額追加積立を逆算
- インサイトメッセージ生成

### AllocationOptimizer
- 現在の資産配分を計算
- 年齢・リスク許容度に基づくモデル配分を提供（保守的/バランス/積極的）
- 目標配分との乖離5%以上でリバランス提案（買い/売り/維持）

### RetirementCalculator
- 4%ルールに基づく必要退職資金算出
- 年金収入考慮のギャップ分析

### InsightEngine（ルールベースAI）
- 緊急資金不足警告（生活費6ヶ月未満）
- 配分偏り検出（目標配分との乖離）
- ゴール未達リスクアラート
- 積立増額提案
- マイルストーン達成通知

---

## 画面設計（5タブ構成）

| タブ | 画面 | 主要コンテンツ |
|------|------|---------------|
| Dashboard | DashboardView | 総資産額、月間積立額、トップ3ゴール進捗、インサイトカード |
| Goals | GoalListView → GoalDetailView | ゴール一覧（進捗バー）、詳細（達成可能性分析）、追加/編集シート |
| Allocation | AllocationView | パイチャート（現在vs目標）、リバランス提案シート |
| Projection | ProjectionView | 成長予測AreaChart、3シナリオ比較LineMark、スライダー操作 |
| Settings | SettingsView | 生体認証ON/OFF、通貨、年齢/退職年齢、デフォルトインフレ率 |

---

## 再利用する既存パターン・ファイル

| パターン | 参照元 | ファイル |
|----------|--------|---------|
| Package.swift構造 | AsaEduGameKit | `Packages/AsaEduGameKit/Package.swift` |
| project.yml構造 | AsaEduGame | `Apps/AsaEduGame/project.yml` |
| 金融計算Decimal | AsaPortfolio | `Apps/AsaPortfolio/.../PerformanceCalculator.swift` |
| パイチャート（SectorMark） | AsaPortfolio | `Apps/AsaPortfolio/.../AllocationPieChart.swift` |
| AI分析サービス構成 | AsaBudgetAI | `Apps/AsaBudgetAI/.../BudgetPredictor.swift` 等 |
| SwiftData DataService | AsaEduGame | `Packages/AsaEduGameKit/.../EduGameDataService.swift` |
| ViewModel パターン | 全アプリ共通 | `@MainActor @Observable` + DI + MARK区分 |

---

## 実装フェーズ

### Phase 1: 基盤層（Models + Package構造）
1. `Packages/AsaFinancePlannerKit/Package.swift` 作成
2. 全11モデル + エラー定義 + 全5プロトコル
3. モデルの単体テスト（4ファイル）
4. `swift build` でコンパイル確認

### Phase 2: 計算エンジン + サービス
1. CompoundInterestCalculator + テスト（既知の値で精度検証）
2. InflationAdjuster + テスト
3. GoalFeasibilityAnalyzer + テスト
4. AllocationOptimizer + テスト
5. RetirementCalculator + テスト
6. InsightEngine + テスト
7. BiometricAuthService
8. FinanceDataService + テスト（inMemory SwiftData）
9. `swift test` で全テスト通過確認

### Phase 3: ViewModel + 状態管理
1. 6つのViewModel実装（DI + @MainActor @Observable）
2. MockサービスクラスをProtocol準拠で作成
3. ViewModelテスト（5ファイル）
4. `swift test` で全テスト通過確認

### Phase 4: UI実装
1. `Apps/AsaFinancePlanner/project.yml` 作成 + `xcodegen generate`
2. AsaFinancePlannerApp.swift + ContentView.swift（TabView）
3. Dashboard画面（GoalSummaryCard, InsightCard）
4. Goals画面群（一覧、詳細、フォーム）
5. Allocation画面（パイチャート、リバランスシート）
6. Projection画面（成長予測チャート、シナリオ比較）
7. Settings画面
8. 共通コンポーネント（CurrencyTextField, PercentageSlider）
9. `xcodebuild -sdk iphonesimulator build` で成功確認

### Phase 5: 統合テスト + 仕上げ
1. 全テスト実行・カバレッジ95%+確認
2. ブランドガイドライン確認（AsaColors統一）
3. アクセシビリティ対応（VoiceOver, Dynamic Type）
4. ドキュメント作成 `Docs/Notes/Day97-Implementation.md`
5. 最終ビルド確認 + git commit

---

## project.yml
```yaml
name: AsaFinancePlanner
options:
  bundleIdPrefix: com.asapapa.apps
  deploymentTarget:
    iOS: "18.0"
  createIntermediateGroups: true
  generateEmptyDirectories: true
settings:
  MARKETING_VERSION: "1.0"
  CURRENT_PROJECT_VERSION: "1"
  DEVELOPMENT_TEAM: ""
  CODE_SIGN_STYLE: Automatic
packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit
  AsaFinancePlannerKit:
    path: ../../Packages/AsaFinancePlannerKit
targets:
  AsaFinancePlanner:
    type: application
    platform: iOS
    sources: [Sources]
    resources: [Sources/Assets.xcassets]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.asapapa.apps.asafinanceplanner
      GENERATE_INFOPLIST_FILE: true
      INFOPLIST_KEY_UIApplicationSceneManifest_Generation: true
      INFOPLIST_KEY_UILaunchScreen_Generation: true
      INFOPLIST_KEY_CFBundleDisplayName: "AsaFinancePlanner"
      INFOPLIST_KEY_LSApplicationCategoryType: "public.app-category.finance"
      INFOPLIST_KEY_NSFaceIDUsageDescription: "資産データを保護するためにFace IDを使用します"
      SWIFT_STRICT_CONCURRENCY: complete
    dependencies:
      - package: AsaUIKit
        product: AsaUIKit
      - package: AsaFinancePlannerKit
        product: AsaFinancePlannerKit
  AsaFinancePlannerTests:
    type: bundle.unit-test
    platform: iOS
    sources: [AsaFinancePlannerTests]
    settings:
      GENERATE_INFOPLIST_FILE: true
    dependencies:
      - target: AsaFinancePlanner
  AsaFinancePlannerUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [AsaFinancePlannerUITests]
    settings:
      GENERATE_INFOPLIST_FILE: true
    dependencies:
      - target: AsaFinancePlanner
```

---

## 検証方法

1. **パッケージビルド**: `cd Packages/AsaFinancePlannerKit && swift build`
2. **パッケージテスト**: `cd Packages/AsaFinancePlannerKit && swift test`（全16テストファイル通過）
3. **Xcode生成**: `cd Apps/AsaFinancePlanner && xcodegen generate`
4. **アプリビルド**: `xcodebuild -project AsaFinancePlanner.xcodeproj -scheme AsaFinancePlanner -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
5. **複利計算精度**: 既知の値（月5万円×年利5%×30年 ≈ 4161万円）との差が1%以内
6. **全テスト**: `xcodebuild test -project AsaFinancePlanner.xcodeproj -scheme AsaFinancePlannerTests -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
