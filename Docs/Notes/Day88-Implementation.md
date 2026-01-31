# Day 88 - AsaRecipeAI 実装ノート

## アプリ概要

**AsaRecipeAI** は、画像からレシピを提案するAIアプリです。Foundation Models フレームワーク（iOS 26+）を活用し、オンデバイスLLMで食材認識とレシピ生成を行います。

### コンセプト

「冷蔵庫の食材を撮影するだけでレシピを提案」

- **完全オフライン**: A17 Pro以降のデバイスでオンデバイスAI処理
- **無料**: API呼び出しコスト不要
- **プライバシー**: 画像データがデバイス外に送信されない

## 技術スタック

| 技術 | 用途 |
|------|------|
| **Foundation Models** | オンデバイスLLM（@Generable, LanguageModelSession） |
| **Vision** | VNClassifyImageRequest で画像分類 |
| **SwiftUI** | UI + @Observable でリアクティブ |
| **Swift Data** | データ永続化 |
| **PhotosUI** | PhotosPicker で画像選択 |
| **AsaUIKit** | 共有UIコンポーネント |

## Foundation Models フレームワーク

### @Generable マクロ

Foundation Models の中核機能。構造体に `@Generable` を付けることで、LLMが型安全な構造化データを生成できます。

```swift
@Generable
struct IngredientInfo: Equatable, Sendable {
    @Guide(description: "食材の名前（日本語で出力）")
    let name: String

    @Guide(description: "認識の信頼度", range: 0.0...1.0)
    let confidence: Double
}
```

### @Guide マクロ

LLMに生成のヒントを与えます：

- `description`: フィールドの説明
- `range`: 数値の範囲制限
- `.count()`: 配列の要素数制限

### LanguageModelSession

LLMセッションの管理。プレウォームでモデルを事前ロードし、レスポンスを高速化。

```swift
let session = LanguageModelSession()
try await session.prewarm()

// 非ストリーミング
let response = try await session.respond(
    to: prompt,
    generating: IngredientRecognitionResult.self
)

// ストリーミング
for try await partial in session.streamResponse(
    to: prompt,
    generating: RecipeRecommendations.self
) {
    // partial.result で部分生成結果を取得
}
```

### PartiallyGenerated

ストリーミング中の部分生成結果。`@Generable` な型には自動的に `.PartiallyGenerated` 型が生成され、各フィールドがオプショナルになります。

## アーキテクチャ

### レイヤー構成

```
┌─────────────────────────────────────────────────────────────┐
│                         Views                                │
│  HomeView → FavoritesView → HistoryView → SettingsView      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       ViewModel                              │
│  RecipeAIViewModel (@Observable, @MainActor)                 │
│  - 状態管理 (AppState enum)                                   │
│  - ストリーミング応答処理                                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                        Services                              │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐  │
│  │ VisionService  │  │ RecipeAIService│  │ DataService   │  │
│  │ (画像分類)      │  │ (LLM連携)      │  │ (Swift Data)  │  │
│  └────────────────┘  └────────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### フロー

1. **画像選択**: PhotosPicker で画像を選択
2. **Vision処理**: VNClassifyImageRequest で画像分類
3. **食材認識**: 分類結果をLLMに渡して食材を特定
4. **レシピ生成**: 食材リストからレシピをストリーミング生成
5. **表示**: 部分生成結果をリアルタイムでUI更新

## ディレクトリ構造

```
Apps/AsaRecipeAI/
├── project.yml
├── AsaRecipeAI/
│   ├── AsaRecipeAIApp.swift
│   ├── ContentView.swift
│   │
│   ├── Models/
│   │   ├── Generable/
│   │   │   ├── IngredientInfo.swift     # @Generable 食材情報
│   │   │   └── RecipeRecommendation.swift # @Generable レシピ推薦
│   │   ├── Ingredient.swift             # Swift Data 食材モデル
│   │   ├── Recipe.swift                 # Swift Data レシピモデル
│   │   ├── RecognitionHistory.swift     # 認識履歴
│   │   └── UserPreferences.swift        # ユーザー設定
│   │
│   ├── ViewModels/
│   │   └── RecipeAIViewModel.swift      # メインVM + 状態管理
│   │
│   ├── Views/
│   │   ├── Home/
│   │   │   └── HomeView.swift           # メイン画面
│   │   ├── Favorites/
│   │   │   └── FavoritesView.swift      # お気に入り
│   │   ├── Settings/
│   │   │   ├── HistoryView.swift        # 履歴
│   │   │   └── SettingsView.swift       # 設定
│   │   └── Components/
│   │       ├── IngredientCard.swift     # 食材カード
│   │       ├── RecipeCard.swift         # レシピカード
│   │       └── StreamingTextView.swift  # ストリーミング表示
│   │
│   ├── Services/
│   │   ├── VisionService.swift          # Vision画像分類
│   │   ├── RecipeAIService.swift        # Foundation Models連携
│   │   └── DataService.swift            # Swift Data
│   │
│   └── Assets.xcassets
│
├── AsaRecipeAITests/
│   └── AsaRecipeAITests.swift           # 40+テスト
└── AsaRecipeAIUITests/
    └── AsaRecipeAIUITests.swift
```

## 主要機能

### 1. 食材認識

Vision フレームワークで画像を分類し、Foundation Models で食材を特定。

```swift
// Vision で分類
let labels = try await visionService.extractFoodLabels(image)

// LLM で食材特定
let result = try await recipeAIService.recognizeIngredients(from: labels)
```

### 2. レシピ生成（ストリーミング）

食材リストからレシピをストリーミング生成。UI がリアルタイムで更新。

```swift
for try await partial in recipeAIService.streamRecipeRecommendations(
    for: ingredients,
    preferences: preferences
) {
    partialRecipes = partial.result
    // UI更新
}
```

### 3. お気に入り・履歴管理

Swift Data でレシピと履歴を永続化。

### 4. ユーザー設定

- 最大調理時間
- デフォルト人数
- 食事制限（ベジタリアン、ヴィーガン等）
- 自動履歴保存

## テスト

### Unit Tests（40+テスト）

- `IngredientInfo` のテスト
- `RecipeRecommendation` のテスト
- `IngredientCategory` のテスト
- `RecipeDifficulty` のテスト
- `DietaryRestriction` のテスト
- モデル変換のテスト
- エラーハンドリングのテスト

### UI Tests

- アプリ起動テスト
- タブナビゲーションテスト
- 空状態表示テスト

## 対応デバイス

Foundation Models フレームワークは以下のデバイスで利用可能：

- iPhone 15 Pro / Pro Max（A17 Pro）
- iPhone 16 / 16 Plus / 16 Pro / 16 Pro Max

## 今後の拡張

1. **カメラリアルタイム認識**: AVCaptureSession でライブ認識
2. **レシピ共有機能**: ShareLink で共有
3. **外部レシピAPI連携**: レシピ検索の拡充
4. **栄養計算**: 食材から栄養素を計算

## 学習ポイント

### Foundation Models

- `@Generable` マクロで型安全なLLM出力
- `@Guide` で生成のヒント提供
- `LanguageModelSession` のプレウォーム
- ストリーミング応答と `.PartiallyGenerated`

### Vision + LLM連携

- Vision で粗い分類 → LLM で詳細な認識
- 2段階処理で精度向上

### SwiftUI + Streaming

- `@Observable` でリアクティブ状態管理
- ストリーミング結果のリアルタイムUI更新
- アニメーションとの組み合わせ

## ビルド手順

```bash
cd Apps/AsaRecipeAI
xcodegen generate
open AsaRecipeAI.xcodeproj
# Xcode で iOS 26 Simulator を選択してビルド (Cmd+B)
```

## 参照ドキュメント

- [Foundation Models Framework](https://developer.apple.com/documentation/FoundationModels)
- [Meet the Foundation Models (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/286/)
- [Deep dive into Foundation Models (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/301/)
- [Vision Framework](https://developer.apple.com/documentation/vision)

---

**作成日**: 2026年1月31日
**アプリ番号**: #88
**技術レベル**: 上級
**主要技術**: Foundation Models, Vision, SwiftUI, Swift Data
