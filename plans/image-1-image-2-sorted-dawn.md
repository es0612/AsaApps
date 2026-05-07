# AsaPapaHub サンプルデータ反映改善計画

## Context（なぜこれをやるのか）

スクリーンショットから「ホーム画面の朝活スコア=0、6カテゴリのサマリーが全て『--』」「朝活タブが『今日のルーティンがまだ設定されていません』で空」という症状。一方、資産画面（インサイト→資産）には目標進捗・月次支出グラフが表示されており、**サンプルデータが部分的にしか反映されていない**ように見える。

### 根本原因

1. **`SampleDataLoader` が「初回起動時に1回だけ」seed する設計**
   - `Apps/AsaPapaHub/Sources/Services/SampleDataLoader.swift:20` で UserDefaults フラグ `SampleDataLoaded_v1` を使い、一度 true にすると以後 seed しない
   - seed 時の today（`Calendar.current.startOfDay(for: Date())`）が固定で `MorningRoutine.date` / `DomainSnapshot.date` / `HubDashboard.date`（dayOffset=0 のもの）に書き込まれる
   - **シード翌日以降、`AppDataBridge.loadTodayData()` の `date >= today && < tomorrow` predicate（同 swift L33-53）は何にもヒットしない**
2. **資産画面が「データがあるように見える」のはモック描画のせい**
   - `FinanceOverviewView.swift:19` の `if let snapshot { ... }` ブランチは実際には nil で消えている（スコアヘッダーが描画されていない）
   - その下の `GoalProgressCard()` / `MonthlySpendingChart()` は DB を参照せず**ハードコード値を直描き**しているだけ
3. **影響範囲**
   - ホーム: `MorningScoreCard` / 6つの `*SummaryCard` / `briefingCard` が全て空
   - 朝活タブ: `MorningRoutineView` の `EmptyDomainView` ブランチに固定
   - 各ドメイン詳細画面（Health/Family/Finance/Community/Learning/Morning）の**スコアヘッダー部のみ**消失（資産以外は補助コンテンツも貧弱）

メモリの教訓「サンプルデータseed判定はデータ存在ベースで（UserDefaults boolフラグはストアとズレた瞬間に詰む。fetch().isEmpty で冪等処理）」がドンピシャで該当。

## 確定方針（ユーザー承認済み）

- **観点1（seed 範囲）**: 当日分補充 + 7日履歴スライド
- **観点2（朝活初期状態）**: 進行中（5件中3件完了 + `startTime` 設定済み）
- **観点3（詳細画面充実）**: 資産画面と同等のモックセクションを各詳細画面に追加

## 修正詳細

### 1. `Apps/AsaPapaHub/Sources/Services/SampleDataLoader.swift`

#### 1-A. `loadIfNeeded()` の責務を「初回マスター seed」に限定

UserDefaults フラグで投入する対象を「日付に依存しない不変データ」のみに変更:
- `loadPreferences()` … `HubUserPreferences`
- `loadQuickActions()` … `QuickAction`

これらは現状のまま「1回限り」で OK。

#### 1-B. 新メソッド `seedTodayIfMissing()` を追加

`@MainActor func seedTodayIfMissing() async` として、毎起動時に呼ぶ冪等処理。fetch().isEmpty 判定で空の場合のみ insert。

対象テーブル別の処理:

**(a) MorningRoutine（当日分1件）**
- `FetchDescriptor<MorningRoutine>(predicate: $0.date >= today && $0.date < tomorrow)` で空判定
- 空なら 60分目標の routine を1件作成。5件のアイテム（起床・水分補給/ストレッチ/瞑想/朝食準備/学習タイム）を投入
- **進行中状態**にする:
  - `routine.startTime = Date()`（今朝起床と仮定して `today + 6h` でも OK、見栄え重視）
  - 先頭3件（起床・水分補給/ストレッチ/瞑想）の `status = .completed`、`actualMinutes = estimatedMinutes`
  - 残り2件は `.notStarted` のまま
  - `routine.isCompleted = false`、`routine.totalScore` は計算しない（実行中扱い）

**(b) DomainSnapshot（当日分6件）**
- 6ドメインそれぞれについて、`predicate: $0.date >= today && $0.date < tomorrow && $0.domainRawValue == X` で空判定
- 空なら現状の `loadDomainSnapshots()` のスコア・サマリー値で1件 insert

**(c) HubDashboard（当日分1件 + 過去6日分のスライド）**
- 直近7日分（today, today-1日, ..., today-6日）について順番にチェック
- 各日について空なら現状の `loadDashboards()` 同等のスコア・歩数・睡眠時間を計算して insert
- これにより**毎日起動で最新7日分の履歴が常にスライドし、チャート表示が常に直近を指す**

**(d) DailyBriefing（当日分1件）**
- 当日分の DailyBriefing が無ければ insert
- 既存 `loadDailyBriefing()` には date predicate が無いので、`DailyBriefing.date` を `today` に設定するよう修正が必要（`DailyBriefing` モデル定義で `date` が無ければ `createdAt` で代替判定）

#### 1-C. `loadMorningRoutine()`（既存、L86-109）の置き換え

`seedTodayIfMissing()` 内の (a) ロジックに統合し、初回マスター seed からは外す。

### 2. `Apps/AsaPapaHub/Sources/ContentView.swift`

`initializeApp()`（L101-113）を修正:

```swift
private func initializeApp() async {
    let loader = SampleDataLoader(modelContext: modelContext)
    await loader.loadIfNeeded()           // 不変マスター（preferences, quickActions）
    await loader.seedTodayIfMissing()     // 日次補充（routine, snapshots, dashboards, briefing）

    let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    if !hasSeenOnboarding { showOnboarding = true }
    isInitialized = true
}
```

### 3. 各ドメイン詳細画面のモックセクション追加

参照パターン: `Apps/AsaPapaHub/Sources/Views/Finance/FinanceOverviewView.swift:24-27`（`GoalProgressCard()` / `MonthlySpendingChart()`）

**(a) `Apps/AsaPapaHub/Sources/Views/Health/HealthOverviewView.swift`**
- 追加コンポーネント案:
  - `WeeklyStepsChart`: 直近7日分の歩数を棒グラフ表示（モック値: 6800〜9200歩のランダム）
  - `SleepQualityCard`: 平均睡眠時間 7.2h、深い眠り 1.8h のラベル + プログレスバー

**(b) `Apps/AsaPapaHub/Sources/Views/Family/FamilyHubView.swift`**
- 追加コンポーネント案:
  - `FamilyEventsCard`: 「明日: 子供の習い事 15:00」「今週末: お出かけ予定」など2〜3件の予定リスト
  - `RecentFamilyPhotosGrid`: 3×2 のサムネイルプレースホルダ（SF Symbol で代用可）

**(c) `Apps/AsaPapaHub/Sources/Views/Community/CommunityOverviewView.swift`**
- 追加コンポーネント案:
  - `NearbyEventsCard`: 「地域防災訓練 5/15 10:00」「町内清掃 5/20 8:00」など2件
  - `VolunteerActivitiesCard`: 今月のボランティア時間 4h、参加回数 2回

**(d) `Apps/AsaPapaHub/Sources/Views/Learning/LearningOverviewView.swift`**
- 追加コンポーネント案:
  - `FlashcardProgressCard`: 復習済み 32 / 新規 8 / 学習時間 30分
  - `LearningStreakCard`: 連続学習 5日、合計時間 12h、お気に入りジャンル「SwiftUI」

**(e) `Apps/AsaPapaHub/Sources/Views/MorningRoutine/MorningScoreDetailView.swift`**
- 追加コンポーネント案:
  - `WeeklyMorningScoreChart`: 直近7日のスコア推移（既存 HubDashboard.morningScore を活用してもよい）
  - `StreakCard`: 連続早起き 5日、平均スコア 78点

各コンポーネントは現時点ではモック値ハードコードで OK（資産画面の `GoalProgressCard` と同じ思想）。後日 SwiftData バック化はスコープ外。

## 修正対象ファイル一覧

```
Apps/AsaPapaHub/Sources/
├── ContentView.swift                                    [修正] initializeApp() に seedTodayIfMissing() 追加
├── Services/SampleDataLoader.swift                      [修正] seedTodayIfMissing() 追加 + loadMorningRoutine 統合
└── Views/
    ├── Health/HealthOverviewView.swift                  [追加] WeeklyStepsChart, SleepQualityCard
    ├── Family/FamilyHubView.swift                       [追加] FamilyEventsCard, RecentFamilyPhotosGrid
    ├── Community/CommunityOverviewView.swift            [追加] NearbyEventsCard, VolunteerActivitiesCard
    ├── Learning/LearningOverviewView.swift              [追加] FlashcardProgressCard, LearningStreakCard
    └── MorningRoutine/MorningScoreDetailView.swift      [追加] WeeklyMorningScoreChart, StreakCard
```

## 既存実装の再利用

- `Apps/AsaPapaHub/Sources/Views/Finance/FinanceOverviewView.swift` — モックセクション追加の参照パターン
- `Apps/AsaPapaHub/Sources/Services/AppDataBridge.swift:31-84 loadTodayData()` — 当日 fetch ロジック（変更不要、seed 側を直すだけ）
- `Packages/AsaPapaHubKit/Sources/AsaPapaHubKit/Models/MorningRoutine.swift` — `completionRate` / `completedItemsCount` の computed property を活用
- `Packages/AsaUIKit` — `AsaCard` / `AsaColors` / `ScoreRing` / `TrendIndicator` などの共有コンポーネント

## 検証手順

### Step 1: ビルド
```bash
cd Apps/AsaPapaHub
xcodegen generate -s project.yml
xcodebuild -project AsaPapaHub.xcodeproj -scheme AsaPapaHub \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Step 2: クリーンインストールで初回起動を再現
```bash
xcrun simctl uninstall booted com.asapapa.apps.asapapahub
xcrun simctl install booted [DerivedData の .app パス]
xcrun simctl launch booted com.asapapa.apps.asapapahub
```

### Step 3: 第1日チェック（初回起動）
- ホーム: 朝活スコア > 0、6カードに数字とトレンドアイコン、ブリーフィング表示
- 朝活タブ: ScoreRing が約60%、5アイテム中3件 `.completed`、タイマー動作中、「ルーティンを終了」ボタン表示
- インサイト→Health/Family/Finance/Community/Learning/Morning: スコアヘッダー描画 + モックセクション2個ずつ表示

### Step 4: 第2日チェック（冪等性確認）
- シミュレータの日付を翌日に進める:
  ```bash
  sudo date -u 0508120000  # 翌日 12:00 UTC
  ```
- アプリを再起動 → ホーム/朝活/詳細画面が**第1日と同等の充実度**で表示されることを確認
- HubDashboard の履歴グラフが直近7日分にスライドしていることを確認

### Step 5: テスト
```bash
xcodebuild test -project AsaPapaHub.xcodeproj -scheme AsaPapaHub \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
`AsaPapaHubTests/` 配下が `loadIfNeeded()` の挙動に依存している場合のみ最小修正。

## デモ撮影推奨フロー（実装完了後）

1. **起動直後のホーム**（充実したカード並びを見せる）
2. **「朝活」タブをタップ**（ScoreRing の進行中アニメ + 3件完了の達成感）
3. **未完了アイテムをタップして完了化**（操作デモ）
4. **インサイトタブ → 各ドメイン**（充実した詳細画面の連続フリック）
5. **ホームに戻ってクイックアクション**（Siri Tip も含めて締め）

## スコープ外（今回はやらない）

- AppDataBridge / 各 ViewModel のロジック変更
- SwiftData モデル定義の変更
- 詳細画面のモックセクションを SwiftData 化
- 既存の Onboarding フロー変更
