# Day 75: AsaHealthDashboard - 健康データ統合ダッシュボード

## 概要

**AsaHealthDashboard**は、HealthKitから取得した複数の健康データを統合表示するダッシュボードアプリです。上級レベル（71〜100本目）のアプリとして、複雑なアーキテクチャとHealthKit統合を実装しました。

## スクリーンショット

（実機でのスクリーンショットを追加予定）

## 主要機能

### 1. 統合ダッシュボード
- 歩数、距離、カロリー、運動時間、睡眠データを1画面で確認
- 円形プログレスバーで各指標の達成状況を可視化
- 今日のサマリーと週間ハイライトを表示
- 総合健康スコア（0-100点）の算出

### 2. アクティビティタブ
- Swift Chartsによる棒グラフでデータ推移を表示
- カテゴリ切り替え（歩数/距離/カロリー/運動時間）
- 期間切り替え（日/週/月）
- 統計サマリー（合計、平均、最大、最小）

### 3. 睡眠タブ
- 睡眠時間の推移チャート
- 目標ラインの表示
- 睡眠統計（平均、最長、最短、目標達成日数）

### 4. トレンドタブ
- 各カテゴリのトレンド分析（前期間比）
- 総合健康スコアの表示
- カテゴリ別スコア内訳

### 5. 設定タブ
- 目標設定（スライダーで調整）
- HealthKit権限管理
- データ更新

## 技術スタック

| 技術 | 用途 |
|------|------|
| SwiftUI | UI構築 |
| @Observable | 状態管理（iOS 17+） |
| HealthKit | 健康データ取得 |
| Swift Charts | データ可視化 |
| SwiftData | 目標設定の永続化 |
| AsaUIKit | 共通コンポーネント |

## アーキテクチャ

### MVVM + Protocol-Based Abstraction

```
┌─────────────────────────────────────────────────────────┐
│                       Views                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │Dashboard │ │Activity  │ │Sleep     │ │Settings  │   │
│  │Tab       │ │Tab       │ │Tab       │ │Tab       │   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘   │
│       │            │            │            │          │
│       └────────────┴────────────┴────────────┘          │
│                          │                               │
│                    ┌─────▼─────┐                        │
│                    │ViewModel  │                        │
│                    └─────┬─────┘                        │
└──────────────────────────┼──────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────┐
│                    ┌─────▼─────┐                        │
│                    │Aggregator │                        │
│                    └─────┬─────┘                        │
│                          │                               │
│              ┌───────────┴───────────┐                  │
│              │                       │                  │
│        ┌─────▼─────┐          ┌─────▼─────┐            │
│        │HealthKit  │          │ SwiftData │            │
│        │ Service   │          │  (Goals)  │            │
│        └───────────┘          └───────────┘            │
│                                                         │
│                    Services Layer                       │
└─────────────────────────────────────────────────────────┘
```

### ファイル構成

```
AsaHealthDashboard/
├── AsaHealthDashboardApp.swift      # エントリーポイント
├── Models/
│   ├── HealthCategory.swift         # カテゴリ定義
│   ├── HealthMetric.swift           # メトリクスモデル
│   ├── TimePeriod.swift             # 期間定義
│   ├── HealthGoal.swift             # 目標（SwiftData）
│   └── TrendAnalysis.swift          # トレンド分析
├── Services/
│   ├── HealthDataServiceProtocol.swift  # プロトコル
│   ├── HealthKitService.swift           # HealthKit統合
│   └── HealthDataAggregator.swift       # データ集計
├── ViewModels/
│   ├── HealthDashboardViewModel.swift   # メインVM
│   └── GoalSettingsViewModel.swift      # 目標設定VM
└── Views/
    ├── ContentView.swift                # TabView
    ├── Dashboard/                       # ダッシュボード
    ├── Activity/                        # アクティビティ
    ├── Sleep/                           # 睡眠
    ├── Trend/                           # トレンド
    ├── Settings/                        # 設定
    └── Components/                      # 共通コンポーネント
```

## 実装のポイント

### 1. HealthKit統合

```swift
// 読み取り権限が必要なデータタイプ
private let readTypes: Set<HKObjectType> = [
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
    HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
]

// 非同期でのデータ取得
func fetchStepCount(for date: Date) async -> Double {
    return await withCheckedContinuation { continuation in
        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let stepCount = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            continuation.resume(returning: stepCount)
        }
        healthStore.execute(query)
    }
}
```

### 2. Swift Chartsによる可視化

```swift
Chart(metrics) { metric in
    BarMark(
        x: .value("日付", metric.date, unit: .day),
        y: .value("歩数", metric.value)
    )
    .foregroundStyle(
        LinearGradient(
            colors: [category.color, category.color.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    )
    .cornerRadius(4)

    // 目標ライン
    if let goal = metric.goal {
        RuleMark(y: .value("目標", goal))
            .foregroundStyle(AsaColors.mutedSage)
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
    }
}
```

### 3. トレンド分析

```swift
init(category: HealthCategory, currentValues: [Double], previousValues: [Double]) {
    // 平均値の計算
    self.currentPeriodAverage = currentValues.isEmpty ? 0 :
        currentValues.reduce(0, +) / Double(currentValues.count)
    self.previousPeriodAverage = previousValues.isEmpty ? 0 :
        previousValues.reduce(0, +) / Double(previousValues.count)

    // トレンド判定（±5%をしきい値に）
    let change = ((currentPeriodAverage - previousPeriodAverage) / previousPeriodAverage) * 100
    if change > 5 {
        self.trend = .up
    } else if change < -5 {
        self.trend = .down
    } else {
        self.trend = .stable
    }
}
```

### 4. 総合健康スコア計算

```swift
static func calculate(from metrics: [HealthMetric]) -> HealthScore {
    var breakdown: [HealthCategory: Int] = [:]
    var totalScore = 0
    var categoryCount = 0

    for category in HealthCategory.allCases {
        if let metric = metrics.first(where: { $0.category == category }) {
            let categoryScore = min(Int(metric.progress * 100), 100)
            breakdown[category] = categoryScore
            totalScore += categoryScore
            categoryCount += 1
        }
    }

    let averageScore = categoryCount > 0 ? totalScore / categoryCount : 0
    return HealthScore(score: averageScore, breakdown: breakdown, date: Date())
}
```

## 学習ポイント

### HealthKitの注意点

1. **権限管理の複雑さ**: API層の権限状態と実際のアクセス可能性が異なる場合がある
2. **シミュレータでの制限**: HealthKitはシミュレータでは完全に動作しない
3. **睡眠データ**: Apple Watchが必要

### Protocol-Based Abstraction

テスト容易性のためにプロトコルを定義：

```swift
protocol HealthDataServiceProtocol: AnyObject {
    var isHealthKitAvailable: Bool { get }
    var isAuthorized: Bool { get }
    func requestAuthorization() async
    func fetchStepCount(for date: Date) async -> Double
    // ...
}
```

### SwiftDataとの統合

目標設定をSwiftDataで永続化：

```swift
@Model
final class HealthGoal {
    var id: UUID
    var categoryRawValue: String  // EnumはSwiftData非対応
    var targetValue: Double
    var createdAt: Date
    var updatedAt: Date
}
```

## 今後の改善点

1. **ウィジェット対応**: ホーム画面で健康データを確認
2. **通知機能**: 目標達成時の通知
3. **データエクスポート**: CSVやPDFでのデータ出力
4. **Apple Watch対応**: watchOSアプリの作成

## 参考にした既存アプリ

- [AsaFitnessGoal](../Apps/AsaFitnessGoal/) - HealthKit統合パターン
- [AsaSleepAnalyzer](../Apps/AsaSleepAnalyzer/) - 睡眠データ取得
- [AsaHabitPro](../Apps/AsaHabitPro/) - ダッシュボードUI
- [AsaMoodChart](../Apps/AsaMoodChart/) - Swift Charts実装

## 作成日

2026年1月19日
