# AsaSocialFeed 実装ノート

## 実装日
2026-01-12

## アプリ概要
- **名前**: AsaSocialFeed（簡易SNSアプリ）
- **カテゴリ**: ソーシャル・コミュニケーション
- **難易度**: 中級
- **アプリ番号**: 73/100

## 実装内容

### 主要機能
1. **投稿機能**
   - テキストのみの投稿作成
   - 投稿者名・作成日時表示（「たった今」「3分前」「2時間前」「3日前」）
   - 自分の投稿の削除機能

2. **いいね機能**
   - いいね/いいね解除のトグル動作
   - いいね数のカウント表示
   - スプリングアニメーション（scaleEffect: 1.0 → 1.3 → 1.0、300ms）
   - ハートアイコンの色変更（グレー ↔ 赤）

3. **ユーザー管理**
   - ユーザー名をUserDefaultsで保存
   - 初回起動時にユーザー名設定画面を強制表示（`.interactiveDismissDisabled`）
   - 設定画面でユーザー名変更可能

### 技術スタック
- **アーキテクチャ**: MVVM
- **データ管理**: Swift Data（Post, Like モデル）
- **状態管理**: @Observable（FeedViewModel, NewPostViewModel）
- **UI**: SwiftUI + AsaUIKit（AsaButton、AsaCard、ブランドカラー統一）
- **テスト**: Swift Testing（@Test構文）
- **プロジェクト管理**: XcodeGen

### データモデル設計
```swift
// Post（投稿）
@Model
final class Post {
    var id: UUID
    var content: String
    var authorName: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Like.post)
    var likes: [Like] = []

    // Computed Properties
    var likeCount: Int { likes.count }
    func isLikedBy(_ userName: String) -> Bool
    var timeAgo: String
}

// Like（いいね）
@Model
final class Like {
    var id: UUID
    var userName: String
    var createdAt: Date
    var post: Post?  // 逆参照
}
```

**リレーション**: Post (1) ─< (N) Like
- cascade削除: Postを削除すると関連Likeも自動削除
- inverse設定: 双方向リレーション維持

### UI/UX
- **ブランドカラー**: AsaCoffeeBrown、AsaSoftCream、AsaMutedSage統一
- **いいねアニメーション**: `spring(response: 0.3, dampingFraction: 0.6)`
- **カード型UI**: AsaCard使用、角丸12px、シャドウ（radius: 2, opacity: 0.1）
- **空状態UI**: 「まだ投稿がありません」メッセージ + アイコン表示
- **LazyVStack**: 投稿リストの遅延読み込みでパフォーマンス最適化

## 学び

### 1. Swift Dataリレーション

#### 1対多リレーションの実装
```swift
// 親側（Post）
@Relationship(deleteRule: .cascade, inverse: \Like.post)
var likes: [Like] = []

// 子側（Like）
var post: Post?
```

**メリット**:
- `deleteRule: .cascade`: Post削除時に関連Likeも自動削除
- `inverse:`: 双方向リレーション自動維持
- ModelContext.save()一回で両側のリレーション保存

**参考元**: AsaFamilyAlbumのPhoto-Commentパターン

#### リレーションの活用
- `post.likes.count`: いいね数を簡単に取得
- `post.isLikedBy(userName)`: ユーザーごとのいいね状態チェック
- `post.addLike()` / `post.removeLike()`: ビジネスロジックをモデルに集約

### 2. @Observableパターン

#### 従来のObservableObjectとの比較
```swift
// ❌ 旧方式（ObservableObject）
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
}

// ✅ 新方式（@Observable）
@Observable
final class FeedViewModel {
    private(set) var posts: [Post] = []
    private(set) var isLoading = false
}
```

**メリット**:
- `@Published`不要（自動変更検知）
- `private(set)`によるカプセル化が自然
- より簡潔なコード

**注意点**:
- `@MainActor`を忘れずに付与
- `@Bindable`でViewとバインディング

### 3. スプリングアニメーション

#### 実装パターン
```swift
Button {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        isLikeAnimating = true
        viewModel.toggleLike(on: post)
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isLikeAnimating = false
        }
    }
} label: {
    Image(systemName: isLikedByCurrentUser ? "heart.fill" : "heart")
        .scaleEffect(isLikeAnimating ? 1.3 : 1.0)
}
```

**パラメータ**:
- `response: 0.3`: アニメーション継続時間（秒）
- `dampingFraction: 0.6`: 減衰率（0.0-1.0、低いほどバウンス強い）
- `scaleEffect(1.3)`: 1.3倍に拡大

**効果**:
- 自然なバウンス効果
- ユーザーアクションへの即座のフィードバック
- SNS特有の「いいね」の気持ちよさを再現

### 4. UserDefaults統合

#### シンプルな永続化
```swift
// FeedViewModel初期化時
init(dataService: SocialFeedDataService) {
    self.dataService = dataService
    self.currentUserName = UserDefaults.standard.string(forKey: "currentUserName") ?? ""
}

// ユーザー名設定時
func setUserName(_ name: String) {
    currentUserName = trimmed
    UserDefaults.standard.set(trimmed, forKey: "currentUserName")
}
```

**学び**:
- 固定ユーザー名はUserDefaultsで十分
- ViewModelで一元管理することで整合性保持
- 初回起動時の強制設定（`.interactiveDismissDisabled`）でUX向上

### 5. LazyVStackによるパフォーマンス最適化

```swift
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(viewModel.posts) { post in
            PostCardView(post: post, viewModel: viewModel)
        }
    }
    .padding()
}
```

**効果**:
- 画面に表示される投稿のみ描画
- 大量の投稿でもスムーズなスクロール
- メモリ効率的

**比較**: VStackは全要素を一度に描画するため、要素が多いと重くなる

### 6. XcodeGen活用

#### project.ymlの構成
```yaml
packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit

targets:
  AsaSocialFeed:
    dependencies:
      - package: AsaUIKit
        product: AsaUIKit
      - sdk: SwiftData.framework
```

**メリット**:
- .xcodeprojをGit管理から除外できる
- チーム開発時のコンフリクト回避
- 依存関係の明確化

### 7. Swift Testing

#### @Test構文の利点
```swift
@Test("Post: いいね追加テスト")
func testAddLike() {
    let post = Post(content: "テスト投稿", authorName: "テストユーザー")
    post.addLike(from: "いいねユーザー")

    #expect(post.likeCount == 1)
    #expect(post.isLikedBy("いいねユーザー"))
}
```

**従来のXCTestとの比較**:
- `@Test`アノテーションで簡潔
- `#expect`が`XCTAssert`より読みやすい
- 失敗時のメッセージが明確

## 実装時の課題と解決策

### 課題1: いいねの重複防止
**問題**: 同じユーザーが複数回いいねできてしまう

**解決策**:
```swift
func addLike(from userName: String) {
    guard !isLikedBy(userName) else { return }
    // いいね追加処理
}
```

### 課題2: 投稿削除時のLikeの扱い
**問題**: Post削除時にLikeが孤立する可能性

**解決策**:
```swift
@Relationship(deleteRule: .cascade, inverse: \Like.post)
var likes: [Like] = []
```
→ cascade削除で自動的にLikeも削除

### 課題3: 初回起動時のユーザー名設定
**問題**: ユーザー名未設定だと投稿できない

**解決策**:
```swift
.onAppear {
    if !viewModel.hasUserName {
        viewModel.showingUserNameSetting = true
    }
}
.interactiveDismissDisabled(!viewModel.hasUserName)
```
→ 初回起動時に設定画面を強制表示、閉じられないようにする

## 改善点（将来の拡張）

### 機能拡張
1. **コメント機能**: Likeモデルを拡張してCommentモデル追加
2. **画像投稿**: PhotoPickerによる画像添付機能
3. **タイムライン無限スクロール**: FetchDescriptorのlimit/offset活用
4. **プロフィール画面**: ユーザー別投稿一覧表示
5. **通知機能**: 新しいいいね/コメントの通知
6. **検索機能**: 投稿内容の全文検索
7. **ハッシュタグ**: #タグによる投稿分類

### UX改善
1. **Pull-to-refresh**: スワイプダウンで投稿更新
2. **投稿編集機能**: 投稿後の内容修正
3. **下書き保存**: 未投稿の内容を一時保存
4. **ダークモード最適化**: カラーの見直し
5. **アクセシビリティ**: VoiceOver対応強化

### 技術的改善
1. **ページネーション**: 大量投稿の効率的読み込み
2. **オフライン対応**: ネットワーク不要のローカルモード
3. **画像キャッシュ**: Kingfisher等の導入
4. **パフォーマンス計測**: Instrumentsでの最適化
5. **エラーハンドリング強化**: より詳細なエラーメッセージ

## デモ動画・スクリーンショット
- 保存先: `/Users/shinya/workspace/claude/AsaApps/Docs/Screenshot/AsaSocialFeed/`
- **フィード画面**: 投稿リスト表示
- **いいねアニメーション**: ハートアイコンのスプリングアニメーション
- **新規投稿画面**: TextEditorによる複数行入力
- **ユーザー名設定画面**: 初回起動時の設定フロー
- **空状態UI**: 投稿がない場合の表示

## テスト結果
### Unit Tests（Swift Testing）
- **PostTests**: 5テスト
  - いいね追加テスト ✅
  - いいね重複防止テスト ✅
  - いいね削除テスト ✅
  - timeAgoプロパティテスト ✅
  - 複数ユーザーのいいねテスト ✅

- **FeedViewModelTests**: 5テスト
  - ユーザー名設定テスト ✅
  - 空白ユーザー名の拒否テスト ✅
  - 投稿作成テスト ✅
  - 空投稿の拒否テスト ✅
  - ユーザー名未設定時の投稿拒否テスト ✅

### 手動テスト
- [x] 初回起動時にユーザー名設定画面表示
- [x] 新規投稿の作成・表示
- [x] いいねボタンのアニメーション（scaleEffect確認）
- [x] 自分の投稿の削除
- [x] 空状態UIの表示
- [x] 時間表示（「たった今」「X分前」「X時間前」「X日前」）

## 参考アプリ・コード

### データ層
- **AsaFamilyAlbum**: Swift Dataリレーション（Photo-Like）
  - `/Users/shinya/workspace/claude/AsaApps/Apps/AsaFamilyAlbum/AsaFamilyAlbum/Models/Photo.swift`
- **AsaTaskKit**: DataServiceパターン
  - `/Users/shinya/workspace/claude/AsaApps/Packages/AsaTaskKit/Sources/AsaTaskKit/Services/TaskDataService.swift`

### ViewModel
- **AsaSmartTodo**: @Observableパターン
  - `/Users/shinya/workspace/claude/AsaApps/Apps/AsaSmartTodo/AsaSmartTodo/ViewModels/SmartTodoViewModel.swift`

### UI
- **AsaRecipe**: いいねアニメーション
  - `/Users/shinya/workspace/claude/AsaApps/Apps/AsaRecipe/AsaRecipe/RecipeListView.swift`
- **AsaNewsReader**: LazyVStackパターン
  - `/Users/shinya/workspace/claude/AsaApps/Apps/AsaNewsReader/AsaNewsReader/NewsListView.swift`
- **AsaUIKit**: 共有UIコンポーネント
  - `/Users/shinya/workspace/claude/AsaApps/Packages/AsaUIKit/Sources/AsaUIKit/`

## ファイル構造
```
Apps/AsaSocialFeed/
├── AsaSocialFeed/
│   ├── AsaSocialFeedApp.swift        # アプリエントリーポイント
│   ├── Models/
│   │   ├── Post.swift                # 投稿モデル（@Model）
│   │   └── Like.swift                # いいねモデル（@Model）
│   ├── Services/
│   │   └── SocialFeedDataService.swift  # データ永続化サービス
│   ├── ViewModels/
│   │   ├── FeedViewModel.swift          # フィード管理（@Observable）
│   │   └── NewPostViewModel.swift       # 新規投稿管理
│   ├── Views/
│   │   ├── ContentView.swift            # メインフィード画面
│   │   ├── PostCardView.swift           # 投稿カードコンポーネント
│   │   ├── NewPostView.swift            # 新規投稿画面
│   │   └── UserNameSettingView.swift    # ユーザー名設定画面
│   └── Assets.xcassets/              # ブランドカラー5色
├── AsaSocialFeedTests/
│   ├── PostTests.swift               # Postモデルのテスト
│   └── FeedViewModelTests.swift      # FeedViewModelのテスト
└── project.yml                       # XcodeGen設定
```

## 統計
- **実装時間**: 約5時間
- **ファイル数**: 14ファイル
- **コード行数**: 約800行
- **テスト数**: 10テスト
- **依存関係**: AsaUIKit、SwiftData

## まとめ

AsaSocialFeedは、Swift Dataの1対多リレーション、@Observableパターン、スプリングアニメーションといったモダンSwiftUIの技術を統合した、実践的なSNSアプリです。

**技術的な成果**:
1. Swift Dataリレーションの実装（cascade削除、inverse設定）
2. @Observableによるモダンな状態管理
3. スプリングアニメーションによるリッチなUX
4. LazyVStackによるパフォーマンス最適化
5. Swift Testingによる堅牢なテスト

**学びの要点**:
- **リレーション設計**: 親子関係の適切な定義が重要
- **アニメーション**: `spring(response, dampingFraction)`で自然な動き
- **カプセル化**: `private(set)`で外部からの変更を防止
- **UX配慮**: 初回起動時の強制設定でユーザー体験向上

このプロジェクトを通じて、SNSアプリの基本的な機能（投稿、いいね、ユーザー管理）を実装し、Swift DataとSwiftUIの連携を深く理解できました。将来的にはコメント機能や画像投稿など、より高度な機能を追加していく予定です。
