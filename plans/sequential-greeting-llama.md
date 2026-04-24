# AsaRecipeAI 写真選択クラッシュ修正プラン

## Context（なぜこの変更が必要か）

### 発生している問題
ユーザーが AsaRecipeAI で写真を選択し食材認識を実行するとクラッシュする。シミュレータでは**毎回必ず**発生し、SNS デモ動画の撮影ができない状態。

### エラーログの核心
```
Passing along Model Catalog error: com.apple.UnifiedAssetFramework Code=5000
"There are no underlying assets ... for asset set com.apple.modelcatalog"
Received ModelManagerError that couldn't be converted to a TokenGenerationError
Prewarm failed: Model Catalog error...
CSU exception: Failed to create espresso context
```

### 根本原因
Apple **Foundation Models フレームワーク**（Apple Intelligence オンデバイス LLM）の初期化失敗。

1. **シミュレータは Foundation Models 非対応** — `LanguageModelSession.prewarm()` が低レベルで失敗する
2. **`CSU exception: Failed to create espresso context`** は CoreML 推論エンジン（Espresso）の C++ 例外で、Swift の `do-catch` で捕捉できない可能性がある
3. 現在のコード (`RecipeAIService.swift:46-58`) は `.available` チェック後に `prewarm()` を呼んでいるが、`.available` は「SDK 的に利用可能」を意味するだけで、実際にモデルアセットがダウンロード済みか・Espresso が初期化できるかは別問題
4. フォールバック機構が存在しないため、Foundation Models が使えない環境では常に落ちる

### 目指す成果
- **シミュレータでも実機でも写真選択 → 食材認識 → レシピ生成が最後まで動く**
- Foundation Models 非対応環境では自動的に**デモモード（モックデータ）**にフォールバック
- Apple Intelligence 対応実機では従来通り本物の Foundation Models 推論を実行
- SNS デモ動画の撮影をシミュレータで完結できる

---

## 修正方針サマリ

`RecipeAIService` に `RecipeAIServiceMode`（`.live` / `.mock`）を導入し、Foundation Models 実行経路とモック経路の二本立てにする。**シミュレータでは `#if targetEnvironment(simulator)` で無条件にモック分岐**、実機では availability 詳細チェック＋`prewarm` 失敗時の劣化フォールバックで保護する。ViewModel・View は「デモモードかどうか」だけを知ればよく、UI はオレンジドット＋バッジで誠実に明示する。

既存の `SampleDataGenerator` は **SwiftData 永続モデル** (`Recipe` / `SavedRecipeIngredient` / `SavedCookingStep`) 用で、AI サービスが返すべき **Generable 型** (`IngredientRecognitionResult` / `RecipeRecommendations` / `RecipeRecommendation` / `RecipeIngredient` / `CookingStep`) とは別物のため、レシピ内容は流用しつつ新規 `MockRecipeAIData` を追加する。

---

## 変更対象ファイル一覧

| # | ファイル | 変更概要 |
|---|---|---|
| 1 | `Apps/AsaRecipeAI/AsaRecipeAI/Services/RecipeAIService.swift` | サービスモード導入・prepareSession 再構成・各メソッドにモック分岐 |
| 2 | `Apps/AsaRecipeAI/AsaRecipeAI/Services/MockRecipeAIData.swift` | **新規作成**。Generable 型のモックデータ供給 |
| 3 | `Apps/AsaRecipeAI/AsaRecipeAI/ViewModels/RecipeAIViewModel.swift` | `isDemoMode` / `aiStatusText` 公開・空ラベル時フォールバック・ストリーミング失敗時 sync フォールバック |
| 4 | `Apps/AsaRecipeAI/AsaRecipeAI/Views/Home/HomeView.swift` | `aiStatusSection` をデモモード対応に・`loadImage` catch の空画像を errorMessage に変更 |

XcodeGen プロジェクトなので `project.yml` は編集不要（`Services/` 配下のファイルは自動で拾われる）。

---

## 詳細プラン

### 1. `RecipeAIService.swift`（主戦場）

**ファイルパス:** `Apps/AsaRecipeAI/AsaRecipeAI/Services/RecipeAIService.swift`

#### 1-A. 新規 enum を追加（`// MARK: - RecipeAIService` の直前、現 line 12 付近）

```swift
/// サービスの動作モード
enum RecipeAIServiceMode: Equatable {
    case live                       // Foundation Models で本物の推論
    case mock(reason: String)       // シミュレータ／モデル未対応／準備失敗

    var isLive: Bool {
        if case .live = self { return true }
        return false
    }

    var userFacingLabel: String {
        switch self {
        case .live: return "AI準備完了"
        case .mock: return "デモモード"
        }
    }
}
```

#### 1-B. プロパティ差し替え（現 line 19-30）

```swift
private var session: LanguageModelSession?
private(set) var isProcessing = false
private(set) var mode: RecipeAIServiceMode = .mock(reason: "初期化中")
private(set) var lastError: String?

/// mock モードでも UI 操作を許可するため常に true を返す
var isSessionReady: Bool {
    if case .mock(reason: "初期化中") = mode { return false }
    return true
}
```

**設計意図**: `isSessionReady` は「ボタンを押せるか」という UI 契約。mock モードでも操作可能にしないと SNS デモ動画の撮影ができない。初期化中のみ false。

#### 1-C. `prepareSession()` を全面書き換え（現 line 43-59）

```swift
func prepareSession() async {
    // 1. シミュレータは無条件でモック（CSU 例外を未然に回避）
    #if targetEnvironment(simulator)
    mode = .mock(reason: "シミュレータ環境のためデモモードで動作します")
    lastError = nil
    return
    #else

    // 2. availability の詳細ケース分岐
    switch SystemLanguageModel.default.availability {
    case .available:
        break
    case .unavailable(let reason):
        mode = .mock(reason: Self.describe(reason))
        lastError = nil
        return
    @unknown default:
        mode = .mock(reason: "未対応の availability 状態")
        lastError = nil
        return
    }

    // 3. セッション生成と prewarm を try/catch で包む
    do {
        let newSession = LanguageModelSession()
        try await newSession.prewarm()
        session = newSession
        mode = .live
        lastError = nil
    } catch {
        session = nil
        mode = .mock(reason: "Foundation Models 初期化失敗: \(error.localizedDescription)")
        lastError = nil
    }
    #endif
}

/// availability の理由を人間可読文字列に変換
private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
    switch reason {
    case .deviceNotEligible:
        return "このデバイスは Apple Intelligence 非対応です"
    case .appleIntelligenceNotEnabled:
        return "設定で Apple Intelligence を有効にしてください"
    case .modelNotReady:
        return "モデルアセットをダウンロード中です"
    @unknown default:
        return "Foundation Models を利用できません"
    }
}
```

**実装時の注意**: `SystemLanguageModel.Availability.UnavailableReason` のケース名は iOS 26 SDK の実際の API に合わせる必要あり。Xcode の補完で正式名を確認し、違っていても `@unknown default` でビルドは通る。

#### 1-D. `recognizeIngredients(from:)` にモック分岐（現 line 64-93）

```swift
func recognizeIngredients(from visionLabels: [String]) async throws -> IngredientRecognitionResult {
    isProcessing = true
    defer { isProcessing = false }

    // モックモードなら Vision ラベルを参照せずデモデータを返す
    if case .mock = mode {
        try await Task.sleep(nanoseconds: 600_000_000)  // 演出用の軽い遅延
        return MockRecipeAIData.ingredientRecognition()
    }

    guard let session else {
        mode = .mock(reason: "セッション喪失")
        return MockRecipeAIData.ingredientRecognition()
    }

    let labelList = visionLabels.joined(separator: ", ")
    let prompt = """..."""  // 既存プロンプトをそのまま流用

    do {
        let response = try await session.respond(
            to: prompt,
            generating: IngredientRecognitionResult.self
        )
        return response.content
    } catch {
        // 推論中の失敗も劣化フォールバック
        mode = .mock(reason: "推論失敗: \(error.localizedDescription)")
        return MockRecipeAIData.ingredientRecognition()
    }
}
```

#### 1-E. `recommendRecipes(for:preferences:)` にモック分岐（現 line 100-119）

同様に冒頭で `if case .mock = mode` チェック → `MockRecipeAIData.recommendations()` を返す。`session.respond` 失敗時も mode を mock に落としてモックを返す。

#### 1-F. `streamRecipeRecommendations(...)` のモック対応（現 line 126-156）

**方針**: ストリーミング版で `PartiallyGenerated` を手組みしない。mock モード時は即 `continuation.finish(throwing: RecipeAIError.sessionNotReady)` してエラーを返し、ViewModel 側で catch → 非ストリーミングの `recommendRecipes()` にフォールバックする（修正 3-D）。これでモック専用のストリーミング実装が不要になる。

```swift
func streamRecipeRecommendations(...) -> AsyncThrowingStream<...> {
    AsyncThrowingStream { continuation in
        Task { @MainActor in
            // mock モードなら ViewModel に非ストリーミング経路を使わせる
            if case .mock = self.mode {
                continuation.finish(throwing: RecipeAIError.sessionNotReady)
                return
            }

            guard let session = self.session else {
                continuation.finish(throwing: RecipeAIError.sessionNotReady)
                return
            }
            // ... 既存の streamResponse 呼び出し（catch 内で mode = .mock(...) に落とす追加）
        }
    }
}
```

---

### 2. 新規ファイル `MockRecipeAIData.swift`

**ファイルパス:** `Apps/AsaRecipeAI/AsaRecipeAI/Services/MockRecipeAIData.swift`

```swift
import Foundation

/// Foundation Models 非対応環境向けのモックデータ供給
enum MockRecipeAIData {
    static func ingredientRecognition() -> IngredientRecognitionResult {
        let ingredients: [IngredientInfo] = [
            .init(name: "にんじん",   category: "野菜", confidence: 0.95, emoji: "🥕"),
            .init(name: "玉ねぎ",     category: "野菜", confidence: 0.92, emoji: "🧅"),
            .init(name: "じゃがいも", category: "野菜", confidence: 0.88, emoji: "🥔"),
            .init(name: "牛肉",       category: "肉類", confidence: 0.85, emoji: "🥩"),
            .init(name: "卵",         category: "卵",   confidence: 0.90, emoji: "🥚"),
        ]
        return IngredientRecognitionResult(
            ingredients: ingredients,
            summary: "デモモード：野菜と肉類を認識しました"
        )
    }

    static func recommendations() -> RecipeRecommendations {
        RecipeRecommendations(recipes: [
            .init(
                name: "肉じゃが",
                description: "家庭の定番料理。ホクホクのじゃがいもと甘辛い味付け",
                difficulty: "普通",
                cookingTimeMinutes: 40,
                servings: 4,
                ingredients: [
                    .init(name: "じゃがいも", amount: "4個",   isAvailable: true),
                    .init(name: "にんじん",   amount: "1本",   isAvailable: true),
                    .init(name: "玉ねぎ",     amount: "1個",   isAvailable: true),
                    .init(name: "牛肉",       amount: "200g", isAvailable: true),
                    .init(name: "醤油",       amount: "大さじ3", isAvailable: false),
                ],
                steps: [
                    .init(stepNumber: 1, instruction: "じゃがいもを一口大に切る", tip: "水にさらすとホクホク"),
                    .init(stepNumber: 2, instruction: "牛肉を炒めて野菜を加える", tip: nil),
                    .init(stepNumber: 3, instruction: "だし汁と調味料で20分煮る", tip: "落し蓋で味が染みます"),
                ],
                recommendationReason: "認識した野菜で作れる定番家庭料理"
            ),
            .init(
                name: "親子丼",
                description: "ふわとろ卵と鶏肉のハーモニー。15分で完成",
                difficulty: "簡単",
                cookingTimeMinutes: 15,
                servings: 2,
                ingredients: [
                    .init(name: "鶏もも肉", amount: "200g", isAvailable: false),
                    .init(name: "卵",       amount: "3個",  isAvailable: true),
                    .init(name: "玉ねぎ",   amount: "1/2個", isAvailable: true),
                ],
                steps: [
                    .init(stepNumber: 1, instruction: "玉ねぎをスライスする", tip: nil),
                    .init(stepNumber: 2, instruction: "だし汁で鶏肉と玉ねぎを煮る", tip: nil),
                    .init(stepNumber: 3, instruction: "卵を回し入れて半熟で火を止める", tip: "余熱でふわとろに"),
                ],
                recommendationReason: "時短で作れるスタミナ丼"
            ),
            .init(
                name: "野菜炒め",
                description: "シャキシャキ食感の中華風炒めもの",
                difficulty: "簡単",
                cookingTimeMinutes: 10,
                servings: 2,
                ingredients: [
                    .init(name: "にんじん", amount: "1/2本", isAvailable: true),
                    .init(name: "玉ねぎ",   amount: "1/2個", isAvailable: true),
                    .init(name: "キャベツ", amount: "1/4個", isAvailable: false),
                ],
                steps: [
                    .init(stepNumber: 1, instruction: "野菜を食べやすい大きさに切る", tip: nil),
                    .init(stepNumber: 2, instruction: "強火で一気に炒める", tip: "シャキシャキ感が大事"),
                    .init(stepNumber: 3, instruction: "醤油とごま油で味付け", tip: nil),
                ],
                recommendationReason: "認識した野菜ですぐ作れる一品"
            ),
        ])
    }
}
```

**実装時リスクと対策**:
- `@Generable` struct のメンバーワイズ init が合成されない場合（マクロが init を隠蔽する可能性）、コンパイルエラーになる
- 対策: `IngredientInfo.swift` / `RecipeRecommendation.swift` の各 struct に明示 init を追加する安全弁
  ```swift
  // 例: IngredientInfo.swift 末尾に
  extension IngredientInfo {
      init(name: String, category: String, confidence: Double, emoji: String) {
          self.name = name
          self.category = category
          self.confidence = confidence
          self.emoji = emoji
      }
  }
  ```
- Swift の `let` プロパティのみの struct は通常自動合成 init を持つため、まずは無修正でビルド → エラー時のみ extension 追加。

---

### 3. `RecipeAIViewModel.swift`

**ファイルパス:** `Apps/AsaRecipeAI/AsaRecipeAI/ViewModels/RecipeAIViewModel.swift`

#### 3-A. デモモード判定プロパティを追加（`isAIReady` の近く、line 40-42 周辺）

```swift
var isAIReady: Bool {
    recipeAIService.isSessionReady
}

/// デモモード（Foundation Models 非対応環境）かどうか
var isDemoMode: Bool {
    if case .mock = recipeAIService.mode { return true }
    return false
}

/// AI ステータスの表示文字列
var aiStatusText: String {
    recipeAIService.mode.userFacingLabel
}
```

#### 3-B. `analyzeImage(_:)` のエラー経路強化（line 128-163）

デモモードでは Vision が空ラベルを返しても強制的にモック食材を返すよう分岐:

```swift
func analyzeImage(_ image: UIImage) async {
    isAnalyzing = true
    appState = .analyzing
    errorMessage = nil
    clearResults()

    do {
        // Vision は失敗しても続行
        let labels: [String]
        do {
            labels = try await visionService.extractFoodLabels(image)
        } catch {
            labels = []
        }
        visionLabels = labels

        // デモモードでない & ラベルが空ならエラー
        if labels.isEmpty && !isDemoMode {
            throw RecipeAIError.generationFailed("食品が認識できませんでした")
        }

        // recognizeIngredients は mock モードなら labels を無視してモック返す
        let result = try await recipeAIService.recognizeIngredients(from: labels)
        recognizedIngredients = result.ingredients

        // 履歴保存（既存ロジックそのまま）
        let preferences = dataService.fetchUserPreferences()
        if preferences.autoSaveHistory {
            let thumbnail = visionService.generateThumbnail(image)
            _ = dataService.saveHistoryFromResult(result, thumbnailData: thumbnail)
            await refreshHistory()
        }

        appState = .ingredientsRecognized
    } catch {
        errorMessage = error.localizedDescription
        appState = .error(error.localizedDescription)
    }

    isAnalyzing = false
}
```

#### 3-C. `generateRecipes()` のストリーミング失敗時フォールバック（line 168-225）

ストリーミング版が mock モードで `.sessionNotReady` を投げる仕様にしたので、ViewModel 側で catch して同期版にフォールバック:

```swift
func generateRecipes() async {
    guard !recognizedIngredients.isEmpty else {
        errorMessage = "食材が認識されていません"
        return
    }

    // デモモードなら最初から同期版を使う
    if isDemoMode {
        await generateRecipesSync()
        return
    }

    isGeneratingRecipes = true
    appState = .generatingRecipes
    // ... 既存のストリーミングロジック

    // catch 内でフォールバック追加
    // } catch {
    //     if isDemoMode { await generateRecipesSync(); return }
    //     errorMessage = error.localizedDescription
    //     ...
    // }
}
```

既存の `generateRecipesSync()` メソッドがあることを前提としている（ファイル全体を実装時に確認し、無ければ非ストリーミング `recommendRecipes` を呼ぶ新規 async メソッドとして追加）。

---

### 4. `HomeView.swift`

**ファイルパス:** `Apps/AsaRecipeAI/AsaRecipeAI/Views/Home/HomeView.swift`

#### 4-A. `aiStatusSection` をデモモード対応に差し替え（現 line 101-121）

```swift
private var aiStatusSection: some View {
    HStack(spacing: 8) {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)

        Text(viewModel.aiStatusText)
            .font(.caption)
            .foregroundStyle(Color("AsaDarkSlate"))

        if viewModel.isDemoMode {
            Text("・サンプルで動作中")
                .font(.caption2)
                .foregroundStyle(Color("AsaMocha"))
        }

        Spacer()

        Text(viewModel.appState.description)
            .font(.caption)
            .foregroundStyle(Color("AsaMocha"))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color.white.opacity(0.6))
    .clipShape(RoundedRectangle(cornerRadius: 8))
}

private var statusColor: Color {
    if viewModel.isDemoMode { return .orange }
    return viewModel.isAIReady ? .green : .gray
}
```

**分析ボタン（line 198）・レシピボタン（line 264）の `isEnabled` は無変更** — `viewModel.isAIReady` が mock モードでも true を返すよう 1-B で改修済み。

#### 4-B. `loadImage(from:)` の空画像 catch を修正（現 line 311-322）

```swift
private func loadImage(from item: PhotosPickerItem?) async {
    guard let item else { return }

    do {
        if let data = try await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            viewModel.selectImage(uiImage)
        }
    } catch {
        viewModel.errorMessage = "画像の読み込みに失敗しました"
    }
}
```

`viewModel.selectImage(UIImage())` を投げるのは空画像で Vision がクラッシュする元凶だったので削除。`errorMessage` は既に `@Observable` で UI に反映される既存プロパティ。

---

## 再利用する既存コード・ユーティリティ

| 参照先 | 用途 |
|---|---|
| `SampleDataGenerator.swift:39-80+` の肉じゃが・親子丼レシピ | `MockRecipeAIData` のレシピ内容の元ネタ（型は別物なので値のみコピー） |
| `IngredientRecognitionResult` / `IngredientInfo`（`Models/Generable/IngredientInfo.swift`） | モックデータ返却時の型 |
| `RecipeRecommendations` / `RecipeRecommendation` / `RecipeIngredient` / `CookingStep`（`Models/Generable/RecipeRecommendation.swift`） | 同上 |
| `viewModel.errorMessage`（既存 `@Observable` プロパティ） | HomeView catch の画像ロード失敗通知 |
| `RecipeAIError.sessionNotReady`（`RecipeAIService.swift:208`） | ストリーミング mock 失敗の信号（ViewModel がこれを見て sync フォールバック） |

---

## 検証方法（Verification）

### シミュレータ検証（最優先：SNS デモ動画撮影ルート）
1. `cd Apps/AsaRecipeAI && xcodegen generate` で project 再生成
2. `xcodebuild -project AsaRecipeAI.xcodeproj -scheme AsaRecipeAI -sdk iphonesimulator build` が成功すること
3. iPhone 17 Pro シミュレータで起動 → ホーム画面右上に **オレンジドット＋「デモモード ・サンプルで動作中」** が表示される
4. フォトライブラリから任意の画像（食材写真でなくて可）を選択
5. 「食材を認識」タップ → **クラッシュせず** 約0.6秒後に にんじん／玉ねぎ／じゃがいも／牛肉／卵 が表示される
6. 「🍳 レシピを提案」タップ → 肉じゃが／親子丼／野菜炒めが表示される
7. お気に入り追加・履歴保存が動作することを確認
8. 動画撮影可能な状態であることを確認

### 実機検証（Apple Intelligence 対応端末がある場合）
1. 設定 > Apple Intelligence が **有効** → 「AI準備完了」緑ドット → 実際の食材写真で本物の Foundation Models 推論が動く
2. 設定 > Apple Intelligence を **無効** → アプリ再起動 → 「デモモード・設定で Apple Intelligence を有効にしてください」表示でクラッシュなし、モック経路で完走

### 実機検証（非対応端末）
- iPhone 15 等 → 即デモモード、クラッシュなし

### 回帰確認
- 既存の `SampleDataGenerator.insertSampleData()` による初回 DB 投入（`loadInitialData`）は変更していないので、お気に入りタブ・履歴タブに従来どおりサンプルが表示されることを確認
- 既存の全テスト (`xcodebuild test -project AsaRecipeAI.xcodeproj -scheme AsaRecipeAI -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`) が通ること

---

## 想定リスクと対策

| リスク | 対策 |
|---|---|
| `@Generable` 合成 init が使えない | `IngredientInfo.swift` / `RecipeRecommendation.swift` 等の末尾に extension で明示 init を追加 |
| `SystemLanguageModel.Availability.UnavailableReason` のケース名が SDK と違う | `@unknown default` でビルド安全、実装時に Xcode 補完で確認 |
| `CSU exception` が `prewarm()` より前に発生する（`LanguageModelSession()` 初期化時） | シミュレータは `#if` で init 自体呼ばれない。実機で起きる場合はさらに `LanguageModelSession()` 自体を try 化する必要があるが、現状の API ではそのパターンは稀 |
| ViewModel に `generateRecipesSync()` が存在しない | 実装時にファイル全体を確認し、無ければ `recommendRecipes()` を呼ぶ新規 async メソッドとして同ファイルに追加 |
| デモモード明示が SNS 動画で目立ちすぎる | バッジ文言は「サンプルで動作中」に抑えた控えめな表現。代替案としてステータス行ごと非表示にする選択肢もあり（実装後の見た目で判断可能） |
| カメラボタン（現在 disabled）の扱い | 今回のスコープ外。触らない |

---

## Critical Files for Implementation

主に触るファイル:
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/RecipeAIService.swift`
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/MockRecipeAIData.swift` （新規）
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/ViewModels/RecipeAIViewModel.swift`
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Views/Home/HomeView.swift`

安全弁として init 追加が必要かもしれないファイル:
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Models/Generable/IngredientInfo.swift`
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Models/Generable/RecipeRecommendation.swift`

参考のみ（変更なし）:
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/SampleDataGenerator.swift`
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/project.yml`

---

# 追加修正 (2nd iteration): VisionService の Simulator 分岐

## Context（なぜこの追加修正が必要か）

前回 iteration で Foundation Models（`RecipeAIService`）側のクラッシュを修正した後、
シミュレータで写真選択 → 「食材を認識」をタップしたら**再びクラッシュ**した。

### クラッシュ時の状況証拠（Xcode デバッガのスクリーンショットから）

- **スレッド**: Thread 18 `com.apple.root.user-initiated-qos.cooperative`
- **停止理由**: `EXC_BREAKPOINT` at `brk #0x1`（dispatch assert fail）
- **コールスタック**:
  ```
  0 _dispatch_assert_queue_fail
  1 _dispatch_client_callout
  2 _dispatch_continuation_pop
  3 dispatch_group_async
  5 performRequests:onBehalfOfReq...
  6 -[VNImageRequestHandler ...]          ← Vision フレームワーク
  7 closure #1 in VisionService.ca...      ← 弊社コード!
  8 merged closure #1 in (Built in R...)
  ```
- **コンソール出力**: `CSU exception: Failed to create espresso context.`

### 根本原因（前回の盲点）

前回 iteration では **Foundation Models 側 (`RecipeAIService`) にだけ**
`#if targetEnvironment(simulator)` を入れたが、**`VisionService` は無防備のままだった**。

`VNClassifyImageRequest` も内部で CoreML モデル（Apple が提供する事前訓練済み画像分類モデル）を
使用しており、そのモデルの **Espresso 推論エンジンがシミュレータで初期化できない**。結果として
`VisionService.swift:59` の `try handler.perform([request])` を呼んだ瞬間に
`CSU exception: Failed to create espresso context` が発生し、dispatch queue の assert が発火
してプロセス終了していた。

### なぜ前回の ViewModel 側 do-catch では拾えなかったのか

`RecipeAIViewModel.analyzeImage` では前回 iteration で
```swift
do {
    labels = try await visionService.extractFoodLabels(image)
} catch {
    if isDemoMode { labels = [] } else { throw error }
}
```
という catch を入れたが、**CSU exception は Swift の `throw` 経由の Error ではなく
Espresso 内部の C++ assertion failure** なので `catch` には届かない。
dispatch queue の assert が発火 → プロセス終了、という流れで Swift レベルでは制御不能。

→ 前回の `RecipeAIService` と同じ教訓：**低レベル例外は "起こさない" 以外に対策がない**。

---

## 修正方針サマリ

**`VisionService.classifyImage` の冒頭に `#if targetEnvironment(simulator)` を追加し、
シミュレータでは即座に空配列を返す**。これだけ。

### 波及効果（既存の防御構造がそのまま活きる）

1. シミュレータで `VisionService.classifyImage` → 空配列 `[]` を返す
2. `VisionService.extractFoodLabels` → 空配列を返す（`classifyImage` 経由）
3. `RecipeAIViewModel.analyzeImage` → `labels.isEmpty && !isDemoMode` チェックで `isDemoMode == true` なので throw せず続行
4. `RecipeAIService.recognizeIngredients(from: [])` → mock モードなので `MockRecipeAIData.ingredientRecognition()` を返す
5. UI に にんじん／玉ねぎ／じゃがいも／牛肉／卵 が表示される 🎉

→ **前回 iteration の修正がそのまま全部活きる**。ViewModel・RecipeAIService・HomeView は無変更。

---

## 詳細プラン

### 修正対象ファイル（1ファイルのみ）

`/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/VisionService.swift`

### 修正内容：`classifyImage(_:)` の冒頭に Simulator 分岐を追加（現 line 31-64）

**Before**:
```swift
func classifyImage(_ image: UIImage) async throws -> [(identifier: String, confidence: Float)] {
    guard let cgImage = image.cgImage else {
        throw VisionError.imageConversionFailed
    }

    return try await withCheckedThrowingContinuation { continuation in
        let request = VNClassifyImageRequest { request, error in
            // ... 既存の処理
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            continuation.resume(throwing: VisionError.requestFailed(error))
        }
    }
}
```

**After**:
```swift
func classifyImage(_ image: UIImage) async throws -> [(identifier: String, confidence: Float)] {
    // シミュレータでは Vision の画像分類モデル（CoreML/Espresso）が初期化できず
    // CSU exception でプロセスクラッシュするため、物理的に呼び出しを回避する
    #if targetEnvironment(simulator)
    return []
    #else
    guard let cgImage = image.cgImage else {
        throw VisionError.imageConversionFailed
    }

    return try await withCheckedThrowingContinuation { continuation in
        let request = VNClassifyImageRequest { request, error in
            if let error {
                continuation.resume(throwing: VisionError.classificationFailed(error))
                return
            }

            guard let results = request.results as? [VNClassificationObservation] else {
                continuation.resume(throwing: VisionError.noResults)
                return
            }

            let filteredResults = results
                .filter { $0.confidence >= self.minimumConfidence }
                .prefix(self.maxResults)
                .map { (identifier: $0.identifier, confidence: $0.confidence) }

            continuation.resume(returning: Array(filteredResults))
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            continuation.resume(throwing: VisionError.requestFailed(error))
        }
    }
    #endif
}
```

**実装時の注意**:
- `cgImage` の宣言を `#else` 側に閉じ込めているので、シミュレータビルドで unused variable 警告は出ない
- 実機では既存ロジックが完全にそのまま動く（CoreML が正常にロードできるため）
- `extractFoodLabels(_:)` や `generateThumbnail(_:)` は無変更
  - `extractFoodLabels` は `classifyImage` を呼ぶだけなので自動的に空配列を返す
  - `generateThumbnail` は `UIGraphicsImageRenderer` を使っており Espresso を呼ばないので安全

### 触らないファイル（前回 iteration の修正がそのまま活きる）

- `RecipeAIService.swift` — mock モード分岐は既に正しい
- `MockRecipeAIData.swift` — 既存のモックデータで十分
- `RecipeAIViewModel.swift` — `isDemoMode` での空ラベルフォールバックが既に実装済み
- `HomeView.swift` — デモモード UI は既に対応済み

---

## 検証方法（Verification）

### シミュレータ検証（最優先：今回のクラッシュ再現→解消確認）
1. `cd Apps/AsaRecipeAI && xcodegen generate`
2. `xcodebuild -project AsaRecipeAI.xcodeproj -scheme AsaRecipeAI -sdk iphonesimulator build`
   → BUILD SUCCEEDED
3. iPhone 17 Pro シミュレータで起動 → オレンジドット＋「デモモード ・サンプルで動作中」表示
4. フォトライブラリから任意の画像を選択
5. 「食材を認識」タップ → **今度こそクラッシュせず** 約0.6秒後に にんじん／玉ねぎ／じゃがいも／牛肉／卵 が表示される
6. 「🍳 レシピを提案」タップ → 肉じゃが／親子丼／野菜炒めが表示される
7. Xcode のコンソールを確認し、`CSU exception` や `_dispatch_assert_queue_fail` が発生していないこと

### 実機検証（Apple Intelligence 対応端末がある場合）
- 実機では `#else` ブランチに入り、従来通り `VNClassifyImageRequest` が動作
- Vision による本物の画像分類 → Foundation Models による食材認識 → レシピ生成が完走すること

### 回帰確認
- ViewModel の `analyzeImage` 既存ロジック（`isDemoMode` 分岐）が正しく機能していることを確認
- `recognizeIngredients(from: [])` を mock モードで呼んでモックデータが返ること

---

## 想定リスクと対策 (2nd iteration)

| リスク | 対策 |
|---|---|
| 実機でも CoreML の初期化失敗が起きる | 現時点では確認されていない。発生したら `classifyImage` 内の既存 `VisionError.requestFailed(error)` 経路で通常エラーになり、ViewModel の catch に到達する（CSU ではなく通常エラーとして扱える） |
| `#if targetEnvironment(simulator)` 側で unused warning | `cgImage` 宣言を `#else` 側に閉じ込めているため発生しない |
| 実機テストができない状況でも動作保証したい | シミュレータ分岐＋既存の mock パスで完結するため、実機アクセス不要で SNS デモ動画撮影が可能 |
| Vision 以外の CoreML 系 API が他にもある可能性 | プロジェクト全体を grep して確認すべき。`CoreML`, `VNRequest`, `MLModel` 等をキーワードに。今回は VisionService のみが該当する |

---

## Critical Files for Implementation (2nd iteration)

変更するファイル:
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/VisionService.swift`

前回 iteration で変更済みで今回は触らないファイル（既存防御構造を活用）:
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/RecipeAIService.swift`
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/MockRecipeAIData.swift`
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/ViewModels/RecipeAIViewModel.swift`
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Views/Home/HomeView.swift`

---

# 3rd iteration: シミュレータ環境修復で本物の AI 推論を試す

## Context（この iteration を追加する理由）

ユーザーの希望は **SNS デモ動画をシミュレータで撮影しつつ、モックではなく本物の AI 推論結果を見せたい** というもの。
2nd iteration のモックだけで動画を撮ることは可能だが、「本物の Vision 分類」「本物の Foundation Models レシピ生成」を
映せた方が動画のインパクトが桁違いに高い。

### Mac 環境診断結果（実施済み・read-only コマンドで確認）

| 項目 | 値 | 判定 |
|---|---|---|
| macOS | 26.3.1 (Tahoe) build 25D771280a | ✅ Apple Intelligence 完全対応 |
| Chip | Apple M1 (arm64) | ✅ Apple Silicon |
| Memory | 16GB | ✅ 十分（最低 8GB） |
| Xcode | 26.4 build 17E192 | ✅ iOS 26 SDK 同梱 |
| Apple Intelligence | `opted_in_buddy = 1`, `auto_opt_in = 1` | ✅ オプトイン済み |

この環境は **iOS 26 シミュレータから host macOS の Apple Intelligence を透過的に利用する要件を全て満たしている**。
前回の `CSU exception: Failed to create espresso context` は Apple Intelligence 設定の問題ではなく、
**Xcode/シミュレータのキャッシュ破損またはモデルアセットのロード順序問題**である可能性が高い。

## 修復手順（段階的に破壊範囲を広げる）

### Step A: 軽量修復（破壊範囲最小、成功率中）
1. Xcode を閉じる（`killall Xcode`）
2. `xcrun simctl shutdown all` — 全シミュレータのシャットダウン
3. `rm -rf ~/Library/Developer/Xcode/DerivedData/AsaRecipeAI-*` — AsaRecipeAI のビルドキャッシュのみ削除
4. Xcode 再起動
5. `cd Apps/AsaRecipeAI && xcodegen generate`
6. Xcode から iPhone 17 Pro シミュレータで Run（クリーンビルド）
7. アプリ起動 → 写真選択 → 食材認識 → コンソールで CSU exception が出ないか確認

### Step B: 中程度修復（特定シミュレータのみリセット）
Step A で直らなかった場合のみ実施:
1. `xcrun simctl list devices | grep "iPhone 17 Pro"` で対象デバイス UDID を取得
2. `xcrun simctl erase <UDID>` — 特定デバイスのみデータ全消去
3. Step A の 4-7 を再実行

### Step C: 最終手段（破壊範囲最大、ユーザー承認必須）
Step A/B どちらも効果なしの場合のみ実施:
1. `xcrun simctl shutdown all && xcrun simctl erase all` — **全シミュレータのデータが消える**
2. `rm -rf ~/Library/Developer/CoreSimulator/Caches/*` — CoreSimulator キャッシュクリア
3. Step A の 4-7 を再実行

**⚠️ Step C は他アプリのシミュレータデータ（ログイン情報・保存データ・通知履歴等）も全消去するため、実行前にユーザーへ明示的に確認する**

## 診断用コードの一時追加

修復が効いたか判別するため、`RecipeAIService.prepareSession()` の冒頭に診断ログを追加（動作確認後に削除）:

```swift
func prepareSession() async {
    // [DIAGNOSTIC] 環境修復の検証用ログ（検証後削除）
    let availability = SystemLanguageModel.default.availability
    print("[RecipeAI Diagnostic] availability = \(String(describing: availability))")

    #if targetEnvironment(simulator)
    // ...（現状のコード）
```

`VisionService.classifyImage` にも同様のログを追加:

```swift
func classifyImage(_ image: UIImage) async throws -> [(identifier: String, confidence: Float)] {
    print("[Vision Diagnostic] classifyImage called on simulator: \(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "n/a")")
    // ...（現状のコード）
```

## 結果別の実装方針

### シナリオA: Vision & Foundation Models 両方動く 🎉（理想）

**変更内容:**
1. **`RecipeAIService.swift`** の `#if targetEnvironment(simulator)` 分岐を **削除**
   - 代わりに `SystemLanguageModel.default.availability` のチェックに一本化
   - `.available` なら live、`.unavailable` なら mock
2. **`VisionService.swift`** は無変更（元々 `#if` を追加していないので）
3. **`MockRecipeAIData`** は availability 失敗時の保険として残す（非対応実機で有効）
4. **診断ログを削除**
5. デモ動画: 本物の冷蔵庫写真 → 本物の Vision 分類 → 本物の Foundation Models レシピ生成

### シナリオB: Vision 動く / Foundation Models 動かない

**変更内容:**
1. **`RecipeAIService.swift`** の `#if` を削除 + availability チェックを強化
   - availability が `.unavailable` でも mock モードに劣化するだけなので自然に動作
2. **`VisionService.swift`** 無変更
3. Vision 本物 + Foundation Models モック のハイブリッド動画を撮影
4. 動画の尺としては「食材認識（本物）」「レシピ生成（モック）」でも十分魅力的

### シナリオC: Vision も Foundation Models も動かない（CSU exception 再発）

**対応:**
1. → 2nd iteration plan の内容を実装（`VisionService.swift` に `#if targetEnvironment(simulator)` を追加）
2. デモ動画は完全モック経路で撮影
3. ユーザーに「Claude API 切り替え or 実機撮影」の再選択を提案
4. 診断ログから得られた具体的なエラーメッセージを元に、さらなる対策を検討

## 検証方法

### 診断プロセス
1. Step A の 1-6 を実行（軽量修復）
2. シミュレータ起動時に Xcode コンソールで `[RecipeAI Diagnostic] availability = ...` を確認
   - `.available` → シナリオ A or B
   - `.unavailable(...)` → シナリオ B or C
3. 写真選択 → 「食材を認識」タップ
4. Xcode コンソールで `[Vision Diagnostic] classifyImage called` の後にクラッシュするか確認
   - クラッシュしない & 食材が表示される → Vision 本物動作中 = シナリオ A or B
   - CSU exception で落ちる → シナリオ C、Step B へ進む
5. 食材認識成功後、「🍳 レシピを提案」タップ
   - 本物のレシピが数秒かけて生成される → シナリオ A 確定
   - モックレシピが即返る（availability 失敗時のフォールバック経路）→ シナリオ B

### 成功条件
- シミュレータで写真選択 → クラッシュせず進む（必須）
- 食材認識結果が写真の内容を反映している（シナリオ A/B なら Vision が本物）
- レシピ生成に 2〜10 秒程度の推論時間がかかる（シナリオ A なら Foundation Models が本物）

## Critical Files for Implementation (3rd iteration)

診断ログ一時追加→結果判定→本実装、の順で段階的に変更:

**Step 1: 診断ログ追加（一時）**
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/RecipeAIService.swift`
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/VisionService.swift`

**Step 2: シナリオ A の場合の本実装**
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/RecipeAIService.swift` （`#if` 分岐を削除）
- 両ファイルから診断ログを削除

**Step 3: シナリオ B の場合の本実装**
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/RecipeAIService.swift` （`#if` 緩和 + availability チェック強化）
- 両ファイルから診断ログを削除

**Step 4: シナリオ C の場合（フォールバック）**
- `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipeAI/AsaRecipeAI/Services/VisionService.swift` （2nd iteration plan の `#if` 追加）
- 両ファイルから診断ログを削除
- ユーザーに Claude API or 実機撮影の選択肢を再提示

## 想定リスクと対策 (3rd iteration)

| リスク | 対策 |
|---|---|
| Step C の `xcrun simctl erase all` で他アプリのデータが消える | 実行前にユーザーへ明示確認。Step A/B で解決する可能性が高いので Step C は最終手段 |
| Apple Intelligence モデルアセットのダウンロードに時間がかかる | 初回は Mac 側で `システム設定 > Apple Intelligence & Siri` を開いてダウンロードを完了させておく必要あり |
| 診断ログ削除し忘れ | iteration 完了時に `grep -r "Diagnostic" Apps/AsaRecipeAI/AsaRecipeAI/` で確認 |
| シミュレータで動いても実機と挙動が違う | availability チェックに一本化することで実機/シミュレータ差異を吸収。モック経路は保険として維持 |
| 環境修復が一時的な効果で後日再発 | 再発したら再度 Step A を実施。根本対策として CI でシミュレータキャッシュを定期クリアする仕組みも検討可能 |
