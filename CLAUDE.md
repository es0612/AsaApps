# CLAUDE.md

このファイルは、このリポジトリでコードを操作する際のClaude Code (claude.ai/code) へのガイダンスを提供します。

## 重要: 日本語での対応

**このプロジェクトでのClaude Codeとのやり取りは全て日本語で行ってください。**
- 質問、回答、説明は全て日本語で対応する
- コメントやドキュメントも日本語で作成する
- エラーメッセージや説明も可能な限り日本語で提供する

## プロジェクト概要

AsaAppsは「朝活パパエンジニア」によるSwiftUI学習プロジェクトで、1年間で100のSwiftUIアプリを作成することを目標としています。家族、生産性、朝活をテーマに、シンプルで温かみのあるデザイン原則に焦点を当てています。

## プロジェクト構造

```
AsaApps/
├── Apps/                    # 個別のSwiftUIアプリ（40個以上完成）
│   ├── AsaCounter/         # 基本的なカウンターアプリ
│   ├── AsaNumberGame/      # 数当てゲーム
│   ├── AsaTicTacToe/       # 三目並べゲーム
│   ├── AsaTaskBoard/       # Kanbanスタイルタスクボード
│   ├── AsaFlashcardPro/    # 間隔反復学習フラッシュカード
│   └── ...                 # その他35個以上のアプリ
├── Packages/               # Swift Packages（共有ライブラリ）
│   ├── AsaUIKit/          # 共有UIコンポーネントライブラリ
│   │   ├── AsaColors      # ブランドカラー定義
│   │   ├── AsaButton      # 統一ボタンコンポーネント
│   │   ├── AsaCard        # カードコンポーネント
│   │   └── Extensions     # View拡張機能
│   └── AsaTaskKit/        # タスク管理専用ライブラリ
│       ├── Models/        # Task、TaskBoard等のモデル
│       ├── ViewModels/    # TaskBoardViewModel等
│       ├── Services/      # TaskDataService
│       └── Tests/         # 単体テスト
├── Shared/                # 下位互換性のため保持
│   ├── AsaButton.swift    # ※Packages/AsaUIKitに移行済み
│   ├── AsaCard.swift      # ※Packages/AsaUIKitに移行済み
│   ├── AsaLaunchScreen.swift
│   └── Assets.xcassets/   # 共有デザインアセット
├── Docs/                  # ドキュメントと学習ノート
│   ├── BrandGuidelines.md # ブランドカラーとUIガイドライン
│   ├── Notes/             # 日次実装ノート（100日分）
│   └── Screenshot/        # アプリデモ動画とスクリーンショット
├── Designs/               # デザインアセット（ロゴ、アイコン）
└── README.md             # 100アプリのアイデアを含むプロジェクトロードマップ
```

## 開発コマンド

### XcodeGenによるプロジェクト管理

**すべてのXcodeプロジェクトはXcodeGenで管理され、.xcodeproj ファイルはGitトラッキング対象外です。**

#### 基本的なXcodeGenワークフロー

```bash
# プロジェクト構成ファイルを生成/更新
xcodegen generate

# 特定のアプリディレクトリでの生成
cd Apps/AsaNumberGame
xcodegen generate -s project.yml

# 生成されたプロジェクトを開く
open AsaNumberGame.xcodeproj
```

#### プロジェクト設定ファイル（project.yml）の標準構造

```yaml
name: AsaNewApp
options:
  bundleIdPrefix: com.asaapps
  deploymentTarget:
    iOS: "18.0"

targets:
  AsaNewApp:
    type: application
    platform: iOS
    sources:
      - Sources
    dependencies:
      - package: AsaUIKit
        product: AsaUIKit
      - package: AsaTaskKit
        product: AsaTaskKit
    settings:
      SWIFT_VERSION: "5.9"
      GENERATE_INFOPLIST_FILE: true
      INFOPLIST_KEY_UILaunchScreen_Generation: true

packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit
  AsaTaskKit:
    path: ../../Packages/AsaTaskKit
```

#### ビルド・実行コマンド

```bash
# コマンドラインからビルド（シミュレータ向け）
xcodebuild -project AsaNumberGame.xcodeproj -scheme AsaNumberGame -sdk iphonesimulator build

# テスト実行（Swiftパッケージ）
swift test

# シミュレータ指定でビルド・実行
xcodebuild -project AsaNumberGame.xcodeproj -scheme AsaNumberGame \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

## Swift ビルドエラー防止ルール

過去の実装で頻発した12種類のビルドエラーパターンと防止策。**実装時に必ず参照すること。**

### 標準ビルド・テストコマンド

```bash
# 標準シミュレータ: iPhone 17 Pro
# SDKフラグ: -sdk iphonesimulator（必須）

# ビルド
xcodebuild -project [AppName].xcodeproj -scheme [AppName] -sdk iphonesimulator build

# テスト
xcodebuild test -project [AppName].xcodeproj -scheme [AppName] \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# デバイス確認
xcrun simctl list devices available
```

### エラーパターン一覧

#### 1. @Model と Sendable の競合
`@Model` クラスに `Sendable` を付けると SwiftData マクロと衝突する。
```swift
// ❌ NG
@Model final class Item: Sendable { }

// ✅ OK
@Model final class Item { }
```

#### 2. @MainActor + Timer の deinit
`@MainActor` クラスで Timer を `deinit` で invalidate するとコンパイルエラー。
```swift
// ❌ NG
@MainActor @Observable final class VM {
    var timer: Timer?
    deinit { timer?.invalidate() }
}

// ✅ OK
@MainActor @Observable final class VM {
    nonisolated(unsafe) var timer: Timer?
    deinit { timer?.invalidate() }
}
```

#### 3. Info.plist / UILaunchScreen 未設定
project.yml に UILaunchScreen が未設定だとシミュレータで黒帯が表示される。
```yaml
# ✅ project.yml に必ず含める
settings:
  GENERATE_INFOPLIST_FILE: true
  INFOPLIST_KEY_UILaunchScreen_Generation: true
```

#### 4. 型の不一致（Int → TimeInterval、Anchor → GeometryProxy）
```swift
// ❌ NG
let interval: TimeInterval = someIntValue

// ✅ OK
let interval: TimeInterval = TimeInterval(someIntValue)

// ❌ NG: Anchor<CGRect> を直接使う
func layout(bounds: Anchor<CGRect>) { }

// ✅ OK: GeometryProxy 経由で解決
GeometryReader { proxy in ... }
```

#### 5. @Observable と private(set)
パッケージ外から `@Bindable` でバインディングする場合、`private(set)` だと書き込み不可。
```swift
// ❌ NG: パッケージ外からバインディングできない
@Observable public final class VM {
    public private(set) var name: String = ""
}

// ✅ OK: public メソッドで変更を公開
@Observable public final class VM {
    public var name: String = ""
}
```

#### 6. Codable の id プロパティ
`let id = UUID()` だとデコード時に新しいIDが生成されてしまう。
```swift
// ❌ NG
struct Item: Codable, Identifiable {
    let id = UUID()
}

// ✅ OK
struct Item: Codable, Identifiable {
    var id: UUID = UUID()
}
```

#### 7. SwiftData ModelContext の actor isolation
`ModelContext` は `@MainActor` でアクセスする必要がある。
```swift
// ❌ NG: バックグラウンドからの直接アクセス
func save() { modelContext.save() }

// ✅ OK
@MainActor func save() throws { try modelContext.save() }
```

#### 8. Firebase 互換性
`FirebaseFirestoreSwift` は非推奨。`FirebaseFirestore` に統一。
```swift
// ❌ NG
import FirebaseFirestoreSwift

// ✅ OK
import FirebaseFirestore
```

#### 9. システム型との命名衝突
`Color`、`Scene`、`ProgressView` 等のシステム型名をモデル名に使わない。
```swift
// ❌ NG
struct Scene: Identifiable { }  // SwiftUI.Scene と衝突

// ✅ OK: Asa プレフィックスを使用
struct AsaScene: Identifiable { }
```

#### 10. デプロイメントターゲットと API の整合性
最新APIの積極的な使用を推奨。使用するAPIに合わせて `project.yml` のデプロイメントターゲットを更新する。
```yaml
# iOS 18+ API を使う場合
deploymentTarget:
  iOS: "18.0"

# iOS 17 API のみの場合
deploymentTarget:
  iOS: "17.0"
```

#### 11. import 漏れ
SwiftData、Foundation の import を忘れずに含める。
```swift
// ❌ NG: import 漏れでビルドエラー
@Model final class Item { }  // SwiftData が未 import

// ✅ OK
import SwiftData
import Foundation

@Model final class Item { }
```

### コミット前ビルドチェックリスト

1. `xcodegen generate` 成功
2. `xcodebuild -sdk iphonesimulator build` エラー0件
3. `@Model` に `Sendable` がないか確認
4. UILaunchScreen 設定済み（project.yml）
5. import 漏れなし（SwiftData, Foundation）
6. 使用APIのiOSバージョン要件と project.yml ターゲットが一致
7. システム型との命名衝突なし

## アーキテクチャパターン

### アプリ構造
- 各アプリは標準的なSwiftUIアプリ構造に従っています：
  - `ContentView.swift` - メインUI
  - `ViewModel.swift` - ビジネスロジック（MVVMパターン）
  - `Model.swift` - データモデル
  - 複雑なUIコンポーネント用のカスタムビュー

### ローカルパッケージ化戦略

#### UI・ロジック分離原則
**すべてのアプリUIとビジネスロジックはローカルパッケージに集約し、テスト可能な形で実装します。**

これにより、Swift Testingによるテスト容易性を向上させ、SPMを使ったパッケージの再利用性も向上させます。

#### パッケージ構造
- **AsaUIKit** - 共有UIコンポーネント（テスト可能）
  - AsaButton, AsaCard, AsaColors等の統一UIライブラリ
  - SwiftUI プレビューとUnit Tests完備
- **AsaTaskKit** - ドメインロジック（テスト可能）
  - Models, ViewModels, Services の分離実装
  - Business Logic の Swift Test完備
- **App本体** - UIとロジックの組み立て
  - パッケージの組み合わせのみ、独自ロジック最小化

#### パッケージ化の利点
```swift
// ✅ 良い例: テスト可能なパッケージ化
// AsaUIKit/Tests/AsaButtonTests.swift
@Test("AsaButton アクション実行テスト")
func testButtonAction() {
    var actionCalled = false
    let button = AsaButton(title: "Test") {
        actionCalled = true
    }
    // テスト実行
    #expect(actionCalled == true)
}

// ✅ 良い例: ビジネスロジックのテスト
// AsaTaskKit/Tests/TaskViewModelTests.swift
@Test("タスク追加ロジックテスト")
func testAddTask() {
    let viewModel = TaskViewModel()
    viewModel.addTask("新しいタスク")
    #expect(viewModel.tasks.count == 1)
}
```

#### 共有UIコンポーネント（AsaUIKit）
- **AsaButton**: ブランドカラーを使用した一貫したボタンスタイリング
- **AsaCard**: コンテンツセクション用のカードラッパー
- **AsaColors**: ブランドカラーパレット定義
- **AsaLaunchScreen**: アプリ間で共通のランチスクリーン

### データ管理
- シンプルなデータ永続化にはUserDefaults
- より複雑なアプリにはCore Data（中級レベルで予定）
- 状態管理には@Stateと@StateObject

## ブランドガイドライン

### カラーパレット
- **AsaCoffeeBrown** (#C68C53) - ボタンとテキストのプライマリカラー
- **AsaMocha** (#8B5A2B) - 背景のセカンダリカラー
- **AsaSoftCream** (#E8D5B9) - セレクション用のハイライトカラー
- **AsaDarkSlate** (#2F3E46) - 背景用のニュートラルカラー
- **AsaMutedSage** (#7A918D) - 微細な要素用のアクセントカラー

### デザイン原則
- シンプルで温かみのある美学
- ブランドカラーの一貫した使用
- 角丸（標準10px）
- 奥行き感のためのシャドウ効果
- 家族向けで生産性重視のテーマ

## 開発ワークフロー

### アプリカテゴリ
1. **基礎（アプリ1-30）**: SwiftUIの基礎を学習
2. **中級（アプリ31-70）**: Core Data、API、アニメーション、デバイス機能
3. **上級（アプリ71-100）**: 複雑なアーキテクチャ、クラウド同期、AI/ML

### 実装ノート
- 各アプリの実装は`Docs/Notes/DayX-Implementation.md`に文書化
- スクリーンショットとデモ動画は`Docs/Screenshot/`に保存
- シンプルなカウンターから高度な機能まで段階的な複雑化

## このリポジトリでの作業方法

### 新しいアプリの追加
1. `Apps/`に新しいアプリディレクトリを作成
2. `Shared/`ディレクトリの共有コンポーネントを使用
3. 一貫したスタイリングのためのブランドガイドラインに従う
4. `Docs/Notes/`に実装を文書化

### 共有アセットの使用
- 共有コンポーネントのインポート: `import SwiftUI`（コンポーネントは同じプロジェクト内）
- `Color("AsaCoffeeBrown")`などでブランドカラーを使用
- 一貫したUIのために`AsaButton`と`AsaCard`を活用

### ファイル構成
- 各アプリをそのディレクトリ内で自己完結に保つ
- 意味のあるSwiftファイル名を使用（例：`NumberGameViewModel.swift`）
- ビューとモデルのSwiftUI命名規則に従う

## 現在の進捗

プロジェクトは**40個以上のアプリを実装済み**：

### アプリカテゴリ別の進捗
- **基本ユーティリティ（12個）**: カウンター、電卓、タイマー、ストップウォッチ、色選択、サイコロ等
- **ゲーム（5個）**: 数当てゲーム、三目並べ、等
- **生産性ツール（15個）**: 買い物リスト、ムードトラッカー、予算管理、タスクボード、リマインダー等
- **学習・創作（8個）**: SwiftUITutorialシリーズ、フラッシュカード、マインドマップ、描画パッド等
- **ヘルス・フィットネス（5個）**: 水分トラッカー、睡眠ログ、フィットネス目標、歩数カウンター等

### 技術実装レベル
- **@Observable パターン**: 599箇所で実装済み
- **Swift Data**: 複雑なデータ管理アプリで採用
- **Swift Testing**: テストフレームワーク導入
- **Swift Packages**: AsaUIKit、AsaTaskKitでモジュール化

最新の実装にはAsaTaskBoard（Kanbanスタイル）、AsaFlashcardPro（間隔反復学習）があり、モダンSwiftUIプラクティスと共有コンポーネントを活用した高品質なUIを提供しています。

## 技術的アプローチ

### 実装済み技術スタック

#### 状態管理・アーキテクチャ
- **@Observable（599箇所）**: モダンなリアクティブプログラミング
  ```swift
  @Observable
  final class TaskBoardViewModel {
      var currentBoard: TaskBoard?
      var isLoading = false
  }
  ```
- **MVVM パターン**: 一貫したアーキテクチャ実装
- **Swift Packages**: AsaUIKit、AsaTaskKitによるモジュール化

#### データ管理
- **Swift Data**: 複雑なデータモデル（FlashcardPro、TaskBoard等）
- **UserDefaults**: シンプルなデータ永続化（設定、履歴等）
- **Codable**: JSONシリアライゼーション

#### UI・UX
- **SwiftUI**: 最新のUI宣言的開発
- **共有コンポーネント**: AsaButton、AsaCard等の統一UI
- **アニメーション**: 0.2秒のeaseInOut標準、60fpsスムーズ動作
- **ブランドガイドライン**: 5色パレット統一適用

#### 開発・テスト
- **Swift Testing**: モダンテストフレームワーク（@Test構文）
- **GitHub Actions**: CI/CD自動化
- **XcodeGen**: プロジェクトファイル管理

### 技術的特徴
- **型安全**: Sendable準拠、厳密な型チェック
- **パフォーマンス**: LazyVStack、効率的ForEach使用
- **保守性**: MVVMパターン、コンポーネント再利用
- **コード品質**: 統一的コーディング規約、MARK使用

## コード品質管理

### 自動化・CI/CD

#### リンターによるコード品質管理
**すべてのSwiftコードは自動リンター/フォーマッターで一貫性を保ちます。**

```bash
# SwiftLint - コーディング規約チェック
swiftlint lint
swiftlint lint --fix  # 自動修正

# SwiftFormat - コード書式統一
swiftformat .
swiftformat --config .swiftformat .
```

#### リンター設定ファイル (.swiftlint.yml)
```yaml
# SwiftLint設定
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - force_unwrapping
  - implicitly_unwrapped_optional
line_length: 120
identifier_name:
  min_length: 1
excluded:
  - Carthage
  - .build
```

#### フォーマッター設定 (.swiftformat)
```
--indent 4
--maxwidth 120
--linebreaks lf
--commas inline
--trimwhitespace always
--disable redundantSelf
```

#### CI/CD統合
- **GitHub Actions**: 自動ビルド・テスト・リンター実行
- **Pull Request**: テンプレート化されたコードレビュー + 自動品質チェック
- **XcodeGen**: プロジェクトファイル自動生成
- **Pre-commit hooks**: コミット前の自動品質チェック

### Swift Testing実践戦略

#### テスト実行コマンド
```bash
# 全パッケージのテスト実行
swift test

# 特定パッケージのテスト実行
cd Packages/AsaUIKit
swift test

# 特定テストクラスの実行
swift test --filter AsaButtonTests
```

#### テストレベル別戦略

**Unit Tests (最優先 - 95%カバレッジ目標)**
```swift
// ViewModelロジックテスト
@Test("タスク状態変更テスト")
func testTaskStateChange() async {
    let viewModel = TaskViewModel()
    await viewModel.toggleTaskState(id: "task1")
    #expect(viewModel.tasks.first?.isCompleted == true)
}

// UIコンポーネントテスト
@Test("AsaButton状態テスト")
func testButtonStates() {
    let button = AsaButton(title: "Test", isLoading: true)
    #expect(button.isEnabled == false)
}
```

**Integration Tests (重要 - 80%カバレッジ目標)**
```swift
// データ永続化テスト
@Test("UserDefaults統合テスト")
func testDataPersistence() async {
    let service = TaskDataService()
    await service.saveTasks([Task(title: "テストタスク")])
    let loaded = await service.loadTasks()
    #expect(loaded.count == 1)
}
```

**UI Tests (補完的 - 主要フローのみ)**
```swift
// 主要ユーザーフローテスト（XCUITest）
func testMainUserFlow() {
    let app = XCUIApplication()
    app.launch()
    app.buttons["新しいタスク"].tap()
    app.textFields["タスクタイトル"].typeText("重要なタスク")
    app.buttons["保存"].tap()
    XCTAssert(app.staticTexts["重要なタスク"].exists)
}
```

#### テスト実装ガイドライン
- **@Test構文**: 従来のXCTestではなくSwift Testingを使用
- **#expect**: assertではなく#expectマクロでより自然な記述
- **async/await**: 非同期処理のテストサポート
- **並列実行**: Swift Testingの並列実行機能を活用

### コーディング規約
- **命名規約**: `Asa` + 機能名（AsaCounter、AsaBudgetPro）
- **ファイル構造**: ContentView.swift, ViewModel.swift, Model.swift
- **状態管理優先度**: @Observable > @StateObject > @State
- **MARK使用**: Properties, Body, Methods区分

### 品質チェックリスト
- [ ] MVVMアーキテクチャ適用
- [ ] ブランドガイドライン準拠
- [ ] @Observableパターン使用（新規実装時）
- [ ] エラーハンドリング実装
- [ ] アクセシビリティ配慮
- [ ] パフォーマンス検証
- [ ] アプリドキュメントの作成

## 開発ガイドライン詳細

### アプリ作成標準フロー
1. **企画・設計**: 機能要件定義、UI/UXスケッチ
2. **プロジェクト作成**: XcodeGenでプロジェクト生成
3. **MVVMアーキテクチャ構築**: Model, ViewModel, View分離
4. **共有コンポーネント活用**: AsaUIKit使用
5. **テスト実装**: Swift Testingで主要機能テスト
6. **ドキュメント作成**: `Docs/Notes/DayX-Implementation.md`

毎回アプリのドキュメントは確実に作成してください。

### 新規アプリ実装テンプレート
```swift
// AsaNewApp/AsaNewAppApp.swift
@main
struct AsaNewAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NewAppViewModel())
        }
    }
}

// AsaNewApp/ContentView.swift
struct ContentView: View {
    @EnvironmentObject private var viewModel: NewAppViewModel
    
    var body: some View {
        // UI実装
    }
}

// AsaNewApp/NewAppViewModel.swift  
@Observable
final class NewAppViewModel {
    // ビジネスロジック
}
```

### パッケージ活用ガイドライン
```swift
// AsaUIKit使用例
import AsaUIKit

AsaButton(
    title: "保存", 
    action: { viewModel.save() },
    color: AsaColors.coffeeBrown
)

AsaCard {
    Text("カード内容")
        .foregroundColor(AsaColors.darkSlate)
}
```

### エラーハンドリング標準
```swift
enum AsaError: Error, LocalizedError {
    case networkError, validationError, dataCorruption
    
    var errorDescription: String? {
        switch self {
        case .networkError: return "ネットワークエラーが発生しました"
        case .validationError: return "入力データに問題があります"
        case .dataCorruption: return "データが破損しています"
        }
    }
}
```