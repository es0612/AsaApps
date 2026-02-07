# AsaSmartReminder (#94) - 位置情報に基づくスマートリマインダー 実装計画

## 概要

位置情報ベースのジオフェンシングを活用し、特定の場所への到着/離脱時に自動通知するスマートリマインダーアプリ。iOS 17+のモダンAPI（CLMonitor、MapKit for SwiftUI）を全面活用した上級アプリ。

**差別化（AsaReminder #40 との違い）**: #40は日時ベース通知（UNCalendarNotificationTrigger）。#94は位置ベース通知（CLMonitor + UNLocationNotificationTrigger）、地図UI、動的ジオフェンス管理、Siri統合。

---

## 技術スタック

| 技術 | 用途 | バージョン |
|------|------|-----------|
| CLMonitor | ジオフェンシング（async/await） | iOS 17+ |
| MapKit for SwiftUI | 地図表示・ジオフェンス可視化 | iOS 17+ |
| SwiftData | データ永続化（@Model） | iOS 17+ |
| UNLocationNotificationTrigger | バックグラウンド位置通知 | iOS 17+ |
| App Intents | Siri統合 | iOS 17+ |
| @Observable | 状態管理 | iOS 17+ |
| Swift Testing | テスト（@Test, #expect） | - |

---

## 機能一覧

### MVP（必須）
1. **位置ベースリマインダーCRUD** - 場所+メッセージ+到着/離脱トリガー設定
2. **地図ジオフェンス設定** - Map + MapCircle でジオフェンス範囲を可視化・設定
3. **CLMonitor ジオフェンシング** - async/awaitイベントストリームで到着/離脱検知
4. **ローカル位置通知** - UNLocationNotificationTrigger でバックグラウンド通知
5. **リマインダー一覧管理** - リスト表示、完了/未完了、フィルタ、削除
6. **動的リージョン管理** - 20件制限対応（ユーザー位置から近い順に優先監視）
7. **権限オンボーディング** - 位置情報（Always推奨）+ 通知許可のステップガイド
8. **家族向けプリセット場所** - 自宅/学校/スーパー/職場/駅等のカテゴリアイコン
9. **場所検索** - MKLocalSearch で住所・店名から場所を検索

### 拡張（Nice to have）
- App Intents / Siri統合（「スーパーに着いたら牛乳を買う」）
- Live Activities（接近時にロック画面でリアルタイム距離表示）
- ウィジェット（近くのリマインダー表示）

---

## データモデル設計

### ReminderLocation（場所）
```swift
@Model final class ReminderLocation {
    @Attribute(.unique) var id: UUID
    var name: String                    // 場所名（例: イオンモール）
    var latitude: Double
    var longitude: Double
    var radius: Double                  // ジオフェンス半径（メートル）デフォルト100m
    var address: String?                // 逆ジオコーディング結果
    var categoryRawValue: String        // LocationCategory.rawValue
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \LocationReminder.location)
    var reminders: [LocationReminder]
}
```

### LocationReminder（リマインダー）
```swift
@Model final class LocationReminder {
    @Attribute(.unique) var id: UUID
    var title: String                   // タイトル（例: 牛乳を買う）
    var note: String?
    var triggerOnEntry: Bool             // 到着時通知（デフォルトtrue）
    var triggerOnExit: Bool              // 離脱時通知（デフォルトfalse）
    var isRepeating: Bool               // 毎回通知
    var isCompleted: Bool
    var completedAt: Date?
    var isActive: Bool                  // 監視有効/無効
    var lastTriggeredAt: Date?
    var triggerCount: Int
    var notificationIdentifier: String?
    var location: ReminderLocation?
    var createdAt: Date
    var updatedAt: Date
}
```

### LocationCategory（場所カテゴリ）
```swift
enum LocationCategory: String, Codable, CaseIterable, Sendable {
    case home, work, school, supermarket, station, hospital, park, gym, custom
    var displayName: String { ... }     // 日本語名
    var systemImageName: String { ... } // SFSymbol
    var defaultRadius: Double { ... }   // カテゴリ別デフォルト半径
}
```

### UserLocationSettings（設定）
```swift
@Model final class UserLocationSettings {
    var id: UUID
    var defaultRadius: Double           // デフォルト半径 100m
    var defaultTriggerOnEntry: Bool     // デフォルト到着トリガー
    var defaultTriggerOnExit: Bool      // デフォルト離脱トリガー
    var hapticFeedbackEnabled: Bool
}
```

---

## アーキテクチャ（MVVM + パッケージ分離）

### パッケージ: Packages/AsaSmartReminderKit/
ビジネスロジック・データモデルを全てパッケージに集約（AsaFamilyTreeKitパターン踏襲）

```
Sources/AsaSmartReminderKit/
├── Models/
│   ├── ReminderLocation.swift
│   ├── LocationReminder.swift
│   ├── LocationCategory.swift
│   ├── MonitoringState.swift
│   └── UserLocationSettings.swift
├── Services/
│   ├── ReminderDataService.swift       # SwiftData CRUD（inMemoryテスト対応）
│   ├── GeofenceMonitorService.swift    # CLMonitor ラッパー（actor）
│   ├── LocationSearchService.swift     # MKLocalSearch ラッパー
│   ├── NotificationService.swift       # UNLocationNotificationTrigger
│   ├── RegionPrioritizer.swift         # 20件制限の動的優先度管理（純粋ロジック）
│   └── PermissionService.swift         # 位置情報+通知の権限管理
├── ViewModels/
│   ├── SmartReminderViewModel.swift    # メインVM（CRUD、監視、フィルタ）
│   ├── LocationPickerViewModel.swift   # 地図場所選択VM
│   └── SettingsViewModel.swift         # 設定VM
├── Errors/
│   └── SmartReminderError.swift
└── Protocols/
    ├── GeofenceMonitoring.swift        # テスト用プロトコル
    └── LocationSearching.swift         # テスト用プロトコル
```

### アプリ本体: Apps/AsaSmartReminder/
```
Sources/
├── AsaSmartReminderApp.swift
├── ContentView.swift                   # TabView（4タブ）
├── Views/
│   ├── Reminders/
│   │   ├── ReminderListView.swift      # リマインダー一覧
│   │   ├── ReminderCardView.swift      # カード（AsaCard活用）
│   │   ├── AddReminderView.swift       # 追加シート
│   │   └── EditReminderView.swift      # 編集シート
│   ├── Map/
│   │   ├── MapOverviewView.swift       # 全場所地図表示
│   │   └── GeofenceAnnotationView.swift
│   ├── Locations/
│   │   ├── LocationManagementView.swift # 場所管理一覧
│   │   ├── LocationCardView.swift
│   │   ├── LocationPickerView.swift    # 地図で場所選択
│   │   └── LocationSearchBarView.swift # MKLocalSearch
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── PermissionStatusView.swift
│   ├── Onboarding/
│   │   ├── PermissionOnboardingView.swift
│   │   └── OnboardingStepView.swift
│   └── Common/
│       ├── EmptyStateView.swift
│       └── MonitoringStatusBadge.swift
└── Assets.xcassets/
```

---

## 画面構成（4タブ）

| タブ | 画面 | 主要機能 |
|------|------|---------|
| 1. リマインダー | ReminderListView | アクティブ/完了セグメント、カード一覧、スワイプ操作、FAB追加 |
| 2. 地図 | MapOverviewView | Map + MapCircle + UserAnnotation、全ジオフェンス可視化 |
| 3. 場所管理 | LocationManagementView | カテゴリ別場所一覧、CRUD、アクティブリマインダー数バッジ |
| 4. 設定 | SettingsView | 権限状態、デフォルト半径スライダー、監視状態(X/20) |

**モーダル**: AddReminderView（場所選択→タイトル→トリガー設定→保存）
**モーダル**: LocationPickerView（地図ピン+検索バー+半径スライダー+MapCircleプレビュー）
**初回起動**: PermissionOnboardingView（位置情報Always→通知許可のステップガイド）

---

## 技術実装の重要ポイント

### 1. CLMonitor の安全な利用
- 固定名 `"AsaSmartReminder"` で1インスタンスのみ（複数生成でクラッシュ防止）
- `events` ストリームの購読はキャンセル→再購読不可のため、停止時にmonitorごと破棄し再生成
- 状態はアプリ再起動後も永続化→起動時に既存条件を確認

### 2. 20リージョン制限の動的管理（RegionPrioritizer）
- ユーザー位置からの距離順にソート、上位20件を監視
- significantLocationChangeでバックグラウンド再計算
- 監視対象外の場所はUI上で「休止中」表示

### 3. 通知の二重構成
- **UNLocationNotificationTrigger**: アプリ終了後もシステムレベルで確実に通知（メイン通知手段）
- **CLMonitor events**: アプリ内でのリアルタイムUI更新用

### 4. 権限管理フロー
- 段階的認可: requestWhenInUse → requestAlways（Apple推奨パターン）
- Always権限が必要な理由をオンボーディングで丁寧に説明
- 拒否時は設定アプリへの誘導UI

### 5. Info.plist設定（project.ymlで指定）
- `NSLocationAlwaysAndWhenInUseUsageDescription`: バックグラウンドジオフェンス用
- `NSLocationWhenInUseUsageDescription`: 地図場所選択用
- `UIBackgroundModes: location`: バックグラウンド位置更新

---

## project.yml

```yaml
name: AsaSmartReminder
options:
  bundleIdPrefix: com.asapapa.apps
  deploymentTarget:
    iOS: "17.0"
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
  AsaSmartReminderKit:
    path: ../../Packages/AsaSmartReminderKit
targets:
  AsaSmartReminder:
    type: application
    platform: iOS
    sources: [Sources]
    resources: [Sources/Assets.xcassets]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.asapapa.apps.asasmartreminder
      GENERATE_INFOPLIST_FILE: true
      INFOPLIST_KEY_UIApplicationSceneManifest_Generation: true
      INFOPLIST_KEY_UILaunchScreen_Generation: true
      INFOPLIST_KEY_CFBundleDisplayName: "AsaSmartReminder"
      INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription: "場所に基づくリマインダー通知のために、位置情報への常時アクセスが必要です"
      INFOPLIST_KEY_NSLocationWhenInUseUsageDescription: "地図上で場所を選択し、リマインダーを設定するために位置情報が必要です"
      INFOPLIST_KEY_UIBackgroundModes: "location"
    dependencies:
      - package: AsaUIKit
        product: AsaUIKit
      - package: AsaSmartReminderKit
        product: AsaSmartReminderKit
  AsaSmartReminderUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: AsaSmartReminderUITests
    settings:
      GENERATE_INFOPLIST_FILE: true
    dependencies:
      - target: AsaSmartReminder
```

---

## テスト戦略（目標: ~155件）

| カテゴリ | 件数 | 対象 |
|---------|------|------|
| モデルテスト | 45 | ReminderLocation, LocationReminder, LocationCategory, MonitoringState, UserLocationSettings |
| サービステスト | 53 | ReminderDataService(20), RegionPrioritizer(15), PermissionService(8), NotificationService(10) |
| ViewModelテスト | 42 | SmartReminderViewModel(25), LocationPickerViewModel(10), SettingsViewModel(7) |
| 統合テスト | 10 | リマインダー作成→監視登録→通知スケジュールの一連フロー |
| UIテスト | 5 | リマインダー追加、一覧、完了、削除、設定 |

テストはSwift Testing（@Test, #expect）。GeofenceMonitorServiceはprotocol経由でモック注入。DataServiceはinMemory: trueでテスト分離。

---

## 実装順序

### Phase 1: 基盤（パッケージ + モデル + DataService）
1. `Packages/AsaSmartReminderKit/` パッケージ作成（Package.swift）
2. 全データモデル実装（5ファイル）
3. `ReminderDataService` 実装（SwiftData CRUD）
4. モデル + DataService テスト（~50件）

### Phase 2: コアサービス（位置情報 + 通知 + 権限）
5. `PermissionService` 実装（位置+通知権限管理）
6. `GeofenceMonitorService` 実装（CLMonitor actor）
7. `RegionPrioritizer` 実装（20件制限ロジック）
8. `NotificationService` 実装（UNLocationNotificationTrigger）
9. `LocationSearchService` 実装（MKLocalSearch）
10. サービステスト（~53件）

### Phase 3: ViewModel
11. `SmartReminderViewModel` 実装
12. `LocationPickerViewModel` 実装
13. `SettingsViewModel` 実装
14. ViewModelテスト（~42件）

### Phase 4: アプリUI
15. project.yml + AsaSmartReminderApp.swift + ContentView.swift（TabView）
16. PermissionOnboardingView（初回起動）
17. ReminderListView + ReminderCardView + Add/EditReminderView
18. MapOverviewView + GeofenceAnnotationView
19. LocationManagementView + LocationPickerView + LocationSearchBarView
20. SettingsView + PermissionStatusView
21. EmptyStateView, MonitoringStatusBadge

### Phase 5: テスト + ドキュメント
22. 統合テスト（10件）+ UIテスト（5件）
23. `Docs/Notes/Day94-Implementation.md` 作成

---

## 参照ファイル（既存パターンの踏襲元）

- `Apps/AsaSmartTodo/project.yml` - XcodeGen設定テンプレート
- `Apps/AsaSmartTodo/AsaSmartTodo/Services/DataService.swift` - SwiftData CRUD + inMemoryパターン
- `Apps/AsaSmartTodo/AsaSmartTodo/ViewModels/SmartTodoViewModel.swift` - @MainActor @Observable VMパターン
- `Apps/AsaLocationTracker/AsaLocationTracker/LocationManager.swift` - CLLocationManager + nonisolatedデリゲート
- `Apps/AsaReminder/AsaReminder/ReminderViewModel.swift` - 通知スケジューリング基本パターン
- `Packages/AsaFamilyTreeKit/Package.swift` - 専用パッケージのPackage.swift構成
- `Packages/AsaUIKit/Sources/AsaUIKit/` - AsaColors, AsaButton, AsaCard

---

## 検証方法

### ビルド確認
```bash
cd Packages/AsaSmartReminderKit && swift build
cd Apps/AsaSmartReminder && xcodegen generate && xcodebuild -scheme AsaSmartReminder -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### テスト実行
```bash
cd Packages/AsaSmartReminderKit && swift test
```

### 動作確認（シミュレータ）
1. シミュレータで起動 → オンボーディング権限許可
2. 場所を追加（地図ピンまたは検索）→ ジオフェンス半径設定
3. リマインダー作成（場所選択→タイトル→到着/離脱トリガー）
4. シミュレータのLocation機能でCustom Location設定 → ジオフェンス内座標に移動
5. 通知が表示されることを確認
6. 地図タブで全ジオフェンスがMapCircleで表示されることを確認
