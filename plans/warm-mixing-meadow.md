# AsaFitnessCoach 実装計画

## 概要

**AsaFitnessCoach**（アプリ #86）は、AIで個人に最適化された運動プランを提案するフィットネスコーチアプリです。

### コンセプト
- 「AIがあなた専属のパーソナルトレーナーに」
- ユーザーの目標・体力レベル・過去の実績を分析し、最適なワークアウトを提案
- プログレッシブオーバーロードで継続的な成長をサポート

---

## 主要機能

| 機能 | 説明 |
|------|------|
| **AI運動プラン提案** | 6要因分析で最適なワークアウトを提案 |
| **パーソナライズ設定** | 目標・体力レベル・利用可能機器・時間を設定 |
| **ワークアウト実行** | タイマー付きのガイド付きワークアウト |
| **進捗トラッキング** | HealthKit連携 + 手動記録の統合 |
| **プログレッシブオーバーロード** | 過去実績から負荷増加を自動提案 |
| **週間プランニング** | 曜日別の運動スケジュール管理 |
| **成果分析** | 週間/月間の進捗グラフとAI洞察 |

---

## 技術スタック

- **UI**: SwiftUI + AsaUIKit（共有コンポーネント）
- **状態管理**: @Observable + @MainActor
- **データ永続化**: Swift Data
- **ヘルスデータ**: HealthKit（歩数・カロリー・ワークアウト）
- **AI予測**: 6要因重み付けスコアリング + Foundation Models（iOS 18+）
- **グラフ**: Charts.framework
- **テスト**: Swift Testing（@Test構文）

---

## ディレクトリ構造

```
Apps/AsaFitnessCoach/
├── project.yml
├── AsaFitnessCoach/
│   ├── AsaFitnessCoachApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── UserProfile.swift           # ユーザープロファイル
│   │   ├── FitnessGoal.swift            # 目標設定
│   │   ├── WorkoutPlan.swift            # 運動プラン
│   │   ├── Exercise.swift               # エクササイズ定義
│   │   ├── WorkoutSession.swift         # セッション実績
│   │   ├── ProgressRecord.swift         # 進捗記録
│   │   └── AIRecommendation.swift       # AI提案結果
│   ├── ViewModels/
│   │   ├── FitnessCoachViewModel.swift  # メインViewModel
│   │   ├── WorkoutViewModel.swift       # ワークアウト実行
│   │   ├── ProgressViewModel.swift      # 進捗分析
│   │   └── SettingsViewModel.swift      # 設定管理
│   ├── Views/
│   │   ├── Home/
│   │   │   ├── HomeView.swift           # ホーム画面
│   │   │   └── TodayWorkoutCard.swift   # 今日のワークアウト
│   │   ├── Plan/
│   │   │   ├── PlanListView.swift       # プラン一覧
│   │   │   ├── PlanDetailView.swift     # プラン詳細
│   │   │   └── CreatePlanView.swift     # プラン作成
│   │   ├── Workout/
│   │   │   ├── WorkoutSessionView.swift # ワークアウト実行
│   │   │   ├── ExerciseGuideView.swift  # エクササイズガイド
│   │   │   └── RestTimerView.swift      # 休憩タイマー
│   │   ├── Progress/
│   │   │   ├── ProgressView.swift       # 進捗画面
│   │   │   ├── WeeklyChartView.swift    # 週間チャート
│   │   │   └── AIInsightsView.swift     # AI洞察
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift        # プロファイル
│   │   │   └── GoalSettingView.swift    # 目標設定
│   │   └── Components/
│   │       ├── ExerciseCard.swift
│   │       ├── ProgressRing.swift
│   │       └── AIRecommendationCard.swift
│   ├── Services/
│   │   ├── DataService.swift            # Swift Data操作
│   │   ├── HealthKitService.swift       # HealthKit連携
│   │   ├── WorkoutPlanGenerator.swift   # AI運動プラン生成
│   │   ├── ProgressiveOverloadService.swift # 負荷提案
│   │   └── NotificationService.swift    # リマインダー通知
│   └── Assets.xcassets
└── AsaFitnessCoachTests/
    ├── Models/
    ├── Services/
    │   ├── WorkoutPlanGeneratorTests.swift
    │   └── ProgressiveOverloadServiceTests.swift
    └── ViewModels/
```

---

## AI運動プラン提案エンジン

### 6要因重み付けスコアリング

AsaSmartTodo/AsaBudgetAIのパターンを応用:

```swift
struct WorkoutPlanGenerator {
    // 6要因の重み（デフォルト）
    var weights = PlanWeights(
        goalAlignment: 0.25,      // 目標との適合度
        fitnessLevel: 0.20,       // 体力レベル適合
        equipmentMatch: 0.15,     // 利用可能機器
        timeConstraint: 0.15,     // 時間制約
        recoveryStatus: 0.15,     // 回復状態（前回からの経過）
        progressionRate: 0.10    // 進捗ペース
    )

    func generatePlan(for profile: UserProfile) -> AIRecommendation {
        let scores = calculateScores(profile)
        let totalScore = weightedSum(scores)
        let recommendedExercises = selectExercises(basedOn: totalScore)
        return AIRecommendation(
            exercises: recommendedExercises,
            confidence: calculateConfidence(scores),
            reasons: generateReasons(scores)
        )
    }
}
```

### 要因詳細

| 要因 | 説明 | スコア計算 |
|------|------|----------|
| **目標適合度** | ユーザー目標（筋力/持久力/減量等）との一致度 | 目標カテゴリとエクササイズタイプの一致率 |
| **体力レベル** | 初心者〜上級者に適した難易度 | ユーザーレベルとエクササイズ難易度の差分 |
| **機器適合** | 利用可能な器具でできるエクササイズ | 必要機器が利用可能かの一致率 |
| **時間制約** | 設定された運動時間に収まるか | 推定所要時間/設定時間の比率 |
| **回復状態** | 前回のワークアウトからの経過時間 | 筋肉グループ別の回復率（48-72時間基準） |
| **進捗ペース** | 過去の成長率に基づく適切な負荷 | 履歴データからの成長曲線分析 |

---

## データモデル

### UserProfile（ユーザープロファイル）
```swift
@Model
final class UserProfile {
    var id: UUID
    var name: String
    var birthDate: Date?
    var gender: Gender?
    var height: Double?           // cm
    var weight: Double?           // kg
    var fitnessLevel: FitnessLevel  // 初心者/中級/上級
    var primaryGoal: FitnessGoalType
    var availableEquipment: [Equipment]
    var preferredWorkoutDuration: Int  // 分
    var workoutDaysPerWeek: Int
    var createdAt: Date
    var updatedAt: Date
}
```

### WorkoutPlan（運動プラン）
```swift
@Model
final class WorkoutPlan {
    var id: UUID
    var name: String
    var planDescription: String
    var difficulty: Difficulty
    var targetMuscleGroups: [MuscleGroup]
    var estimatedDuration: Int    // 分
    var exercises: [Exercise]
    var scheduledDays: [WeekDay]
    var isAIGenerated: Bool
    var aiConfidence: Double?
    var createdAt: Date
}
```

### Exercise（エクササイズ）
```swift
@Model
final class Exercise {
    var id: UUID
    var name: String
    var category: ExerciseCategory  // 筋力/有酸素/柔軟性
    var targetMuscles: [MuscleGroup]
    var requiredEquipment: [Equipment]
    var sets: Int
    var reps: Int?
    var duration: Int?            // 秒（有酸素系）
    var weight: Double?           // kg
    var restTime: Int             // 秒
    var instructions: String
    var videoURL: String?
}
```

### WorkoutSession（セッション実績）
```swift
@Model
final class WorkoutSession {
    var id: UUID
    var planId: UUID
    var startTime: Date
    var endTime: Date?
    var completedExercises: [CompletedExercise]
    var totalCalories: Double?
    var averageHeartRate: Int?
    var rating: SessionRating      // 1-5星
    var notes: String?
    var isCompleted: Bool
}
```

---

## 実装フェーズ（6日間）

### Phase 1: 基盤構築（Day 1）
- [ ] project.yml作成（HealthKit、Charts依存関係）
- [ ] データモデル実装（UserProfile, FitnessGoal, Exercise）
- [ ] AsaUIKit依存関係設定
- [ ] Assets.xcassets準備

### Phase 2: サービス層（Day 2）
- [ ] DataService実装（Swift Data CRUD）
- [ ] HealthKitService実装（権限管理、データ取得）
- [ ] WorkoutPlanGenerator実装（6要因AI提案エンジン）
- [ ] ProgressiveOverloadService実装

### Phase 3: プロファイル・プラン管理（Day 3）
- [ ] SettingsViewModel実装
- [ ] ProfileView（プロファイル設定）
- [ ] GoalSettingView（目標設定）
- [ ] FitnessCoachViewModel実装
- [ ] PlanListView、CreatePlanView

### Phase 4: ワークアウト実行（Day 4）
- [ ] WorkoutViewModel実装
- [ ] WorkoutSessionView（ワークアウト実行画面）
- [ ] ExerciseGuideView（エクササイズガイド）
- [ ] RestTimerView（休憩タイマー）
- [ ] セッション完了記録

### Phase 5: 進捗・分析（Day 5）
- [ ] ProgressViewModel実装
- [ ] ProgressView（進捗画面）
- [ ] WeeklyChartView（Charts.framework）
- [ ] AIInsightsView（AI洞察表示）
- [ ] プログレッシブオーバーロード提案UI

### Phase 6: 仕上げ・テスト（Day 6）
- [ ] Unit Tests実装（50テスト目標）
- [ ] HealthKit実機テスト
- [ ] UI調整・アニメーション
- [ ] ドキュメント作成（Day86-Implementation.md）

---

## 重要な参照ファイル

| 目的 | ファイル |
|------|---------|
| AI予測エンジン | `Apps/AsaSmartTodo/AsaSmartTodo/Services/TaskPriorityPredictor.swift` |
| 6要因スコアリング | `Apps/AsaBudgetAI/AsaBudgetAI/Services/AnomalyDetector.swift` |
| HealthKit連携 | `Apps/AsaFitnessGoal/AsaFitnessGoal/Services/HealthKitService.swift` |
| プログレッシブオーバーロード | `Apps/AsaWorkoutPlanner/AsaWorkoutPlanner/Services/ProgressiveOverloadService.swift` |
| 運動モデル設計 | `Apps/AsaWorkoutPlanner/AsaWorkoutPlanner/Models/` |
| Charts表示 | `Apps/AsaBudgetAI/AsaBudgetAI/Views/Analytics/` |

---

## 検証方法

### 1. ビルド確認
```bash
cd Apps/AsaFitnessCoach
xcodegen generate
open AsaFitnessCoach.xcodeproj
# Cmd+B でビルド
```

### 2. テスト実行
```bash
xcodebuild test -project AsaFitnessCoach.xcodeproj \
  -scheme AsaFitnessCoach \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### 3. 機能確認チェックリスト
- [ ] プロファイル作成（目標・体力レベル・機器設定）
- [ ] AI運動プラン生成（信頼度・理由表示）
- [ ] ワークアウト実行（タイマー・セット記録）
- [ ] HealthKitデータ取得（カロリー・心拍数）
- [ ] 進捗グラフ表示（週間チャート）
- [ ] プログレッシブオーバーロード提案
- [ ] 通知リマインダー

---

## 技術的考慮事項

### HealthKit権限管理
- 段階的な権限要求（初回は必須項目のみ）
- 実際のアクセステストで権限状態を検証
- 権限未取得時のグレースフルデグラデーション

### AI提案の透明性
- 予測理由をリスト形式で表示
- 信頼度スコアの可視化
- ユーザーによる重み調整オプション

### パフォーマンス
- LazyVStackによる遅延読み込み
- HealthKitクエリのキャッシング（5分有効）
- 非同期処理（async/await）の活用

### オフライン対応
- Swift Dataによるローカル永続化
- HealthKit未連携時は手動記録をサポート
