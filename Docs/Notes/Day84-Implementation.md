# Day 84: AsaBudgetAI - AI予算管理アプリ 実装ノート

## 📱 アプリ概要

**AsaBudgetAI**は、AI技術を活用した高度な家計簿・予算管理アプリです。機械学習ベースの支出パターン分析、異常検知、予算予測機能を搭載し、ユーザーの財務管理をスマートにサポートします。

### 主要機能
- **AI支出パターン分析**: 6要素重み付けスコアリングシステムによる異常検知
- **高度なデータ可視化**: Swift Chartsを使用したトレンド、ヒートマップ、円グラフ
- **スマート予算提案**: 過去データに基づく最適予算推奨
- **予算警告通知**: 70%/90%/100%での段階的アラート
- **ハイブリッドAI分析**: ルールベース(40%) + LLM(60%)

## 🏗️ アーキテクチャ

### MVVMパターン + サービス層

```
AsaBudgetAI/
├── Models/                    # データモデル
│   ├── Transaction.swift      # 取引モデル (@Model)
│   ├── Category.swift         # カテゴリモデル (@Model)
│   ├── Budget.swift           # 予算モデル (@Model)
│   ├── SpendingPattern.swift  # パターン分析結果
│   ├── AIAnalysisResult.swift # AI分析結果
│   ├── UserSettings.swift     # ユーザー設定
│   └── BudgetAnalytics.swift  # 分析データ構造
├── Services/                  # AI分析サービス
│   ├── SpendingFeatureExtractor.swift    # 特徴量抽出
│   ├── AnomalyDetector.swift             # 異常検知
│   ├── BudgetPredictor.swift             # 予算予測
│   ├── SmartBudgetRecommender.swift      # 予算推奨
│   ├── SpendingPatternAnalyzer.swift     # パターン分析
│   ├── EnhancedSpendingAnalyzer.swift    # ハイブリッドAI
│   ├── DataService.swift                 # データ永続化
│   └── NotificationService.swift         # 通知管理
├── ViewModels/               # ビジネスロジック
│   ├── BudgetAIViewModel.swift
│   ├── AnalyticsViewModel.swift
│   ├── TransactionViewModel.swift
│   ├── AIInsightsViewModel.swift
│   └── SettingsViewModel.swift
└── Views/                    # UI層
    ├── ContentView.swift
    ├── Dashboard/DashboardView.swift
    ├── Transactions/
    ├── Analytics/AnalyticsView.swift
    ├── AI/AIInsightsView.swift
    └── Settings/SettingsView.swift
```

## 🧠 AI分析エンジン

### 6要素重み付けスコアリングシステム

AsaSmartTodoで実績のある6要素重み付けシステムを予算管理に適用：

| 要素 | 重み | 説明 |
|------|------|------|
| カテゴリパターン | 25% | カテゴリ別の通常支出との乖離度 |
| 金額偏差 | 25% | 過去平均からの金額乖離（Zスコア） |
| 時間パターン | 15% | 通常の支出時間帯との乖離 |
| 頻度 | 15% | 支出頻度の異常性 |
| 履歴トレンド | 10% | 過去の傾向との比較 |
| 季節性 | 10% | 季節変動との比較 |

### 異常検知アルゴリズム

```swift
// Zスコアベースの異常検知
private func calculateAmountDeviationScore(
    transaction: Transaction,
    historicalData: [Transaction]
) -> Double {
    let zScore = abs(transaction.amount - mean) / stdDev

    if zScore >= 3.0 { return 1.0 }      // 極めて異常
    if zScore >= 2.0 { return 0.7+ }     // 要注意
    if zScore >= 1.0 { return 0.4+ }     // やや異常
    return zScore * 0.4                   // 通常範囲
}
```

### ハイブリッドAI分析

```swift
// ルールベース 40% + LLM 60% のハイブリッド
hybridScore = ruleBasedResult.score * 0.4 + llmResult.score * 0.6
```

- **ルールベース分析**: 常に実行、高速・安定
- **LLM分析**: iOS 18+で利用可能、より自然な洞察生成

## 📊 データ可視化

### Swift Charts活用

1. **月次トレンドチャート**: 収入・支出の推移をLineMark/AreaMarkで表示
2. **カテゴリ別円グラフ**: SectorMarkによる支出内訳
3. **週別ヒートマップ**: RectangleMarkによる曜日×週の支出パターン

```swift
// 週別ヒートマップの実装例
Chart(viewModel.weeklyHeatmapData) { cell in
    RectangleMark(
        x: .value("曜日", cell.dayName),
        y: .value("週", cell.weekNumber)
    )
    .foregroundStyle(by: .value("金額", cell.amount))
}
```

## 🔔 通知システム

### 段階的予算警告

```swift
enum BudgetAlertThreshold: Double {
    case warning = 0.7    // 70%: 注意
    case caution = 0.9    // 90%: 要警戒
    case exceeded = 1.0   // 100%: 超過
}
```

### 異常取引アラート

- リアルタイム異常検知
- 高額支出の即座通知
- パターン外支出の警告

## 🧪 テスト戦略

### Swift Testing採用

34のテストケースを8つのテストスイートで実装：

- **SpendingFeatureExtractorTests**: 特徴量抽出の正確性
- **AnomalyDetectorTests**: 異常検知の精度
- **BudgetPredictorTests**: 予算予測の信頼性
- **SmartBudgetRecommenderTests**: 推奨ロジックの検証
- **AnalysisWeightsTests**: 重み付け計算の正確性
- **SpendingFeaturesTests**: スコア計算の検証
- **BudgetPredictionResultTests**: 結果フォーマットの検証
- **MonthlyBudgetRecommendationTests**: 月次推奨の検証

```swift
@Test("高額支出は金額偏差スコアが高い")
func testHighAmountDeviationScore() {
    let historicalData = (0..<20).map { i in
        createTransaction(amount: 800 + Double(i % 5) * 100)
    }
    let highAmountTransaction = createTransaction(amount: 10000)

    let features = extractor.extractFeatures(...)
    #expect(features.amountDeviationScore >= 0.7)
}
```

## 💡 実装のポイント

### 1. Sendable準拠によるスレッドセーフ

```swift
// 状態を持たないサービスはSendable
final class SpendingFeatureExtractor: Sendable { }

// 可変状態を持つサービスは@unchecked Sendable
final class AnomalyDetector: @unchecked Sendable {
    private var weights: AnalysisWeights
}
```

### 2. Swift Data統合

```swift
@Model
final class Transaction {
    var amount: Double
    var title: String
    var date: Date
    var type: TransactionType
    var category: Category?
    var isAnomaly: Bool
}
```

### 3. 初期化子でのself参照回避

```swift
// ❌ エラー: クロージャがselfをキャプチャ
let variance = amounts.map { pow($0 - self.averageAmount, 2) }

// ✅ 正解: ローカル変数を使用
let average = total / Double(amounts.count)
let variance = amounts.map { pow($0 - average, 2) }
```

## 📱 UI/UX特徴

- **タブベースナビゲーション**: ダッシュボード、取引、分析、AI洞察、設定
- **ブランドカラー統一**: AsaCoffeeBrown, AsaMocha, AsaSoftCream
- **円滑なアニメーション**: 0.2秒のeaseInOut標準
- **アクセシビリティ対応**: VoiceOver、Dynamic Type対応

## 🔧 使用技術

- **SwiftUI + Swift Data**: iOS 17.0+
- **Swift Charts**: データ可視化
- **UserNotifications**: プッシュ通知
- **Foundation Models**: iOS 18+ LLM統合（準備）
- **Swift Testing**: モダンテストフレームワーク
- **AsaUIKit**: 共有UIコンポーネント

## 📈 今後の拡張案

1. **Foundation Models完全統合**: iOS 18リリース後のLLM本格活用
2. **銀行API連携**: 自動取引取り込み
3. **家族共有機能**: CloudKit同期
4. **ウィジェット対応**: ホーム画面に予算状況表示
5. **Apple Watch対応**: 手首から支出入力

## 📝 学びのポイント

1. **統計的異常検知**: Zスコア、標準偏差の実践的活用
2. **重み付けスコアリング**: 複数要素の統合評価手法
3. **ハイブリッドAI設計**: ルールベース+MLの組み合わせ
4. **Swift Chartsマスター**: 複数チャートタイプの活用
5. **Sendable設計**: 並行処理対応のサービス設計

---

**実装日**: 2026年1月29日
**ビルド状態**: ✅ 成功
**テスト状態**: ✅ 34/34 パス
