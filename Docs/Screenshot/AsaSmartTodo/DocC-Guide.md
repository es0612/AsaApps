# AsaSmartTodo DocC APIドキュメント生成ガイド

## 📖 概要

DocC（Documentation Compiler）を使用して、AsaSmartTodoのAPIドキュメントを自動生成します。
主要クラス（SmartTodoViewModel、TaskPriorityPredictor、DataService、NotificationService）には
包括的なDocCコメントが追加されています。

---

## 📝 DocCコメント追加済みクラス

### 1. SmartTodoViewModel.swift
**クラス概要**: メインViewModel、タスク管理とAI予測の統括

**ドキュメント内容**:
- 主要機能（CRUD、AI予測、フィルタリング、分析統合、通知管理）
- 使用例コードスニペット
- `@MainActor`によるスレッドセーフ性の説明
- `createTask()`メソッドの詳細パラメータ説明

### 2. TaskPriorityPredictor.swift
**クラス概要**: AI優先度予測エンジン

**ドキュメント内容**:
- 6要因分析アルゴリズムの数式
- 重み配分の詳細（期限35%, カテゴリ20%, タイトル15%, 説明10%, 朝活10%, 履歴10%）
- スコアから優先度への変換ロジック
- `PriorityWeights`構造体のカスタマイズ例

### 3. DataService.swift
**クラス概要**: Swift Data永続化サービス

**ドキュメント内容**:
- 管理対象モデル（SmartTask、TaskAnalytics、UserSettings、CustomCategory）
- 本番環境とテスト環境の使い分け（`inMemory`フラグ）
- `save()`メソッドによるコミットの重要性
- スレッドセーフ性（`@MainActor`）

### 4. NotificationService.swift
**クラス概要**: タスク期限通知管理サービス

**ドキュメント内容**:
- UserNotificationsフレームワークの使用
- 通知権限管理、スケジューリング、キャンセルの詳細
- シングルトンパターンの説明
- iOS 10以降の要件

---

## 🛠️ DocCドキュメント生成手順

### 方法1: Xcode GUI（推奨）

1. **Xcodeでプロジェクトを開く**
   ```bash
   cd Apps/AsaSmartTodo
   open AsaSmartTodo.xcodeproj
   ```

2. **Product > Build Documentation**を選択
   - メニューバー: `Product` → `Build Documentation`
   - キーボードショートカット: `⌃⇧⌘D` (Control + Shift + Command + D)

3. **ドキュメントビューアが開く**
   - 左サイドバーに「AsaSmartTodo」が表示される
   - クラス、メソッド、プロパティのドキュメントを閲覧可能

4. **ドキュメントのエクスポート（オプション）**
   - Xcode → Window → Developer Documentation
   - Archive → Export...
   - `.doccarchive`ファイルを保存

---

### 方法2: コマンドライン（CI/CD向け）

#### xcodebuildを使用したビルド

```bash
# AsaSmartTodoディレクトリに移動
cd Apps/AsaSmartTodo

# DocCドキュメントをビルド
xcodebuild docbuild \
    -scheme AsaSmartTodo \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -derivedDataPath ./DerivedData

# 生成されたドキュメントの場所を確認
find ./DerivedData -name "*.doccarchive"
```

#### 生成されたファイルの場所

```
DerivedData/Build/Products/Debug-iphonesimulator/AsaSmartTodo.doccarchive
```

---

### 方法3: Swift-DocC Plugin（最新）

Swift 5.6以降では、Swift Package Managerプラグインを使用可能です。

```bash
# Swift Package用のDocC生成（将来のモジュール化対応）
swift package generate-documentation \
    --target AsaSmartTodo \
    --output-path ./docs
```

---

## 📂 生成されるドキュメント構造

```
AsaSmartTodo.doccarchive/
├── index.html                     # トップページ
├── documentation/
│   ├── asasmarttodo/              # モジュールトップ
│   │   ├── smarttodoviewmodel/   # SmartTodoViewModel詳細
│   │   ├── taskprioritypredictor/ # TaskPriorityPredictor詳細
│   │   ├── dataservice/          # DataService詳細
│   │   ├── notificationservice/  # NotificationService詳細
│   │   └── ...                   # その他のクラス
│   └── ...
├── css/                          # スタイルシート
├── js/                           # JavaScript
└── data/                         # JSONデータ
```

---

## 🌐 ドキュメントのホスティング

### GitHub Pagesでの公開

1. **`.doccarchive`をウェブ対応形式に変換**
   ```bash
   # xcrunでDocCアーカイブを処理
   xcrun docc process-archive transform-for-static-hosting \
       AsaSmartTodo.doccarchive \
       --output-path ./docs \
       --hosting-base-path /AsaApps
   ```

2. **GitHubリポジトリにプッシュ**
   ```bash
   git add docs/
   git commit -m "docs: Add AsaSmartTodo API documentation (DocC)"
   git push origin main
   ```

3. **GitHub Pages設定**
   - リポジトリSettings → Pages
   - Source: `main` branch, `/docs` folder
   - Save

4. **公開URL**
   ```
   https://yourusername.github.io/AsaApps/documentation/asasmarttodo/
   ```

---

## ✅ ドキュメント品質チェックリスト

生成後、以下を確認してください：

### 必須項目
- [ ] SmartTodoViewModelの概要が表示される
- [ ] TaskPriorityPredictorのアルゴリズム説明が表示される
- [ ] DataServiceの使用例コードが正しくフォーマットされている
- [ ] NotificationServiceのメソッドパラメータが記載されている

### コード例の動作確認
- [ ] 使用例のSwiftコードがシンタックスハイライト表示される
- [ ] サンプルコードがコピー可能
- [ ] リンクが正しく機能する

### ナビゲーション
- [ ] 左サイドバーでクラス一覧を表示できる
- [ ] 検索機能が動作する
- [ ] クラス間のリンクが機能する

---

## 🔧 トラブルシューティング

### Issue 1: "No documentation found"
**原因**: DocCコメントが不足している

**解決策**:
```swift
// ✅ 正しい: /// で始まる
/// SmartTodoViewModelの概要
final class SmartTodoViewModel {}

// ❌ 間違い: // で始まる
// SmartTodoViewModelの概要
final class SmartTodoViewModel {}
```

### Issue 2: ビルドエラー "Scheme not found"
**原因**: スキーム名が間違っている

**解決策**:
```bash
# スキーム一覧を確認
xcodebuild -list -project AsaSmartTodo.xcodeproj

# 正しいスキーム名を使用
xcodebuild docbuild -scheme AsaSmartTodo ...
```

### Issue 3: コード例がフォーマットされない
**原因**: バッククォート（```）の不足

**解決策**:
```swift
/// ## 使用例
/// ```swift
/// let viewModel = SmartTodoViewModel()
/// viewModel.loadTasks()
/// ```
```

---

## 📊 DocC統計（AsaSmartTodo）

| 項目 | 数値 |
|------|------|
| ドキュメント化されたクラス | 4個（主要クラス） |
| DocCコメント行数 | 約150行 |
| コード例 | 6個 |
| アルゴリズム説明 | 1個（AI予測） |
| パラメータドキュメント | 15個以上 |

---

## 🎓 参考リンク

- [Apple DocC公式ドキュメント](https://developer.apple.com/documentation/docc)
- [DocC構文ガイド](https://apple.github.io/swift-docc/documentation/docc/formatting-your-documentation-content)
- [Swift Markup Reference](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/)

---

## 💡 ベストプラクティス

### DocCコメントの書き方

1. **概要は1行で簡潔に**
   ```swift
   /// タスク管理のメインViewModel
   final class SmartTodoViewModel {}
   ```

2. **詳細説明は空行の後に**
   ```swift
   /// タスク管理のメインViewModel
   ///
   /// AI優先度予測、フィルタリング、分析データ統合を提供します。
   ```

3. **使用例を必ず含める**
   ```swift
   /// ## 使用例
   /// ```swift
   /// let viewModel = SmartTodoViewModel(dataService: dataService)
   /// viewModel.loadTasks()
   /// ```
   ```

4. **パラメータと戻り値を明記**
   ```swift
   /// - Parameters:
   ///   - title: タスクのタイトル
   ///   - category: タスクのカテゴリ
   /// - Returns: 作成されたタスク
   ```

5. **Note/Warningを適切に使う**
   ```swift
   /// - Note: メインスレッドで実行されます
   /// - Warning: save()を呼び出さないと変更が保存されません
   ```

---

## ✨ Phase 4完了チェック

- [x] 主要4クラスにDocCコメント追加
- [ ] Xcodeでドキュメントビルド確認
- [ ] `.doccarchive`ファイル生成
- [ ] （オプション）GitHub Pagesで公開

**次のステップ**: Xcodeで`Product > Build Documentation`を実行し、ドキュメントを確認してください。
