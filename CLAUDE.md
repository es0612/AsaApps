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

XcodeプロジェクトはXcodeGenコマンドで管理すること。

各アプリは独立したXcodeプロジェクトです。作業する特定のアプリディレクトリに移動してください：

```bash
# 特定のアプリをXcodeで開く
cd Apps/AsaNumberGame
open AsaNumberGame.xcodeproj

# コマンドラインからビルドして実行
xcodebuild -project AsaNumberGame.xcodeproj -scheme AsaNumberGame
```

## アーキテクチャパターン

### アプリ構造
- 各アプリは標準的なSwiftUIアプリ構造に従っています：
  - `ContentView.swift` - メインUI
  - `ViewModel.swift` - ビジネスロジック（MVVMパターン）
  - `Model.swift` - データモデル
  - 複雑なUIコンポーネント用のカスタムビュー

### 共有コンポーネント
- **AsaButton**: ブランドカラーを使用した一貫したボタンスタイリング
- **AsaCard**: コンテンツセクション用のカードラッパー
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
- **GitHub Actions**: 自動ビルド・テスト実行
- **Pull Request**: テンプレート化されたコードレビュー
- **XcodeGen**: プロジェクトファイル自動生成

### テスト戦略
- **Swift Testing**: モダン@Test構文使用
- **単体テスト**: ViewModelロジックテスト
- **UIテスト**: 主要ユーザーフローテスト
- **カバレッジ目標**: 段階的拡張中（現在4ファイル→全ViewModel）

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

## 開発ガイドライン詳細

### アプリ作成標準フロー
1. **企画・設計**: 機能要件定義、UI/UXスケッチ
2. **プロジェクト作成**: XcodeGenでプロジェクト生成
3. **MVVMアーキテクチャ構築**: Model, ViewModel, View分離
4. **共有コンポーネント活用**: AsaUIKit使用
5. **テスト実装**: Swift Testingで主要機能テスト
6. **ドキュメント作成**: `Docs/Notes/DayX-Implementation.md`

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