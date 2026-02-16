# AsaEduGame（子供向け教育ゲーム）実装計画書

## Context（背景・目的）

AsaEduGameはAsaApps 100本ノックの96番目のアプリ。上級アプリ（#71-100）として、**SpriteKit**（プロジェクト初導入）、SwiftData、TipKit、Core ML等の高度なiOS技術を統合した子供向け教育ゲームを構築する。

- **対象年齢**: 4-8歳（幼児〜低学年）
- **ゲームモード**: 4種類（算数クイズ、ひらがな練習、図形パズル、論理ゲーム）
- **描画エンジン**: SpriteKit（SpriteViewでSwiftUIと統合）
- **iOS ターゲット**: iOS 18.0

### 技術的挑戦
- AsaApps初のSpriteKit導入（SpriteView経由でSwiftUIと統合）
- Core MLによる手書き文字認識（ひらがな練習）
- アダプティブ難易度（正答率に基づく自動調整）
- ゲーミフィケーション（星/レベル/バッジシステム）

---

## 技術スタック

| 技術 | 用途 |
|------|------|
| **SpriteKit** | ゲームシーン、パーティクルエフェクト、タッチインタラクション |
| **SwiftData** | ユーザープロフィール、学習履歴、セッション記録の永続化 |
| **TipKit** | 子供向けチュートリアル、ゲームルール説明 |
| **Core ML** | ひらがな手書き認識（書き取りモード） |
| **Swift Charts** | 保護者向け進捗ダッシュボード |
| **AsaUIKit** | ブランドカラー、共通UIコンポーネント |

---

## アーキテクチャ設計

### ファイル構造

```
Apps/AsaEduGame/
├── project.yml
├── Sources/
│   ├── AsaEduGameApp.swift
│   ├── ContentView.swift                      # TabView
│   ├── Assets.xcassets/
│   └── Views/
│       ├── Home/
│       │   └── HomeView.swift                 # ゲームモード選択
│       ├── Game/
│       │   ├── GameContainerView.swift        # SpriteView ラッパー
│       │   ├── GameResultView.swift           # 結果画面
│       │   ├── Math/MathQuizView.swift
│       │   ├── Hiragana/HiraganaView.swift
│       │   ├── Shape/ShapePuzzleView.swift
│       │   └── Logic/LogicGameView.swift
│       ├── Progress/
│       │   ├── ProgressDashboardView.swift    # 保護者向け（Swift Charts）
│       │   ├── GameModeStatsView.swift
│       │   └── ChartViews.swift
│       ├── Profile/
│       │   ├── ProfileView.swift
│       │   └── BadgeCollectionView.swift
│       └── Components/
│           ├── EduGameTabBar.swift
│           ├── StarRatingView.swift
│           ├── LevelBadgeView.swift
│           ├── ComboCounterView.swift
│           └── ChildFriendlyButton.swift
├── AsaEduGameTests/
│   └── AsaEduGameTests.swift
└── AsaEduGameUITests/
    └── AsaEduGameUITests.swift

Packages/AsaEduGameKit/
├── Package.swift                              # swift-tools-version: 5.9
├── Sources/AsaEduGameKit/
│   ├── Models/
│   │   ├── UserProfile.swift                  # @Model
│   │   ├── GameSession.swift                  # @Model
│   │   ├── LearningRecord.swift               # @Model
│   │   ├── Achievement.swift                  # @Model
│   │   ├── GameMode.swift                     # enum
│   │   ├── DifficultyLevel.swift              # enum
│   │   ├── QuestionType.swift                 # enum
│   │   ├── GameQuestion.swift                 # struct（非永続化）
│   │   └── GameState.swift                    # enum EduGameState
│   ├── Errors/
│   │   └── EduGameError.swift
│   ├── Protocols/
│   │   ├── QuestionGenerating.swift
│   │   ├── DifficultyAdjusting.swift
│   │   ├── GameScoring.swift
│   │   ├── EduGameDataServiceProtocol.swift
│   │   └── HandwritingRecognizing.swift
│   ├── Services/
│   │   ├── EduGameDataService.swift           # SwiftData CRUD
│   │   ├── QuestionGeneratorService.swift     # 問題生成エンジン
│   │   ├── AdaptiveDifficultyService.swift    # 難易度自動調整
│   │   ├── ScoringService.swift               # 星/ポイント計算
│   │   ├── AchievementService.swift           # バッジ管理
│   │   ├── HandwritingRecognitionService.swift # Core ML
│   │   └── TipService.swift                   # TipKit管理
│   ├── SpriteKit/
│   │   ├── Scenes/
│   │   │   ├── BaseGameScene.swift            # 共通基底シーン
│   │   │   ├── MathQuizScene.swift
│   │   │   ├── HiraganaScene.swift
│   │   │   ├── ShapePuzzleScene.swift
│   │   │   └── LogicGameScene.swift
│   │   ├── Nodes/
│   │   │   ├── QuestionNode.swift
│   │   │   ├── AnswerOptionNode.swift
│   │   │   ├── CharacterNode.swift
│   │   │   ├── ShapeNode.swift
│   │   │   └── DrawingCanvasNode.swift
│   │   └── Effects/
│   │       ├── ParticleEffects.swift
│   │       ├── CelebrationEffect.swift
│   │       └── TransitionEffect.swift
│   └── ViewModels/
│       ├── HomeViewModel.swift
│       ├── GameViewModel.swift                # メインゲームVM
│       ├── MathQuizViewModel.swift
│       ├── HiraganaViewModel.swift
│       ├── ShapePuzzleViewModel.swift
│       ├── LogicGameViewModel.swift
│       ├── ProgressViewModel.swift
│       └── ProfileViewModel.swift
└── Tests/AsaEduGameKitTests/
    ├── Models/
    │   ├── UserProfileTests.swift
    │   ├── GameSessionTests.swift
    │   ├── LearningRecordTests.swift
    │   └── AchievementTests.swift
    ├── Services/
    │   ├── EduGameDataServiceTests.swift
    │   ├── QuestionGeneratorTests.swift
    │   ├── AdaptiveDifficultyTests.swift
    │   ├── ScoringServiceTests.swift
    │   └── AchievementServiceTests.swift
    └── ViewModels/
        ├── GameViewModelTests.swift
        ├── MathQuizViewModelTests.swift
        ├── HiraganaViewModelTests.swift
        ├── ShapePuzzleViewModelTests.swift
        ├── LogicGameViewModelTests.swift
        ├── ProgressViewModelTests.swift
        └── ProfileViewModelTests.swift
```

### データフロー

```
SwiftUI Views → ViewModels (@Observable @MainActor)
     ↕ (バインディング)        ↕ (DI: Protocol)
SpriteView ← SpriteKit Scenes   Services (Protocol準拠)
                                     ↕
                              SwiftData (ModelContainer)
```

---

## データモデル設計

### @Model（SwiftData永続化）

**UserProfile** - ユーザープロフィール
- `var id: UUID = UUID()`, name, avatarEmoji, age, totalStars, currentLevel, createdAt, updatedAt
- `@Relationship(deleteRule: .cascade)` sessions: [GameSession], achievements: [Achievement]

**GameSession** - ゲームセッション記録
- `var id: UUID = UUID()`, gameModeRawValue (String), difficultyRawValue (String)
- totalQuestions, correctAnswers, earnedStars, maxCombo, durationSeconds, startedAt, endedAt
- Computed: `var gameMode: GameMode`, `var difficulty: DifficultyLevel`, `var accuracy: Double`

**LearningRecord** - 個別問題回答記録
- `var id: UUID = UUID()`, questionTypeRawValue, questionContent, userAnswer, correctAnswer
- isCorrect, responseTimeSeconds, answeredAt

**Achievement** - バッジ/アチーブメント
- `var id: UUID = UUID()`, badgeId, title, achievementDescription, emoji, unlockedAt

### Enum定義

**GameMode**: mathQuiz / hiraganaPractice / shapePuzzle / logicGame
- displayName（さんすう/ひらがな/かたち/ろんり）、emoji、themeColor

**DifficultyLevel**: easy / normal / hard
- displayName（やさしい/ふつう/むずかしい）、starMultiplier（1.0/1.5/2.0）

**QuestionType**: 13種（算数4種+ひらがな3種+図形3種+論理3種）

**EduGameState**: idle / playing / answering / showingResult / celebration / sessionComplete

---

## SpriteKit ゲームシーン設計

### BaseGameScene（共通基底）
- GameSceneDelegate プロトコルでViewModel連携
- 共通ノード: questionNode, characterNode, scoreLabel, comboLabel
- 共通メソッド: showCorrectEffect(), showIncorrectEffect(), showComboEffect()

### 各シーン

| シーン | 操作 | やさしい | ふつう | むずかしい |
|--------|------|---------|--------|-----------|
| MathQuizScene | 選択肢タップ | 1-5の足し引き | 1-10+比較 | 1-20+穴埋め |
| HiraganaScene | タップ+手書き | あ〜さ行 | +た〜は行 | 全文字+濁音 |
| ShapePuzzleScene | タップ+ドラッグ | 基本図形識別 | +パターン | +組み合わせ |
| LogicGameScene | タップ+ドラッグ | 仲間はずれ | +順番並べ | +パターン完成 |

### パーティクルエフェクト
- 正解: 星バースト → コンボ5: 花火 → コンボ10: 大花火+キャラ祝福
- 不正解: 優しい応援エフェクト（がんばれ!）
- レベルアップ: 画面全体エフェクト

---

## ゲーミフィケーション設計

### 星/ポイントシステム
- 正解1問 = 1星 x 難易度倍率（easy:1.0, normal:1.5, hard:2.0）
- コンボ3: +1星、コンボ5: +2星、コンボ10: +5星
- 全問正解: +3星（パーフェクトボーナス）

### レベルシステム（7段階）
- Lv1: 0-49星 → Lv7: 1000星以上

### バッジ（13種）
- はじめてのほし⭐、さんすうマスター🔢、ひらがなヒーロー🎌
- かたちはかせ🔷、ろんりてんさい🧩、コンボ5!🔥、スーパーコンボ💥
- パーフェクト💯、まいにちがんばる📅、ほしあつめ100🌟/500✨
- レベル3たっせい🏆、ぜんぶやったよ🎮

---

## テスト戦略

**合計**: 約166テスト、カバレッジ目標80%以上

- **Model テスト** (29): UserProfile(8), GameSession(10), LearningRecord(6), Achievement(5)
- **Service テスト** (72): DataService(15), QuestionGenerator(20), AdaptiveDifficulty(12), Scoring(10), Achievement(15)
- **ViewModel テスト** (65): Game(15), Math(10), Hiragana(10), Shape(8), Logic(8), Progress(8), Profile(6)

パターン: `@Suite` + `@Test` + `#expect` + MockService DI + `inMemory: true`

---

## 実装フェーズ

### Phase 1: 基盤構築
- AsaEduGameKit パッケージ作成（Models, Errors, Enums, Protocols）
- Apps/AsaEduGame 骨格（project.yml, App, ContentView）
- EduGameDataService + ScoringService
- Model/Service テスト

### Phase 2: ゲームエンジン
- SpriteKit共通基盤（BaseGameScene, Nodes, Effects）
- QuestionGeneratorService（4モード全対応）
- 4つのゲームシーン実装
- GameViewModel + モード別VM
- AdaptiveDifficultyService

### Phase 3: UI/UX・高度機能
- SwiftUI全画面実装
- Core ML手書き認識（ひらがな書き取り）
- TipKit統合
- アクセシビリティ（60ptタップ、丸ゴシック、VoiceOver）

### Phase 4: ゲーミフィケーション・保護者機能
- AchievementService（13種バッジ）
- 進捗ダッシュボード（Swift Charts）
- ブランドカラー適用、最終仕上げ
- ドキュメント（Docs/Notes/Day96-Implementation.md）

---

## 検証方法

```bash
# パッケージテスト
cd Packages/AsaEduGameKit && swift test

# プロジェクト生成
cd Apps/AsaEduGame && xcodegen generate -s project.yml

# ビルド
xcodebuild -project AsaEduGame.xcodeproj -scheme AsaEduGame \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# テスト
xcodebuild test -project AsaEduGame.xcodeproj -scheme AsaEduGame \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### ビルドエラー防止チェック
- [ ] @Model に Sendable なし
- [ ] var id: UUID = UUID() パターン
- [ ] UILaunchScreen 設定済み
- [ ] import 漏れなし（SwiftData, Foundation, SpriteKit）
- [ ] システム型命名衝突なし（EduGameState等）
- [ ] @MainActor + Timer → nonisolated(unsafe)

---

## 実装リファレンス（既存ファイル）

| パターン | リファレンスファイル |
|---------|-------------------|
| SwiftData DataService | `Packages/AsaSmartReminderKit/Sources/.../Services/ReminderDataService.swift` |
| Protocol DI | `Packages/AsaPhotoStoryKit/Sources/.../Protocols/ServiceProtocols.swift` |
| ViewModel テスト | `Packages/AsaPhotoStoryKit/Tests/.../ViewModelTests.swift` |
| project.yml | `Apps/AsaSmartReminder/project.yml` |
| ViewModel パターン | `Packages/AsaSmartReminderKit/Sources/.../ViewModels/SmartReminderViewModel.swift` |
