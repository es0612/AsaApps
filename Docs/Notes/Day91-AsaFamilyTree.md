# Day 91 - AsaFamilyTree（家系図作成ツール）実装

## 概要

**AsaFamilyTree**は、家族の歴史を記録・可視化するための家系図作成アプリです。
複雑な家族関係（親子、配偶者、兄弟姉妹）をビジュアルに表示し、統計情報とエクスポート機能を提供します。

### 主な機能
- 📊 **家系図ビジュアライゼーション**: Canvas描画による家系図表示
- 👥 **メンバー管理**: 家族メンバーのCRUD操作
- 💑 **関係管理**: 親子関係・配偶者関係の設定
- 📈 **統計表示**: Swift Chartsによる年齢分布・世代別人数グラフ
- 📤 **エクスポート**: PNG/PDF形式でのエクスポート
- ☁️ **iCloud同期**: SwiftDataによる自動同期対応

## 技術スタック

| カテゴリ | 技術 |
|----------|------|
| データ永続化 | SwiftData + iCloud同期 |
| UI | SwiftUI + Canvas |
| チャート | Swift Charts |
| 状態管理 | @MainActor @Observable |
| テスト | Swift Testing |
| パッケージ | AsaFamilyTreeKit（ローカルSPM）|

## アーキテクチャ

### MVVMパターン

```
ContentView (TabView)
├── TreeVisualizationView → FamilyTreeViewModel
├── MemberListView        → FamilyTreeViewModel
├── StatisticsView        → TreeStatistics
└── SettingsView          → FamilyTreeViewModel

AsaFamilyTreeKit (Package)
├── Models/     → FamilyMember, Marriage, FamilyTree, Gender
├── ViewModels/ → FamilyTreeViewModel
├── Services/   → FamilyTreeDataService, TreeLayoutEngine
├── Layout/     → TreeNode, TreeConnection, TreeLayout
└── Errors/     → FamilyTreeError
```

### データモデル

```swift
@Model
public final class FamilyMember {
    var id: UUID
    var firstName: String
    var lastName: String
    var genderRawValue: String
    var birthDate: Date?
    var deathDate: Date?
    var profileImageData: Data?
    var parents: [FamilyMember]  // N:N関係
    var children: [FamilyMember] // N:N関係
    var marriages: [Marriage]    // 1:N関係
}

@Model
public final class Marriage {
    var id: UUID
    var marriageDate: Date?
    var divorceDate: Date?
    var partners: [FamilyMember] // 常に2人
}
```

## 実装のポイント

### 1. SwiftDataでのN:N関係

```swift
// 親子関係の双方向リレーション
@Relationship(inverse: \FamilyMember.children)
public var parents: [FamilyMember] = []

@Relationship
public var children: [FamilyMember] = []
```

**ポイント**: `inverse:`で双方向リレーションを自動管理

### 2. ツリーレイアウトアルゴリズム

```swift
public func calculateLayout(for tree: FamilyTree) -> TreeLayout {
    // 1. 世代を計算
    tree.calculateGenerations()

    // 2. 世代別にグループ化
    let membersByGeneration = tree.membersByGeneration()

    // 3. 配偶者ペアを隣接配置
    let (pairs, singles) = groupBySpouse(members: members)

    // 4. 子を親の中心に調整
    adjustChildPositions(nodes: &nodes, ...)

    // 5. 重複を解消
    resolveOverlaps(nodes: &nodes, ...)
}
```

### 3. 循環参照の検出

```swift
private func wouldCreateCycle(parent: FamilyMember, child: FamilyMember) -> Bool {
    // 自分自身の親にはなれない
    if parent.id == child.id { return true }

    // 子孫が親になることはできない
    return isDescendant(of: child, potentialAncestor: parent)
}
```

### 4. Canvas描画

```swift
Canvas { context, size in
    // 接続線を描画
    for connection in layout.connections {
        // 階段状の接続線（親子）または直線（配偶者）
    }

    // ノードを描画
    for node in layout.nodes {
        // MemberNodeViewを配置
    }
}
```

## 画面構成

| タブ | 機能 |
|------|------|
| 家系図 | ツリービジュアライゼーション、ズーム・パン |
| メンバー | 一覧表示、検索、フィルター、詳細編集 |
| 統計 | グラフ表示（年齢分布、世代別人数、性別） |
| 設定 | 家系図管理、エクスポート、データ管理 |

## ディレクトリ構造

```
Apps/AsaFamilyTree/
├── project.yml
├── AsaFamilyTree/
│   ├── AsaFamilyTreeApp.swift
│   ├── ContentView.swift
│   └── Views/
│       ├── Tree/           # TreeVisualizationView, MemberNodeView
│       ├── Members/        # MemberListView, MemberDetailView, AddMemberSheet
│       ├── Relationships/  # RelationshipSheet
│       ├── Statistics/     # StatisticsView
│       ├── Export/         # ExportSheet
│       └── Settings/       # SettingsView
└── AsaFamilyTreeTests/

Packages/AsaFamilyTreeKit/
├── Sources/AsaFamilyTreeKit/
│   ├── Models/         # FamilyMember, Marriage, FamilyTree, Gender
│   ├── ViewModels/     # FamilyTreeViewModel
│   ├── Services/       # FamilyTreeDataService, TreeLayoutEngine
│   ├── Layout/         # TreeNode, TreeConnection, TreeLayout
│   └── Errors/         # FamilyTreeError
└── Tests/
```

## 学んだこと

### SwiftData N:N関係
- `@Relationship(inverse:)`で双方向リレーションを定義
- 配列同士の関係も自動追跡される

### 世代計算アルゴリズム
- BFS/DFSで親から子へ世代を伝播
- ルートメンバー（親がいない）を世代0として起点に

### Canvas vs GeometryReader
- 動的なグラフにはCanvasが適切
- ズーム・パンにはScaleEffectとoffset組み合わせ

### Swift Charts統合
- SectorMark（円グラフ）、BarMark（棒グラフ）
- innerRadiusでドーナツチャート化

## 今後の拡張案

1. **家族間共有**: Firebase統合で複数ユーザー間でのリアルタイム共有
2. **写真管理**: 各メンバーの写真ギャラリー
3. **タイムライン**: 家族の歴史イベントを時系列表示
4. **検索機能強化**: 関係性による検索（「祖父の兄弟」など）
5. **GEDCOM対応**: 家系図標準フォーマットのインポート/エクスポート

## 参考リソース

- [objc.io - Drawing Trees in SwiftUI](https://www.objc.io/blog/2019/12/16/drawing-trees/)
- [SwiftData CloudKit Sync](https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit)
- [Swift Charts Documentation](https://developer.apple.com/documentation/charts)

---

**実装日**: 2026年2月1日
**アプリ番号**: #91
**カテゴリ**: 上級
