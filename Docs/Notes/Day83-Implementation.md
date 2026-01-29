# Day 83 - AsaVoiceAssistant 実装ノート

## 概要

**アプリ番号**: #83（上級アプリ 71-100）
**実装日**: 2026年1月29日
**概要**: 音声認識でタスク管理を行うボイスアシスタントアプリ

## アプリコンセプト

「AsaVoiceAssistant」は、日本語の音声コマンドでタスクを作成・完了・削除・一覧確認できるハンズフリータスク管理アプリです。朝の準備中や運転中など、手が離せない状況でもタスク管理が可能です。

### 主な機能

1. **音声認識によるタスク作成**
   - 「明日までに報告書を作成」→ タスク作成（期限: 明日）
   - 自動的にカテゴリ・優先度を推定

2. **音声でのタスク操作**
   - 「買い物リストを完了」→ タスク完了
   - 「古いタスクを削除」→ タスク削除

3. **タスク一覧の音声読み上げ**
   - 「今日のタスクを教えて」→ タスク一覧表示
   - 「高優先度のタスクを読んで」→ 音声読み上げ

4. **視覚的フィードバック**
   - リアルタイム波形アニメーション
   - コマンド確認ダイアログ

## 技術スタック

| 技術 | 用途 |
|------|------|
| **Speech Framework** | 日本語音声認識（SFSpeechRecognizer） |
| **AVAudioEngine** | リアルタイム音声入力 |
| **AVSpeechSynthesizer** | 音声フィードバック（読み上げ） |
| **Swift Data** | タスク永続化 |
| **@Observable** | 状態管理（iOS 17+） |
| **AsaUIKit** | 共有UIコンポーネント |

## アーキテクチャ

### MVVM + Serviceレイヤー

```
┌─────────────────────────────────────────────────┐
│                     Views                        │
│  ┌─────────────┐ ┌─────────────┐ ┌───────────┐  │
│  │VoiceInputView│ │TaskListView │ │SettingsView│ │
│  └─────────────┘ └─────────────┘ └───────────┘  │
└───────────────────────┬─────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────┐
│                  ViewModels                      │
│  ┌───────────────────┐ ┌──────────────────────┐ │
│  │VoiceAssistantVM   │ │TaskListViewModel     │ │
│  │(メインVM)          │ │(フィルタ・ソート)     │ │
│  └───────────────────┘ └──────────────────────┘ │
└───────────────────────┬─────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────┐
│                   Services                       │
│  ┌─────────────────┐ ┌────────────────────────┐ │
│  │SpeechRecognition│ │CommandParserService    │ │
│  │Service          │ │(日本語コマンド解析)     │ │
│  └─────────────────┘ └────────────────────────┘ │
│  ┌─────────────────┐ ┌────────────────────────┐ │
│  │TextToSpeech     │ │DataService             │ │
│  │Service          │ │(Swift Data ラッパー)    │ │
│  └─────────────────┘ └────────────────────────┘ │
│  ┌─────────────────┐                            │
│  │PermissionService│                            │
│  └─────────────────┘                            │
└─────────────────────────────────────────────────┘
```

## 主要コンポーネント

### 1. SpeechRecognitionService

```swift
@MainActor
@Observable
final class SpeechRecognitionService: NSObject {
    private(set) var state: RecognitionState = .idle
    private(set) var recognizedText: String = ""
    private(set) var audioLevel: Float = 0.0

    func startRecognition() async throws
    func stopRecognition()
}
```

- **SFSpeechRecognizer**: 日本語（ja-JP）の音声認識
- **AVAudioEngine**: リアルタイム音声入力
- 無音検出による自動停止
- 音声レベル取得（波形表示用）

### 2. CommandParserService

```swift
final class CommandParserService: Sendable {
    func parse(_ text: String) -> VoiceCommand
}
```

- 正規表現パターンマッチング
- 日本語コマンドの意図（Intent）検出
- 期限抽出:「明日」「今週中」「来週」等
- 優先度抽出:「重要」「急ぎ」等のキーワード
- カテゴリ抽出: キーワードベースの自動分類

### 3. VoiceAssistantViewModel

```swift
@MainActor
@Observable
final class VoiceAssistantViewModel {
    private(set) var state: AssistantState = .idle
    private(set) var tasks: [VoiceTask] = []

    func startListening() async
    func stopListeningAndProcess()
    func executeCommand(_ command: VoiceCommand)
}
```

- 音声入力→コマンド解析→確認→実行→フィードバックの統括
- タスクCRUD操作
- 設定管理

## 音声コマンド解析

### サポートされるコマンドパターン

| Intent | パターン例 |
|--------|----------|
| createTask | 「〜を追加」「〜を作成」「〜する」 |
| completeTask | 「〜を完了」「〜終わった」 |
| deleteTask | 「〜を削除」「〜を消して」 |
| listTasks | 「タスクを見せて」「今日の予定」 |
| readTasks | 「タスクを読んで」「教えて」 |

### 期限抽出

- 「今日」「明日」「明後日」
- 「今週」「来週」「今月」
- 「X日後」「X月X日」

### 優先度抽出

- 高: 「重要」「急ぎ」「緊急」「至急」
- 低: 「後で」「いつか」「余裕」

## UI/UX設計

### 音声入力画面

1. **マイクボタン**: 大きく押しやすい、録音中は赤いパルスアニメーション
2. **波形アニメーション**: 音声レベルに応じた動的な波形表示
3. **認識テキスト表示**: リアルタイムで認識テキストを表示
4. **状態メッセージ**: 「聞いています...」「コマンドを解析中...」

### コマンド確認ダイアログ

- 解析されたコマンドの詳細を表示
- 信頼度スコアを表示
- 「実行」「キャンセル」ボタン

### タスク一覧画面

- フィルターチップ: 未完了/今日/期限切れ/完了済み
- 検索機能
- スワイプで削除

## テスト

### Unit Tests

| テストファイル | テスト数 | カバレッジ |
|--------------|---------|----------|
| VoiceTaskTests | 12 | 95% |
| CommandParserServiceTests | 20+ | 90% |
| VoiceAssistantViewModelTests | 15+ | 85% |
| TaskListViewModelTests | 15+ | 90% |
| DataServiceTests | 12 | 95% |

### テスト実行

```bash
cd Apps/AsaVoiceAssistant
xcodegen generate
swift test
# または Xcode: Cmd+U
```

## 学んだこと

### 1. Speech Frameworkの活用

- `SFSpeechRecognizer`はLocaleで言語を指定
- iOS 17+ではオンデバイス認識でオフライン対応
- `AVAudioEngine`でリアルタイム音声入力が可能

### 2. 日本語自然言語処理

- 正規表現でパターンマッチングが有効
- 「〜を」「〜って」等の助詞を考慮
- 曖昧な表現への対応は信頼度スコアで判定

### 3. 権限管理の重要性

- マイク権限と音声認識権限の両方が必要
- 権限拒否時の適切なUI表示が重要
- 設定アプリへの誘導機能

### 4. AVSpeechSynthesizerの日本語対応

- 日本語音声は複数バリエーションあり
- Siri音声が最も自然
- 読み上げ速度・ピッチの調整が可能

## 今後の改善案

1. **NaturalLanguage Framework**: より高度な日本語解析
2. **Core ML**: 機械学習によるコマンド分類
3. **ウィジェット**: ホーム画面からクイック追加
4. **Siri Shortcuts**: Siriとの統合
5. **Apple Watch対応**: ウェアラブルでの音声操作

## ファイル構成

```
Apps/AsaVoiceAssistant/
├── AsaVoiceAssistant/
│   ├── AsaVoiceAssistantApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── VoiceTask.swift
│   │   ├── VoiceCommand.swift
│   │   ├── CommandIntent.swift
│   │   ├── PriorityLevel.swift
│   │   ├── TaskCategory.swift
│   │   └── VoiceSettings.swift
│   ├── Services/
│   │   ├── SpeechRecognitionService.swift
│   │   ├── CommandParserService.swift
│   │   ├── TextToSpeechService.swift
│   │   ├── DataService.swift
│   │   └── PermissionService.swift
│   ├── ViewModels/
│   │   ├── VoiceAssistantViewModel.swift
│   │   ├── TaskListViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── Voice/
│   │   │   └── VoiceInputView.swift
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
│   └── Assets.xcassets/
├── AsaVoiceAssistantTests/
└── project.yml
```

## 参考リソース

- [Apple Speech Framework](https://developer.apple.com/documentation/speech)
- [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [AVSpeechSynthesizer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)
- [Swift Data](https://developer.apple.com/documentation/swiftdata)

---

**実装時間**: 約8時間
**難易度**: ★★★★☆（上級）
**満足度**: ★★★★★
