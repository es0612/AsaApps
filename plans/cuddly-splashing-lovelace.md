# AsaStudyPlanner 実装計画

## 概要
**AsaStudyPlanner**（アプリ #79）は、AIで学習計画を最適化する上級SwiftUIアプリです。
AsaSmartTodoの6要因重み付きスコアリングパターンを「学習計画最適化」に特化させます。

## コア機能

1. **学習項目管理**: 科目/スキルの登録・進捗管理
2. **AI最適化エンジン**: 6要因分析で学習順序を最適化
3. **間隔反復学習**: SM-2アルゴリズムで復習タイミングを自動計算
4. **学習セッション記録**: タイマー付きの学習時間記録
5. **分析ダッシュボード**: 週間/月間の学習統計と朝活スコア

## AI最適化の6要因

| 要因 | 重み | 説明 |
|------|------|------|
| 目標期限 | 35% | 期限が近いほど高優先 |
| 難易度×時間帯 | 20% | 朝は難問、夜は軽い学習 |
| 習熟度 | 15% | 低いほど優先 |
| 復習必要度 | 10% | SM-2アルゴリズム基準 |
| 時間帯適性 | 10% | 朝活時間帯（5-7時）ボーナス |
| 前提知識 | 10% | 依存関係を考慮 |

## ディレクトリ構造

```
Apps/AsaStudyPlanner/
├── project.yml
├── AsaStudyPlanner/
│   ├── AsaStudyPlannerApp.swift
│   ├── Models/
│   │   ├── StudyItem.swift           # 学習項目（Swift Data）
│   │   ├── StudySession.swift        # 学習セッション
│   │   ├── StudyPlan.swift           # 日別計画
│   │   ├── LearningAnalytics.swift   # 分析データ
│   │   ├── StudyCategory.swift       # カテゴリ enum
│   │   ├── DifficultyLevel.swift     # 難易度 enum
│   │   ├── OptimizationResult.swift  # AI最適化結果
│   │   └── UserLearningProfile.swift # ユーザー設定
│   ├── Services/
│   │   ├── StudyOptimizer.swift      # AI最適化エンジン（コア）
│   │   ├── LearningFeatureExtractor.swift
│   │   ├── SpacedRepetitionEngine.swift
│   │   ├── DataService.swift
│   │   └── NotificationService.swift
│   ├── ViewModels/
│   │   ├── StudyPlanViewModel.swift
│   │   ├── AnalyticsViewModel.swift
│   │   └── SettingsViewModel.swift
│   └── Views/
│       ├── Dashboard/
│       ├── StudyItems/
│       ├── Session/
│       ├── AI/
│       ├── Analytics/
│       └── Settings/
├── AsaStudyPlannerTests/
└── AsaStudyPlannerUITests/
```

## 主要データモデル

### StudyItem（学習項目）
```swift
@Model
final class StudyItem {
    var id: UUID
    var title: String
    var category: StudyCategory       // プログラミング、語学、資格等
    var difficulty: DifficultyLevel   // easy, medium, hard, expert
    var estimatedMinutes: Int
    var targetDate: Date?
    var masteryLevel: Double          // 習熟度 0.0-1.0
    var nextReviewDate: Date?         // 間隔反復用
    var aiPriorityScore: Double       // AI計算スコア
}
```

### StudySession（学習セッション）
```swift
@Model
final class StudySession {
    var id: UUID
    var studyItemId: UUID
    var startedAt: Date
    var durationMinutes: Int
    var focusLevel: Int               // 1-5
    var isEarlyMorning: Bool          // 朝活判定
}
```

## 実装フェーズ

### Phase 1: 基盤構築（2-3日）
- [ ] project.yml 作成
- [ ] 基本モデル実装（StudyItem, StudySession, StudyCategory, DifficultyLevel）
- [ ] DataService 実装（Swift Data永続化）
- [ ] 基本UI（タブ構造、学習項目一覧、追加画面）
- [ ] モデル・DataService テスト

### Phase 2: AI最適化エンジン（2-3日）
- [ ] LearningFeatureExtractor 実装
- [ ] StudyOptimizer 実装（6要因重み付けアルゴリズム）
- [ ] SpacedRepetitionEngine 実装（SM-2簡易版）
- [ ] OptimizationResult, OptimizationWeights 実装
- [ ] StudyOptimizerTests（30+テストケース）

### Phase 3: ViewModel・UI統合（2-3日）
- [ ] StudyPlanViewModel 実装
- [ ] SessionViewModel 実装
- [ ] AI関連UI（OptimizationCardView, AIInsightsView）
- [ ] セッション関連UI（TimerView, SessionCompleteView）
- [ ] 統合テスト

### Phase 4: 分析・通知・仕上げ（2-3日）
- [ ] AnalyticsViewModel 実装
- [ ] AnalyticsView, ProductivityChartView 実装
- [ ] NotificationService 実装
- [ ] SettingsView 実装
- [ ] UIテスト、パフォーマンステスト
- [ ] Docs/Notes/Day79-Implementation.md 作成

## 参考ファイル（実装時に参照）

| ファイル | 用途 |
|---------|------|
| `Apps/AsaSmartTodo/.../TaskPriorityPredictor.swift` | AI予測エンジンのパターン |
| `Apps/AsaSmartTodo/.../TaskFeatureExtractor.swift` | 特徴量抽出パターン |
| `Apps/AsaSmartTodo/.../SmartTodoViewModel.swift` | @Observable VMパターン |
| `Apps/AsaSmartTodo/...Tests/TaskPriorityPredictorTests.swift` | Swift Testingパターン |

## 技術スタック

- iOS 17.0+, Swift 5.9+
- SwiftUI + Swift Data
- @Observable + @MainActor
- Swift Testing（95%カバレッジ目標）
- XcodeGen（プロジェクト管理）
- AsaUIKit（共有UIコンポーネント）

## 検証方法

1. **ビルド確認**: `xcodegen generate && xcodebuild -scheme AsaStudyPlanner`
2. **テスト実行**: `swift test` または Cmd+U
3. **動作確認**:
   - 学習項目を追加し、AI最適化提案が表示されることを確認
   - 学習セッションを開始・完了し、習熟度が更新されることを確認
   - 分析画面で週間統計が表示されることを確認
