# Day 93 - AsaCrowdsource 実装ノート

## 日付
2026年2月3日

## アプリ概要
**AsaCrowdsource** - 家族でアイデアを共有するクラウドソーシングアプリ

### コンセプト
家族やグループで「やりたいこと」「欲しいもの」「行きたい場所」などのアイデアを投稿し、みんなで投票・コメントして最適な選択を見つけるアプリ。

### テーマ
- 家族 👨‍👩‍👧
- 生産性 📊
- コラボレーション 🤝

## 技術的なハイライト

### 1. SwiftData + @Observable の組み合わせ

```swift
@Model
final class Idea {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryRawValue: String  // enumのrawValue保存

    // Computed propertyでenum変換
    var category: IdeaCategory {
        get { IdeaCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}
```

**学んだこと**: SwiftDataの`@Model`はenumを直接保存できないため、rawValueで保存し、computed propertyで変換するパターンが有効。

### 2. @ModelActor によるスレッドセーフなデータアクセス

```swift
@ModelActor
actor LocalDataService: CrowdsourceDataServiceProtocol {
    func fetchIdeas(groupId: String) async throws -> [Idea] {
        let descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { $0.groupId == groupId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
```

**学んだこと**: `@ModelActor`マクロを使うと、actorとModelContextが自動的に連携し、スレッドセーフなデータ操作が可能。

### 3. プロトコル指向によるデータサービス抽象化

```swift
protocol IdeaDataServiceProtocol: Sendable {
    func createIdea(_ idea: Idea) async throws -> Idea
    func fetchIdeas(groupId: String) async throws -> [Idea]
    // ...
}

// ローカル実装
actor LocalDataService: CrowdsourceDataServiceProtocol { }

// Firebase実装（将来）
actor FirebaseDataService: CrowdsourceDataServiceProtocol { }
```

**学んだこと**: プロトコルでデータサービスを抽象化することで、ローカル/リモートの切り替えが容易に。

### 4. 招待コード方式のグループ参加

```swift
static func generateInviteCode() -> String {
    let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // 紛らわしい文字を除外
    return String((0..<6).map { _ in characters.randomElement()! })
}
```

**学んだこと**: 招待コードは紛らわしい文字（I/1, O/0など）を除外することでユーザビリティが向上。

### 5. 投票の重み付けスコア

```swift
enum VoteType {
    case like       // weight: 1
    case love       // weight: 3
    case interested // weight: 2
}

struct VoteSummary {
    var weightedScore: Int {
        (likeCount * 1) + (loveCount * 3) + (interestedCount * 2)
    }
}
```

**学んだこと**: 投票に重み付けを設けることで、より意味のある優先度計算が可能。

## 画面フロー

```
[ログイン] → [アイデア一覧] ←→ [アイデア詳細]
                ↓               ↓
         [グループ管理]    [コメント/投票]
                ↓
         [招待コード共有]
```

## 実装ファイル一覧

### Models (6ファイル)
- `IdeaCategory.swift` - アイデアカテゴリenum
- `IdeaStatus.swift` - ステータスenum
- `VoteType.swift` - 投票タイプenum
- `Idea.swift` - アイデア@Model
- `Comment.swift` - コメント@Model
- `Vote.swift` - 投票@Model + VoteSummary
- `LocalFamilyGroup.swift` - グループ@Model
- `LocalMember.swift` - メンバー@Model + MemberRole
- `User.swift` - 認証ユーザー構造体

### ViewModels (5ファイル)
- `AuthViewModel.swift` - 認証状態管理
- `FamilyGroupViewModel.swift` - グループ管理
- `IdeaListViewModel.swift` - 一覧・フィルタ・ソート
- `IdeaDetailViewModel.swift` - 詳細・コメント・投票
- `CreateIdeaViewModel.swift` - 作成・編集

### Views (12ファイル)
- Authentication: LoginView, SignUpView
- Family: FamilyDashboardView, CreateFamilyView, JoinFamilyView, InviteCodeView
- Ideas: IdeaListView, IdeaCardView, IdeaDetailView, CreateIdeaView, EditIdeaView
- Comments: CommentRowView
- Voting: VotingView
- Settings: SettingsView
- ContentView

### Services (2ファイル)
- `CrowdsourceDataService.swift` - プロトコル定義
- `LocalDataService.swift` - SwiftData実装

## 使用した技術・パターン

| 技術/パターン | 用途 |
|--------------|------|
| SwiftData @Model | データ永続化 |
| @Observable | 状態管理（iOS 17+） |
| @ModelActor | スレッドセーフなDB操作 |
| MVVM | アーキテクチャ |
| Protocol-Oriented | データサービス抽象化 |
| async/await | 非同期処理 |
| AsaUIKit | 共有UIコンポーネント |
| Firebase SDK | リモート同期（準備） |

## 苦労した点と解決策

### 1. SwiftDataでのenum保存
**問題**: `@Model`クラスでenumを直接プロパティにできない

**解決**: rawValueをStringで保存し、computed propertyで変換

### 2. @Observableと@ModelActorの連携
**問題**: ViewModelからactorのデータサービスを呼び出す際の型安全性

**解決**: プロトコルで抽象化し、ViewModelは具体的な実装に依存しない設計

### 3. フィルター・ソートの状態管理
**問題**: 複数のフィルター条件を組み合わせた検索

**解決**: `applyFilters()`メソッドで一括処理し、常に最新のフィルター状態を反映

## 今後の改善点

1. **Firebase統合**: FirebaseDataServiceの本格実装
2. **オフライン対応**: 同期キューの実装
3. **通知機能**: 新規アイデア・コメントの通知
4. **画像添付**: アイデアへの写真添付
5. **UIテスト**: 主要フローのUIテスト追加

## 参考にしたアプリ

- **AsaFamilySync**: グループ管理、招待コード方式
- **AsaLiveChat**: リアルタイム通信パターン
- **AsaTaskBoard**: Kanbanスタイルのステータス管理

## まとめ

AsaCrowdsourceは、SwiftDataと@Observableを組み合わせた現代的なiOSアプリアーキテクチャの良い実践例となった。プロトコル指向設計により、将来的なFirebase統合もスムーズに行える基盤が整った。

家族でのコラボレーションというテーマは、朝活パパエンジニアのプロジェクトコンセプトにぴったりで、実際に家族で使えるアプリとして完成度が高い。

---

**次のアプリ**: #94へ続く

**総開発時間**: 約4-5時間（Phase 1-3実装）
