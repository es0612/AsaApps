# Day 82: AsaSmartAlarm 実装ノート

## 概要

**アプリ名**: AsaSmartAlarm（スマートアラーム）
**カテゴリ**: 上級（71-100）
**開発日**: 2026年1月29日

天気や予定に応じてアラーム時刻を自動調整する「スマートアラーム」アプリを実装しました。朝活パパのための賢いアラームで、雨の日は早めに起こしたり、重要な朝の予定がある場合は準備時間を考慮して起床時刻を自動計算します。

---

## 主要機能

### 1. スマートアラーム設定
- 基本アラーム（時刻、繰り返し曜日、ラベル）
- 天気条件による起床時刻調整（雨の日は15分早めに起こす等）
- 予定との連携（イベント開始時刻から逆算して自動アラーム設定）

### 2. 天気連携
- **Open-Meteo API**（無料、APIキー不要）で翌朝の天気を取得
- 天気条件（雨、雪、晴れ等）による起床時刻オフセット設定
- 通勤・通学時間帯（6:00-9:00）の天気予報表示
- 天気コードからWeatherCondition enumへの変換

### 3. 予定連携
- 独自イベントモデル（Swift Data）によるカレンダー管理
- イベント開始時刻から逆算してアラーム自動設定
- 準備時間、移動時間の設定（デフォルト: 準備30分、移動30分）
- 推奨起床時刻の自動計算

### 4. 通知管理
- **UserNotifications**による確実な通知配信
- スヌーズ機能（5分、10分選択可能）
- フォアグラウンド通知対応
- カテゴリ付きアクションでスヌーズ・停止ボタン

---

## 技術スタック

| 技術 | 用途 |
|------|------|
| SwiftUI | UI構築 |
| Swift Data | データ永続化（@Model） |
| @Observable | リアクティブ状態管理 |
| UserNotifications | 通知配信 |
| CoreLocation | 位置情報取得 |
| Open-Meteo API | 天気情報取得 |
| AsaUIKit | 共有UIコンポーネント |

---

## アーキテクチャ

### ディレクトリ構造

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

### MVVM + Service層

```
View層 ─── ViewModel層 ─── Service層 ─── Data層
  │            │              │           │
AlarmListView  AlarmViewModel  AlarmScheduler  SmartAlarm
EventListView  WeatherViewModel WeatherService  CalendarEvent
SettingsView   EventViewModel   Notification    AlarmSettings
                               LocationService
```

---

## データモデル設計

### SmartAlarm（メインモデル）

```swift
@Model
final class SmartAlarm {
    @Attribute(.unique) var id: UUID
    var baseTime: Date                    // 基準時刻
    var label: String
    var isEnabled: Bool
    var repeatDaysData: Data?             // [Int]をJSONで保存
    var soundName: String
    var weatherAdjustmentEnabled: Bool
    var eventAdjustmentEnabled: Bool

    @Relationship(deleteRule: .cascade, inverse: \AlarmAdjustmentRule.alarm)
    var adjustmentRules: [AlarmAdjustmentRule] = []
}
```

### AlarmAdjustmentRule（調整ルール）

```swift
@Model
final class AlarmAdjustmentRule {
    var id: UUID
    var conditionTypeRawValue: String     // weather, event
    var weatherConditionRawValue: String?
    var adjustmentMinutes: Int            // 正=早める、負=遅らせる
    var isEnabled: Bool
    var alarm: SmartAlarm?
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
    var priorityRawValue: String

    var suggestedWakeUpTime: Date {
        startTime.addingTimeInterval(TimeInterval(-(preparationMinutes + travelMinutes) * 60))
    }
}
```

---

## サービス層の実装

### WeatherService（Open-Meteo API）

Open-Meteo APIを使用して、翌朝6:00-9:00の天気を取得します。

```swift
func fetchMorningWeather(for location: CLLocation) async throws -> MorningWeatherForecast {
    let urlString = "\(baseURL)/forecast?latitude=\(lat)&longitude=\(lon)" +
        "&hourly=temperature_2m,weather_code&timezone=auto&forecast_days=2"
    // ...
}
```

天気コードからWeatherConditionへの変換：

| コード | 天気 | デフォルト調整 |
|--------|------|---------------|
| 0-1 | 晴れ | 0分 |
| 2-3 | 曇り | 0分 |
| 61-67 | 雨 | 15分早める |
| 71-77 | 雪 | 30分早める |
| 95-99 | 雷雨 | 20分早める |

### AlarmSchedulerService（スマート計算）

```swift
func calculateNextAlarmTime(
    for alarm: SmartAlarm,
    weatherForecast: MorningWeatherForecast?,
    events: [CalendarEvent]
) -> AlarmCalculationResult? {
    // 1. 基準時刻を取得
    // 2. 天気による調整を計算
    // 3. イベントによる調整を計算
    // 4. 合計調整時間を適用
}
```

### NotificationService（通知管理）

シングルトンパターンで実装し、以下の機能を提供：

- 通知権限リクエスト
- アラーム通知のスケジュール
- スヌーズ通知のスケジュール
- カテゴリ付きアクション（スヌーズ、停止）
- フォアグラウンド通知対応

---

## UIコンポーネント

### WeekdayPickerView

曜日選択のためのコンパクトなコンポーネント：

```swift
HStack(spacing: 8) {
    ForEach(0..<7) { dayIndex in
        DayButton(dayName: dayNames[dayIndex], isSelected: ...)
    }
}
```

プリセットボタン：
- 平日（月〜金）
- 週末（土日）
- 毎日
- なし

### WeatherCardView

翌朝の天気予報を表示するカード：

- 天気アイコンと状態名
- 気温範囲（最低〜最高）
- 時間帯別の天気（6:00-9:00）
- アラーム調整の提案

### AdjustmentRuleSummary

適用された調整の要約を表示：

- 天気による調整（例: 雨予報 -15分）
- イベントによる調整（例: 朝会議の準備 -30分）

---

## 学んだこと

### 1. Swift Data + @Observable の組み合わせ

Swift DataのモデルとObservationフレームワークを組み合わせる際の注意点：

- `@Model`は自動的にObservableになる
- `@Bindable`はbody内でローカル変数として宣言可能
- Enum値はRaw Valueで永続化が必要

```swift
var body: some View {
    @Bindable var bindableViewModel = viewModel
    // ...
    .sheet(isPresented: $bindableViewModel.showingAddAlarm) { ... }
}
```

### 2. @MainActorとnonisolated delegate

CoreLocationのデリゲートメソッドはSwift 6対応で`nonisolated`が必要：

```swift
@MainActor
final class LocationService: NSObject, ObservableObject {
    // ...
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.currentLocation = location
        }
    }
}
```

### 3. Open-Meteo APIの活用

APIキー不要で使える天気APIの利点：
- 無料で利用可能
- 時間ごとの詳細な予報
- タイムゾーン自動対応
- 天気コードによる分類

### 4. Equatableプロトコルの重要性

`onChange(of:)`で監視するプロパティは`Equatable`準拠が必要：

```swift
struct MorningWeatherForecast: Equatable {
    // ...
}
```

---

## テスト

### Unit Tests（Swift Testing）

```swift
@Suite("AlarmSchedulerService Tests")
struct AlarmSchedulerServiceTests {
    @Test("天気による調整計算")
    func testWeatherAdjustment() async { }

    @Test("イベントによる調整計算")
    func testEventAdjustment() async { }
}

@Suite("WeatherCondition Tests")
struct WeatherConditionTests {
    @Test("天気コードマッピング")
    func testWeatherCodeMapping() { }
}
```

---

## 今後の拡張案

1. **スヌーズパターン学習** - Core MLでユーザーのスヌーズ傾向を学習
2. **睡眠サイクル分析** - HealthKitと連携して最適な起床タイミングを提案
3. **WidgetKit対応** - 次回アラームと天気をウィジェット表示
4. **Apple Watch対応** - 手首で振動アラーム

---

## スクリーンショット

（実機またはシミュレーターでのスクリーンショットを追加予定）

---

## まとめ

AsaSmartAlarmは、天気とスケジュールを考慮したインテリジェントなアラームアプリです。Open-Meteo APIの活用、Swift Dataによるデータ永続化、UserNotificationsによる通知管理など、複数の技術を組み合わせた上級レベルのアプリとなりました。

朝活パパエンジニアの日々の朝活をサポートする、実用的なツールとして完成しました。
