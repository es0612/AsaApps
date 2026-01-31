# Day 87 - AsaSmartHome 実装ノート

## アプリ概要

**AsaSmartHome** - スマートホームコントロールアプリ

模擬IoTデバイスを操作するシミュレーターベースのアプリです。実際のハードウェアなしで、8種類のスマートデバイスの操作を体験できます。

## 機能一覧

### デバイスタイプ（8種類）
1. **照明 (Light)** - 電源、明るさ、色温度
2. **エアコン (Air Conditioner)** - 電源、温度、モード、風量
3. **テレビ (Television)** - 電源、音量、入力切替
4. **スピーカー (Speaker)** - 電源、音量、再生状態
5. **防犯カメラ (Security Camera)** - 電源、録画
6. **スマートロック (Smart Lock)** - 施錠/解錠
7. **サーモスタット (Thermostat)** - 電源、温度
8. **カーテン (Curtain)** - 開度

### 画面構成（4タブ）
1. **ダッシュボード** - 全デバイス一覧、お気に入り、クイックアクション
2. **部屋** - 部屋ごとのデバイス管理
3. **シーン** - プリセット/カスタムシーン管理
4. **設定** - 接続状態、アプリ設定

### プリセットシーン
- おやすみ（照明OFF、カーテン閉、施錠）
- おはよう（照明ON、カーテン開）
- 外出（全デバイスOFF、施錠）
- 帰宅（照明ON、エアコンON、解錠）
- 映画モード（照明暗く、テレビON、カーテン閉）

## 技術スタック

### アーキテクチャ
- **MVVM** + **@Observable**（Swift 5.9）
- **Swift Data** - データ永続化
- **Protocol + Mock パターン** - IoTデバイスシミュレーション

### ファイル構成
```
AsaSmartHome/
├── AsaSmartHomeApp.swift
├── Models/
│   ├── DeviceState.swift      # デバイス状態enum
│   ├── SmartDevice.swift      # デバイスモデル
│   ├── Room.swift             # 部屋モデル
│   ├── Scene.swift            # シーンモデル（SmartScene）
│   ├── Schedule.swift         # スケジュールモデル
│   └── DeviceCommand.swift    # コマンドモデル
├── ViewModels/
│   ├── SmartHomeViewModel.swift
│   ├── DeviceControlViewModel.swift
│   └── SceneEditorViewModel.swift
├── Services/
│   ├── Protocols/
│   │   └── SmartHomeServiceProtocol.swift
│   └── Mock/
│       ├── MockSmartHomeService.swift
│       └── DeviceSimulator.swift
└── Views/
    ├── ContentView.swift
    ├── Dashboard/
    ├── Rooms/
    ├── Scenes/
    ├── Devices/
    └── Settings/
```

## 実装のポイント

### 1. Protocol + Mock パターン
実際のIoTハードウェアなしでデバイス操作をシミュレート：

```swift
@MainActor
protocol SmartHomeServiceProtocol: AnyObject {
    func fetchDevices() async throws -> [SmartDevice]
    func sendCommand(deviceId: UUID, command: DeviceCommand) async throws -> CommandResult
    // ...
}

@MainActor
final class MockSmartHomeService: SmartHomeServiceProtocol {
    // Swift Dataを使用してデバイス状態を永続化
    // DeviceSimulatorでコマンド実行をシミュレート
}
```

### 2. デバイスメタデータのJSON格納
デバイスタイプ別のプロパティをメタデータJSONとして格納：

```swift
@Model
final class SmartDevice {
    var metadataJSON: String = "{}"

    var brightness: Int {
        get { getMetadata(SmartDevice.MetadataKey.brightness) ?? 100 }
        set { setMetadata(SmartDevice.MetadataKey.brightness, value: min(100, max(0, newValue))) }
    }
}
```

### 3. Swift 6 並行性対応
- `@MainActor` でUI関連クラスを隔離
- Sendable準拠でスレッドセーフを確保
- ObservationTokenでリアルタイム更新管理

### 4. SmartScene命名の理由
SwiftUIの`Scene`プロトコルとの名前衝突を避けるため、シーンモデルを`SmartScene`に命名。

## テスト

### 実装済みテスト
- **SmartDeviceTests** - デバイスモデルのテスト
- **DeviceSimulatorTests** - コマンド実行テスト
- **DeviceCommandTests** - コマンド作成テスト
- **SmartSceneTests** - シーンモデルテスト
- **PresetSceneTests** - プリセットシーンテスト

### テスト実行
```bash
cd Apps/AsaSmartHome
xcodebuild test -project AsaSmartHome.xcodeproj -scheme AsaSmartHome \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)'
```

## スクリーンショット

（追加予定）

## 学んだこと

1. **Swift 6 Concurrency**: `@MainActor`と`Sendable`の適切な使い分け
2. **Swift Data**: `@Model`とメタデータJSONによる柔軟なデータ構造
3. **Protocol Oriented Design**: Mock実装による依存性の分離
4. **名前空間の重要性**: SwiftUI標準型との衝突回避

## 今後の改善案

1. ウィジェット対応（ホーム画面からクイック操作）
2. 音声コントロール統合
3. 複数ホーム対応
4. デバイスグループ化
5. 自動化ルール（時間/センサートリガー）

## 参考資料

- [Apple HomeKit Documentation](https://developer.apple.com/documentation/homekit)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Swift Data](https://developer.apple.com/documentation/swiftdata)
