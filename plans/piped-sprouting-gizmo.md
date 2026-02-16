# AsaLifeLog (#99) 実装計画

## Context

100本ノックの99番目 — フィナーレ直前の集大成アプリ。**ライフログを統合管理**するアプリとして、HealthKit、CoreLocation、CoreMotion、Photos、Swift Charts、WidgetKit、TipKit など複数の Apple フレームワークを統合し、AIヒューリスティック分析でインサイトを提供する上級アプリ。

## コンセプト

健康データ、位置情報、写真、アクティビティ、気分、メモを **統合タイムライン** に集約し、日次/週次のAIインサイトと美しいチャートで「自分の毎日」を振り返れるアプリ。朝活パパエンジニアとして「朝活スコア」機能も搭載。

---

## 技術スタック（iOS最新動向を反映）

| 技術 | 用途 |
|------|------|
| **SwiftData** (iOS 18) | 全データ永続化。`#Index` によるクエリ最適化 |
| **AsaHealthKit** (既存) | 歩数/睡眠/水分/気分/体重/心拍/体脂肪/ワークアウト 統合 |
| **CoreLocation** | 訪問場所の自動記録 + ジオコーディング |
| **CoreMotion** (新規) | 歩行/走行/自転車/運転/静止 の自動検出 |
| **Photos/PhotosUI** | 日のタイムラインに関連写真を自動関連付け |
| **Swift Charts** | 6種のチャート (Line, Bar, Area, Sector, Rule) |
| **WidgetKit** | ホーム/ロック画面に本日サマリー表示 (5サイズ) |
| **TipKit** | 各機能へのコンテキストTips |
| **MapKit** | 場所の地図表示 + アノテーション |
| **Swift 6.0 Concurrency** | `SWIFT_STRICT_CONCURRENCY: complete` |

---

## パッケージ構成

### AsaLifeLogKit (新規作成)
- swift-tools-version: 6.0 / iOS 18+, macOS 15+
- **依存なし** (フレームワーク非依存、プロトコル抽象化)
- Models / Protocols / Services / ViewModels / Errors

### アプリ側依存
```yaml
packages:
  AsaUIKit: ../../Packages/AsaUIKit
  AsaLifeLogKit: ../../Packages/AsaLifeLogKit
  AsaHealthKit: ../../Packages/AsaHealthKit   # swift 5.9 / iOS 17+
  AsaCoreKit: ../../Packages/AsaCoreKit       # AsaHealthKit の依存
```

---

## データモデル (SwiftData @Model)

### LifeLogEntry — タイムラインのコアエンティティ
```
id: UUID (@Attribute(.unique))
timestamp: Date
entryTypeRawValue: String     → manual/health/location/photo/activity/mood
title: String
content: String?
moodScoreRawValue: String?    → terrible(1)〜great(5)
tags: [String]
latitude/longitude: Double?
locationName: String?
photoAssetIdentifiers: [String]
activityTypeRawValue: String? → stationary/walking/running/cycling/driving
durationSeconds: Double?
sourceRawValue: String        → manual/healthKit/coreLocation/photoLibrary/coreMotion
healthMetricTypeRawValue: String?
healthMetricValue: Double?
aiSummary: String?
isFavorite: Bool
createdAt/updatedAt: Date
```

### DailySummary — 日次サマリー
```
id, date, entryCount, moodAverage, totalSteps, totalDistanceKm,
sleepHours, waterIntakeMl, dominantActivityRawValue,
visitedPlaces: [String], photoCount, aiInsightText, highlightEntryId
```

### WeeklySummary — 週次サマリー
```
id, weekStartDate, weekEndDate, entryCount, averageMood,
totalSteps, averageSleepHours, topTags: [String],
trendInsight, comparisonWithPreviousWeek
```

### PlaceLog — 場所ログ
```
id, name, latitude, longitude, address,
categoryRawValue (home/work/restaurant/shop/park/gym/other),
visitCount, firstVisitedAt, lastVisitedAt, isFavorite
```

### UserPreferences — ユーザー設定
```
enableHealthTracking, enableLocationTracking,
enablePhotoIntegration, enableActivityRecognition, enableAIInsights,
dailyReminderTime, preferredChartPeriodRawValue,
morningRoutineStartHour (5), morningRoutineEndHour (7)
```

---

## ビュー階層 (4タブ構成)

```
TabView
├── Tab 1: タイムライン (TimelineView)
│   ├── TimelineFilterBar (日付/ソースフィルタ)
│   ├── LazyVStack → TimelineDateHeader + TimelineEntryRow
│   └── FAB → EntryEditorSheet (mood/tags/location/photo)
│
├── Tab 2: ダッシュボード (DashboardView)
│   ├── 期間セレクタ (週/月/3ヶ月/年)
│   └── DailyStatsCard, MoodDistributionChart (SectorMark)
│       StepsLineChart, SleepBarChart, ActivityBreakdownChart, WeeklyTrendChart
│
├── Tab 3: インサイト (InsightsView)
│   ├── DailySummaryCard (朝活スコア含む)
│   ├── WeeklySummaryCard
│   └── PatternCard (相関分析結果)
│
└── Tab 4: 設定 (SettingsView)
    ├── データソースON/OFF
    ├── 目標設定 / エクスポート
    └── 場所一覧 (PlaceMapView) / 写真一覧
```

---

## サービス層

| サービス | 責務 | 参考実装 |
|---------|------|---------|
| **LifeLogDataService** | SwiftData CRUD (エントリー/サマリー/場所) | AsaCommunityKit/CommunityDataService |
| **LocationTrackingService** | CLLocationManager + ジオコーディング | AsaCommunityKit/LocationService |
| **PhotoIntegrationService** | PHAsset取得 + サムネイル/EXIF | AsaFamilyAlbum/PhotoLibraryService |
| **ActivityRecognitionService** | CMMotionActivityManager (新規) | — |
| **InsightsEngine** | ヒューリスティック日次/週次分析 | AsaSmartTodo/TaskPriorityPredictor |
| **DailySummaryGenerator** | InsightsEngine呼び出し→DailySummary生成 | — |
| **WeeklySummaryGenerator** | InsightsEngine呼び出し→WeeklySummary生成 | — |
| **ExportService** | JSON/CSV エクスポート | — |

### InsightsEngine 分析項目
- 朝活時間帯(5:00-7:00)のエントリー密度 → **朝活スコア**
- 気分と活動量の相関分析
- 場所訪問パターン（ルーチン検出）
- 睡眠時間と翌日気分の相関
- 写真枚数と気分の相関

---

## ViewModel層

| ViewModel | 主要メソッド |
|-----------|-------------|
| **TimelineViewModel** | loadEntries, filterBySource, refreshAllSources, toggleFavorite, deleteEntry |
| **DashboardViewModel** | loadDashboardData, changePeriod |
| **EntryEditorViewModel** | saveEntry, addTag, removeTag, setCurrentLocation |
| **InsightsViewModel** | generateTodayInsights, generateWeeklyInsights, detectPatterns |
| **SettingsViewModel** | toggleHealthTracking, exportData, requestAllPermissions |
| **PlaceLogViewModel** | loadPlaces, toggleFavorite |

---

## Widget設計 (WidgetKit)

App Group `group.com.asapapa.apps.asalifelog` でデータ共有。

| サイズ | 内容 |
|--------|------|
| systemSmall | 気分 + エントリー数 + 朝活スコア |
| systemMedium | 気分 + 歩数 + 睡眠 + エントリー数 |
| systemLarge | 本日タイムライン要約 (直近5件) |
| accessoryCircular | 朝活スコアゲージ |
| accessoryRectangular | 歩数 + 気分 (ロック画面) |

---

## テスト戦略 (目標: 110+テスト)

| カテゴリ | 件数 | 内容 |
|---------|------|------|
| モデルテスト | 25 | 全@Model, enum, computed property |
| サービステスト | 40 | DataService, Location, Photo, Activity, Insights, Generators, Export |
| ViewModelテスト | 30 | Timeline, Dashboard, EntryEditor, Insights, Settings, PlaceLog |
| 統合テスト | 10 | タイムラインフロー, データフロー, インサイト生成 |
| パフォーマンステスト | 5 | タイムラインロード, インサイト生成 |

Mock戦略: 全サービスをプロトコル経由で差し替え可能。MockLifeLogDataService(インメモリ), MockLocationTrackingService(固定座標), MockActivityRecognitionService(固定アクティビティ) 等。

---

## project.yml

```yaml
name: AsaLifeLog
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
  AsaLifeLogKit:
    path: ../../Packages/AsaLifeLogKit
  AsaHealthKit:
    path: ../../Packages/AsaHealthKit
  AsaCoreKit:
    path: ../../Packages/AsaCoreKit
targets:
  AsaLifeLog:
    type: application
    platform: iOS
    sources: [Sources]
    resources: [Sources/Assets.xcassets]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.asapapa.apps.asalifelog
      GENERATE_INFOPLIST_FILE: true
      INFOPLIST_KEY_UIApplicationSceneManifest_Generation: true
      INFOPLIST_KEY_UILaunchScreen_Generation: true
      INFOPLIST_KEY_CFBundleDisplayName: "AsaLifeLog"
      INFOPLIST_KEY_LSApplicationCategoryType: "public.app-category.lifestyle"
      INFOPLIST_KEY_NSLocationWhenInUseUsageDescription: "訪問場所を記録しタイムラインに表示するために位置情報を使用します"
      INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription: "バックグラウンドでの場所記録のために位置情報を使用します"
      INFOPLIST_KEY_NSPhotoLibraryUsageDescription: "タイムラインに写真を統合するためにフォトライブラリを使用します"
      INFOPLIST_KEY_NSMotionUsageDescription: "歩行やランニング等のアクティビティを自動検出するためにモーションデータを使用します"
      INFOPLIST_KEY_NSHealthShareUsageDescription: "歩数や睡眠等の健康データをライフログに統合するために使用します"
      SWIFT_STRICT_CONCURRENCY: complete
      CODE_SIGN_ENTITLEMENTS: Sources/AsaLifeLog.entitlements
    entitlements:
      com.apple.developer.healthkit: true
      com.apple.developer.healthkit.access: []
    dependencies:
      - package: AsaUIKit
      - package: AsaLifeLogKit
      - package: AsaHealthKit
      - package: AsaCoreKit
      - target: LifeLogWidgetExtension
        embed: true
        codeSignOnCopy: true
  LifeLogWidgetExtension:
    type: app-extension
    platform: iOS
    sources: [LifeLogWidgetExtension, Shared]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.asapapa.apps.asalifelog.widget
      GENERATE_INFOPLIST_FILE: true
      SKIP_INSTALL: "YES"
      LD_RUNPATH_SEARCH_PATHS: "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks"
    dependencies:
      - package: AsaUIKit
  AsaLifeLogTests:
    type: bundle.unit-test
    platform: iOS
    sources: [AsaLifeLogTests]
    settings:
      GENERATE_INFOPLIST_FILE: true
    dependencies:
      - target: AsaLifeLog
  AsaLifeLogUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [AsaLifeLogUITests]
    settings:
      GENERATE_INFOPLIST_FILE: true
    dependencies:
      - target: AsaLifeLog
schemes:
  AsaLifeLog:
    build:
      targets:
        AsaLifeLog: all
        LifeLogWidgetExtension: all
        AsaLifeLogTests: [test]
    run:
      config: Debug
    test:
      config: Debug
      targets: [AsaLifeLogTests]
    profile:
      config: Release
    analyze:
      config: Debug
    archive:
      config: Release
```

---

## ディレクトリ構成

```
Packages/AsaLifeLogKit/
  Package.swift
  Sources/AsaLifeLogKit/
    Models/       (LifeLogEntry, DailySummary, WeeklySummary, PlaceLog, UserPreferences)
    Models/Enums/ (EntryType, MoodScore, ActivityType, DataSource, PlaceCategory, ChartPeriod)
    Protocols/    (6プロトコル: DataService, Location, Photo, Activity, Insights, Timeline)
    Services/     (8サービス)
    ViewModels/   (6ViewModel)
    Errors/       (LifeLogError)
  Tests/AsaLifeLogKitTests/
    Models/       Services/       ViewModels/
    Integration/  Performance/

Apps/AsaLifeLog/
  project.yml
  Sources/
    AsaLifeLogApp.swift / ContentView.swift
    Views/
      Timeline/   (TimelineView, EntryRow, FilterBar, DateHeader)
      Entry/      (EditorSheet, MoodSelector, TagInput, LocationPicker, PhotoAttachment)
      Dashboard/  (DashboardView, 6種チャート)
      Insights/   (InsightsView, DailySummaryCard, WeeklySummaryCard, PatternCard)
      Places/     (PlaceMapView, PlaceListView, PlaceDetailView)
      Photos/     (PhotoTimelineView, PhotoGridView)
      Settings/   (SettingsView, DataSourceToggle, GoalSettings, Export, About)
      Components/ (AsaLifeLogCard, MoodBadge, ActivityIcon, StatRing, EmptyState)
      Onboarding/ (OnboardingView, PermissionRequestView)
    Services/     (4つのBridgeサービス: Health, Location, Photo, Motion + SampleDataLoader)
  Shared/         (LifeLogWidgetData, SharedDefaults)
  LifeLogWidgetExtension/
    LifeLogWidget.swift, Provider, 5つのWidgetView
```

---

## 実装フェーズ (4段階)

### Phase 1: 基盤 (Models + Core + 手動エントリー)
1. AsaLifeLogKit パッケージ作成
2. 全Enum定義 (6種)
3. 全@Modelクラス定義 (5種)
4. 全Protocol定義 (6種)
5. LifeLogDataService (SwiftData CRUD)
6. EntryEditorViewModel + TimelineViewModel
7. アプリ骨格 (App, ContentView, 4タブ)
8. TimelineView + EntryEditorSheet
9. モデルテスト (25件)

### Phase 2: データソース統合
10. AppHealthKitBridge (AsaHealthKit → LifeLogEntry変換)
11. LocationTrackingService + AppLocationBridge
12. PhotoIntegrationService + AppPhotoBridge
13. ActivityRecognitionService (CMMotionActivityManager, 新規)
14. SettingsViewModel + SettingsView + OnboardingView
15. サービステスト (40件)

### Phase 3: インサイト + チャート
16. FeatureExtractor + InsightsEngine (朝活スコア, 相関分析)
17. DailySummaryGenerator + WeeklySummaryGenerator
18. InsightsViewModel + InsightsView (3種のカード)
19. DashboardViewModel + DashboardView (6種のSwift Charts)
20. PlaceMapView + PlaceLogViewModel
21. ViewModelテスト (30件)

### Phase 4: Widget + 仕上げ
22. SharedDefaults + App Group設定
23. LifeLogWidget (5サイズ)
24. TipKit オンボーディング
25. ExportService (JSON/CSV)
26. SampleDataLoader (#if DEBUG)
27. 統合テスト + パフォーマンステスト (15件)
28. ドキュメント (Docs/Notes/Day99-Implementation.md)

---

## 参照すべき既存ファイル

| ファイル | 参照目的 |
|---------|---------|
| `Packages/AsaHealthKit/Sources/AsaHealthKit/Models/HealthMetric.swift` | HealthMetricType enum, GenericHealthRecord 構造 |
| `Packages/AsaHealthKit/Sources/AsaHealthKit/Managers/HealthManager.swift` | HealthKit API 統合パターン |
| `Packages/AsaCommunityKit/Sources/AsaCommunityKit/Services/LocationService.swift` | CoreLocation + @MainActor パターン |
| `Apps/AsaFamilyAlbum/AsaFamilyAlbum/Services/PhotoLibraryService.swift` | Photos/PhotosUI 統合パターン |
| `Apps/AsaSmartTodo/AsaSmartTodo/Services/TaskPriorityPredictor.swift` | ヒューリスティックAI分析パターン |
| `Apps/AsaQuoteWidget/project.yml` | Widget Extension の project.yml 構成 |
| `Apps/AsaCommunity/project.yml` | 最新の標準 project.yml パターン |

---

## 検証方法

1. **パッケージビルド**: `cd Packages/AsaLifeLogKit && swift build`
2. **パッケージテスト**: `cd Packages/AsaLifeLogKit && swift test`
3. **XcodeGen生成**: `cd Apps/AsaLifeLog && xcodegen generate`
4. **アプリビルド**: `xcodebuild -project AsaLifeLog.xcodeproj -scheme AsaLifeLog -sdk iphonesimulator build`
5. **アプリテスト**: `xcodebuild test -project AsaLifeLog.xcodeproj -scheme AsaLifeLog -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
