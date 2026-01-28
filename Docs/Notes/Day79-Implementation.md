# Day 79: AsaStudyPlanner 実装ノート

## 概要

**AsaStudyPlanner**は、AIで学習計画を最適化する上級SwiftUIアプリです。AsaSmartTodoの6要因重み付きスコアリングパターンを「学習計画最適化」に特化させ、SM-2間隔反復学習アルゴリズムと組み合わせることで、科学的に効果的な学習スケジュールを提案します。

## 主要機能

### 1. 学習項目管理
- 科目/スキルの登録・進捗管理
- カテゴリ別分類（プログラミング、語学、資格、数学、理科、ビジネス、クリエイティブ）
- 難易度設定（やさしい、普通、難しい、上級）
- 目標期限と習熟度トラッキング

### 2. AI最適化エンジン
6要因分析で学習順序を最適化：

| 要因 | 重み | 説明 |
|------|------|------|
| 目標期限 | 35% | 期限が近いほど高優先 |
| 難易度×時間帯 | 20% | 朝は難問、夜は軽い学習 |
| 習熟度 | 15% | 低いほど優先 |
| 復習必要度 | 10% | SM-2アルゴリズム基準 |
| 時間帯適性 | 10% | 朝活時間帯（5-7時）ボーナス |
| 前提知識 | 10% | 依存関係を考慮 |

### 3. 間隔反復学習（SM-2アルゴリズム）
- 復習タイミングを自動計算
- EaseFactor（難易度係数）による個人適応
- 連続正解で復習間隔が伸長
- 失敗時はリセットして翌日復習

### 4. 学習セッション記録
- タイマー付きの学習時間記録
- 集中度・理解度の5段階評価
- 朝活判定（5-7時は深朝活、5-9時は朝活）
- セッション完了時に習熟度・復習スケジュール自動更新

### 5. 分析ダッシュボード
- 週間/月間の学習統計
- 朝活スコア（最大100点）
- カテゴリ別学習時間分布
- AI採用率トラッキング
- 連続学習・朝活ストリーク

## 技術スタック

- **iOS 17.0+, Swift 5.9+**
- **SwiftUI + Swift Data**
- **@Observable + @MainActor**
- **Swift Testing**（テストケース60+）
- **XcodeGen**（プロジェクト管理）
- **AsaUIKit**（共有UIコンポーネント）

## アーキテクチャ

```
AsaStudyPlanner/
├── Models/
│   ├── StudyItem.swift           # 学習項目（@Model）
│   ├── StudySession.swift        # 学習セッション
│   ├── StudyPlan.swift           # 日別計画
│   ├── LearningAnalytics.swift   # 分析データ
│   ├── StudyCategory.swift       # カテゴリ enum
│   ├── DifficultyLevel.swift     # 難易度 enum
│   ├── OptimizationResult.swift  # AI最適化結果
│   └── UserLearningProfile.swift # ユーザー設定
├── Services/
│   ├── StudyOptimizer.swift      # AI最適化エンジン（コア）
│   ├── LearningFeatureExtractor.swift  # 特徴量抽出
│   ├── SpacedRepetitionEngine.swift    # SM-2アルゴリズム
│   ├── DataService.swift         # Swift Data永続化
│   └── NotificationService.swift # 通知管理
├── ViewModels/
│   ├── StudyPlanViewModel.swift  # @Observable
│   ├── AnalyticsViewModel.swift
│   └── SettingsViewModel.swift
└── Views/
    ├── Dashboard/
    ├── StudyItems/
    ├── Session/
    ├── AI/
    ├── Analytics/
    └── Settings/
```

## 主要パターン

### 1. 6要因重み付けスコアリング
```swift
let totalScore =
    features.targetDateScore * weights.targetDateWeight +
    features.difficultyTimeScore * weights.difficultyTimeWeight +
    features.masteryScore * weights.masteryWeight +
    features.reviewScore * weights.reviewWeight +
    features.timeOfDayScore * weights.timeOfDayWeight +
    features.prerequisiteScore * weights.prerequisiteWeight
```

### 2. SM-2アルゴリズム
```swift
// EaseFactorの更新
EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))

// 復習間隔の計算
if repetitionCount == 1: interval = 1日
if repetitionCount == 2: interval = 6日
if repetitionCount >= 3: interval = 前回間隔 × EaseFactor
```

### 3. 時間帯最適化
```swift
// 深朝活（5-7時）: 難しい内容に最適
// 朝（7-9時）: 集中力が高い時間帯
// 午後: 通常スコア
// 夜間（21時以降）: 難しい内容は避ける
```

## テスト

### テストスイート構成
- **StudyItemTests**: 30+テスト
- **StudySessionTests**: 20+テスト
- **LearningFeatureExtractorTests**: 25+テスト
- **SpacedRepetitionEngineTests**: 20+テスト
- **StudyOptimizerTests**: 30+テスト

### テストカバレッジ目標
- Unit Tests: 95%
- Integration Tests: 80%

## 最適化プリセット

1. **バランス型（デフォルト）**: すべての要因をバランスよく考慮
2. **期限重視**: 期限が近い項目を優先的に学習
3. **朝活重視**: 朝の集中力を活かした難問優先
4. **復習重視**: 復習タイミングを重視して定着を図る
5. **カスタム**: 各要因の重みを自由にカスタマイズ

## 学習効果の科学的根拠

- **間隔反復学習**: エビングハウスの忘却曲線に基づく最適復習タイミング
- **朝活効果**: 起床後2-3時間が最も集中力が高いとされる
- **難易度×時間帯**: 認知負荷理論に基づく学習効率最適化
- **習熟度トラッキング**: メタ認知による学習効果向上

## 今後の拡張予定

- [ ] ウィジェット対応（朝活スコア、今日の推奨）
- [ ] iCloud同期
- [ ] Apple Watch対応
- [ ] Siriショートカット統合
- [ ] Core ML による学習パターン予測

## スクリーンショット

（アプリ完成後に追加予定）

---

**作成日**: 2026-01-28
**アプリ番号**: #79
**カテゴリ**: 上級 - AI/ML統合
