# AsaPapaHub (#100) - 100本ノック集大成ハブアプリ 設計計画

## Context

AsaApps 100本ノックの最終アプリ。README の定義：「全アプリの機能を集約したハブアプリ」。
「朝活パパエンジニア」のテーマ（家族・生産性・朝活）を体現し、iOS 26 の最新技術を全て活用した上級アプリとして設計する。

**設計方針**: スタンドアロン（AsaPapaHubKit 独自モデル + SampleDataLoader、既存 Kit への依存なし）
**スコープ**: 全8フェーズ完全実装（AI、Siri、Widget、Live Activity 含む）

---

## 技術スタック

| カテゴリ | 技術 |
|---------|------|
| デプロイメントターゲット | iOS 26.0（AsaRecipeAI と同様） |
| Swift | 6.0 + `SWIFT_STRICT_CONCURRENCY: complete` |
| AI | Foundation Models（`@Generable`, `LanguageModelSession`, ストリーミング） |
| データ永続化 | SwiftData `@Model`（enum rawValue パターン） |
| 状態管理 | `@MainActor @Observable` + Protocol DI |
| 音声/自動化 | App Intents + `AppShortcutsProvider` + `SiriTipView` |
| ウィジェット | WidgetKit（インタラクティブ）+ Live Activities + Dynamic Island |
| ヒント | TipKit（`Tips.configure()`） |
| UI | AsaUIKit + Charts フレームワーク |
| テスト | Swift Testing（`@Test`, `#expect`） |

---

## ディレクトリ構造

### Apps/AsaPapaHub/

```
Apps/AsaPapaHub/
  project.yml
  Sources/
    AsaPapaHubApp.swift                      # @main, Tips.configure(), .modelContainer()
    ContentView.swift                        # 5タブ TabView
    Assets.xcassets/
    AsaPapaHub.entitlements                  # App Group for Widget

    Services/
      AppDataBridge.swift                    # ModelContext -> Kit services ブリッジ
      SampleDataLoader.swift                 # 初回起動用サンプルデータ
      NotificationBridge.swift               # 通知管理

    AI/
      PapaHubAIService.swift                 # Foundation Models LanguageModelSession ラッパー
      Models/
        MorningBriefing.swift                # @Generable 朝の AI ブリーフィング
        WeeklySummaryReport.swift            # @Generable 週間サマリー
        AISearchResult.swift                 # @Generable 自然言語検索結果
      Views/
        AIBriefingView.swift                 # AI ブリーフィングカード（ストリーミング対応）
        AISearchView.swift                   # 自然言語検索インターフェース
        StreamingResponseView.swift          # ストリーミング出力コンポーネント

    Intents/
      MorningScoreIntent.swift               # 「今日の朝活スコアは？」
      WeeklySummaryIntent.swift              # 「今週のサマリーを教えて」
      QuickEntryIntent.swift                 # 音声クイック記録
      PapaHubShortcuts.swift                 # AppShortcutsProvider

    Views/
      Dashboard/
        DashboardView.swift                  # メインダッシュボード
        MorningScoreCard.swift               # 朝活スコアリング表示
        HealthSummaryCard.swift              # 歩数・睡眠サマリー
        FamilySummaryCard.swift              # 家族予定・写真
        FinanceSummaryCard.swift             # 資産目標進捗
        CommunitySummaryCard.swift           # 地域イベント・安全
        LearningSummaryCard.swift            # 学習ストリーク
        QuickActionBar.swift                 # クイックアクションボタン

      MorningRoutine/
        MorningRoutineView.swift             # 朝活ルーティンチェックリスト＋タイマー
        RoutineItemRow.swift                 # ルーティンアイテム行
        MorningScoreDetailView.swift         # スコア内訳詳細

      Health/
        HealthOverviewView.swift             # Charts: 歩数折れ線・睡眠棒グラフ
        StepsChartView.swift
        SleepChartView.swift
        ActivityRingView.swift               # カスタムアクティビティリング

      Family/
        FamilyHubView.swift                  # 家族予定・写真・教育
        FamilyEventCard.swift
        KidsLearningCard.swift
        PhotoHighlightView.swift

      Finance/
        FinanceOverviewView.swift            # 資産目標＋支出概要
        GoalProgressCard.swift
        MonthlySpendingChart.swift

      Community/
        CommunityOverviewView.swift          # 地域イベント＋安全情報
        LocalEventCard.swift
        SafetyStatusCard.swift

      Learning/
        LearningOverviewView.swift           # 学習進捗＋ストリーク
        StudyStreakView.swift                 # ヒートマップカレンダー
        RecentLearningCard.swift

      Settings/
        SettingsView.swift
        DomainSettingsView.swift             # ドメイン ON/OFF
        AISettingsView.swift                 # AI 設定
        NotificationSettingsView.swift
        AboutView.swift                      # 100本ノック完走記念

      Components/
        DomainSectionHeader.swift            # セクションヘッダー（アイコン付き）
        ScoreRing.swift                      # 円形スコアリング
        TrendIndicator.swift                 # トレンド矢印（↑↓→）
        EmptyDomainView.swift                # 空状態ビュー
        SiriTipBanner.swift                  # SiriTipView ラッパー

      Onboarding/
        OnboardingView.swift                 # 初回オンボーディング
        DomainSelectionView.swift            # ドメイン選択

  Shared/
    PapaHubWidgetData.swift                  # Widget 共有データモデル（Codable）
    SharedDefaults.swift                     # App Group UserDefaults

  PapaHubWidgetExtension/
    PapaHubWidget.swift                      # WidgetBundle
    PapaHubWidgetProvider.swift              # TimelineProvider
    SmallWidgetView.swift                    # systemSmall: 朝活スコア＋歩数
    MediumWidgetView.swift                   # systemMedium: マルチドメインサマリー
    LargeWidgetView.swift                    # systemLarge: ミニダッシュボード
    CircularWidgetView.swift                 # accessoryCircular: スコアリング
    RectangularWidgetView.swift              # accessoryRectangular: 今日の概要
    InteractiveWidgetButtons.swift           # インタラクティブボタン
    LiveActivity/
      MorningRoutineAttributes.swift         # ActivityAttributes
      MorningRoutineLiveActivityView.swift   # Live Activity + Dynamic Island UI

  AsaPapaHubTests/
  AsaPapaHubUITests/
```

### Packages/AsaPapaHubKit/

```
Packages/AsaPapaHubKit/
  Package.swift                              # swift-tools-version: 6.0, iOS 18+, macOS 15+
  Sources/AsaPapaHubKit/
    Models/
      HubDashboard.swift                     # @Model: 日次ダッシュボードスナップショット
      MorningRoutine.swift                   # @Model: 朝活ルーティン
      MorningRoutineItem.swift               # @Model: ルーティンアイテム
      DomainSnapshot.swift                   # @Model: ドメイン別スナップショット
      HubUserPreferences.swift               # @Model: ユーザー設定
      WeeklySummary.swift                    # @Model: AI 週間サマリー
      DailyBriefing.swift                    # @Model: AI 朝ブリーフィング
      QuickAction.swift                      # @Model: クイックアクション設定
    Models/Enums/
      LifeDomain.swift                       # morning, health, family, finance, community, learning
      RoutineItemStatus.swift                # pending, inProgress, completed, skipped
      TrendDirection.swift                   # up, down, stable
      BriefingStatus.swift                   # pending, generating, completed, failed
      ChartPeriod.swift                      # day, week, month
    Protocols/
      HubDataServiceProtocol.swift           # CRUD 全モデル
      DomainAggregatorProtocol.swift         # ドメイン別データ集約
      MorningRoutineServiceProtocol.swift    # ルーティン管理
      AIBriefingServiceProtocol.swift        # AI ブリーフィング生成
      ScoreCalculatorProtocol.swift          # スコア計算
      WidgetDataServiceProtocol.swift        # ウィジェットデータ更新
    Services/
      HubDataService.swift                   # SwiftData CRUD
      DomainAggregatorService.swift          # ドメインデータ集約
      MorningRoutineService.swift            # ルーティンロジック
      ScoreCalculator.swift                  # 朝活スコア＋ドメインスコア計算
      WidgetDataService.swift                # SharedDefaults 更新
      NotificationScheduler.swift            # 通知スケジューリング
    ViewModels/
      DashboardViewModel.swift               # メインダッシュボード集約
      MorningRoutineViewModel.swift          # ルーティンライフサイクル
      HealthViewModel.swift                  # 健康データ表示
      FamilyViewModel.swift                  # 家族データ表示
      FinanceViewModel.swift                 # 資産データ表示
      CommunityViewModel.swift               # 地域データ表示
      LearningViewModel.swift                # 学習データ表示
      SettingsViewModel.swift                # 設定管理
    Errors/
      PapaHubError.swift                     # カスタムエラー型

  Tests/AsaPapaHubKitTests/
    Models/
      HubDashboardTests.swift
      MorningRoutineTests.swift
      DomainSnapshotTests.swift
      EnumTests.swift
    Services/
      HubDataServiceTests.swift
      DomainAggregatorServiceTests.swift
      MorningRoutineServiceTests.swift
      ScoreCalculatorTests.swift
      WidgetDataServiceTests.swift
    ViewModels/
      DashboardViewModelTests.swift
      MorningRoutineViewModelTests.swift
      HealthViewModelTests.swift
      SettingsViewModelTests.swift
    Mocks/
      MockHubDataService.swift
      MockDomainAggregator.swift
      MockMorningRoutineService.swift
      MockAIBriefingService.swift
      MockScoreCalculator.swift
```

---

## 主要モデル設計

### LifeDomain (6ドメイン)

```swift
public enum LifeDomain: String, CaseIterable, Codable, Sendable {
    case morning    // 朝活 ☀️ sunrise.fill
    case health     // 健康 ❤️ heart.fill
    case family     // 家族 👨‍👩‍👧 figure.2.and.child.holdinghands
    case finance    // 資産 💰 yensign.circle.fill
    case community  // 地域 🏘️ building.2.fill
    case learning   // 学習 📚 book.fill
}
```

### HubDashboard (@Model)

日次ダッシュボードスナップショット。朝活スコア、歩数、睡眠、気分、各ドメイン進捗を集約。

### MorningRoutine + MorningRoutineItem (@Model)

朝活ルーティン管理。RoutineItem は cascade delete 関係。`RoutineItemStatus` で進捗管理。

### DomainSnapshot (@Model)

ドメイン別のスコア・サマリー・トレンド。`LifeDomain` を rawValue で保存。

### HubUserPreferences (@Model)

起床時間、有効ドメイン、AI 設定、通知設定、歩数目標、睡眠目標。

### DailyBriefing / WeeklySummary (@Model)

AI 生成のブリーフィング・サマリー。`BriefingStatus` で生成状態管理。

---

## ナビゲーション構造（5タブ）

| タブ | View | アイコン | 説明 |
|-----|------|---------|------|
| ホーム | DashboardView | square.grid.2x2.fill | 統合ダッシュボード |
| 朝活 | MorningRoutineView | sunrise.fill | ルーティンチェックリスト＋タイマー |
| AI検索 | AISearchView | sparkle.magnifyingglass | 自然言語検索 |
| インサイト | (各ドメイン詳細へのハブ) | chart.bar.fill | Charts グラフ |
| 設定 | SettingsView | gear | ドメイン・AI・通知設定 |

### ダッシュボード構成

```
ScrollView:
  AIBriefingView           ← AI 朝ブリーフィング（ストリーミング）
  MorningScoreCard         ← 大きなスコアリング（CircularProgress）
  SiriTipBanner            ← 「朝活スコアは？と聞いてみて」
  LazyVGrid(2列):
    HealthSummaryCard      → tap → HealthOverviewView
    FamilySummaryCard      → tap → FamilyHubView
    FinanceSummaryCard     → tap → FinanceOverviewView
    CommunitySummaryCard   → tap → CommunityOverviewView
    LearningSummaryCard    → tap → LearningOverviewView
  QuickActionBar           ← クイックアクションボタン
```

---

## Foundation Models AI 統合

### 参照実装: `Apps/AsaRecipeAI/AsaRecipeAI/Services/RecipeAIService.swift`

**@Generable モデル**（Sources/AI/Models/ に配置、Kit ではなくアプリ層）:

- `MorningBriefing`: 朝の挨拶、スケジュール、健康アドバイス、モチベーション
- `WeeklySummaryReport`: 週間サマリー、ハイライト、提案
- `AISearchResult`: 自然言語検索結果

**PapaHubAIService**: `LanguageModelSession` ラッパー
- `prepareSession()` + `LanguageModelSession.isAvailable` チェック
- `generateMorningBriefing()` → `@Generable` 型安全出力
- `streamMorningBriefing()` → `PartiallyGenerated` ストリーミング
- `generateWeeklySummary()` → 週間 AI レポート
- `searchNaturalLanguage()` → 全ドメイン横断検索

---

## App Intents / Siri

### 3つの App Intent

1. **MorningScoreIntent**: 「今日の朝活スコアは？」→ スコアと一言コメント返却
2. **WeeklySummaryIntent**: 「今週のサマリーを教えて」→ 週間ハイライト返却
3. **QuickEntryIntent**: 「記録して」→ 音声テキストをクイック記録

### PapaHubShortcuts (AppShortcutsProvider)

自動登録されるフレーズ + `SiriTipView` でダッシュボードに表示

---

## Widget + Live Activity

### WidgetKit (5種類)

| サイズ | 内容 |
|-------|------|
| systemSmall | 朝活スコア＋今日の歩数 |
| systemMedium | マルチドメイン概要（6ドメインアイコン＋スコア） |
| systemLarge | ミニダッシュボード（スコア＋グラフ＋次のタスク） |
| accessoryCircular | 朝活スコアゲージ |
| accessoryRectangular | 今日のブリーフィング要約 |

### インタラクティブ Widget

ルーティンアイテム完了ボタン（`AppIntent` トリガー）

### Live Activity + Dynamic Island

朝活ルーティン実行中に:
- **Expanded**: 現在のアイテム名＋進捗バー＋経過時間
- **Compact**: アイテムアイコン＋完了数/全体数
- **Lock Screen**: 現在のアイテム＋スコア

App Group entitlement で Widget とデータ共有（`SharedDefaults.swift`）

---

## テスト計画

**目標: 120+ テスト、95% カバレッジ**

### AsaPapaHubKitTests (~100 テスト)

| テストファイル | テスト数 | カバレッジ |
|-------------|---------|----------|
| HubDashboardTests | 8 | モデル初期化、計算プロパティ |
| MorningRoutineTests | 10 | リレーション、アイテム管理 |
| DomainSnapshotTests | 6 | enum マッピング |
| EnumTests | 12 | 全 enum の rawValue、displayName、icon |
| HubDataServiceTests | 15 | 全モデル CRUD |
| DomainAggregatorServiceTests | 10 | ドメイン別集約 |
| MorningRoutineServiceTests | 12 | 開始→完了→スキップ→終了→スコア |
| ScoreCalculatorTests | 10 | 朝活・ドメイン・総合スコア、エッジケース |
| WidgetDataServiceTests | 5 | シリアライズ、SharedDefaults |
| DashboardViewModelTests | 12 | 読込、更新、ブリーフィング、エラー |
| MorningRoutineViewModelTests | 10 | ライフサイクル、アイテム進行 |
| HealthViewModelTests | 5 | データ読込、期間変更 |
| SettingsViewModelTests | 8 | 読込、保存、ドメイン切替、リセット |

### AsaPapaHubTests (~20 テスト)

- AI Service テスト（モック）: 8
- App Intent テスト: 6
- 統合テスト: 6

---

## 実装フェーズ（依存関係順）

### Phase 1: Package 基盤 (AsaPapaHubKit)

1. `Package.swift` 作成
2. 全 Enum 実装（`LifeDomain`, `RoutineItemStatus`, `TrendDirection`, `BriefingStatus`, `ChartPeriod`）
3. 全 `@Model` 実装（`HubDashboard`, `MorningRoutine`, `MorningRoutineItem`, `DomainSnapshot`, `HubUserPreferences`, `WeeklySummary`, `DailyBriefing`, `QuickAction`）
4. `PapaHubError` 実装
5. 全 Protocol 実装（6つ）
6. `ScoreCalculator`, `MorningRoutineService`, `HubDataService`, `DomainAggregatorService`, `WidgetDataService`, `NotificationScheduler` 実装
7. モデル・サービステスト実行

### Phase 2: ViewModel + Mock テスト

1. 全 Mock サービス実装（5つ）
2. 全 ViewModel 実装（8つ: Dashboard, MorningRoutine, Health, Family, Finance, Community, Learning, Settings）
3. 全 ViewModel テスト実行
4. `swift test` — 全テスト通過確認

### Phase 3: アプリスケルトン + コア UI

1. `project.yml` 作成（iOS 26.0、xcodeVersion 26.0、AsaUIKit + AsaPapaHubKit + AsaCoreKit 依存）
2. `AsaPapaHubApp.swift`（Tips.configure() + .modelContainer()）
3. `ContentView.swift`（5タブ構成）
4. `DashboardView` + 全サマリーカード（MorningScore, Health, Family, Finance, Community, Learning）
5. `MorningRoutineView` + `RoutineItemRow`
6. 再利用コンポーネント: `ScoreRing`, `TrendIndicator`, `DomainSectionHeader`, `EmptyDomainView`
7. `SampleDataLoader.swift`（豊富なデモデータ）
8. `Shared/SharedDefaults.swift` + `PapaHubWidgetData.swift`
9. `xcodegen generate` + `xcodebuild build` 成功確認

### Phase 4: ドメイン詳細 View

1. `HealthOverviewView`（Charts: 歩数折れ線、睡眠棒グラフ、アクティビティリング）
2. `FamilyHubView`, `FinanceOverviewView`, `CommunityOverviewView`, `LearningOverviewView`
3. `SettingsView` + サブビュー（Domain, AI, Notification, About）
4. `OnboardingView` + `DomainSelectionView`

### Phase 5: Foundation Models AI 統合

1. `@Generable` モデル実装（`MorningBriefing`, `WeeklySummaryReport`, `AISearchResult`）
2. `PapaHubAIService` 実装（`LanguageModelSession.isAvailable` ガード付き）
3. `AIBriefingView`（ストリーミング UI）
4. `AISearchView`（自然言語検索）
5. `StreamingResponseView` コンポーネント
6. フォールバック: AI 非対応デバイスではヒューリスティックベースのブリーフィング

### Phase 6: App Intents + Siri

1. `MorningScoreIntent`, `WeeklySummaryIntent`, `QuickEntryIntent` 実装
2. `PapaHubShortcuts`（AppShortcutsProvider）
3. `SiriTipBanner` を DashboardView と MorningRoutineView に配置

### Phase 7: Widget Extension + Live Activity

1. `PapaHubWidgetExtension/` ディレクトリ作成
2. `PapaHubWidget.swift`（WidgetBundle）
3. `PapaHubWidgetProvider.swift`（TimelineProvider）
4. 5種類の Widget View 実装
5. `InteractiveWidgetButtons`（AppIntent トリガー）
6. `MorningRoutineAttributes` + `MorningRoutineLiveActivityView`
7. App Group entitlement 設定
8. project.yml に PapaHubWidgetExtension ターゲット追加

### Phase 8: テスト・ドキュメント・仕上げ

1. 全統合テスト実行
2. UI アニメーション調整（0.2s easeInOut、ブランドカラー統一）
3. アクセシビリティラベル追加
4. `Docs/Notes/Day100-AsaPapaHub-Implementation.md` 作成
5. `xcodebuild -sdk iphonesimulator build` エラー0件最終確認
6. git commit

---

## 重要な参照ファイル

| ファイル | 参照理由 |
|---------|---------|
| `Apps/AsaRecipeAI/AsaRecipeAI/Services/RecipeAIService.swift` | Foundation Models パターン |
| `Apps/AsaRecipeAI/AsaRecipeAI/Models/Generable/RecipeRecommendation.swift` | @Generable モデルパターン |
| `Apps/AsaRecipeAI/project.yml` | iOS 26.0 + xcodeVersion 26.0 設定 |
| `Apps/AsaLifeLog/project.yml` | Widget Extension + entitlements 設定 |
| `Apps/AsaLifeLog/Sources/ContentView.swift` | タブ構成 + ViewModel 生成パターン |
| `Packages/AsaLifeLogKit/Sources/AsaLifeLogKit/Models/LifeLogEntry.swift` | @Model + enum rawValue パターン |
| `Packages/AsaLifeLogKit/Sources/AsaLifeLogKit/Protocols/LifeLogDataServiceProtocol.swift` | Protocol DI パターン |
| `Packages/AsaLifeLogKit/Sources/AsaLifeLogKit/ViewModels/DashboardViewModel.swift` | @MainActor @Observable ViewModel パターン |
| `Packages/AsaCoreKit/Sources/AsaCoreKit/ViewModels/BaseViewModel.swift` | BaseViewModel パターン |
| `Packages/AsaUIKit/Sources/AsaUIKit/Colors/AsaColors.swift` | ブランドカラー定義 |

---

## 検証方法

1. **パッケージテスト**: `cd Packages/AsaPapaHubKit && swift test` → 100+ テスト全通過
2. **ビルド確認**: `xcodegen generate && xcodebuild -project AsaPapaHub.xcodeproj -scheme AsaPapaHub -sdk iphonesimulator build` → エラー0件
3. **Widget ビルド**: PapaHubWidgetExtension ターゲットのビルド成功確認
4. **AI 動作**: Foundation Models 非対応デバイスでもフォールバックで動作確認
5. **アプリテスト**: `xcodebuild test -scheme AsaPapaHub -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
