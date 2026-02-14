# Day 98 - AsaCommunity 実装ノート

## アプリ概要

**AsaCommunity** は日本の地域コミュニティ（町内会・自治会）をデジタル化する上級iOSアプリです。
掲示板、イベント管理、防災情報、ゴミ出しカレンダー、近隣マップを統合し、地域住民の暮らしをサポートします。

## 技術スタック

### 統合iOSフレームワーク（10+）

| # | フレームワーク | 使用箇所 |
|---|---|---|
| 1 | SwiftData | 14モデルの永続化 |
| 2 | MapKit | NeighborhoodMapView, ShelterMapView |
| 3 | CoreLocation | LocationService |
| 4 | NaturalLanguage | ContentModerationService（感情分析） |
| 5 | Charts | CommunityAnalyticsChart |
| 6 | TipKit | OnboardingView |
| 7 | UserNotifications | NotificationService |
| 8 | PhotosUI | CreatePostSheet |
| 9 | App Intents | Siriショートカット対応 |
| 10 | Foundation (Calendar) | GarbageScheduleService |

### アーキテクチャ

- **MVVM + Protocol-based DI**: すべてのサービスがプロトコルで抽象化
- **AsaCommunityKit パッケージ**: Models / Protocols / Services / ViewModels / Analytics を分離
- **AsaUIKit 統合**: ブランドカラー・コンポーネント活用
- **Swift 6.0 strict concurrency**: `@MainActor @Observable` パターン

## 主要機能（5タブ構成）

### 1. ホーム（ダッシュボード）
- 今日のゴミ出し表示
- 近日イベント一覧
- 未読投稿数
- アクティブ安全アラート

### 2. 掲示板
- 8カテゴリ（イベント/質問/譲ります/探しています/回覧板/防犯防災/子育て/一般）
- NaturalLanguage による感情分析（投稿モデレーション）
- PhotosPicker による画像添付
- カテゴリフィルタ + テキスト検索

### 3. イベント
- カレンダー表示 + リスト表示
- RSVP参加表明（参加/検討中/不参加）
- イベントリマインダー通知
- MapKit によるイベント場所表示

### 4. マップ
- 投稿・イベント・店舗・避難所のマルチレイヤー表示
- カスタムアノテーション
- フィルタバー（表示/非表示切り替え）
- CoreLocation による現在位置

### 5. 防災・安全
- 安全レポートの投稿・管理
- 避難所マップ（設備情報付き）
- ゴミ出しカレンダー（曜日別スケジュール）
- 前夜リマインダー通知

## ファイル構成

### パッケージ（AsaCommunityKit）
- Models: 14ファイル（@Model 10 + enum 4）
- Protocols: 5ファイル
- Services: 7ファイル
- ViewModels: 8ファイル
- Analytics: 1ファイル
- Errors: 1ファイル

### アプリ（AsaCommunity）
- App: 2ファイル（App + ContentView）
- Views: 21ファイル
- Components: 4ファイル

**合計: 約63ファイル**

## 日本コミュニティ特化

- **回覧板**: デジタル既読管理
- **ゴミ出しカレンダー**: 曜日×第N週ロジック + 前夜リマインダー
- **防災マップ**: 避難所の収容人数・設備情報
- **子育て支援**: 専用カテゴリ
- **地域店舗**: お気に入り管理

## 学んだこと

### SortDescriptor の Bool 制約
`SortDescriptor` で `Bool` プロパティをソートキーにする場合、`NSObject` 継承が必要。
SwiftData の `@Model` クラスでは直接使えないため、メモリ内ソートで代替。

### foregroundStyle の型推論
三項演算子で `.secondary` と `.red` を混ぜると `HierarchicalShapeStyle` と `Color` の型不一致が発生。
`Color.secondary` と `Color.red` のように明示的に型を指定する必要がある。

### Protocol-based DI の威力
`CommunityDataServiceProtocol` でサービス層を抽象化したことで、
テスト時に `MockCommunityDataService` を差し替え可能。
ViewModel のテストが SwiftData の実体に依存せず実行できる。

## ビルド検証

```bash
# パッケージビルド
cd Packages/AsaCommunityKit && swift build  # SUCCESS

# アプリビルド
cd Apps/AsaCommunity && xcodegen generate && \
xcodebuild -project AsaCommunity.xcodeproj -scheme AsaCommunity \
  -sdk iphonesimulator build  # BUILD SUCCEEDED
```
