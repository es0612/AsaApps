# コードスタイル・規約

## SwiftUIアーキテクチャパターン

### アプリ構造
各アプリは標準的なSwiftUIアプリ構造に従います：
- `ContentView.swift` - メインUI
- `ViewModel.swift` - ビジネスロジック（MVVMパターン、@Observable使用）
- `Model.swift` - データモデル
- 複雑なUIコンポーネント用のカスタムビュー

### データ管理パターン
- **@Observable**: モダンなSwift observationパターンを使用
- **Swift Data**: Core Dataの後継として複雑なデータ管理に使用
- **UserDefaults**: シンプルなデータ永続化
- **@State/@StateObject**: 状態管理

## コーディング規約

### 命名規約
- **アプリ名**: `Asa` + 機能名（例：AsaCounter, AsaBudgetPro）
- **ViewModel**: `[機能名]ViewModel`（例：BudgetViewModel）
- **Model**: 機能に応じた名詞（例：Transaction, Category）
- **共有コンポーネント**: `Asa` + コンポーネント名（AsaButton, AsaCard）

### ファイル構成
- 各アプリはそのディレクトリ内で自己完結
- 意味のあるSwiftファイル名を使用
- ViewとModelのSwiftUI命名規則に従う

### コメントとMARK
```swift
// MARK: - Properties
@State private var count = 0

// MARK: - Body
var body: some View {
    // 具体的な機能の説明
}

// MARK: - Methods
func validateAmount() {
    // 処理の説明
}
```

### エラーハンドリング
```swift
do {
    try modelContext.save()
    loadTransactions()
} catch {
    print("取引の保存に失敗しました: \(error)")
}
```

## テスト規約

### Swift Testing使用
```swift
import Testing
@testable import AsaFitnessGoal

struct AsaFitnessGoalTests {
    @Test("FitnessGoalモデルの初期化テスト")
    func fitnessGoalInitialization() throws {
        // テスト実装
        #expect(goal.title == title)
    }
}
```

### テストファイル構造
- `[AppName]Tests/` - 単体テスト
- `[AppName]UITests/` - UIテスト