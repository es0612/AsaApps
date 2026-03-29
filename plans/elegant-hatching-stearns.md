# AsaFitnessCoach (App #86) SNSデモ動画準備プラン

## Context

AsaFitnessCoach（AIフィットネスコーチ）をSNSプロモーション動画として撮影できる状態にする。
アプリ自体は完成度が高く、サンプルデータも既に実装済みだが、**デモ時に見栄えが悪い箇所が2つ**あり、それを修正する。

## 発見した問題点

### 問題1: HealthKitデータが全て0表示（重要度: 高）
- ホーム画面トップの「今日の活動」カード4枚（歩数/カロリー/運動時間/ワークアウト回数）が全て0
- シミュレータではHealthKit未連携のため、データが取得できない
- さらに赤い「HealthKitと連携」ボタンが目立ち、未完成に見える

### 問題2: ホーム画面の「開始」ボタンが動作しない（重要度: 高）
- `HomeView.swift:136` の `onStart: {}` が空のクロージャ
- TodayWorkoutCardの「開始」ボタンを押しても何も起きない
- デモ動画で最も操作したい部分なので必須修正

## 修正計画（2ファイル、約15行の変更）

### Step 1: FitnessCoachViewModel.swift にデモモード追加

**ファイル**: `Apps/AsaFitnessCoach/AsaFitnessCoach/ViewModels/FitnessCoachViewModel.swift`

1. `isDemoMode: Bool = false` プロパティを追加
2. `loadData()` のサンプルデータ挿入ブロックで `UserDefaults` にデモモードフラグを保存
3. HealthKit未連携 & デモモード時に、リアルなダミー値を注入:
   - todaySteps = 6,842
   - todayCalories = 320
   - todayActiveTime = 45（分）
   - todayWorkoutCount = 1

### Step 2: HomeView.swift のワークアウト開始機能 & HealthKitボタン制御

**ファイル**: `Apps/AsaFitnessCoach/AsaFitnessCoach/Views/Home/HomeView.swift`

1. `@State private var selectedPlanForWorkout: WorkoutPlan?` を追加
2. TodayWorkoutCard の `onStart` で `selectedPlanForWorkout = plan` をセット
3. `.sheet(item: $selectedPlanForWorkout)` で `WorkoutSessionView` を表示
4. HealthKitボタンの表示条件に `&& !viewModel.isDemoMode` を追加

### Step 3: ビルド検証

```bash
cd Apps/AsaFitnessCoach && xcodegen generate
xcodebuild -project AsaFitnessCoach.xcodeproj -scheme AsaFitnessCoach -sdk iphonesimulator build
```

### Step 4: コミット

## 影響範囲

- **実ユーザーへの影響: ゼロ** - デモモードは SampleDataGenerator 経由で初回起動した場合のみ有効
- 実ユーザーがオンボーディングで自分のプロフィールを作成した場合、フラグは設定されない
- HealthKit連携後は実データが優先される

## デモ撮影推奨フロー

1. **アプリ起動** → サンプルデータ自動投入、HealthKitダミー表示
2. **ホーム画面** → 活動サマリー（歩数6,842等）、AI提案、負荷増加提案
3. **「開始」タップ** → ワークアウトセッション画面（ベンチプレス60kg等）
4. **プランタブ** → 4つのプラン一覧、カテゴリフィルター
5. **進捗タブ** → グラフ表示、週間カレンダー、AI洞察
6. **プロフィール** → ユーザー情報、器具設定、累計実績

## 検証方法

- シミュレータでアプリをクリーンインストール（既存データ削除）
- 起動後にホーム画面のサマリーカードに値が表示されることを確認
- 「開始」ボタンでワークアウトセッションが開きることを確認
- 全4タブの表示が正常であることを確認
