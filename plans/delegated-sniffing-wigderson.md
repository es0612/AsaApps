# AsaRecipeAI 実装計画

## 概要

**AsaRecipeAI**（アプリ #88）は、画像からレシピを提案する上級アプリです。**Foundation Models + Vision** を活用して食材を認識し、オンデバイスLLMがレシピを推薦します。

### コンセプト
- 「冷蔵庫の食材を撮影するだけでレシピを提案」
- **Foundation Models フレームワーク**（iOS 26+）でオンデバイスAI
- Vision フレームワークとの連携で画像分析
- @Generable マクロで型安全な構造化データ生成
- ストリーミング応答でリアルタイムUI更新

---

## 主要機能

| 機能 | 説明 |
|------|------|
| **食材認識** | Vision + Foundation Models で画像から食材を識別・分類 |
| **AIレシピ提案** | オンデバイスLLMがレシピを生成（完全オフライン） |
| **ストリーミングUI** | レシピ生成をリアルタイムで表示 |
| **PhotosPicker統合** | 写真ライブラリからの画像選択 |
| **お気に入り管理** | レシピのお気に入り保存 |
| **履歴管理** | 認識履歴・調理履歴の管理 |

---

## 技術スタック

| 技術 | 用途 |
|------|------|
| **Foundation Models** | オンデバイスLLM（@Generable, LanguageModelSession） |
| **Vision** | VNClassifyImageRequest で画像分類 |
| **SwiftUI** | UI + @State でストリーミング表示 |
| **Swift Data** | データ永続化 |
| **PhotosUI** | PhotosPicker で画像選択 |
| **AsaUIKit** | 共有UIコンポーネント |

### 対象OS
- **iOS 26+**（Foundation Models 必須）
- iPhone 15 Pro / iPhone 16 シリーズ（A17 Pro以降）

---

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                         Views                                │
│  HomeView → AnalysisView → RecipeListView → RecipeDetailView │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       ViewModels                             │
│  RecipeAIViewModel (@Observable, @MainActor)                 │
│  - LanguageModelSession (状態管理)                            │
│  - ストリーミング応答処理                                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                        Services                              │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐  │
│  │ VisionService  │  │ RecipeService  │  │ DataService   │  │
│  │ (画像分類)      │  │ (LLMレシピ生成) │  │ (Swift Data)  │  │
│  └────────────────┘  └────────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Foundation Models                          │
│  @Generable: IngredientInfo, RecipeRecommendation            │
│  LanguageModelSession: respond(), streamResponse()           │
└─────────────────────────────────────────────────────────────┘
```

---

## ディレクトリ構造

```
Apps/AsaRecipeAI/
├── project.yml
├── AsaRecipeAI/
│   ├── AsaRecipeAIApp.swift
│   ├── ContentView.swift
│   │
│   ├── Models/
│   │   ├── Generable/                    # @Generable 型
│   │   │   ├── IngredientInfo.swift      # 食材認識結果
│   │   │   ├── RecipeRecommendation.swift # レシピ推薦
│   │   │   └── CookingStep.swift         # 調理手順
│   │   ├── Ingredient.swift              # 食材モデル (@Model)
│   │   ├── Recipe.swift                  # レシピモデル (@Model)
│   │   ├── RecognitionHistory.swift      # 認識履歴 (@Model)
│   │   └── UserPreferences.swift         # 設定 (@Model)
│   │
│   ├── ViewModels/
│   │   ├── RecipeAIViewModel.swift       # メインVM + LanguageModelSession
│   │   └── SettingsViewModel.swift       # 設定VM
│   │
│   ├── Views/
│   │   ├── Home/
│   │   │   └── HomeView.swift
│   │   ├── Analysis/
│   │   │   ├── ImagePickerView.swift     # PhotosPicker
│   │   │   ├── AnalysisView.swift        # 分析画面
│   │   │   └── IngredientListView.swift  # 認識結果
│   │   ├── Recipe/
│   │   │   ├── RecipeListView.swift      # レシピ一覧
│   │   │   ├── RecipeDetailView.swift    # レシピ詳細
│   │   │   └── RecipeStreamingView.swift # ストリーミング表示
│   │   ├── Favorites/
│   │   │   └── FavoritesView.swift
│   │   ├── Settings/
│   │   │   └── SettingsView.swift
│   │   └── Components/
│   │       ├── IngredientCard.swift
│   │       ├── RecipeCard.swift
│   │       └── StreamingTextView.swift   # ストリーミングテキスト
│   │
│   ├── Services/
│   │   ├── VisionService.swift           # Vision画像分類
│   │   ├── RecipeAIService.swift         # Foundation Models連携
│   │   └── DataService.swift             # Swift Data
│   │
│   └── Assets.xcassets
│
├── AsaRecipeAITests/
└── AsaRecipeAIUITests/
```

---

## @Generable モデル設計

### IngredientInfo（食材認識結果）

```swift
import FoundationModels

@Generable
struct IngredientInfo: Equatable, Sendable {
    /// 食材名（日本語）
    let name: String

    /// カテゴリ（野菜、肉類、魚介類、乳製品、穀物、調味料、その他）
    let category: String

    /// 認識信頼度
    @Guide(range: 0.0...1.0)
    let confidence: Double

    /// 絵文字アイコン
    let emoji: String
}

@Generable
struct IngredientRecognitionResult: Equatable, Sendable {
    /// 認識された食材リスト
    @Guide(.count(1...20))
    let ingredients: [IngredientInfo]

    /// 分析サマリー
    let summary: String
}
```

### RecipeRecommendation（レシピ推薦）

```swift
@Generable
struct RecipeRecommendation: Equatable, Sendable {
    /// レシピ名
    let name: String

    /// レシピの説明
    let description: String

    /// 難易度（簡単、普通、上級）
    let difficulty: String

    /// 調理時間（分）
    @Guide(range: 5...180)
    let cookingTimeMinutes: Int

    /// 人数
    @Guide(range: 1...8)
    let servings: Int

    /// 必要な食材
    @Guide(.count(1...15))
    let ingredients: [RecipeIngredient]

    /// 調理手順
    @Guide(.count(1...20))
    let steps: [CookingStep]

    /// 推薦理由
    let recommendationReason: String
}

@Generable
struct RecipeIngredient: Equatable, Sendable {
    let name: String
    let amount: String
    let isAvailable: Bool  // 認識された食材かどうか
}

@Generable
struct CookingStep: Equatable, Sendable {
    @Guide(range: 1...20)
    let stepNumber: Int
    let instruction: String
    let tip: String?
}

@Generable
struct RecipeRecommendations: Equatable, Sendable {
    @Guide(.count(1...5))
    let recipes: [RecipeRecommendation]
}
```

---

## Service層設計

### RecipeAIService（Foundation Models連携）

```swift
import FoundationModels
import Vision
import UIKit

@MainActor
@Observable
final class RecipeAIService {
    // MARK: - Properties

    private var session: LanguageModelSession?
    private(set) var isProcessing = false

    // ストリーミング用
    private(set) var partialRecipes: RecipeRecommendations.PartiallyGenerated?

    // MARK: - Initialization

    init() {
        // セッションをプレウォーム
        Task {
            self.session = LanguageModelSession()
            try? await self.session?.prewarm()
        }
    }

    // MARK: - 食材認識

    func recognizeIngredients(from image: UIImage) async throws -> IngredientRecognitionResult {
        guard let session else {
            throw RecipeAIError.sessionNotReady
        }

        // Vision で画像分類
        let visionResults = try await classifyImage(image)

        // Foundation Models で食材を特定
        let prompt = """
        以下の画像分類結果から、料理に使える食材を特定してください。
        分類結果: \(visionResults.joined(separator: ", "))

        日本語で食材名、カテゴリ、信頼度、絵文字を返してください。
        """

        let response = try await session.respond(
            to: prompt,
            generating: IngredientRecognitionResult.self
        )

        return response.content
    }

    // MARK: - レシピ推薦（ストリーミング）

    func streamRecipeRecommendations(
        for ingredients: [IngredientInfo],
        preferences: UserPreferences?
    ) -> AsyncThrowingStream<RecipeRecommendations.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let session else {
                    continuation.finish(throwing: RecipeAIError.sessionNotReady)
                    return
                }

                let ingredientList = ingredients.map { "\($0.emoji) \($0.name)" }.joined(separator: ", ")
                let maxTime = preferences?.maxCookingTime ?? 60

                let prompt = """
                以下の食材を使ったレシピを3つ提案してください。

                食材: \(ingredientList)
                最大調理時間: \(maxTime)分

                家庭料理として作りやすく、美味しいレシピを提案してください。
                各レシピには詳細な調理手順を含めてください。
                """

                do {
                    for try await partial in session.streamResponse(
                        to: prompt,
                        generating: RecipeRecommendations.self
                    ) {
                        continuation.yield(partial.result)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func classifyImage(_ image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw RecipeAIError.imageProcessingFailed
        }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let results = request.results else {
            return []
        }

        return results
            .filter { $0.confidence > 0.3 }
            .prefix(10)
            .map { $0.identifier }
    }
}

enum RecipeAIError: Error, LocalizedError {
    case sessionNotReady
    case imageProcessingFailed
    case noIngredientsFound

    var errorDescription: String? {
        switch self {
        case .sessionNotReady: return "AIセッションが準備できていません"
        case .imageProcessingFailed: return "画像の処理に失敗しました"
        case .noIngredientsFound: return "食材が見つかりませんでした"
        }
    }
}
```

### RecipeAIViewModel

```swift
import SwiftUI
import FoundationModels

@MainActor
@Observable
final class RecipeAIViewModel {
    // MARK: - Properties

    private let recipeAIService: RecipeAIService
    private let dataService: DataService

    // 状態
    private(set) var isAnalyzing = false
    private(set) var isGeneratingRecipes = false

    // 認識結果
    private(set) var recognizedIngredients: [IngredientInfo] = []

    // レシピ（ストリーミング）
    private(set) var partialRecipes: RecipeRecommendations.PartiallyGenerated?
    private(set) var finalRecipes: [RecipeRecommendation] = []

    // エラー
    private(set) var errorMessage: String?

    // MARK: - Initialization

    init(recipeAIService: RecipeAIService, dataService: DataService) {
        self.recipeAIService = recipeAIService
        self.dataService = dataService
    }

    // MARK: - Public Methods

    func analyzeImage(_ image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        recognizedIngredients = []

        do {
            let result = try await recipeAIService.recognizeIngredients(from: image)
            recognizedIngredients = result.ingredients

            // 履歴に保存
            try await dataService.saveRecognitionHistory(result)

        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    func generateRecipes() async {
        guard !recognizedIngredients.isEmpty else { return }

        isGeneratingRecipes = true
        partialRecipes = nil
        finalRecipes = []

        let preferences = try? await dataService.fetchUserPreferences()

        do {
            for try await partial in recipeAIService.streamRecipeRecommendations(
                for: recognizedIngredients,
                preferences: preferences
            ) {
                partialRecipes = partial

                // 完成したレシピを抽出
                if let recipes = partial.recipes {
                    finalRecipes = recipes.compactMap { $0 }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGeneratingRecipes = false
    }
}
```

---

## UI実装

### RecipeStreamingView（ストリーミング表示）

```swift
import SwiftUI

struct RecipeStreamingView: View {
    let partialRecipes: RecipeRecommendations.PartiallyGenerated?
    let isGenerating: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let recipes = partialRecipes?.recipes {
                    ForEach(recipes.indices, id: \.self) { index in
                        if let recipe = recipes[index] {
                            RecipeCardView(recipe: recipe)
                                .transition(.opacity.combined(with: .slide))
                        }
                    }
                }

                if isGenerating {
                    ProgressView("レシピを生成中...")
                        .padding()
                }
            }
            .padding()
        }
        .animation(.easeInOut, value: partialRecipes?.recipes?.count)
    }
}

struct RecipeCardView: View {
    let recipe: RecipeRecommendation.PartiallyGenerated

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                // レシピ名
                if let name = recipe.name {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                // 説明
                if let description = recipe.description {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                // メタ情報
                HStack {
                    if let time = recipe.cookingTimeMinutes {
                        Label("\(time)分", systemImage: "clock")
                    }
                    if let difficulty = recipe.difficulty {
                        Label(difficulty, systemImage: "star")
                    }
                    if let servings = recipe.servings {
                        Label("\(servings)人分", systemImage: "person.2")
                    }
                }
                .font(.caption)

                // 食材（生成中）
                if let ingredients = recipe.ingredients {
                    Text("食材:")
                        .font(.headline)
                    ForEach(ingredients.indices, id: \.self) { i in
                        if let ing = ingredients[i] {
                            HStack {
                                Image(systemName: ing.isAvailable == true ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(ing.isAvailable == true ? .green : .gray)
                                Text("\(ing.name ?? "") \(ing.amount ?? "")")
                            }
                        }
                    }
                }
            }
        }
    }
}
```

---

## project.yml

```yaml
name: AsaRecipeAI
options:
  bundleIdPrefix: com.asapapa.apps
  deploymentTarget:
    iOS: "26.0"  # Foundation Models 必須
  createIntermediateGroups: true

packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit

targets:
  AsaRecipeAI:
    type: application
    platform: iOS
    sources: [AsaRecipeAI]
    settings:
      SWIFT_VERSION: "6.0"
      INFOPLIST_KEY_NSPhotoLibraryUsageDescription: "写真から食材を認識するために写真ライブラリへのアクセスが必要です"
      INFOPLIST_KEY_NSCameraUsageDescription: "食材を撮影するためにカメラへのアクセスが必要です"
    dependencies:
      - package: AsaUIKit
        product: AsaUIKit
      - sdk: SwiftUI.framework
      - sdk: SwiftData.framework
      - sdk: FoundationModels.framework
      - sdk: Vision.framework
      - sdk: PhotosUI.framework

  AsaRecipeAITests:
    type: bundle.unit-test
    platform: iOS
    sources: AsaRecipeAITests
    dependencies:
      - target: AsaRecipeAI
```

---

## 実装フェーズ（6日間）

### Phase 1: 基盤構築（Day 1）
- [ ] project.yml作成（iOS 26+, FoundationModels）
- [ ] @Generable モデル実装（IngredientInfo, RecipeRecommendation）
- [ ] AsaUIKit依存関係設定
- [ ] Assets.xcassets準備

### Phase 2: Service層（Day 2）
- [ ] RecipeAIService実装（LanguageModelSession統合）
- [ ] VisionService実装（画像分類）
- [ ] DataService実装（Swift Data）
- [ ] エラーハンドリング

### Phase 3: ViewModel・ストリーミング（Day 3）
- [ ] RecipeAIViewModel実装
- [ ] ストリーミング応答処理
- [ ] 状態管理（isAnalyzing, isGeneratingRecipes）

### Phase 4: 画像選択・分析UI（Day 4）
- [ ] ImagePickerView（PhotosPicker）
- [ ] AnalysisView（分析画面）
- [ ] IngredientListView（認識結果）

### Phase 5: レシピUI（Day 5）
- [ ] RecipeStreamingView（ストリーミング表示）
- [ ] RecipeListView / RecipeDetailView
- [ ] FavoritesView / SettingsView
- [ ] HomeView（タブナビゲーション）

### Phase 6: テスト・仕上げ（Day 6）
- [ ] Unit Tests実装（40テスト目標）
- [ ] UI調整・アニメーション
- [ ] ドキュメント作成（Day88-Implementation.md）

---

## 参照ドキュメント

| リソース | URL |
|---------|-----|
| Foundation Models Framework | https://developer.apple.com/documentation/FoundationModels |
| Meet the Foundation Models (WWDC25) | https://developer.apple.com/videos/play/wwdc2025/286/ |
| Deep dive into Foundation Models (WWDC25) | https://developer.apple.com/videos/play/wwdc2025/301/ |
| Code-along: Foundation Models (WWDC25) | https://developer.apple.com/videos/play/wwdc2025/259/ |
| Vision Framework | https://developer.apple.com/documentation/vision |

## 参照すべき既存ファイル

| 目的 | ファイルパス |
|------|-------------|
| @Observable ViewModel | `Apps/AsaSmartHome/AsaSmartHome/ViewModels/SmartHomeViewModel.swift` |
| 画像処理Service | `Apps/AsaPhotoEditor/AsaPhotoEditor/Services/ImageProcessingService.swift` |
| PhotosPicker統合 | `Apps/AsaFamilyAlbum/AsaFamilyAlbum/Views/Components/PhotoPickerView.swift` |
| Swift Data 永続化 | `Apps/AsaSmartTodo/AsaSmartTodo/Services/DataService.swift` |

---

## 検証方法

### ビルド確認
```bash
cd Apps/AsaRecipeAI
xcodegen generate
open AsaRecipeAI.xcodeproj
# Cmd+B でビルド（iOS 26 Simulator）
```

### 機能確認チェックリスト
- [ ] PhotosPickerで画像選択
- [ ] Vision + Foundation Models で食材認識
- [ ] ストリーミングでレシピ生成（リアルタイム表示）
- [ ] レシピ詳細・調理手順表示
- [ ] お気に入り登録
- [ ] 設定変更

---

## 技術的考慮事項

### Foundation Models の制限
- **対応デバイス**: A17 Pro以降（iPhone 15 Pro, iPhone 16シリーズ）
- **オフライン動作**: 完全オンデバイス処理
- **無料**: API呼び出しコスト不要

### パフォーマンス最適化
- `session.prewarm()` でLLMを事前ロード
- ストリーミングで即時フィードバック
- Vision処理は非同期で実行

### 将来拡張
- カメラリアルタイム認識（AVCaptureSession）
- レシピ共有機能
- 外部レシピAPI連携
