# Day 89: AsaLanguageLearn - 言語学習アプリ（音声認識）

## 概要

音声認識・音声合成・間隔反復学習（SRS）を組み合わせた英語学習アプリ。
ユーザーの発音をリアルタイムで認識・評価し、効率的な復習スケジュールで習得をサポート。

## 完成したアプリ

### 主要機能

1. **音声認識による発音練習**
   - SFSpeechRecognizerでリアルタイム認識（英語: en-US）
   - 波形表示、認識中テキストのライブ表示
   - オフラインモード対応（requiresOnDeviceRecognition）

2. **音声合成による模範発音**
   - AVSpeechSynthesizerで英語ネイティブ発音
   - 速度調整: 0.3x〜1.3x（5段階）
   - 高品質音声の自動選択

3. **発音スコアリング**
   - Levenshtein距離ベースの類似度計算
   - Perfect/Good/Fair/NeedsWork の4段階評価
   - 単語ごとのマッチング表示

4. **間隔反復学習（SRS）**
   - SM-2アルゴリズム簡易版
   - 復習間隔: 1日→3日→7日→14日→30日→90日
   - 習熟度: New → Learning → Review → Mastered

5. **学習ダッシュボード**
   - 学習時間、正解率、ストリーク
   - 週間チャート（Swift Charts）
   - 習熟レベル分布

## 技術スタック

| 項目 | 技術 |
|------|------|
| iOS | 17.0+ |
| Swift | 5.9 |
| 音声認識 | SFSpeechRecognizer |
| 音声合成 | AVSpeechSynthesizer |
| データ永続化 | Swift Data |
| アーキテクチャ | MVVM + Service層 |
| UI | SwiftUI + AsaUIKit |
| チャート | Swift Charts |
| テスト | Swift Testing |

## ディレクトリ構造

```
Apps/AsaLanguageLearn/
├── AsaLanguageLearn/
│   ├── Models/
│   │   ├── Domain/
│   │   │   ├── Course.swift
│   │   │   ├── Lesson.swift
│   │   │   ├── LearningItem.swift
│   │   │   ├── LearningProgress.swift
│   │   │   ├── StudySession.swift
│   │   │   └── UserProfile.swift
│   │   └── Enums/
│   │       ├── ContentCategory.swift
│   │       ├── MasteryLevel.swift
│   │       └── PronunciationAccuracy.swift
│   ├── ViewModels/
│   │   ├── LanguageLearnViewModel.swift
│   │   ├── PracticeViewModel.swift
│   │   ├── ReviewViewModel.swift
│   │   └── DashboardViewModel.swift
│   ├── Services/
│   │   ├── Protocols/
│   │   │   ├── SpeechRecognitionServiceProtocol.swift
│   │   │   ├── TextToSpeechServiceProtocol.swift
│   │   │   └── PronunciationScoringServiceProtocol.swift
│   │   ├── Production/
│   │   │   ├── SpeechRecognitionService.swift
│   │   │   ├── TextToSpeechService.swift
│   │   │   └── PronunciationScoringService.swift
│   │   ├── Mock/
│   │   │   └── MockServices.swift
│   │   └── Utilities/
│   │       └── SRSCalculator.swift
│   ├── Views/
│   │   ├── Home/
│   │   ├── Practice/
│   │   ├── Review/
│   │   ├── Dashboard/
│   │   └── Components/
│   └── Resources/
│       └── SampleContent/
│           └── DefaultCourses.json
├── AsaLanguageLearnTests/
│   ├── SRSCalculatorTests.swift
│   ├── PronunciationScoringServiceTests.swift
│   └── LearningProgressTests.swift
└── project.yml
```

## アーキテクチャ

### Service層のプロトコル設計

```swift
// 音声認識サービス
@MainActor
protocol SpeechRecognitionServiceProtocol: AnyObject {
    var state: RecognitionState { get }
    var recognizedText: String { get }
    var audioLevel: Float { get }

    func startRecognition() async throws
    func stopRecognition()
}

// 音声合成サービス
@MainActor
protocol TextToSpeechServiceProtocol: AnyObject {
    var state: SpeechState { get }
    var speechRate: Float { get set }

    func speak(_ text: String)
    func stop()
}
```

### SRS（間隔反復学習）アルゴリズム

```swift
// SM-2アルゴリズム簡易版
static func calculateInterval(streak: Int) -> Int {
    switch streak {
    case 0: return 0      // 未学習
    case 1: return 1      // 1日後
    case 2: return 3      // 3日後
    case 3: return 7      // 1週間後
    case 4: return 14     // 2週間後
    case 5: return 30     // 1ヶ月後
    default: return min(90, streak * 15)  // 最大3ヶ月
    }
}
```

### 発音スコアリング

```swift
// Levenshtein距離ベースの類似度計算
func calculateScore(recognized: String, target: String) -> PronunciationResult {
    // テキスト正規化（小文字化、句読点除去）
    // 単語ごとのマッチング
    // 全体スコア計算（単語マッチ60% + 文字列類似度40%）
}
```

## 学んだこと

### 1. SFSpeechRecognizer の使い方

- `requiresOnDeviceRecognition`でオフライン対応
- `shouldReportPartialResults`でリアルタイム表示
- 音声レベル（RMS）計算で波形表示

### 2. AVSpeechSynthesizer の活用

- `AVSpeechSynthesizerDelegate`で単語ハイライト
- 高品質音声の自動選択ロジック
- 速度調整（rate プロパティ）

### 3. 間隔反復学習（SRS）

- SM-2アルゴリズムの実装
- 復習優先度の計算
- 習熟レベルの段階的管理

### 4. Swift Charts

- `BarMark`でバーチャート作成
- 週間データの可視化
- 動的なカラー設定

## テスト結果

```
✔ Suite LearningProgressTests passed (15 tests)
✔ Suite PronunciationScoringServiceTests passed (16 tests)
✔ Suite SRSCalculatorTests passed (14 tests)
✔ Test run with 45 tests passed
```

## 改善ポイント

1. iOS 26 SpeechAnalyzer APIへの移行準備（プロトコル抽象化済み）
2. サーバー連携による追加コンテンツ配信
3. 発音の詳細分析（音素レベル）
4. ゲーミフィケーション要素の追加

## スクリーンショット

（実機でのスクリーンショットを追加予定）

## 次のステップ

- Day 90: 次の上級アプリへ
- 音声認識精度の向上
- 多言語対応（中国語、スペイン語等）
