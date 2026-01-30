# AsaSmartAlarm 実装計画

> **アプリ #82**: 天気や予定に応じたスマートアラーム（上級レベル）

## 概要

| 項目 | 内容 |
|------|------|
| アプリ名 | AsaSmartAlarm |
| カテゴリ | 上級（71-100） |
| iOS要件 | iOS 17.0+ |
| 技術スタック | SwiftUI, Swift Data, UserNotifications, Open-Meteo API, CoreLocation |

### コンセプト
朝活パパのための「賢いアラーム」。天気や予定に応じて起床時刻を自動調整し、最適な朝活スタートをサポート。

---

## 主要機能

### 1. スマートアラーム設定
- 基本アラーム（時刻、繰り返し曜日、ラベル）
- 天気条件による起床時刻調整（雨の日は15分早めに起こす等）
- 予定との連携（イベント開始時刻から逆算して自動アラーム設定）

### 2. 天気連携
- Open-Meteo API（無料、APIキー不要）で翌朝の天気を取得
- 天気条件（雨、雪、晴れ等）による起床時刻オフセット設定
- 通勤・通学時間帯（6:00-9:00）の天気予報表示

### 3. 予定連携
- 独自イベントモデル（Swift Data）によるカレンダー管理
- イベント開始時刻から逆算してアラーム自動設定
- 準備時間、移動時間の設定（デフォルト: 準備30分、移動30分）

### 4. 通知管理
- UserNotificationsによる確実な通知配信
- スヌーズ機能（5分、10分）
- フォアグラウンド通知対応

---

## ディレクトリ構造

```
Apps/AsaSmartAlarm/
├── project.yml
└── AsaSmartAlarm/
    ├── AsaSmartAlarmApp.swift
    ├── ContentView.swift
    ├── Models/
    │   ├── SmartAlarm.swift          # アラームモデル（@Model）
    │   ├── WeatherCondition.swift    # 天気状態enum
    │   ├── AlarmAdjustmentRule.swift # 調整ルールモデル（@Model）
    │   ├── CalendarEvent.swift       # イベントモデル（@Model）
    │   └── AlarmSettings.swift       # 設定モデル（@Model）
    ├── Services/
    │   ├── WeatherService.swift      # Open-Meteo API連携
    │   ├── LocationService.swift     # 位置情報取得
    │   ├── AlarmSchedulerService.swift # アラームスケジューリング
    │   ├── NotificationService.swift # 通知管理
    │   └── DataService.swift         # Swift Data CRUD
    ├── ViewModels/
    │   ├── AlarmViewModel.swift      # メインViewModel
    │   ├── WeatherViewModel.swift    # 天気ViewModel
    │   └── EventViewModel.swift      # イベントViewModel
    └── Views/
        ├── AlarmListView.swift       # アラーム一覧（メイン）
        ├── AddAlarmView.swift        # アラーム追加
        ├── AlarmDetailView.swift     # アラーム詳細
        ├── EventListView.swift       # イベント一覧
        ├── AddEventView.swift        # イベント追加
        ├── SettingsView.swift        # 設定画面
        └── Components/
            ├── AlarmRowView.swift            # アラーム行
            ├── WeatherCardView.swift         # 天気カード
            ├── AdjustmentRuleView.swift      # 調整ルール設定
            └── WeekdayPickerView.swift       # 曜日選択
```

---

## データモデル設計

### SmartAlarm（メインモデル）
```swift
@Model
final class SmartAlarm {
    @Attribute(.unique) var id: UUID
    var time: Date                    // 基準時刻
    var label: String
    var isEnabled: Bool
    var repeatDaysRawValue: [Int]     // 曜日配列
    var soundName: String

    // スマート機能
    var weatherAdjustmentEnabled: Bool
    var eventAdjustmentEnabled: Bool

    @Relationship(deleteRule: .cascade)
    var adjustmentRules: [AlarmAdjustmentRule]
}
```

### AlarmAdjustmentRule（調整ルール）
```swift
@Model
final class AlarmAdjustmentRule {
    var id: UUID
    var conditionType: ConditionType  // weather, event
    var weatherConditionRawValue: String?
    var adjustmentMinutes: Int        // 正=早める、負=遅らせる
    var isEnabled: Bool
}

enum WeatherCondition: String, Codable, CaseIterable {
    case rain, snow, clear, clouds, thunderstorm
}
```

### CalendarEvent（イベント）
```swift
@Model
final class CalendarEvent {
    var id: UUID
    var title: String
    var startTime: Date
    var preparationMinutes: Int  // デフォルト30分
    var travelMinutes: Int       // デフォルト30分
    var priority: EventPriority

    var suggestedAlarmTime: Date {
        startTime.addingTimeInterval(TimeInterval(-(preparationMinutes + travelMinutes) * 60))
    }
}
```

---

## サービス層設計

### WeatherService（Open-Meteo API）
- AsaWeatherパターンを踏襲
- `fetchMorningWeather(for: CLLocation)` - 翌朝6:00-9:00の天気取得
- weather_codeからWeatherConditionへ変換

### AlarmSchedulerService（スマート計算）
- `calculateNextAlarmTime(for:events:)` - 天気+イベント考慮した次回時刻計算
- 天気による調整（雨→15分早める等）
- イベントによる調整（準備時間+移動時間を逆算）

### NotificationService
- AsaSmartTodoパターンを踏襲
- シングルトン実装
- スヌーズアクション対応

---

## ViewModel設計

### AlarmViewModel
```swift
@MainActor
@Observable
final class AlarmViewModel {
    private let dataService: DataService
    private let schedulerService: AlarmSchedulerService
    private let notificationService: NotificationService

    private(set) var alarms: [SmartAlarm] = []
    var showingAddAlarm = false

    func addAlarm(_ alarm: SmartAlarm)
    func toggleAlarm(_ alarm: SmartAlarm)
    func getNextAlarmPreview(for alarm: SmartAlarm) async -> (date: Date, adjustments: [String])?
}
```

---

## 実装フェーズ

### Phase 1: 基本構造構築（1日目）
- [ ] プロジェクト作成（XcodeGen）
- [ ] データモデル実装（SmartAlarm, AlarmSettings）
- [ ] DataService実装
- [ ] 基本的なAlarmListView実装
- [ ] AsaUIKit統合

### Phase 2: アラーム機能実装（2日目）
- [ ] NotificationService実装
- [ ] AlarmViewModel実装
- [ ] AddAlarmView実装
- [ ] AlarmRowView実装
- [ ] 基本的なアラームスケジューリング

### Phase 3: 天気連携実装（3日目）
- [ ] WeatherService実装（Open-Meteo API）
- [ ] LocationService実装
- [ ] WeatherViewModel実装
- [ ] WeatherCardView実装
- [ ] AlarmAdjustmentRule実装（天気条件）

### Phase 4: 予定連携実装（4日目）
- [ ] CalendarEvent実装
- [ ] EventViewModel実装
- [ ] EventListView / AddEventView実装
- [ ] AlarmSchedulerService実装（イベント考慮）

### Phase 5: スマート機能統合（5日目）
- [ ] AlarmSchedulerService完成（天気+イベント統合）
- [ ] NextAlarmPreviewView実装
- [ ] AdjustmentRuleView実装
- [ ] 設定画面実装

### Phase 6: テスト・ドキュメント（6日目）
- [ ] Unit Tests実装
- [ ] UI Tests実装
- [ ] Day82-Implementation.md作成
- [ ] スクリーンショット撮影

---

## テスト戦略

### Unit Tests（Swift Testing）
```swift
@Suite("AlarmSchedulerService Tests")
struct AlarmSchedulerServiceTests {
    @Test("天気による調整計算")
    func testWeatherAdjustment() async { }

    @Test("イベントによる調整計算")
    func testEventAdjustment() async { }

    @Test("天気+イベント複合調整")
    func testCombinedAdjustment() async { }
}

@Suite("WeatherService Tests")
struct WeatherServiceTests {
    @Test("Open-Meteo API レスポンスパース")
    func testOpenMeteoResponseParsing() async throws { }

    @Test("天気コードマッピング")
    func testWeatherCodeMapping() { }
}
```

---

## project.yml

```yaml
name: AsaSmartAlarm
options:
  bundleIdPrefix: com.asapapa.apps
  deploymentTarget:
    iOS: "17.0"

packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit

targets:
  AsaSmartAlarm:
    type: application
    platform: iOS
    sources: [AsaSmartAlarm]
    settings:
      INFOPLIST_KEY_NSLocationWhenInUseUsageDescription: "翌朝の天気を取得するために位置情報を使用します"
    dependencies:
      - package: AsaUIKit
        product: AsaUIKit

  AsaSmartAlarmTests:
    type: bundle.unit-test
    platform: iOS
    sources: AsaSmartAlarmTests
    dependencies:
      - target: AsaSmartAlarm
```

---

## 重要ファイル（実装優先順）

1. **Models/SmartAlarm.swift** - コアデータモデル
2. **Services/AlarmSchedulerService.swift** - スマート計算の中核
3. **Services/WeatherService.swift** - Open-Meteo API連携
4. **ViewModels/AlarmViewModel.swift** - MVVM中核
5. **Views/AlarmListView.swift** - メインUI

---

## 検証方法

1. **ビルド確認**: `xcodegen generate && xcodebuild -project AsaSmartAlarm.xcodeproj -scheme AsaSmartAlarm`
2. **シミュレーター実行**: iPhone 16 Simulatorで動作確認
3. **テスト実行**: `swift test`
4. **通知テスト**: シミュレーターで通知権限許可後、アラーム設定→通知受信確認
5. **天気API確認**: 位置情報許可後、WeatherCardViewに天気表示確認

---

## 今後の拡張案（オプション）
- スヌーズパターン学習（Core ML）
- 睡眠サイクル分析（HealthKit）
- WidgetKit対応（次回アラーム表示）
- Apple Watch対応
