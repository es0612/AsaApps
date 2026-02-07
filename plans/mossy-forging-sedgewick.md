# AsaCrowdsource 実装計画

## 概要
**アプリ番号**: #93（上級）
**コンセプト**: 家族でアイデアを共有するクラウドソーシングアプリ
**テーマ**: 家族、生産性、朝活

## 技術選定

### 同期技術: Firebase Firestore
**選定理由**:
- AsaFamilySyncで実績あり（招待コード方式、リアルタイム同期）
- オフライン対応がSDKに組み込み
- Snapshot Listenerによる即時反映

### データ永続化: SwiftData + Firestore ハイブリッド
- **ローカル**: SwiftData（iOS 17+）
- **リモート**: Firebase Firestore
- **同期**: ローカルファースト + 差分同期

### 参考アプリ
- AsaFamilySync: グループ管理、招待コード、Firebase連携
- AsaLiveChat: リアルタイム通信パターン

---

## 主要機能

1. **家族グループ管理**
   - グループ作成/参加（招待コード方式）
   - メンバー管理（オーナー/メンバーロール）

2. **アイデア管理**
   - 投稿（タイトル、説明、カテゴリ）
   - 編集/削除（作成者のみ）
   - ステータス管理（提案中→議論中→承認→実行→完了）

3. **投票機能**
   - いいね/大好き/興味あり
   - 投票集計表示

4. **コメント機能**
   - コメント投稿/削除
   - リアルタイム反映

5. **カテゴリ分類**
   - 家族旅行、週末、子育て、買い物、食事、イベント、健康、その他

---

## ディレクトリ構造

```
Apps/AsaCrowdsource/
├── AsaCrowdsource/
│   ├── AsaCrowdsourceApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── Idea.swift              # @Model - アイデア
│   │   ├── Comment.swift           # @Model - コメント
│   │   ├── Vote.swift              # @Model - 投票
│   │   ├── FamilyGroup.swift       # グループ（AsaFamilySyncから移植）
│   │   ├── Member.swift            # メンバー
│   │   ├── IdeaCategory.swift      # enum - カテゴリ
│   │   └── IdeaStatus.swift        # enum - ステータス
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── FamilyGroupViewModel.swift
│   │   ├── IdeaListViewModel.swift
│   │   ├── IdeaDetailViewModel.swift
│   │   └── CreateIdeaViewModel.swift
│   ├── Views/
│   │   ├── Authentication/         # ログイン/サインアップ
│   │   ├── Family/                 # グループ管理
│   │   ├── Ideas/                  # アイデア一覧/詳細/作成
│   │   ├── Comments/               # コメント
│   │   ├── Voting/                 # 投票
│   │   └── Settings/               # 設定
│   ├── Services/
│   │   ├── CrowdsourceDataService.swift  # プロトコル
│   │   ├── LocalDataService.swift        # SwiftData実装
│   │   ├── FirebaseDataService.swift     # Firebase実装
│   │   └── SyncService.swift             # 同期管理
│   └── Assets.xcassets/
├── AsaCrowdsourceTests/
└── project.yml
```

---

## データモデル

### Idea（アイデア）
```swift
@Model
final class Idea {
    @Attribute(.unique) var id: UUID
    var title: String              // タイトル（必須、最大100文字）
    var description: String        // 説明（任意、最大1000文字）
    var categoryRawValue: String   // カテゴリ
    var statusRawValue: String     // ステータス
    var authorId: String
    var authorName: String
    var createdAt: Date
    var updatedAt: Date
    var voteCount: Int = 0
    var commentCount: Int = 0
    var firestoreId: String?       // Firebase連携用
}
```

### IdeaCategory（カテゴリ）
- familyTrip: 家族旅行 ✈️
- weekend: 週末の過ごし方 ☀️
- parenting: 子育て 👨‍👩‍👧
- shopping: 買い物 🛒
- homeImprovement: 住まい 🏠
- meal: 食事・レシピ 🍽️
- event: イベント 📅
- health: 健康・運動 ❤️
- other: その他 💡

### IdeaStatus（ステータス）
- proposed: 提案中
- discussing: 議論中
- approved: 承認済み
- inProgress: 実行中
- completed: 完了
- archived: アーカイブ

---

## 実装フェーズ

### Phase 1: 基盤構築（3-4日）
- [ ] project.yml作成、XcodeGen実行
- [ ] Models層実装（Idea, Comment, Vote, IdeaCategory, IdeaStatus）
- [ ] FamilyGroup, Member（AsaFamilySyncから移植）
- [ ] LocalDataService実装（SwiftData）
- [ ] 基本ViewModel実装（IdeaListViewModel）
- [ ] 単体テスト作成

### Phase 2: UI実装（4-5日）
- [ ] Authentication Views（Login, SignUp - モック認証）
- [ ] Family Views（Dashboard, Create, Join, Invite）
- [ ] Ideas Views（List, Card, Detail, Create, Edit）
- [ ] Comments Views（List, Row, Add）
- [ ] Voting Views（Button, Summary）
- [ ] Settings View
- [ ] TabView構造

### Phase 3: Firebase統合（3-4日）
- [ ] Firebase SDK導入（project.yml更新）
- [ ] FirebaseAuthService実装
- [ ] FirebaseDataService実装
- [ ] SyncService実装（ローカル/リモート同期）
- [ ] リアルタイムリスナー実装
- [ ] オフラインキャッシュ対応

### Phase 4: 仕上げ（2-3日）
- [ ] エラーハンドリング強化
- [ ] アニメーション追加（0.2秒 easeInOut）
- [ ] アクセシビリティ対応
- [ ] README.md作成
- [ ] Docs/Notes/Day93-AsaCrowdsource.md作成
- [ ] UIテスト実装

---

## 重要ファイル（参考）

### AsaFamilySyncから流用
1. `/Apps/AsaFamilySync/AsaFamilySync/Services/LocalFamilyDataService.swift`
   - グループ管理、招待コード方式の実装パターン

2. `/Apps/AsaFamilySync/project.yml`
   - Firebase SDK統合の設定パターン

3. `/Apps/AsaFamilySync/AsaFamilySync/Models/FamilyGroup.swift`
   - グループモデル、招待コード生成

---

## project.yml 設定

```yaml
name: AsaCrowdsource
options:
  bundleIdPrefix: com.asaapps
  deploymentTarget:
    iOS: "17.0"

targets:
  AsaCrowdsource:
    type: application
    platform: iOS
    sources: [AsaCrowdsource]
    resources: [AsaCrowdsource/Assets.xcassets]
    settings:
      INFOPLIST_KEY_CFBundleDisplayName: "家族のアイデア共有"
      INFOPLIST_KEY_UIBackgroundModes: "fetch remote-notification"
      OTHER_SWIFT_FLAGS: "$(inherited) -DFIREBASE_ENABLED"
    dependencies:
      - sdk: SwiftData.framework
      - package: AsaUIKit
      - package: Firebase
        product: FirebaseAuth
      - package: Firebase
        product: FirebaseFirestore

packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    from: 11.0.0
```

---

## テスト戦略

### Unit Tests（目標: 85%カバレッジ）
- Models: Idea, Comment, Vote の初期化・計算プロパティ
- ViewModels: フィルタ、ソート、CRUD操作
- Services: LocalDataService の永続化

### Integration Tests（目標: 60%カバレッジ）
- 認証→グループ参加→アイデア投稿フロー
- オフライン時のキュー処理

### UI Tests
- アイデア作成フロー
- 投票フロー

---

## 検証方法

1. **ビルド確認**
   ```bash
   cd Apps/AsaCrowdsource
   xcodegen generate
   xcodebuild -project AsaCrowdsource.xcodeproj -scheme AsaCrowdsource -destination 'platform=iOS Simulator,name=iPhone 16'
   ```

2. **テスト実行**
   ```bash
   swift test
   ```

3. **動作確認**
   - グループ作成→招待コード表示
   - アイデア投稿→一覧表示
   - 投票→カウント反映
   - コメント追加→リアルタイム反映

---

## 将来の拡張候補

- **SharePlay/GroupActivities**: FaceTime統合でリアルタイムブレインストーミング
- **CloudKit Sharing**: Apple純正同期（Firebaseの代替）
- **AIアシスト**: iOS 18 Foundation Modelsでアイデア分析・提案
