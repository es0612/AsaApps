# Day 94 - AsaSmartReminder 実装ノート

## アプリ概要

**AsaSmartReminder** - 位置情報に基づくスマートリマインダーアプリ

場所への到着・離脱時に自動通知するジオフェンシングベースのリマインダー。iOS 17+のモダンAPI（CLMonitor、MapKit for SwiftUI）を全面活用した上級アプリ。

### AsaReminder（#40）との差別化
- #40: 日時ベース通知（UNCalendarNotificationTrigger）
- #94: 位置ベース通知（CLMonitor + UNLocationNotificationTrigger）、地図UI、動的ジオフェンス管理

## 技術スタック

| 技術 | 用途 |
|------|------|
| CLMonitor | ジオフェンシング（async/await、iOS 17+） |
| MapKit for SwiftUI | 地図表示・ジオフェンス可視化 |
| SwiftData | データ永続化（@Model） |
| UNLocationNotificationTrigger | バックグラウンド位置通知 |
| @Observable | 状態管理 |
| Swift Testing | テスト（@Test, #expect） |

## アーキテクチャ

### パッケージ分離（MVVM）

```
Packages/AsaSmartReminderKit/
├── Models/          # ReminderLocation, LocationReminder, LocationCategory, MonitoringState, UserLocationSettings
├── Services/        # ReminderDataService, GeofenceMonitorService, NotificationService, LocationSearchService, RegionPrioritizer, PermissionService
├── ViewModels/      # SmartReminderViewModel, LocationPickerViewModel, SettingsViewModel
├── Errors/          # SmartReminderError
└── Protocols/       # GeofenceMonitoring, LocationSearching

Apps/AsaSmartReminder/
└── Sources/
    ├── Views/
    │   ├── Reminders/    # ReminderListView, ReminderCardView, AddReminderView
    │   ├── Map/          # MapOverviewView, GeofenceAnnotationView
    │   ├── Locations/    # LocationManagementView, LocationPickerView, LocationSearchBarView
    │   ├── Settings/     # SettingsView, PermissionStatusView
    │   ├── Onboarding/   # PermissionOnboardingView
    │   └── Common/       # EmptyStateView, MonitoringStatusBadge
    └── ContentView.swift # TabView（4タブ）
```

## 主要な技術的判断

### 1. CLMonitor の安全な利用
- actor で排他制御し、1インスタンスのみ管理
- 停止時はmonitorごと破棄し再生成（events ストリームの再購読問題を回避）

### 2. 20リージョン制限の動的管理
- `RegionPrioritizer` で純粋ロジックとして実装
- ユーザー位置からの距離順にソート、上位20件を監視対象
- 差分計算で効率的な監視対象の入れ替え

### 3. 通知の二重構成
- UNLocationNotificationTrigger: アプリ終了後もシステムレベルで通知（メイン）
- CLMonitor events: アプリ内でのリアルタイムUI更新用

### 4. #if os(iOS) ガード
- CLMonitor、UNLocationNotificationTrigger 等のiOS専用APIは `#if os(iOS)` でガード
- SPMの `swift build` はmacOSでコンパイルするため必須
- モデルとRegionPrioritizer はクロスプラットフォーム対応

### 5. iOS 17 互換性
- `Tab` API（iOS 18+）の代わりに `tabItem` を使用
- `MapCameraPosition` はSwiftUI依存のためViewModelから分離

## 画面構成

| タブ | 画面 | 主要機能 |
|------|------|---------|
| リマインダー | ReminderListView | セグメント（アクティブ/完了/すべて）、カード一覧、スワイプ削除 |
| 地図 | MapOverviewView | Map + MapCircle + UserAnnotation、全ジオフェンス可視化 |
| 場所管理 | LocationManagementView | カテゴリ別グループ化、CRUD |
| 設定 | SettingsView | 権限状態、デフォルト半径スライダー、監視状態表示 |

## テスト

84件のSwift Testingテストを実装:
- LocationCategory: 22件（表示名、SFSymbol、半径、Codable）
- LocationReminder: 14件（初期化、トリガー、完了/未完了、発火記録）
- ReminderLocation: 10件（初期化、座標、カテゴリ、距離計算）
- MonitoringState: 14件（状態判定、表示テキスト、エラー、等値比較）
- UserLocationSettings: 4件（初期化、変更反映）
- ReminderDataService: 15件（CRUD、フィルタ、設定）
- RegionPrioritizer: 13件（ソート、20件制限、差分計算）

## 学んだこと

1. **SPMとiOS専用API**: `swift build` はmacOSでコンパイルするため、`#if os(iOS)` が必須
2. **CLMonitor の制約**: 同一名での複数生成不可、events ストリームの再購読不可
3. **SwiftUI MapKit**: `MapCameraPosition` はSwiftUIに属し、パッケージのViewModelからは直接使えない
4. **iOS 17 vs 18**: `Tab` は iOS 18新API。iOS 17では `tabItem` を使う
5. **@Observable + actor**: actor型のサービスは `@MainActor` VMから `await` で呼び出し
