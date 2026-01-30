# AsaBudgetAI 実装計画

**アプリ #84**: 支出パターンをAIで分析する高度な予算管理アプリ

## 概要

AsaSmartTodoのAI分析パターン（6要因重み付けスコアリング）とAsaFamilyBudgetのCharts実装を統合し、上級アプリとして実装します。

### 主要機能
- **AI支出パターン分析**: 異常検知、トレンド予測、節約提案
- **高度なデータ可視化**: トレンドチャート、ヒートマップ、円グラフ
- **スマート予算提案**: 過去データから最適予算を自動提案
- **予算警告通知**: 70%/90%/100%到達時にアラート

---

## プロジェクト構造

```
Apps/AsaBudgetAI/
├── project.yml
├── AsaBudgetAI/
│   ├── AsaBudgetAIApp.swift
│   ├── ContentView.swift
│   │
│   ├── Models/
│   │   ├── Transaction.swift          # 支出/収入（@Model）
│   │   ├── Category.swift             # カテゴリ（@Model）
│   │   ├── Budget.swift               # 月次予算（@Model）
│   │   ├── SpendingPattern.swift      # 支出パターン分析結果
│   │   ├── AIAnalysisResult.swift     # AI分析結果
│   │   ├── UserSettings.swift         # ユーザー設定（@Model）
│   │   └── BudgetAnalytics.swift      # 日次分析データ
│   │
│   ├── Services/
│   │   ├── SpendingPatternAnalyzer.swift     # パターン分析
│   │   ├── SpendingFeatureExtractor.swift    # 特徴量抽出
│   │   ├── AnomalyDetector.swift             # 異常検知（6要因分析）
│   │   ├── BudgetPredictor.swift             # 予算超過予測
│   │   ├── SmartBudgetRecommender.swift      # 予算提案
│   │   ├── EnhancedSpendingAnalyzer.swift    # ハイブリッドAI
│   │   ├── DataService.swift
│   │   └── NotificationService.swift
│   │
│   ├── ViewModels/
│   │   ├── BudgetAIViewModel.swift           # メイン
│   │   ├── AnalyticsViewModel.swift          # 分析
│   │   ├── TransactionViewModel.swift        # 取引管理
│   │   ├── SettingsViewModel.swift           # 設定
│   │   └── AIInsightsViewModel.swift         # AI洞察
│   │
│   ├── Views/
│   │   ├── Dashboard/                        # ダッシュボード
│   │   ├── Transactions/                     # 取引管理
│   │   ├── Analytics/                        # 分析チャート
│   │   ├── AI/                               # AI洞察
│   │   └── Settings/                         # 設定
│   │
│   └── Assets.xcassets/
│
└── AsaBudgetAITests/                         # テスト（95%カバレッジ目標）
```

---

## AI分析エンジン設計

### 6要因重み付けスコアリング（AsaSmartTodo転用）

| 要因 | 重み | 説明 |
|------|------|------|
| カテゴリパターン | 25% | カテゴリ別の通常支出との乖離度 |
| 金額偏差 | 25% | 過去平均からの金額乖離（Zスコア） |
| 時間パターン | 15% | 通常の支出時間帯との乖離 |
| 支出頻度 | 15% | 通常の支出頻度との乖離 |
| 履歴トレンド | 10% | 過去の支出傾向との整合性 |
| 季節変動 | 10% | 季節的な支出パターンの考慮 |

### 異常検知アルゴリズム

```
anomalyScore = Σ(featureScore × weight)

判定基準:
- 0.9以上: 緊急（critical）
- 0.75-0.9: 危険（high）
- 0.6-0.75: 警告（medium）
- 0.6未満: 正常
```

### ハイブリッドAI統合

- **ルールベース分析（40%）**: 常に実行、即時結果
- **LLM意味分析（60%）**: iOS 18+のみ、支出の文脈理解

---

## データモデル設計

### Transaction（支出/収入）
```swift
@Model final class Transaction {
    var id: UUID
    var amount: Double
    var title: String
    var note: String?
    var date: Date
    var typeRawValue: String        // "income" / "expense"
    var isAnomaly: Bool             // AI異常フラグ
    var anomalyScore: Double?       // 異常スコア
    var category: Category?
    var budget: Budget?
}
```

### UserSettings（AI重み設定）
```swift
@Model final class UserSettings {
    // AI分析重み（合計100%）
    var categoryPatternWeight: Double = 0.25
    var amountDeviationWeight: Double = 0.25
    var timePatternWeight: Double = 0.15
    var frequencyWeight: Double = 0.15
    var historicalTrendWeight: Double = 0.10
    var seasonalWeight: Double = 0.10

    // 予算警告設定
    var budgetWarningAt70: Bool = true
    var budgetWarningAt90: Bool = true
    var budgetWarningAt100: Bool = true
}
```

---

## UI画面構成

### TabView（5タブ）
1. **ダッシュボード**: 予算サマリー、AIアラート、最近の取引
2. **取引一覧**: 取引追加/編集/削除、フィルタリング
3. **分析**: トレンドチャート、円グラフ、ヒートマップ
4. **AI洞察**: 異常検知結果、予測、節約提案
5. **設定**: AI重み、通知、カテゴリ管理

### Charts実装（AsaFamilyBudget転用）
- **線グラフ**: 支出トレンド推移
- **棒グラフ**: 月別比較、予算vs実績
- **円グラフ（ドーナツ形）**: カテゴリ別支出分布
- **ヒートマップ**: 曜日×時間帯の支出パターン

---

## テスト戦略

### Unit Tests（120テスト目標）
- SpendingFeatureExtractorTests（20テスト）
- AnomalyDetectorTests（25テスト）
- BudgetPredictorTests（20テスト）
- SmartBudgetRecommenderTests（15テスト）
- ViewModelTests（40テスト）

### Integration Tests
- エンドツーエンド異常検知フロー
- ハイブリッドAI分析統合

---

## 実装フェーズ

| Phase | 内容 | 日数 |
|-------|------|------|
| 1 | 基盤構築（プロジェクト、モデル、DataService） | 2-3日 |
| 2 | 取引管理機能（CRUD、カテゴリ管理） | 2日 |
| 3 | AI分析エンジン（6要因分析、異常検知、予測） | 3-4日 |
| 4 | ハイブリッドAI統合（LLM連携、フォールバック） | 2日 |
| 5 | 分析ダッシュボード（Charts、ヒートマップ） | 2-3日 |
| 6 | AI洞察UI（アラート、予測カード、提案） | 2日 |
| 7 | 設定・通知（重み設定UI、予算警告） | 1-2日 |
| 8 | テスト・ドキュメント | 2日 |

**総見積もり: 16-20日**

---

## 参照ファイル（転用パターン）

| ファイル | 転用内容 |
|----------|----------|
| `AsaSmartTodo/.../TaskPriorityPredictor.swift` | 6要因重み付けスコアリング |
| `AsaSmartTodo/.../EnhancedPriorityPredictor.swift` | ハイブリッドAI（40:60統合） |
| `AsaSmartTodo/.../AIPredictionWeightsView.swift` | 重み設定UI（スライダー） |
| `AsaFamilyBudget/.../Transaction.swift` | Swift Dataモデル設計 |
| `AsaFamilyBudget/.../ExpenseChartView.swift` | Charts.framework実装 |

---

## 検証方法

1. **ビルド確認**: `xcodegen generate && xcodebuild`
2. **テスト実行**: `swift test`（95%カバレッジ）
3. **動作確認**:
   - 取引追加 → 異常検知が動作
   - 月末予算消化率 → 予測が表示
   - AI重み変更 → 分析結果が変化
