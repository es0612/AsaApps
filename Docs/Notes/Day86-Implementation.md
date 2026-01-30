# Day 86: AsaFitnessCoach 実装

## 概要

**AsaFitnessCoach**は、AIで個人に最適化された運動プランを提案するフィットネスコーチアプリです。

### コンセプト
- 「AIがあなた専属のパーソナルトレーナーに」
- ユーザーの目標・体力レベル・過去の実績を分析し、最適なワークアウトを提案
- プログレッシブオーバーロードで継続的な成長をサポート

## 技術スタック

| 技術 | 用途 |
|------|------|
| **SwiftUI** | UI構築 |
| **@Observable** | 状態管理（MVVMパターン） |
| **Swift Data** | データ永続化 |
| **HealthKit** | 歩数・カロリー・運動時間取得 |
| **Charts.framework** | 進捗グラフ表示 |
| **Swift Testing** | @Test構文によるユニットテスト |

## 主要機能

### 1. AI運動プラン提案（6要因スコアリング）

独自の6要因重み付けスコアリングエンジンを実装：

```swift
struct PlanWeights {
    var goalAlignment: Double      // 目標との適合度（25%）
    var fitnessLevel: Double       // 体力レベル適合（20%）
    var equipmentMatch: Double     // 利用可能機器（15%）
    var timeConstraint: Double     // 時間制約（15%）
    var recoveryStatus: Double     // 回復状態（15%）
    var progressionRate: Double    // 進捗ペース（10%）
}
```

各エクササイズに対してスコアを計算し、最適なプランを生成します。

### 2. プログレッシブオーバーロード

過去のワークアウト実績から負荷増加を自動提案：
- 完了率95%以上 + フォーム良好 → 5%増加
- 完了率90%以上 → 2.5%増加
- 2.5kg単位で丸め処理

### 3. ワークアウト実行

- タイマー付きのガイド付きワークアウト
- セット間の休憩タイマー
- リアルタイムの進捗表示
- 完了後の評価・RPE記録

### 4. 進捗トラッキング

- HealthKit連携（歩数・カロリー・運動時間）
- 週間/月間のトレンドチャート
- ワークアウトストリーク表示
- AI洞察（頻度・時間・モチベーション分析）

## ファイル構成

```
Apps/AsaFitnessCoach/
├── project.yml
├── AsaFitnessCoach/
│   ├── AsaFitnessCoachApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── UserProfile.swift           # ユーザープロファイル
│   │   ├── Exercise.swift               # エクササイズ定義
│   │   ├── WorkoutPlan.swift            # 運動プラン
│   │   ├── WorkoutSession.swift         # セッション実績
│   │   ├── AIRecommendation.swift       # AI提案結果
│   │   └── PresetExercises.swift        # プリセットエクササイズ
│   ├── ViewModels/
│   │   ├── FitnessCoachViewModel.swift  # メインViewModel
│   │   ├── WorkoutViewModel.swift       # ワークアウト実行
│   │   └── ProgressViewModel.swift      # 進捗分析
│   ├── Views/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── TodayWorkoutCard.swift
│   │   ├── Plan/
│   │   │   ├── PlanListView.swift
│   │   │   ├── PlanDetailView.swift
│   │   │   └── CreatePlanView.swift
│   │   ├── Workout/
│   │   │   ├── WorkoutSessionView.swift
│   │   │   ├── RestTimerView.swift
│   │   │   └── WorkoutCompletionView.swift
│   │   ├── Progress/
│   │   │   └── ProgressDashboardView.swift
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift
│   │   │   └── OnboardingView.swift
│   │   └── Components/
│   │       └── AIRecommendationCard.swift
│   └── Services/
│       ├── DataService.swift            # Swift Data操作
│       ├── HealthKitService.swift       # HealthKit連携
│       ├── WorkoutPlanGenerator.swift   # AI運動プラン生成
│       └── ProgressiveOverloadService.swift
└── AsaFitnessCoachTests/
    ├── Models/
    │   └── ModelTests.swift
    └── Services/
        ├── WorkoutPlanGeneratorTests.swift
        └── ProgressiveOverloadServiceTests.swift
```

## AI運動プラン生成アルゴリズム

### スコアリングフロー

1. **利用可能なエクササイズのフィルタリング**
   - 体力レベルに合わない高難度エクササイズを除外
   - 利用不可能な器具が必要なエクササイズを除外

2. **6要因スコアリング**
   - 各要因について0.0〜1.0のスコアを計算
   - 重み付けで総合スコアを算出

3. **エクササイズ選択**
   - スコア上位からカテゴリの多様性を考慮して選択
   - 目標時間内に収まるよう調整

4. **信頼度計算**
   - スコアの平均値
   - スコアの一貫性（標準偏差が小さいほど高い）
   - データ量ボーナス

### 各要因の計算方法

| 要因 | 計算方法 |
|------|---------|
| 目標適合度 | ユーザー目標の推奨カテゴリとエクササイズカテゴリの一致度 |
| 体力レベル | エクササイズ難易度とユーザーレベルの差 |
| 機器適合 | 必要器具の利用可能率 |
| 時間制約 | エクササイズ時間/目標時間の比率 |
| 回復状態 | 筋肉グループ別の最終トレーニングからの経過時間 |
| 進捗ペース | 過去セッションの完了率平均 |

## HealthKit連携

### 取得するデータ
- 歩数（stepCount）
- 距離（distanceWalkingRunning）
- 消費カロリー（activeEnergyBurned）
- 運動時間（appleExerciseTime）
- 心拍数（heartRate）
- ワークアウト回数（workoutType）

### 権限管理
- 5分キャッシュで権限状態を保持
- 実際のデータアクセステストで権限確認
- グレースフルデグラデーション（未連携時は手動記録）

## テスト

### 実装したテスト（50テスト）

#### WorkoutPlanGeneratorTests
- 初心者/上級者向けプラン生成
- 信頼度スコア範囲検証
- 6要因の含有確認
- 推定時間の妥当性
- 器具フィルタリング
- 目標別エクササイズ提案
- カスタム重みによる結果変化

#### ProgressiveOverloadServiceTests
- セッションなし/対象なしの処理
- 高/低完了率での提案
- 信頼度レベル判定
- 2.5kg単位の丸め処理
- 複数エクササイズ対応

#### ModelTests
- BMI計算・カテゴリ判定
- 年齢計算
- 総ボリューム計算
- 時間ベースエクササイズ判定
- プラン複製
- セッション時間・完了率計算

## 学んだこと

### 1. AIスコアリングの設計

6要因重み付けスコアリングは、AsaSmartTodoやAsaBudgetAIで培ったパターンをフィットネス領域に応用しました。各要因の重みは経験則とユーザビリティテストで調整可能です。

### 2. 筋肉グループの回復時間

大きな筋肉群（大臀筋、大腿四頭筋）は72時間、小さな筋肉群（上腕二頭筋）は24時間と、実際のスポーツ科学に基づいた回復時間を設定しました。

### 3. プログレッシブオーバーロード

2.5kg単位の丸めは、実際のジムで使用されるプレート重量に基づいています。これにより、提案された重量をそのまま実践できます。

## 今後の改善点

1. **Foundation Models統合**（iOS 18+）
   - 自然言語でのワークアウト指示
   - より詳細なフォームフィードバック

2. **Apple Watch連携**
   - ワークアウト中のリアルタイム心拍数表示
   - 休憩タイマーの haptic フィードバック

3. **ソーシャル機能**
   - 友達とのワークアウト共有
   - チャレンジ機能

## スクリーンショット

（実機ビルド後に追加予定）

## ビルド方法

```bash
cd Apps/AsaFitnessCoach
xcodegen generate
open AsaFitnessCoach.xcodeproj
# Cmd+B でビルド
```

## 関連アプリ

- **AsaWorkoutPlanner**（Day 65）: ワークアウトプラン管理
- **AsaFitnessGoal**（Day 45）: フィットネス目標トラッキング
- **AsaSmartTodo**（Day 72）: AIタスク優先度予測
- **AsaBudgetAI**（Day 78）: AI予算分析
