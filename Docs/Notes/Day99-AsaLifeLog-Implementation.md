# Day 99 - AsaLifeLog 実装ノート

## アプリ概要

**AsaLifeLog** は、朝活パパエンジニアの日常を総合的に記録・可視化するライフログアプリです。
HealthKit、CoreLocation、CoreMotion、Photos、Swift Charts、WidgetKitなど複数のAppleフレームワークを統合し、
手動入力と自動取り込みの両方でタイムラインを構築します。100本ノックの99番目として、
これまで学んだ技術の集大成としてフレームワーク横断的な実装を行いました。

## 技術スタック

### 統合iOSフレームワーク（8+）

| # | フレームワーク | 使用箇所 |
|---|---|---|
| 1 | SwiftData | 5つの@Modelクラスの永続化 |
| 2 | HealthKit | AppHealthKitBridge（歩数・睡眠・水分） |
| 3 | CoreLocation | AppLocationBridge（位置情報・逆ジオコーディング） |
| 4 | CoreMotion | AppMotionBridge（アクティビティ認識） |
| 5 | Photos / PhotosUI | AppPhotoBridge（写真タイムライン統合） |
| 6 | Charts | 6種チャート（LineMark, BarMark, SectorMark, AreaMark, RuleMark） |
| 7 | WidgetKit | 5サイズ対応ウィジェット |
| 8 | TipKit | OnboardingView |

### アーキテクチャ

- **MVVM + Protocol-based DI**: 6つのプロトコルで全サービスを抽象化
- **AsaLifeLogKit パッケージ**: Models / Enums / Protocols / Services / ViewModels を完全分離
- **AsaUIKit / AsaHealthKit / AsaCoreKit 統合**: 既存パッケージの活用
- **Swift 6.0 strict concurrency**: `@MainActor @Observable` パターン
- **App Group**: アプリ・ウィジェット間のデータ共有

## 主要機能（4タブ構成）

### 1. タイムライン
- 日付選択器による日別表示
- ソースフィルタ（手動/HealthKit/位置情報/写真/モーション）
- エントリー行にタイプ別アイコン・気分バッジ表示
- フローティングアクションボタンで新規エントリー作成
- お気に入り切り替え・スワイプ削除

### 2. ダッシュボード
- 日次統計カード（4つのStatRing: 歩数/睡眠/朝活スコア/エントリー数）
- 気分分布チャート（SectorMark円グラフ）
- 歩数推移チャート（LineMark + RuleMark目標線）
- 睡眠時間チャート（BarMark棒グラフ）
- アクティビティ内訳（SectorMark円グラフ）
- 週間トレンドチャート（AreaMark面グラフ）
- 期間切替（1週間/1ヶ月/3ヶ月/1年）

### 3. インサイト
- 日次サマリーカード（朝活スコアリング + テキスト分析）
- 週次サマリーカード（トレンド分析 + 前週比較）
- パターン検出カード（気分×活動相関、タグ頻度、時間帯、場所パターン）
- ヒューリスティック分析エンジン（AI/ML不使用のルールベース）

### 4. 設定
- 5つのトラッキング設定トグル（ヘルス/位置/写真/アクティビティ/AIインサイト）
- 朝活時間帯設定（開始・終了時刻）
- 目標設定（歩数・睡眠時間）
- JSON / CSV エクスポート
- 場所ログ一覧（カテゴリ別グループ・お気に入り）
- アプリ情報

## パッケージ構成

### AsaLifeLogKit（33ファイル + テスト）

```
Sources/AsaLifeLogKit/
├── Models/
│   ├── Enums/          # 6 enum（EntryType, MoodScore, ActivityType, DataSource, PlaceCategory, ChartPeriod）
│   ├── LifeLogEntry.swift    # メインエントリーモデル（@Model）
│   ├── DailySummary.swift    # 日次サマリー（@Model）
│   ├── WeeklySummary.swift   # 週次サマリー（@Model）
│   ├── PlaceLog.swift        # 訪問場所ログ（@Model）
│   ├── UserPreferences.swift # ユーザー設定（@Model）
│   └── SupportingTypes.swift # 補助構造体（PhotoAssetInfo, ActivityRecord 等）
├── Protocols/          # 6 プロトコル
├── Services/           # 8 サービス
│   ├── LifeLogDataService.swift     # SwiftData CRUD
│   ├── TimelineService.swift         # タイムライン構築
│   ├── InsightsEngine.swift          # ヒューリスティック分析
│   ├── DailySummaryGenerator.swift   # 日次サマリー生成
│   ├── WeeklySummaryGenerator.swift  # 週次サマリー生成
│   └── ExportService.swift           # JSON/CSVエクスポート
├── ViewModels/         # 6 ViewModel
│   ├── TimelineViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── EntryEditorViewModel.swift
│   ├── InsightsViewModel.swift
│   ├── SettingsViewModel.swift
│   └── PlaceLogViewModel.swift
└── Errors/
    └── LifeLogError.swift    # 7種のエラー定義
```

## テスト実装

### テスト統計

| カテゴリ | テスト数 | 対象 |
|---|---|---|
| EnumTests | 24 | 全6 enum の rawValue / displayName / icon / allCases |
| ModelTests | 25 | @Model 初期化・computed property、SupportingTypes |
| ErrorTests | 7 | LifeLogError 全ケースの errorDescription |
| ServiceTests | 30 | InsightsEngine / ExportService / Generator / TimelineService |
| ViewModelTests | 42 | 全6 ViewModel の初期化・操作・エラーハンドリング |
| **合計** | **129** | - |

### テストパターン

- **MockDataService**: `LifeLogDataServiceProtocol` 準拠のインメモリ実装、`shouldThrowError` フラグでエラーテスト
- **MockInsightsEngine**: 固定値を返すモックで ViewModel テストの依存を制御
- **MockLocationService**: 位置情報のモック（座標設定・逆ジオコーディング結果制御）
- **Swift Testing**: `@Test` / `#expect` / `@Suite` / `.tags()` を活用

## ウィジェット

### 5サイズ対応

| サイズ | 表示内容 |
|---|---|
| systemSmall | 歩数 + 気分絵文字 + 朝活スコア |
| systemMedium | 歩数 + 睡眠 + 朝活スコア + エントリー数 + 気分 |
| systemLarge | ヘッダー + 統計サマリー + 直近5エントリーリスト |
| accessoryCircular | 歩数 + Gauge |
| accessoryRectangular | 気分 + 歩数 + 朝活スコア |

## 朝活スコア算出ロジック

InsightsEngine による3要素のスコアリング:

```
朝活スコア (0〜100) = エントリー密度 + 気分 + 多様性
├── エントリー密度: min(件数 × 15, 50) ... 最大50点
├── 気分スコア:     avg(numericValue) × 6.0 ... 最大30点
└── 多様性スコア:   min(種別数 × 5, 20) ... 最大20点
```

## 実装上の注意点と学び

### @Model enum パターン
SwiftData の `@Model` はenumをネイティブ保存できないため、`rawValue: String` で保存し computed property でアクセサを提供するパターンを全5モデルで統一。

### CLLocationManagerDelegate + @MainActor
`CLLocationManagerDelegate` のメソッドは `nonisolated` で宣言し、`Task { @MainActor in ... }` でメインアクターに送る必要がある。これは NSObject ベースのデリゲートパターン全般に適用。

### .foregroundStyle(.accent) は存在しない
SwiftUI の `ShapeStyle` に `.accent` は存在しない。`Color.accentColor` を使用する必要がある。`.primary` / `.secondary` は `ShapeStyle` のメンバーだが `.accent` は非対応。

### Widget の App Group 共有
ウィジェットとアプリ間のデータ共有には `UserDefaults(suiteName:)` を使い、`Codable` 構造体を JSON でシリアライズ。SwiftData の直接共有は Widget Extension では不可。

## ファイル数

| カテゴリ | ファイル数 |
|---|---|
| AsaLifeLogKit パッケージ | 34 |
| アプリ Sources | 54 |
| ウィジェット | 7 |
| テスト | 8 |
| 設定ファイル | 3 |
| **合計** | **106** |
