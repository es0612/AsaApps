# AsaCommunity (#98) 実装計画

## Context

100本ノックの98番目、上級アプリ「AsaCommunity - 地域コミュニティ用アプリ」の設計・実装計画。
日本の地域コミュニティ（町内会・自治会）をデジタル化し、掲示板、イベント管理、防災情報、ゴミ出しカレンダー、近隣マップを統合した地域住民向けアプリ。

**上級アプリとして10以上のiOSフレームワーク**（MapKit, CoreLocation, NaturalLanguage, Charts, TipKit, App Intents, UserNotifications, PhotosUI, SwiftData等）を統合し、protocol-basedサービスアーキテクチャで実装する。

**データ戦略**: SwiftData（ローカル永続化）+ MockCommunityFeedService（コミュニティデータシミュレーション）。SwiftData+CloudKitはプライベート同期のみのため、バックエンド接続可能なprotocol設計で将来対応。

---

## パッケージ構成

AsaFinancePlannerKit のパターンに準拠。

```
Packages/AsaCommunityKit/
├── Package.swift                        # swift-tools-version: 6.0, iOS 18+
├── Sources/AsaCommunityKit/
│   ├── Models/                          (14ファイル)
│   │   ├── CommunityProfile.swift       # @Model: ユーザープロフィール
│   │   ├── Community.swift              # @Model: コミュニティ（町内会）
│   │   ├── CommunityPost.swift          # @Model: 掲示板投稿
│   │   ├── PostCategory.swift           # enum: 投稿カテゴリ(8種)
│   │   ├── CommunityEvent.swift         # @Model: イベント
│   │   ├── EventRSVP.swift              # @Model: 参加表明 + RSVPStatus enum
│   │   ├── SafetyReport.swift           # @Model: 安全レポート
│   │   ├── SafetyAlertLevel.swift       # enum: 警戒レベル(4段階)
│   │   ├── EvacuationShelter.swift      # @Model: 避難所
│   │   ├── GarbageSchedule.swift        # @Model: ゴミ出しスケジュール
│   │   ├── GarbageType.swift            # enum: ゴミ種類(7種)
│   │   ├── LocalBusiness.swift          # @Model: 地域のお店
│   │   ├── BusinessCategory.swift       # enum: 店舗カテゴリ(7種)
│   │   └── CommunitySettings.swift      # @Model: アプリ設定
│   │
│   ├── Protocols/                       (5ファイル)
│   │   ├── CommunityDataServiceProtocol.swift  # SwiftData CRUD全体
│   │   ├── CommunityFeedServiceProtocol.swift  # バックエンド抽象化
│   │   ├── LocationServiceProtocol.swift       # CoreLocation抽象化
│   │   ├── NotificationServiceProtocol.swift   # 通知抽象化
│   │   └── ContentModerating.swift             # 感情分析抽象化
│   │
│   ├── Services/                        (7ファイル)
│   │   ├── CommunityDataService.swift        # SwiftData CRUD
│   │   ├── MockCommunityFeedService.swift    # モックコミュニティフィード
│   │   ├── LocationService.swift             # CLLocationManager wrapper
│   │   ├── NotificationService.swift         # UNUserNotificationCenter
│   │   ├── ContentModerationService.swift    # NLTagger感情分析
│   │   ├── GarbageScheduleService.swift      # 次回収集日計算
│   │   └── SampleDataService.swift           # サンプルデータ生成
│   │
│   ├── ViewModels/                      (8ファイル)
│   │   ├── CommunityHomeViewModel.swift      # ダッシュボード統合
│   │   ├── PostFeedViewModel.swift           # 掲示板+検索+モデレーション
│   │   ├── EventCalendarViewModel.swift      # カレンダー/リスト+RSVP
│   │   ├── NeighborhoodMapViewModel.swift    # マップ+フィルタ
│   │   ├── SafetyViewModel.swift             # 防災+避難所+安否確認
│   │   ├── GarbageScheduleViewModel.swift    # ゴミ出し+リマインダー
│   │   ├── LocalBusinessViewModel.swift      # 店舗+お気に入り
│   │   └── ProfileSettingsViewModel.swift    # プロフィール+設定
│   │
│   ├── Errors/
│   │   └── CommunityError.swift              # LocalizedError
│   │
│   └── Analytics/
│       └── CommunityAnalytics.swift          # Charts用データ集計
│
└── Tests/AsaCommunityKitTests/          (16ファイル)
    ├── Models/ (5ファイル)
    ├── Services/ (4ファイル)
    └── ViewModels/ (7ファイル: MockServices含む)
```

```
Apps/AsaCommunity/
├── project.yml
├── Sources/
│   ├── AsaCommunityApp.swift
│   ├── ContentView.swift                # 5タブ TabView
│   ├── Assets.xcassets/
│   └── Views/
│       ├── Home/CommunityHomeView.swift
│       ├── Feed/ (4ファイル: PostFeedView, PostCardView, PostDetailView, CreatePostSheet)
│       ├── Events/ (4ファイル: EventCalendarView, EventListView, EventDetailView, CreateEventSheet)
│       ├── Map/ (2ファイル: NeighborhoodMapView, MapAnnotationView)
│       ├── Safety/ (3ファイル: SafetyDashboardView, ShelterMapView, SafetyReportSheet)
│       ├── Garbage/GarbageScheduleView.swift
│       ├── Business/ (2ファイル: BusinessListView, BusinessDetailView)
│       ├── Profile/ProfileSettingsView.swift
│       ├── Components/ (4ファイル: CategoryChipView, StatCard, EmptyStateView, CommunityAnalyticsChart)
│       └── Onboarding/OnboardingView.swift
├── AsaCommunityTests/
└── AsaCommunityUITests/
```

**合計: 約85ファイル**

---

## コア機能（5タブ構成）

| タブ | 機能 | 主要技術 |
|------|------|----------|
| **ホーム** | ダッシュボード: 今日のゴミ出し、近日イベント、未読投稿、安全アラート | SwiftData, Charts |
| **掲示板** | 投稿一覧/作成: 8カテゴリ(イベント/質問/譲ります/探しています/回覧板/防犯防災/子育て/一般) | PhotosUI, NaturalLanguage |
| **イベント** | カレンダー/リスト表示、RSVP参加表明、イベント作成 | MapKit, UserNotifications |
| **マップ** | 投稿/イベント/店舗/避難所のマップ表示、半径フィルタ | MapKit, CoreLocation |
| **防災** | 安全レポート、避難所マップ、安否確認、ゴミ出しカレンダー | MapKit, UserNotifications |

### 日本コミュニティ特化機能
- **回覧板**: 既読管理付きデジタル回覧（PostCategory.circular）
- **防災マップ**: 避難所位置・収容人数・設備情報
- **ゴミ出しカレンダー**: 曜日別ゴミ種別 + 前夜リマインダー
- **子育て支援**: 子育て関連投稿カテゴリ
- **見守り**: 安全レポート投稿 + 安否確認

---

## iOSフレームワーク統合（10+）

| # | フレームワーク | 使用箇所 |
|---|---|---|
| 1 | **SwiftData** | 全@Model永続化（14モデル） |
| 2 | **MapKit** | NeighborhoodMapView, ShelterMapView（Map, Annotation, MapCameraPosition） |
| 3 | **CoreLocation** | LocationService（位置権限, 距離計算） |
| 4 | **NaturalLanguage** | ContentModerationService（NLTagger感情分析, 言語検出） |
| 5 | **Charts** | CommunityAnalyticsChart（投稿数推移, カテゴリ分布） |
| 6 | **TipKit** | OnboardingView（初回機能案内） |
| 7 | **UserNotifications** | NotificationService（ゴミ出し/イベント/安全アラート） |
| 8 | **PhotosUI** | CreatePostSheet（PhotosPicker投稿画像選択） |
| 9 | **App Intents** | 「今日のゴミ出し」「近くのイベント」Siriショートカット |
| 10 | **Foundation (Calendar)** | GarbageScheduleService（曜日計算, 次回収集日） |

---

## データモデル設計

### @Model パターン（FinancialGoal.swift 準拠）
- enum は `rawValue: String` で保存 + computed accessor
- `Decimal` は `Decimal.zero` 完全修飾
- `@Model` に `Sendable` 不使用
- `var id: UUID = UUID()`（let ではなく var）
- `@Relationship(deleteRule: .cascade)` でリレーション

### 主要モデル関係
```
Community (1) ──→ (n) CommunityPost
Community (1) ──→ (n) CommunityEvent
CommunityProfile (1) ──→ (n) CommunityPost
CommunityProfile (1) ──→ (n) EventRSVP
CommunityEvent (1) ──→ (n) EventRSVP
```

---

## 実装フェーズ

### Phase 1: 基盤層（Package + Models + Protocols + Errors）
- Package.swift
- 14 Models, 5 Protocols, CommunityError
- `swift build` 型チェック

### Phase 2: サービス層
- 7 Services（DataService, MockFeed, Location, Notification, Moderation, Garbage, SampleData）

### Phase 3: ViewModel層
- 8 ViewModels + CommunityAnalytics

### Phase 4: テスト層
- MockServices + 15テストファイル（80+テストケース）
- `swift test` 全パス確認

### Phase 5: App層（Views + project.yml）
- project.yml（iOS 18, AsaUIKit + AsaCommunityKit依存）
- 25 View ファイル（ContentView + 21 Views + App + Assets）
- `xcodegen generate && xcodebuild -sdk iphonesimulator build`

### Phase 6: ドキュメント
- `Docs/Notes/Day98-AsaCommunity-Implementation.md`

---

## 参照ファイル（実装時の参考）

| パターン | 参照ファイル |
|---------|------------|
| @Model enum保存 | `Packages/AsaFinancePlannerKit/Sources/.../Models/FinancialGoal.swift` |
| Package.swift | `Packages/AsaFinancePlannerKit/Package.swift` |
| project.yml | `Apps/AsaFinancePlanner/project.yml` |
| Protocol設計 | `Packages/AsaFinancePlannerKit/Sources/.../Protocols/FinanceDataServiceProtocol.swift` |
| ViewModel DI | `Packages/AsaFinancePlannerKit/Sources/.../ViewModels/DashboardViewModel.swift` |
| ContentView TabView | `Apps/AsaFinancePlanner/Sources/ContentView.swift` |
| MockServices | `Packages/AsaFinancePlannerKit/Tests/.../ViewModels/MockServices.swift` |

---

## 検証方法

```bash
# 1. Package ビルド
cd Packages/AsaCommunityKit && swift build

# 2. Package テスト
swift test

# 3. App プロジェクト生成
cd Apps/AsaCommunity && xcodegen generate

# 4. App ビルド
xcodebuild -project AsaCommunity.xcodeproj -scheme AsaCommunity \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# 5. 全テスト実行
xcodebuild test -project AsaCommunity.xcodeproj -scheme AsaCommunity \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```
