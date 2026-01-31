# AsaSmartHome 実装計画

## 概要

AsaSmartHome（#87）は、模擬IoTデバイスを操作するスマートホームアプリです。実際のハードウェア連携は行わず、シミュレーターベースで8種類のデバイスを操作します。

**技術スタック**: SwiftUI + Swift Data + @Observable + MVVM + Protocol/Mock

---

## 1. ディレクトリ構造

```
Apps/AsaSmartHome/
├── project.yml
├── AsaSmartHome/
│   ├── AsaSmartHomeApp.swift
│   ├── ContentView.swift
│   ├── Assets.xcassets/
│   ├── Models/
│   │   ├── SmartDevice.swift           # @Model デバイス基本モデル
│   │   ├── DeviceState.swift           # DeviceType, PowerState, ConnectionStatus
│   │   ├── DeviceTypes/
│   │   │   ├── LightDevice.swift       # 照明（明るさ、色温度）
│   │   │   ├── AirConditioner.swift    # エアコン（温度、モード、風量）
│   │   │   ├── Speaker.swift           # スピーカー（音量、再生状態）
│   │   │   ├── SecurityCamera.swift    # カメラ（録画状態、検知）
│   │   │   ├── SmartLock.swift         # ロック（施錠状態）
│   │   │   ├── Thermostat.swift        # サーモスタット
│   │   │   ├── Curtain.swift           # カーテン（開閉度）
│   │   │   └── Television.swift        # テレビ（電源、入力、音量）
│   │   ├── Room.swift                  # @Model 部屋モデル
│   │   ├── Scene.swift                 # @Model シーンモデル
│   │   ├── Schedule.swift              # @Model スケジュールモデル
│   │   └── DeviceCommand.swift         # コマンド構造体
│   ├── ViewModels/
│   │   ├── SmartHomeViewModel.swift    # メインViewModel
│   │   ├── RoomViewModel.swift
│   │   ├── DeviceControlViewModel.swift
│   │   ├── SceneEditorViewModel.swift
│   │   └── ScheduleViewModel.swift
│   ├── Services/
│   │   ├── Protocols/
│   │   │   └── SmartHomeServiceProtocol.swift
│   │   ├── Mock/
│   │   │   ├── MockSmartHomeService.swift
│   │   │   └── DeviceSimulator.swift
│   │   └── Data/
│   │       └── SmartHomeDataService.swift
│   ├── Views/
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift
│   │   │   ├── QuickControlCard.swift
│   │   │   └── StatusSummaryView.swift
│   │   ├── Rooms/
│   │   │   ├── RoomListView.swift
│   │   │   ├── RoomDetailView.swift
│   │   │   └── RoomCardView.swift
│   │   ├── Devices/
│   │   │   ├── DeviceListView.swift
│   │   │   ├── DeviceDetailView.swift
│   │   │   ├── DeviceCardView.swift
│   │   │   └── Controls/
│   │   │       ├── LightControlView.swift
│   │   │       ├── ACControlView.swift
│   │   │       ├── SpeakerControlView.swift
│   │   │       ├── CameraControlView.swift
│   │   │       ├── LockControlView.swift
│   │   │       └── TVControlView.swift
│   │   ├── Scenes/
│   │   │   ├── SceneListView.swift
│   │   │   ├── SceneEditorView.swift
│   │   │   └── SceneCardView.swift
│   │   ├── Schedules/
│   │   │   ├── ScheduleListView.swift
│   │   │   └── ScheduleEditorView.swift
│   │   ├── Settings/
│   │   │   └── SettingsView.swift
│   │   └── Components/
│   │       ├── DeviceIconView.swift
│   │       ├── PowerToggleView.swift
│   │       ├── BrightnessSlider.swift
│   │       └── TemperatureControl.swift
│   └── Extensions/
│       └── AsaColorsExtension.swift
├── AsaSmartHomeTests/
│   ├── Models/
│   ├── ViewModels/
│   └── Services/
└── AsaSmartHomeUITests/
```

---

## 2. データモデル設計

### 2.1 DeviceType（8種類）

```swift
enum DeviceType: String, Codable, CaseIterable, Sendable {
    case light = "light"              // 照明
    case airConditioner = "ac"        // エアコン
    case speaker = "speaker"          // スピーカー
    case securityCamera = "camera"    // セキュリティカメラ
    case smartLock = "lock"           // スマートロック
    case thermostat = "thermostat"    // サーモスタット
    case curtain = "curtain"          // カーテン
    case television = "tv"            // テレビ（追加）
}
```

### 2.2 SmartDevice（@Model）

```swift
@Model
final class SmartDevice {
    @Attribute(.unique) var id: UUID
    var name: String
    var deviceTypeRawValue: String
    var roomId: UUID?
    var powerStateRawValue: String
    var connectionStatusRawValue: String
    var lastUpdated: Date
    var isFavorite: Bool
    var metadata: [String: String]  // デバイス固有データ格納
}
```

### 2.3 Room / Scene / Schedule

- **Room**: 部屋名、アイコン、ソート順
- **Scene**: シーン名、アイコン、アクションリスト（JSON）
- **Schedule**: 実行時間、繰り返し曜日（ビットフラグ）、シーンID

---

## 3. Services設計

### Protocol + Mock パターン（AsaEventLive踏襲）

```swift
protocol SmartHomeServiceProtocol: AnyObject, Sendable {
    // Devices
    func fetchDevices() async throws -> [SmartDevice]
    func sendCommand(deviceId: UUID, command: DeviceCommand) async throws

    // Rooms
    func fetchRooms() async throws -> [Room]
    func createRoom(_ room: Room) async throws -> Room

    // Scenes
    func fetchScenes() async throws -> [Scene]
    func executeScene(_ sceneId: UUID) async throws

    // Real-time Observation
    func observeAllDevices(handler: @escaping ([SmartDevice]) -> Void) -> Any
    func removeObserver(_ observer: Any)
}
```

**MockSmartHomeService**: サンプルデータでシミュレーション
**DeviceSimulator**: コマンド処理、状態変更をシミュレート

---

## 4. ViewModel設計

### SmartHomeViewModel

```swift
@MainActor
@Observable
final class SmartHomeViewModel {
    private let service: SmartHomeServiceProtocol

    private(set) var appState: SmartHomeAppState = .loading
    private(set) var devices: [SmartDevice] = []
    private(set) var rooms: [Room] = []
    private(set) var scenes: [Scene] = []

    // Computed Properties
    var favoriteDevices: [SmartDevice] { ... }
    var activeDeviceCount: Int { ... }

    // Methods
    func initialize() async { ... }
    func toggleDevice(_ device: SmartDevice) async { ... }
    func executeScene(_ scene: Scene) async { ... }
}
```

---

## 5. UI構成

### タブ構成（4タブ）

| タブ | 画面 | 主要機能 |
|-----|------|---------|
| **ダッシュボード** | DashboardView | ステータスサマリー、クイックアクション、お気に入り、全デバイス |
| **部屋** | RoomListView | 部屋一覧、部屋別デバイス管理 |
| **シーン** | SceneListView | シーン一覧、シーン実行、シーン編集 |
| **設定** | SettingsView | アプリ設定、デバイス自動検出設定 |

### 共通コンポーネント

- **DeviceCardView**: デバイス状態カード（Toggle付き）
- **QuickControlCard**: ワンタップアクションカード
- **StatusSummaryView**: オンライン/アクティブデバイス数

---

## 6. 実装フェーズ

### Phase 1: 基盤構築（1-2日）
- [ ] プロジェクト構造作成（project.yml）
- [ ] データモデル実装（SmartDevice, Room, Scene, Schedule）
- [ ] DeviceType, PowerState, ConnectionStatus enum
- [ ] SmartHomeServiceProtocol定義

### Phase 2: サービス層（2-3日）
- [ ] MockSmartHomeService実装
- [ ] DeviceSimulator実装
- [ ] サンプルデータ作成（8種類のデバイス）
- [ ] Service層Unit Tests

### Phase 3: ViewModel層（2-3日）
- [ ] SmartHomeViewModel実装
- [ ] DeviceControlViewModel実装
- [ ] SceneEditorViewModel実装
- [ ] ViewModel Unit Tests

### Phase 4: 基本UI（3-4日）
- [ ] ContentView（タブ構成）
- [ ] DashboardView + StatusSummaryView
- [ ] RoomListView / RoomDetailView
- [ ] DeviceCardView / DeviceListView

### Phase 5: デバイス詳細UI（2-3日）
- [ ] DeviceDetailView
- [ ] LightControlView（明るさ、色温度スライダー）
- [ ] ACControlView（温度、モード、風量）
- [ ] TVControlView（電源、入力、音量）
- [ ] その他コントロールビュー

### Phase 6: シーン・スケジュール（2-3日）
- [ ] SceneListView / SceneEditorView
- [ ] ScheduleListView / ScheduleEditorView
- [ ] シーンアクション編集（デバイス選択、操作設定）

### Phase 7: 仕上げ（1-2日）
- [ ] SettingsView
- [ ] UIアニメーション調整
- [ ] UI Tests
- [ ] ドキュメント作成（Docs/Notes/Day87-Implementation.md）

---

## 7. 依存パッケージ

```yaml
packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit
  AsaCoreKit:
    path: ../../Packages/AsaCoreKit
```

**使用コンポーネント**:
- AsaUIKit: AsaButton, AsaCard, AsaColors
- AsaCoreKit: ValidationEngine（将来の入力検証用）

---

## 8. テスト戦略

### Unit Tests（95%カバレッジ目標）
- **Services**: MockSmartHomeService, DeviceSimulator
- **ViewModels**: SmartHomeViewModel, DeviceControlViewModel, SceneEditorViewModel
- **Models**: SmartDevice, Room, Scene, Schedule

### UI Tests
- デバイストグルフロー
- シーン実行フロー
- 部屋追加フロー

---

## 9. 検証方法

### ビルド・実行
```bash
cd Apps/AsaSmartHome
xcodegen generate
open AsaSmartHome.xcodeproj
# Cmd+R でシミュレーターで実行
```

### テスト実行
```bash
swift test
# または Xcode で Cmd+U
```

### 動作確認チェックリスト
- [ ] ダッシュボードでデバイス一覧が表示される
- [ ] デバイスカードのトグルで電源ON/OFFが切り替わる
- [ ] 部屋別にデバイスがグループ化される
- [ ] シーン実行で複数デバイスが一括制御される
- [ ] スケジュール設定が保存される

---

## 10. 参考ファイル

| ファイル | 参考内容 |
|---------|---------|
| `Apps/AsaEventLive/Services/Protocols/EventDataServiceProtocol.swift` | Protocol + Mock設計 |
| `Apps/AsaVoiceAssistant/ViewModels/VoiceAssistantViewModel.swift` | 状態マシンパターン |
| `Apps/AsaBudgetAI/Views/Settings/SettingsView.swift` | Form + Section設定画面 |
| `Apps/AsaFitnessCoach/Views/Progress/ProgressDashboardView.swift` | LazyVGridダッシュボード |
