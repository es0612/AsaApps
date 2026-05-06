# AsaCrowdsource SwiftData クラッシュ修正プラン

## Context（なぜこの修正が必要か）

### 発生事象
アイデア画面の操作中に以下のクラッシュが発生:

```
SwiftData/BackingData.swift:835: Fatal error: This model instance was destroyed
by calling ModelContext.reset and is no longer usable.
```

クラッシュ位置: `Idea.id.getter`（SwiftDataマクロ展開部）。

### 根本原因
直接的な `ModelContext.reset()` の呼び出しは存在しない。**真の原因は `@ModelActor` の Context Lifecycle 問題**:

1. `@ModelActor` マクロは `init(modelContainer:)` ごとに**新しい `ModelContext` を内部生成**する
2. ContentView/IdeaListView/IdeaDetailView/CreateIdeaView/EditIdeaView の各 setup関数で `LocalDataService(modelContainer: modelContext.container)` を**毎回newしている**
3. 結果として、独立した複数のContextが乱立
4. 一時的なLocalDataService がスコープ外でARC解放されると、その内部Contextも解放
5. しかし `IdeaListViewModel.ideas: [Idea]` (IdeaListViewModel.swift:37) は解放後Contextに紐づく `Idea` 参照を保持
6. SwiftUIの再描画で `Idea.id` getter にアクセス → `BackingData` が「Contextがdestroyされている」と判定し、`reset` の文言でエラー報告 → クラッシュ

### 修正方針（ユーザー選択済）
- **アプローチA: @MainActor class化**
- **影響範囲: 全データサービスを統一**

`@ModelActor actor` を `@MainActor final class` に変更し、SwiftUI標準の `@Environment(\.modelContext)` から取得した**単一のModelContext** をすべてのDataServiceで共有する。

---

## 修正対象ファイル

### 🔧 サービス層（コア変更）

#### 1. `Apps/AsaCrowdsource/AsaCrowdsource/Services/LocalDataService.swift`

| 変更前 | 変更後 |
|--------|--------|
| `@ModelActor actor LocalDataService` | `@MainActor final class LocalDataService` |
| マクロが自動生成する `modelContext` | `let modelContext: ModelContext`（init で受け取る） |
| `init(modelContainer:)`（自動生成） | `init(modelContext: ModelContext)`（明示的に定義） |
| 各メソッドの `async throws` | `throws` のみ（async削除可、ただし呼び出し側互換のため `async` は維持してもOK） |

**実装イメージ**:
```swift
@MainActor
final class LocalDataService: CrowdsourceDataServiceProtocol {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchIdeas(groupId: String) throws -> [Idea] {
        let descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { $0.groupId == groupId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    // ... 他メソッドも同様に async を削除（または互換維持で残す）
}
```

#### 2. `Apps/AsaCrowdsource/AsaCrowdsource/Services/SampleDataService.swift

同パターンで `@ModelActor actor` → `@MainActor final class`、initで `ModelContext` を受け取る。

#### 3. `Apps/AsaCrowdsource/AsaCrowdsource/Services/CrowdsourceDataService.swift`

プロトコル定義の `async` を維持するか削除するかを判断:
- **推奨**: `async` を **維持**（Firebase版の将来実装で必要、互換性確保）
- @MainActor版は内部で `await` 不要になるが、プロトコル準拠は問題なし

---

### 🎯 アプリエントリポイント

#### 4. `Apps/AsaCrowdsource/AsaCrowdsource/AsaCrowdsourceApp.swift`

**Environment用カスタムキーを追加し、共有のDataServiceを生成**:

```swift
// EnvironmentKey定義
private struct LocalDataServiceKey: EnvironmentKey {
    @MainActor static var defaultValue: LocalDataService? = nil
}

extension EnvironmentValues {
    var localDataService: LocalDataService? {
        get { self[LocalDataServiceKey.self] }
        set { self[LocalDataServiceKey.self] = newValue }
    }
}

@main
struct AsaCrowdsourceApp: App {
    var sharedModelContainer: ModelContainer = { /* 既存のまま */ }()

    var body: some Scene {
        WindowGroup {
            // ContentViewをラップしてEnvironment注入
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(familyViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}

// Environment(\.modelContext) を取得してLocalDataServiceを構築する中継View
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ContentView()
            .environment(\.localDataService, LocalDataService(modelContext: modelContext))
    }
}
```

**ポイント**: `@Environment(\.modelContext)` は `.modelContainer()` 配下のViewでしか取得できないため、中継Viewが必要。

---

### 📱 View層（毎回newを撤廃）

#### 5. `Apps/AsaCrowdsource/AsaCrowdsource/ContentView.swift`

| 変更前 | 変更後 |
|--------|--------|
| `let dataService = LocalDataService(modelContainer: modelContext.container)` (line 97, 118) | `@Environment(\.localDataService) var dataService` で取得 |
| `let sampleService = SampleDataService(modelContainer: modelContext.container)` (line 123) | `SampleDataService(modelContext: modelContext)` または共有Environment |

#### 6. `Apps/AsaCrowdsource/AsaCrowdsource/Views/Ideas/IdeaListView.swift`

- `setupViewModel()` (line 273-280) の `LocalDataService(modelContainer:)` 呼び出しを撤廃
- `@Environment(\.localDataService) var dataService` から取得して `viewModel.setDataService(dataService)`

#### 7. `Apps/AsaCrowdsource/AsaCrowdsource/Views/Ideas/IdeaDetailView.swift` (line 315付近)

同様に Environment から取得。

#### 8. `Apps/AsaCrowdsource/AsaCrowdsource/Views/Ideas/CreateIdeaView.swift` (line 182付近)

同上。

#### 9. `Apps/AsaCrowdsource/AsaCrowdsource/Views/Ideas/EditIdeaView.swift` (line 183付近)

同上。

---

### 🧠 ViewModel層（型互換調整）

#### 10. `Apps/AsaCrowdsource/AsaCrowdsource/ViewModels/IdeaListViewModel.swift`

- `private var dataService: LocalDataService?` の型はそのまま（@MainActor classになっただけなので互換）
- `loadIdeas()` 内の `try await dataService.fetchIdeas(...)` は @MainActor class なら `await` 不要だが、プロトコル定義を `async` 維持なら `await` も維持可

#### 11. `Apps/AsaCrowdsource/AsaCrowdsource/ViewModels/IdeaDetailViewModel.swift`
#### 12. `Apps/AsaCrowdsource/AsaCrowdsource/ViewModels/CreateIdeaViewModel.swift`
#### 13. `Apps/AsaCrowdsource/AsaCrowdsource/ViewModels/FamilyGroupViewModel.swift`

いずれも既に `@MainActor` で動作しているため、型シグネチャはそのままで動く。`await` を削除するかは方針次第（残しても害はない）。

---

## 既存の利用可能なパターン（再利用）

- `FamilyGroupViewModel` は既に `@MainActor final class ObservableObject` パターン (`FamilyGroupViewModel.swift:13-14`) なので、新しい `LocalDataService` (@MainActor class) と相性◎
- `IdeaListViewModel` も既に `@MainActor @Observable final class` (`IdeaListViewModel.swift:32-34`)
- `Idea` モデルの `@Attribute(.unique) var id: UUID` (`Idea.swift:17`) など既存設計はそのまま流用

---

## 検証方法

### ビルド検証
```bash
cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaCrowdsource
xcodegen generate
xcodebuild -project AsaCrowdsource.xcodeproj -scheme AsaCrowdsource -sdk iphonesimulator build
```

### 動作検証（クラッシュ再現の有無）
**クラッシュが起きていた操作シナリオを通しで再現テスト**:

1. アプリを起動 → サンプルデータが投入される
2. 「アイデア」タブで一覧表示（IdeaListView）
3. アイデアをタップ → 詳細表示（IdeaDetailView）
4. 投票ボタンを操作（VotingView）
5. コメント投稿
6. 一覧に戻る → リロード
7. 別のアイデアをタップ → 編集画面（EditIdeaView）
8. ステータス変更 → 保存
9. 新規アイデア作成（CreateIdeaView）
10. グループ切替（FamilyDashboardView）→ アイデア一覧再表示

各ステップでクラッシュが出ないことを確認。

### 単体テスト
```bash
xcodebuild test -project AsaCrowdsource.xcodeproj -scheme AsaCrowdsource \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

`AsaCrowdsourceTests` 配下のテストがすべてパスすること。

### 補足: メモリ・スレッド検証
- Xcode Instruments で **Allocations** プロファイルを取り、`ModelContext` のインスタンス数が**1個に収束**することを確認
- メインスレッドで全DB操作が動くため、**Main Thread Checker** にエラーが出ないこと

---

## リスクと注意点

| リスク | 対策 |
|--------|------|
| プロトコル `CrowdsourceDataServiceProtocol` の `async` を維持しないと将来のFirebase版で破綻 | `async throws` を**維持**し、@MainActor classでも `func ... async throws` の形にする |
| `EnvironmentKey` の `defaultValue` を `nil` にするとアンラップ漏れでクラッシュ | RootView で必ず注入。各Viewでは `guard let dataService` パターンで防御 |
| iOS 17/18 互換性 | `@MainActor` `@Observable` は iOS 17+。 project.yml は iOS 18.0 ターゲットなので問題なし |
| 既存の Firebase連携の準備コードが actor依存 | 現状は `LocalDataService` のみ実装で Firebase版は未着手。プロトコル準拠だけ守れば将来追加可能 |

---

## 修正の所要時間見積もり
- サービス層 (LocalDataService + SampleDataService): 30分
- App + ContentView + EnvironmentKey定義: 20分
- View層 4ファイル の Environment移行: 20分
- 動作検証 + クラッシュ再現テスト: 30分
- **合計: 約1.5〜2時間**

---

## 完了条件
1. ✅ `xcodebuild build` がエラー0件で完了
2. ✅ アイデア一覧→詳細→投票→コメント→編集の全シナリオでクラッシュゼロ
3. ✅ Xcode の Issue Navigator で warning も最小化（Sendable警告なし）
4. ✅ 既存の `Docs/Notes/Day93-AsaCrowdsource.md` に**修正内容の追記**（@ModelActorパターンの落とし穴と教訓）
