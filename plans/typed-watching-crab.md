# AsaFamilyTree 実装計画

## 概要

**AsaFamilyTree**は家系図作成ツールです（アプリ#91 - 上級カテゴリ）。
複雑な家族関係をビジュアル表示し、iCloud同期とエクスポート機能を提供します。

## 技術選択

| 項目 | 選択 | 理由 |
|------|------|------|
| データ永続化 | SwiftData | 個人データ向けiCloud同期が簡単、既存パターンに準拠 |
| UI | SwiftUI + Canvas | カスタムツリー描画、ズーム/パン対応 |
| チャート | Swift Charts | 統計表示（年齢分布、世代別人数） |
| 状態管理 | @MainActor @Observable | プロジェクト標準パターン |
| テスト | Swift Testing | @Test, #expect構文 |

> **注意**: SwiftDataはCloudKit共有（複数ユーザー間）未対応。将来の家族間共有はFirebase統合で対応可能（条件付きコンパイル）

## データモデル

```
FamilyTree (1) ─────┬───── (*) FamilyMember
                    │           │
                    │           ├── parents: [FamilyMember]  (N:N)
                    │           ├── children: [FamilyMember] (N:N)
                    │           └── marriages: [Marriage]    (1:N)
                    │
                    └───── (*) Marriage
                                └── partners: [FamilyMember] (常に2人)
```

### 主要モデル

- **FamilyMember**: id, firstName, lastName, gender, birthDate, deathDate, profileImageData, parents[], children[], marriages[]
- **Marriage**: id, marriageDate, divorceDate, partners[]
- **FamilyTree**: id, name, members[]
- **Gender**: enum (male, female, other) - 性別アイコン・カラー定義

## 画面構成

```
TabView
├── Tab 1: 家系図ビュー (TreeVisualizationView)
│   ├── Canvas描画（ノード + 接続線）
│   ├── ピンチズーム (0.3x〜3.0x)
│   ├── パンジェスチャー
│   └── フローティング追加ボタン
│
├── Tab 2: メンバーリスト (MemberListView)
│   ├── 検索バー
│   ├── フィルター（世代、存命/故人）
│   └── メンバーカード一覧
│
├── Tab 3: 統計 (StatisticsView)
│   ├── 世代数、総人数、存命人数
│   ├── 年齢分布チャート
│   └── 世代別人数チャート
│
└── Tab 4: 設定 (SettingsView)
    ├── iCloud同期状態
    ├── エクスポート（PDF/画像）
    └── データ管理
```

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
│       ├── Statistics/     # StatisticsView, GenerationChart
│       ├── Export/         # ExportSheet
│       └── Settings/       # SettingsView
├── AsaFamilyTreeTests/
└── AsaFamilyTreeUITests/

Packages/AsaFamilyTreeKit/
├── Sources/AsaFamilyTreeKit/
│   ├── Models/            # FamilyMember, Marriage, FamilyTree, Gender
│   ├── ViewModels/        # FamilyTreeViewModel, TreeStatistics
│   ├── Services/          # FamilyTreeDataService, TreeLayoutEngine, ExportService
│   ├── Layout/            # TreeNode, TreeLayoutAlgorithm
│   └── Errors/            # FamilyTreeError
└── Tests/
```

## 実装フェーズ

### Phase 1: 基盤構築
- [ ] `Apps/AsaFamilyTree/project.yml` 作成
- [ ] `Packages/AsaFamilyTreeKit/Package.swift` 作成
- [ ] データモデル実装（FamilyMember, Marriage, FamilyTree, Gender）
- [ ] FamilyTreeDataService実装（CRUD操作）
- [ ] Unit Tests作成（モデル、サービス）

### Phase 2: 家系図ビジュアライゼーション
- [ ] TreeLayoutEngine実装（座標計算アルゴリズム）
- [ ] TreeNode構造体実装
- [ ] TreeVisualizationView実装（Canvas描画）
- [ ] MemberNodeView実装（ノードUI）
- [ ] ズーム・パンジェスチャー実装
- [ ] 接続線描画（親子: 縦線、配偶者: 横線）

### Phase 3: UI/UX完成
- [ ] ContentView（TabView構造）
- [ ] MemberListView（検索・フィルター付き一覧）
- [ ] MemberDetailView（詳細表示・編集）
- [ ] AddMemberSheet（新規メンバー追加）
- [ ] RelationshipSheet（親子・配偶者関係設定）
- [ ] StatisticsView（Charts統合）
- [ ] SettingsView

### Phase 4: 上級機能・仕上げ
- [ ] iCloud同期設定・テスト
- [ ] ExportService実装（PDF/画像エクスポート）
- [ ] PhotosPicker統合（プロフィール写真）
- [ ] UI Tests作成
- [ ] ドキュメント作成（`Docs/Notes/Day91-AsaFamilyTree.md`）

## 主要ファイル

| ファイル | 役割 |
|----------|------|
| `Packages/AsaFamilyTreeKit/Sources/.../Models/FamilyMember.swift` | 家族メンバーモデル（@Model） |
| `Packages/AsaFamilyTreeKit/Sources/.../Services/TreeLayoutEngine.swift` | ツリーレイアウト計算 |
| `Packages/AsaFamilyTreeKit/Sources/.../ViewModels/FamilyTreeViewModel.swift` | メインViewModel |
| `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/TreeVisualizationView.swift` | 家系図Canvas描画 |
| `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/MemberNodeView.swift` | メンバーノードUI |

## 検証方法

### ビルド確認
```bash
cd Apps/AsaFamilyTree
xcodegen generate
xcodebuild -project AsaFamilyTree.xcodeproj -scheme AsaFamilyTree -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### テスト実行
```bash
cd Packages/AsaFamilyTreeKit
swift test
```

### 機能検証チェックリスト
- [ ] メンバー追加・編集・削除が動作する
- [ ] 親子関係・配偶者関係を設定できる
- [ ] 家系図がCanvas上に正しく描画される
- [ ] ピンチズーム・パンが動作する
- [ ] 統計が正しく計算される
- [ ] PDF/画像エクスポートが動作する
- [ ] iCloud同期が有効（設定済みの場合）

## 参考リソース

- [objc.io - Drawing Trees in SwiftUI](https://www.objc.io/blog/2019/12/16/drawing-trees/)
- [SwiftData CloudKit Sync](https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit)
- [Core Data vs SwiftData 2025](https://distantjob.com/blog/core-data-vs-swiftdata/)

## 既存パターン参照

- `Apps/AsaPortfolio/project.yml` - project.yml構造
- `Apps/AsaPortfolio/AsaPortfolio/ViewModels/PortfolioViewModel.swift` - @MainActor @Observable パターン
- `Apps/AsaPortfolio/AsaPortfolio/Views/Charts/AllocationPieChart.swift` - Swift Charts
- `Packages/AsaUIKit/Sources/AsaUIKit/Colors/AsaColors.swift` - ブランドカラー
