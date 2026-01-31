# AsaLanguageLearn 実装計画

言語学習アプリ（音声認識）- 上級アプリ #89

## 概要

音声認識・音声合成・間隔反復学習（SRS）を組み合わせた英語学習アプリ。
ユーザーの発音をリアルタイムで認識・評価し、効率的な復習スケジュールで習得をサポート。

## 技術スタック

| 項目 | 技術 |
|------|------|
| iOS | 17.0+ |
| Swift | 5.9 |
| 音声認識 | SFSpeechRecognizer（将来iOS 26でSpeechAnalyzer移行対応） |
| 音声合成 | AVSpeechSynthesizer |
| データ永続化 | Swift Data |
| アーキテクチャ | MVVM + Service層 |
| UI | SwiftUI + AsaUIKit |
| テスト | Swift Testing |

## 主要機能

### 1. 音声認識による発音練習
- SFSpeechRecognizerでリアルタイム認識（英語: en-US）
- 波形表示、認識中テキストのライブ表示
- オフラインモード対応（`requiresOnDeviceRecognition`）

### 2. 音声合成による模範発音
- AVSpeechSynthesizerで英語ネイティブ発音
- 速度調整: 0.3x〜1.3x（5段階）
- 単語ハイライト（AVSpeechSynthesizerDelegate）

### 3. 発音スコアリング
- 認識テキスト vs ターゲットテキストの類似度計算
- Levenshtein距離ベースのスコア（0.0〜1.0）
- Perfect/Good/Fair/NeedsWork の4段階評価

### 4. 間隔反復学習（SRS）
- SM-2アルゴリズム簡易版（AsaFlashcardProパターン拡張）
- 復習間隔: 1日→3日→7日→14日→30日→90日
- 習熟度: New → Learning → Review → Mastered

### 5. 学習ダッシュボード
- 学習時間、正解率、ストリーク
- 週間チャート（Swift Charts）
- 弱点カテゴリ分析

## ディレクトリ構造

```
Apps/AsaLanguageLearn/
├── AsaLanguageLearn/
│   ├── Models/
│   │   ├── Domain/
│   │   │   ├── Course.swift           # コース
│   │   │   ├── Lesson.swift           # レッスン
│   │   │   ├── LearningItem.swift     # 学習アイテム
│   │   │   ├── LearningProgress.swift # 進捗（SRS）
│   │   │   ├── StudySession.swift     # セッション記録
│   │   │   └── UserProfile.swift      # ユーザープロファイル
│   │   └── Enums/
│   │       ├── ContentCategory.swift
│   │       ├── MasteryLevel.swift
│   │       └── PronunciationAccuracy.swift
│   │
│   ├── ViewModels/
│   │   ├── LanguageLearnViewModel.swift  # メイン
│   │   ├── PracticeViewModel.swift       # 発音練習
│   │   ├── ReviewViewModel.swift         # 復習
│   │   └── DashboardViewModel.swift      # ダッシュボード
│   │
│   ├── Services/
│   │   ├── Protocols/
│   │   │   ├── SpeechRecognitionServiceProtocol.swift
│   │   │   ├── TextToSpeechServiceProtocol.swift
│   │   │   └── PronunciationScoringServiceProtocol.swift
│   │   ├── Production/
│   │   │   ├── SpeechRecognitionService.swift  # ← AsaVoiceAssistant参照
│   │   │   ├── TextToSpeechService.swift
│   │   │   └── PronunciationScoringService.swift
│   │   ├── Mock/
│   │   │   └── MockServices.swift
│   │   └── Utilities/
│   │       └── SRSCalculator.swift  # ← AsaFlashcardPro参照
│   │
│   ├── Views/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   ├── CourseListView.swift
│   │   │   └── LessonListView.swift
│   │   ├── Practice/
│   │   │   ├── PracticeView.swift
│   │   │   ├── RecordingView.swift
│   │   │   └── FeedbackView.swift
│   │   ├── Review/
│   │   │   ├── ReviewDeckView.swift
│   │   │   └── ReviewCardView.swift
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift
│   │   │   └── WeeklyChartView.swift
│   │   └── Components/
│   │       ├── MicButtonView.swift
│   │       ├── WaveformView.swift
│   │       ├── PlaybackButton.swift
│   │       └── AccuracyIndicator.swift
│   │
│   └── Resources/
│       └── SampleContent/
│           └── DefaultCourses.json
│
├── AsaLanguageLearnTests/
└── project.yml
```

## 参照ファイル（既存パターン活用）

| ファイル | 用途 |
|---------|------|
| `Apps/AsaVoiceAssistant/.../SpeechRecognitionService.swift` | 音声認識実装パターン |
| `Apps/AsaVoiceAssistant/.../TextToSpeechService.swift` | 音声合成実装パターン |
| `Apps/AsaFlashcardPro/.../StudyProgress.swift` | SRS間隔計算パターン |
| `Apps/AsaSmartHome/.../SmartHomeServiceProtocol.swift` | Protocol設計パターン |

## 実装フェーズ（15日間）

### Phase 1: 基盤構築（Day 1-3）
- [ ] XcodeGen設定（project.yml）
- [ ] Swift Dataモデル実装
- [ ] サービスプロトコル定義
- [ ] SRSCalculator実装＋テスト

### Phase 2: 音声機能（Day 4-6）
- [ ] SpeechRecognitionService（英語対応）
- [ ] TextToSpeechService（速度調整）
- [ ] PronunciationScoringService

### Phase 3: コアUI（Day 7-10）
- [ ] ホーム画面（コース/レッスン一覧）
- [ ] 発音練習画面（マイク、波形、フィードバック）
- [ ] 復習画面（デッキ、カード）

### Phase 4: ダッシュボード・設定（Day 11-12）
- [ ] ダッシュボード（統計、チャート）
- [ ] 設定画面（音声速度、通知）

### Phase 5: 統合・テスト（Day 13-15）
- [ ] Unit Tests（85%カバレッジ目標）
- [ ] UIテスト（主要フロー）
- [ ] ドキュメント作成

## project.yml

```yaml
name: AsaLanguageLearn
options:
  bundleIdPrefix: com.asapapa.apps
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"

settings:
  SWIFT_VERSION: "5.9"

packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit

targets:
  AsaLanguageLearn:
    type: application
    platform: iOS
    sources:
      - AsaLanguageLearn
    settings:
      INFOPLIST_KEY_NSMicrophoneUsageDescription: "発音練習のためにマイクを使用します"
      INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: "発音を認識してスコアを計算します"
    dependencies:
      - package: AsaUIKit
      - sdk: Speech.framework
      - sdk: AVFoundation.framework

  AsaLanguageLearnTests:
    type: bundle.unit-test
    dependencies:
      - target: AsaLanguageLearn

schemes:
  AsaLanguageLearn:
    build:
      targets:
        AsaLanguageLearn: all
    test:
      targets:
        - AsaLanguageLearnTests
```

## 検証方法

### ビルド確認
```bash
cd Apps/AsaLanguageLearn
xcodegen generate
xcodebuild -project AsaLanguageLearn.xcodeproj -scheme AsaLanguageLearn -destination 'platform=iOS Simulator,name=iPhone 16'
```

### テスト実行
```bash
xcodebuild test -project AsaLanguageLearn.xcodeproj -scheme AsaLanguageLearn -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 動作確認ポイント
1. マイク権限リクエスト → 音声認識開始
2. 英語発音 → リアルタイム認識テキスト表示
3. 模範発音再生 → 速度調整動作
4. 発音スコア表示 → Perfect/Good/Fair/NeedsWork
5. 復習スケジュール → SRS間隔に基づく出題
6. ダッシュボード → ストリーク、チャート表示

## 備考

- iOS 26のSpeechAnalyzer APIへの移行に備え、サービス層をプロトコルで抽象化
- 初期コンテンツはJSON（DefaultCourses.json）で提供、将来的にサーバー連携可能
- ブランドカラー（AsaCoffeeBrown等）はAsaUIKit経由で統一適用
