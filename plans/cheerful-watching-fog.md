# AsaFitnessCoach デモ動画撮影対応計画

## Context

AsaFitnessCoachはAIフィットネスコーチアプリ（個人最適化された運動プラン提案、ワークアウト記録、プログレッシブオーバーロード提案）。SNSデモ動画撮影のため、初回起動時にサンプルデータを投入し、全画面が賑わった状態にする。

**現状の問題**: SwiftDataで永続化しており初回起動は完全に空。オンボーディング → プロフィール設定だけで、ホーム画面のほぼ全セクションが非表示またはゼロ表示。

## 発見された問題

| # | 問題 | 影響 |
|---|------|------|
| 1 | UserProfile未作成 → オンボーディング表示 + AI提案なし | ホーム画面スカスカ |
| 2 | WorkoutPlan未作成 → 「今日のワークアウト」非表示 | ホーム画面の主要セクション欠落 |
| 3 | WorkoutSession未作成 → 週間/月間統計ゼロ + チャート空 + オーバーロード提案なし | 進捗画面が空 |
| 4 | HealthKit未連携 → 歩数/カロリー/運動時間すべて0 | 許容（シミュレータでは不可避）|

## 実装計画

### Step 1: SampleDataGenerator.swift を新規作成

**ファイル**: `Apps/AsaFitnessCoach/AsaFitnessCoach/Services/SampleDataGenerator.swift`

`@MainActor final class SampleDataGenerator` を作成。DataServiceを受け取り、ワンコールでデータ投入。

#### シードデータ設計

**A. UserProfile**
```
名前: "朝活パパ"
fitnessLevel: .intermediate
primaryGoal: .muscleGain
availableEquipment: [.dumbbells, .bench, .yogaMat, .pullUpBar]
preferredWorkoutDuration: 30, workoutDaysPerWeek: 4
height: 175.0, weight: 72.0
```

**B. WorkoutPlans (4つ)** — PresetExercises.toExercise() を再利用

| Plan | カテゴリ | エクササイズ | scheduledDays | isActive |
|------|---------|-------------|---------------|----------|
| 上半身の日 | .strength | ベンチプレス(60kg), ダンベルフライ(12kg), ダンベルロウ(20kg), 懸垂 | **今日の曜日を必ず含む** + 他2日 | true |
| 下半身の日 | .strength | スクワット(80kg), ランジ, レッグプレス(100kg) | 今日+2日後, +4日後 | true |
| HIIT | .hiit | バーピー, マウンテンクライマー, ジャンピングジャック | 2日 | true |
| 体幹・柔軟 | .yoga | プランク, クランチ, ダウンワードドッグ | 1日 | false |

**重要**: Plan1の `scheduledDays` に `WeekDay.today` を動的に含めることで、どの曜日にデモ撮影しても「今日のワークアウト」が表示される。

**C. WorkoutSessions (10個)** — 過去3週間に分散

```
Day -20: Plan1 上半身（ベンチプレス 55kg）  rating: .good,  RPE: 6
Day -18: Plan2 下半身（スクワット 70kg）    rating: .good,  RPE: 7
Day -16: Plan3 HIIT                        rating: .okay,  RPE: 8
Day -13: Plan1 上半身（ベンチプレス 57.5kg） rating: .good,  RPE: 6
Day -11: Plan2 下半身（スクワット 75kg）    rating: .excellent, RPE: 7
Day  -9: Plan3 HIIT                        rating: .good,  RPE: 7
Day  -6: Plan1 上半身（ベンチプレス 60kg）  rating: .excellent, RPE: 6
Day  -4: Plan2 下半身（スクワット 80kg）    rating: .good,  RPE: 7
Day  -2: Plan3 HIIT                        rating: .good,  RPE: 8
Day  -1: Plan4 体幹                        rating: .excellent, RPE: 5
```

各セッションの CompletedExercise に:
- `isCompleted: true`
- `actualSets: [SetRecord]` に weight > 0, reps, isCompleted: true
- `formQuality: .good or .excellent`
- `totalCalories: 150-350`

**Progressive Overload が発動する条件（ProgressiveOverloadService.swift:77-93）**:
- `session.isCompleted == true`
- `exercise.isCompleted == true`
- `exercise.actualWeight` に weight > 0 が含まれる
- 3回以上のデータポイントで `confidence: .high`
- 完了率95%以上 + formQuality good/excellent → 5%増加提案

ベンチプレス(55→57.5→60kg)とスクワット(70→75→80kg)の3回分データで、提案が確実に生成される。

### Step 2: FitnessCoachViewModel.swift に初回判定追加

**ファイル**: `Apps/AsaFitnessCoach/AsaFitnessCoach/ViewModels/FitnessCoachViewModel.swift`

`loadData()` メソッド内（userProfile取得後）に5行追加:

```swift
// ユーザープロファイル読み込み
userProfile = dataService.fetchUserProfile()

// ★ 追加: 初回起動時のサンプルデータ投入
if userProfile == nil {
    let generator = SampleDataGenerator(dataService: dataService)
    generator.insertSampleData()
    userProfile = dataService.fetchUserProfile()
}

// 以下既存のまま...
```

`showOnboarding` は `userProfile == nil` で判定されるため、サンプル投入後はオンボーディングをスキップ。

## 変更対象ファイル一覧

| ファイル | 変更内容 | 変更量 |
|----------|----------|--------|
| `Services/SampleDataGenerator.swift` | **新規作成** — データ生成ロジック | ~200行 |
| `ViewModels/FitnessCoachViewModel.swift` | `loadData()` に初回判定5行追加 | ~5行 |

既存ファイルの変更は FitnessCoachViewModel のみ。モデルやサービスの変更なし。

## デモ動画撮影時の期待される画面状態

**ホーム画面**:
- 今日の活動サマリー（HealthKit未連携で値0 + 連携ボタン）
- **「今日のワークアウト」**: 上半身の日が表示（Plan1）
- **「AI提案」**: UserProfile + recentSessions に基づく最適化プラン
- **「負荷増加の提案」**: ベンチプレス 60→62.5kg, スクワット 80→82.5kg
- **「今週の実績」**: ワークアウト3-4回, 合計時間120分+

**プラン一覧**: 4つのプラン表示（カテゴリ別フィルタ可能）

**進捗ダッシュボード**: チャート3週間分, サマリーに数値あり, 週間カレンダーにチェック

**プロフィール**: 「朝活パパ」の完全プロフィール表示

## デモ動画シナリオ（想定1-2分）

1. アプリ起動 → 即ホーム画面（サンプルデータ充填済み）
2. ホーム画面スクロール → 今日のワークアウト / AI提案 / 負荷増加提案 / 週間統計
3. AI提案の「プランを作成」をタップ → プランリストに追加
4. 「上半身の日」をタップ → プラン詳細（エクササイズ一覧 + 実績）
5. 「ワークアウト開始」→ セット実行 → 休憩タイマー → 完了画面
6. 進捗タブ → チャート + 統計
7. プロフィールタブ → 設定確認

## 検証手順

1. `cd Apps/AsaFitnessCoach && xcodegen generate`
2. `xcodebuild -project AsaFitnessCoach.xcodeproj -scheme AsaFitnessCoach -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
3. シミュレータでアプリ起動 → オンボーディングがスキップされることを確認
4. ホーム画面で全5セクション（サマリー/今日のワークアウト/AI提案/負荷提案/週間統計）表示確認
5. プラン一覧で4プラン表示確認
6. 進捗ダッシュボードでチャートにデータがあることを確認
7. プロフィール画面で「朝活パパ」の情報が表示されることを確認
