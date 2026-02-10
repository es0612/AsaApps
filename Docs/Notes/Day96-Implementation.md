# Day 96 - AsaEduGame（子供向け教育ゲーム）

## アプリ概要

AsaEduGameは、4-8歳の子供を対象とした教育ゲームアプリです。SpriteKit（プロジェクト初導入）をSwiftUIと統合し、楽しみながら学べる4つのゲームモードを提供します。

## 主な機能

### 4つのゲームモード
1. **さんすう** 🔢 - 足し算・引き算・比較・穴埋め
2. **ひらがな** 🎌 - 読み方・組み合わせ・書き取り（手書き認識）
3. **かたち** 🔷 - 図形識別・パターン・組み合わせ
4. **ろんり** 🧩 - 仲間はずれ・順番並べ・パターン完成

### 3段階の難易度
- **やさしい** ⭐ - 5問、30秒制限
- **ふつう** ⭐⭐ - 8問、20秒制限
- **むずかしい** ⭐⭐⭐ - 10問、15秒制限

### アダプティブ難易度
- 正答率90%以上 or 5連続正解 → 自動で難易度UP
- 正答率40%以下 or 3連続不正解 → 自動で難易度DOWN

### ゲーミフィケーション
- **星ポイントシステム**: 正解×難易度倍率 + コンボボーナス + パーフェクトボーナス
- **7段階レベル**: ビギナー → レジェンド（0〜1000星）
- **13種のバッジ**: 各モードマスター、コンボ達成、パーフェクト等

### 保護者向け機能
- **進捗ダッシュボード**: Swift Chartsで正答率推移・モード別統計を可視化
- **プロフィール管理**: 名前・アバター・年齢設定

## 技術スタック

| 技術 | 用途 |
|------|------|
| **SpriteKit** | ゲームシーン、パーティクルエフェクト、タッチインタラクション |
| **SwiftData** | ユーザープロフィール、学習履歴、セッション記録の永続化 |
| **TipKit** | 子供向けチュートリアル、ゲームルール説明 |
| **Core ML** | ひらがな手書き認識（書き取りモード） |
| **Swift Charts** | 保護者向け進捗ダッシュボード |
| **AsaUIKit** | ブランドカラー、共通UIコンポーネント |

## アーキテクチャ

### MVVM + Protocol DI
- **Models**: SwiftData @Model（UserProfile, GameSession, LearningRecord, Achievement）
- **ViewModels**: @Observable @MainActor（8つのVM）
- **Services**: Protocol準拠（テスト容易性のためDI）
- **SpriteKit**: BaseGameScene基底 + 4つのゲームシーン + GameSceneDelegate

### パッケージ構造
- **AsaEduGameKit**: Models/Services/ViewModels/SpriteKit（テスト可能）
- **Apps/AsaEduGame**: SwiftUI Views + App骨格

## ファイル構成

### AsaEduGameKit パッケージ
- **Models** (9ファイル): UserProfile, GameSession, LearningRecord, Achievement, GameMode, DifficultyLevel, QuestionType, GameQuestion, GameState
- **Errors** (1ファイル): EduGameError
- **Protocols** (5ファイル): QuestionGenerating, DifficultyAdjusting, GameScoring, EduGameDataServiceProtocol, HandwritingRecognizing
- **Services** (7ファイル): EduGameDataService, QuestionGeneratorService, AdaptiveDifficultyService, ScoringService, AchievementService, HandwritingRecognitionService, TipService
- **SpriteKit** (13ファイル): BaseGameScene + 4シーン, 5ノード, 3エフェクト
- **ViewModels** (8ファイル): Home, Game, MathQuiz, Hiragana, ShapePuzzle, LogicGame, Progress, Profile

### Apps/AsaEduGame
- **App層** (2ファイル): AsaEduGameApp, ContentView
- **Views** (17ファイル): Home, Game(6), Progress(3), Profile(2), Components(5)

### テスト
- **16テストスイート / 166テスト** - 全パス
- Models(29), Services(72), ViewModels(65)

## 子供向けデザイン
- タップ領域: 最小60pt（大きめボタン）
- フォント: 丸ゴシック系 (.rounded)
- カラー: AsaAppsブランドカラー5色
- アニメーション: 楽しいパーティクルエフェクト（星バースト、花火、紙吹雪）
- 応援キャラクター: 絵文字ベースのマスコット（正解時ジャンプ、不正解時励まし）
- アクセシビリティ: Dynamic Type、VoiceOver対応

## ビルドコマンド

```bash
# パッケージテスト
cd Packages/AsaEduGameKit && swift test

# プロジェクト生成
cd Apps/AsaEduGame && xcodegen generate -s project.yml

# ビルド
xcodebuild -project AsaEduGame.xcodeproj -scheme AsaEduGame \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## 学んだこと

1. **SpriteKit + SwiftUI統合**: SpriteView を使えば、SpriteKitシーンをSwiftUIビューツリーに自然に埋め込める
2. **GameSceneDelegate**: SpriteKitシーンからViewModelへの通知はDelegateパターンが最適。nonisolated + MainActor.run で安全にactor境界を超える
3. **@Model + Enum保存**: SwiftDataの@ModelはEnumを直接保存できないため、rawValue(String)で保存してcomputed propertyで変換
4. **子供向けUI**: 大きなタップ領域、丸みのあるフォント、明るい色使い、ポジティブなフィードバックが重要
5. **アダプティブ難易度**: 正答率と連続正解/不正解の両方を考慮することで、より自然な難易度調整が可能
