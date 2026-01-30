# AsaVoiceAssistant 実装計画

**アプリ番号**: #83（上級アプリ 71-100）
**概要**: 音声認識でタスク管理を行うボイスアシスタントアプリ

---

## 1. アプリ概要

### コンセプト
日本語の音声コマンドでタスクを作成・完了・削除・一覧確認できるハンズフリータスク管理アプリ。
朝の準備中や運転中など、手が離せない状況でもタスク管理が可能。

### 音声コマンド例
| コマンド | 動作 |
|---------|------|
| 「明日までに報告書を作成」 | タスク作成（期限: 明日） |
| 「買い物リストを完了」 | タスク完了 |
| 「今日のタスクを教えて」 | タスク読み上げ |
| 「高優先度のタスクを見せて」 | フィルタリング表示 |

---

## 2. 技術スタック

| 技術 | 用途 |
|------|------|
| **Speech Framework** | 日本語音声認識（SFSpeechRecognizer） |
| **AVAudioEngine** | リアルタイム音声入力 |
| **AVSpeechSynthesizer** | 音声フィードバック（読み上げ） |
| **Swift Data** | タスク永続化 |
| **@Observable** | 状態管理（iOS 17+） |
| **AsaUIKit** | 共有UIコンポーネント |

---

## 3. ディレクトリ構造

```
Apps/AsaVoiceAssistant/
├── AsaVoiceAssistant/
│   ├── AsaVoiceAssistantApp.swift
│   ├── ContentView.swift
│   │
│   ├── Models/
│   │   ├── VoiceTask.swift          # @Model タスクモデル
│   │   ├── VoiceCommand.swift       # コマンド解析結果
│   │   ├── CommandIntent.swift      # コマンド意図enum
│   │   ├── PriorityLevel.swift      # 優先度
│   │   ├── TaskCategory.swift       # カテゴリ
│   │   └── VoiceSettings.swift      # @Model 設定
│   │
│   ├── Services/
│   │   ├── SpeechRecognitionService.swift  # 音声認識
│   │   ├── CommandParserService.swift      # コマンド解析
│   │   ├── TextToSpeechService.swift       # 音声合成
│   │   ├── DataService.swift               # Swift Data
│   │   └── PermissionService.swift         # 権限管理
│   │
│   ├── ViewModels/
│   │   ├── VoiceAssistantViewModel.swift
│   │   ├── TaskListViewModel.swift
│   │   └── SettingsViewModel.swift
│   │
│   ├── Views/
│   │   ├── Voice/
│   │   │   ├── VoiceInputView.swift
│   │   │   ├── VoiceWaveformView.swift
│   │   │   └── VoiceFeedbackView.swift
│   │   ├── Tasks/
│   │   │   ├── TaskListView.swift
│   │   │   ├── TaskRowView.swift
│   │   │   └── TaskDetailView.swift
│   │   ├── Settings/
│   │   │   └── SettingsView.swift
│   │   └── Components/
│   │       ├── MicButtonView.swift
│   │       ├── RecognizedTextView.swift
│   │       └── CommandConfirmationView.swift
│   │
│   └── Assets.xcassets/
│
├── AsaVoiceAssistantTests/
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   └── Integration/
│
├── AsaVoiceAssistantUITests/
└── project.yml
```

---

## 4. 主要モデル設計

### VoiceTask.swift
```swift
@Model
final class VoiceTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String?
    var priorityRawValue: String      // PriorityLevel
    var categoryRawValue: String      // TaskCategory
    var dueDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var originalTranscription: String?  // 元の音声認識テキスト
    var createdByVoice: Bool           // 音声で作成されたか
    var createdAt: Date
    var updatedAt: Date
}
```

### CommandIntent.swift
```swift
enum CommandIntent: String, CaseIterable, Sendable {
    case createTask     // タスク作成
    case completeTask   // タスク完了
    case deleteTask     // タスク削除
    case listTasks      // タスク一覧表示
    case readTasks      // タスク読み上げ
    case unknown        // 不明
}
```

### VoiceCommand.swift
```swift
struct VoiceCommand: Sendable {
    let intent: CommandIntent
    let taskTitle: String?
    let priority: PriorityLevel?
    let category: TaskCategory?
    let dueDate: Date?
    let targetTaskQuery: String?
    let filterPriority: PriorityLevel?
    let rawTranscription: String
    let confidence: Double
}
```

---

## 5. サービス層設計

### SpeechRecognitionService（核心）
- `SFSpeechRecognizer`で日本語音声認識
- `AVAudioEngine`でリアルタイム音声入力
- 認識状態: `idle` → `listening` → `processing` → `finished`
- 音声レベル取得（波形表示用）

### CommandParserService
- 正規表現で日本語コマンドパターンマッチング
- 期限抽出:「明日」「今週中」「来週」等
- 優先度抽出:「重要」「急ぎ」等のキーワード
- 信頼度スコア計算

### TextToSpeechService
- `AVSpeechSynthesizer`で日本語読み上げ
- タスク作成完了、タスク一覧読み上げ
- 読み上げ速度・ピッチ設定可能

---

## 6. 実装フェーズ

### Phase 1: 基盤構築（1-2日）
- [ ] project.yml作成、XcodeGenでプロジェクト生成
- [ ] Models/ディレクトリ（全6ファイル）
- [ ] DataService実装（Swift Data）
- [ ] 基本的なUnit Tests

### Phase 2: 音声サービス実装（2-3日）
- [ ] PermissionService実装
- [ ] SpeechRecognitionService実装
- [ ] CommandParserService実装（日本語パターン）
- [ ] TextToSpeechService実装
- [ ] 各サービスのUnit Tests

### Phase 3: ViewModel・ビジネスロジック（2日）
- [ ] VoiceAssistantViewModel実装
- [ ] TaskListViewModel実装
- [ ] SettingsViewModel実装
- [ ] ViewModelのUnit Tests

### Phase 4: UI実装（2-3日）
- [ ] VoiceInputView、MicButtonView、VoiceWaveformView
- [ ] TaskListView、TaskRowView、TaskDetailView
- [ ] SettingsView
- [ ] ContentView（タブビュー統合）

### Phase 5: 統合・テスト・ドキュメント（1-2日）
- [ ] Integration Tests
- [ ] UI調整、アニメーション
- [ ] ドキュメント作成（Docs/Notes/Day83-Implementation.md）

---

## 7. project.yml

```yaml
name: AsaVoiceAssistant
options:
  bundleIdPrefix: com.asapapa.apps
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
  generateEmptyDirectories: true

packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit

targets:
  AsaVoiceAssistant:
    type: application
    platform: iOS
    sources: [AsaVoiceAssistant]
    resources: [AsaVoiceAssistant/Assets.xcassets]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.asapapa.apps.asavoiceassistant
      GENERATE_INFOPLIST_FILE: true
      INFOPLIST_KEY_CFBundleDisplayName: "AsaVoiceAssistant"
      INFOPLIST_KEY_NSMicrophoneUsageDescription: "音声でタスクを管理するためにマイクを使用します"
      INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: "音声をテキストに変換してタスクを作成します"
    dependencies:
      - package: AsaUIKit
        product: AsaUIKit
      - sdk: SwiftUI.framework
      - sdk: SwiftData.framework
      - sdk: Speech.framework
      - sdk: AVFoundation.framework

  AsaVoiceAssistantTests:
    type: bundle.unit-test
    platform: iOS
    sources: AsaVoiceAssistantTests
    dependencies:
      - target: AsaVoiceAssistant

  AsaVoiceAssistantUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: AsaVoiceAssistantUITests
    dependencies:
      - target: AsaVoiceAssistant
```

---

## 8. テスト戦略

### Unit Tests（95%カバレッジ目標）
| テストファイル | テスト数 | 内容 |
|--------------|---------|------|
| CommandParserServiceTests | 15+ | コマンド解析、日本語パターン |
| VoiceTaskTests | 10+ | モデル操作、期限判定 |
| VoiceAssistantViewModelTests | 20+ | タスクCRUD、コマンド処理 |
| TaskListViewModelTests | 10+ | フィルタ、ソート |
| DataServiceTests | 10+ | Swift Data操作 |

### Integration Tests
| テストファイル | 内容 |
|--------------|------|
| VoiceToTaskIntegrationTests | 音声→コマンド→タスク作成フロー |

---

## 9. 検証方法

### 機能テスト
1. **音声認識テスト**
   - シミュレーター: キーボード入力でテスト
   - 実機: 日本語音声入力テスト

2. **コマンド解析テスト**
   - 各種日本語パターンの認識確認
   - 期限・優先度の抽出確認

3. **タスク管理テスト**
   - 作成→完了→削除のフロー確認
   - 永続化の確認（アプリ再起動後）

### ビルド・テスト実行
```bash
cd Apps/AsaVoiceAssistant
xcodegen generate
open AsaVoiceAssistant.xcodeproj

# テスト実行
swift test
# または Xcode: Cmd+U
```

---

## 10. 参考ファイル（実装時に参照）

| ファイル | 参考内容 |
|---------|---------|
| `Apps/AsaSmartTodo/AsaSmartTodo/ViewModels/SmartTodoViewModel.swift` | @MainActor @Observable ViewModel |
| `Apps/AsaSmartTodo/AsaSmartTodo/Services/DataService.swift` | Swift Dataラッパー |
| `Apps/AsaVoiceMemo/AsaVoiceMemo/AudioRecorderManager.swift` | AVFoundation権限・録音パターン |
| `Apps/AsaSmartTodo/project.yml` | XcodeGen設定 |

---

## 11. 実装の注意点

### 音声認識の制限
- **シミュレーター**: 音声入力不可、テキスト入力でテスト
- **実機**: 実際の音声認識テストが必要
- **オフライン**: iOS 17+でオンデバイス認識対応

### 権限管理
- マイク権限: `NSMicrophoneUsageDescription`
- 音声認識権限: `NSSpeechRecognitionUsageDescription`
- 両方の権限が必要、拒否時の適切なUI表示

### 日本語コマンド解析
- 正規表現ベースのパターンマッチング
- 曖昧な表現への対応（信頼度スコアで判定）
- 将来的にはNaturalLanguage Frameworkで拡張可能
