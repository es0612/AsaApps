# AsaFamilyTree (#91) デモ動画用サンプルデータ実装プラン

## Context

AsaFamilyTree（家系図作成ツール、アプリ #91）は起動時に完全に空の状態で表示される。SNSデモ動画撮影のために、リアルな日本人家族の家系図データを自動投入する機能が必要。#84〜#90 のアプリで実装済みのサンプルデータ生成パターンに倣う。

**現状の問題:**
- 全タブ（家系図・メンバー・統計）が「データがありません」表示
- デモ動画を撮るには手動で家系図作成→メンバー追加→関係設定が必要
- 統計チャートも完全に空

## 実装方針

### 新規作成: 1ファイル

**`Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Services/SampleDataService.swift`**

- `@MainActor public final class SampleDataService`
- `init(modelContext: ModelContext)` で ModelContext を受け取る
- `public func loadSampleData() throws` で一括投入
- 4世代・15人の「山田家」家系図 + 婚姻関係4組

### 変更: 1ファイル

**`Apps/AsaFamilyTree/AsaFamilyTree/ContentView.swift`**

- `@Environment(\.modelContext)` を追加
- `.task` 内に `loadSampleDataIfNeeded()` を追加
- UserDefaults フラグで初回のみ実行

## サンプルデータ: 山田家の家系図（4世代・15人）

### 第1世代（祖父母）
| 名前 | 性別 | 生年月日 | 没年月日 | 出生地 | メモ |
|------|------|---------|---------|--------|------|
| 山田 太郎 | 男性 | 1935-03-15 | 2020-11-08 | 東京都 | 大工の棟梁として活躍 |
| 山田 花子 (旧姓:佐藤) | 女性 | 1938-07-22 | - | 神奈川県 | 茶道を50年以上 |

婚姻: 1960-04-10（東京都）

### 第2世代（親）
| 名前 | 性別 | 生年月日 | 出生地 | メモ |
|------|------|---------|--------|------|
| 山田 一郎 | 男性 | 1962-05-20 | 東京都 | 長男。会社経営 |
| 山田 美咲 (旧姓:田中) | 女性 | 1965-09-03 | 千葉県 | 小学校教諭 |
| 鈴木 幸子 (旧姓:山田) | 女性 | 1967-12-11 | 東京都 | 長女。看護師 |
| 鈴木 健太 | 男性 | 1964-01-28 | 埼玉県 | 幸子の夫。公務員 |

親子: 太郎&花子 → 一郎, 幸子
婚姻: 一郎×美咲 (1990-06-15)、健太×幸子 (1992-10-20)

### 第3世代（子）
| 名前 | 性別 | 生年月日 | 出生地 | メモ |
|------|------|---------|--------|------|
| 山田 翔太 | 男性 | 1992-08-14 | 東京都 | ITエンジニア |
| 山田 由美 (旧姓:高橋) | 女性 | 1994-04-25 | 大阪府 | デザイナー |
| 山田 さくら | 女性 | 1995-03-03 | 東京都 | 医師 |
| 鈴木 大輝 | 男性 | 1993-11-07 | 埼玉県 | 弁護士 |
| 鈴木 あかり | 女性 | 1996-06-19 | 埼玉県 | 薬剤師 |

親子: 一郎&美咲 → 翔太, さくら / 健太&幸子 → 大輝, あかり
婚姻: 翔太×由美 (2020-03-21)

### 第4世代（孫）
| 名前 | 性別 | 生年月日 | 出生地 | メモ |
|------|------|---------|--------|------|
| 山田 陽翔 | 男性 | 2022-01-15 | 東京都 | 翔太の長男 |
| 山田 結菜 | 女性 | 2024-06-30 | 東京都 | 翔太の長女 |

親子: 翔太&由美 → 陽翔, 結菜

### 統計面の見栄え
- 男性8人 / 女性7人（バランス良好）
- 故人1人 / 存命14人
- 4世代・婚姻4組
- 年齢分布: 1歳〜87歳（チャートに適度な分散）

## 実装手順

### Step 1: SampleDataService.swift を新規作成

パス: `Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Services/SampleDataService.swift`

```swift
@MainActor
public final class SampleDataService {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func loadSampleData() throws {
        // 1. FamilyTree 作成 → insert
        // 2. 15人の FamilyMember 作成 → insert → tree.addMember()
        // 3. addChild() で親子関係設定（双方向自動）
        // 4. Marriage 作成 → insert → setPartners() で婚姻設定
        // 5. try modelContext.save() で一括保存
    }
}
```

**実装順序の重要ポイント:**
- 全オブジェクトを `modelContext.insert()` してからリレーション設定（SwiftData制約）
- `addChild()` は `addParent()` も自動設定する（双方向）
- `Marriage.setPartners()` も双方向の `marriages` 配列を設定

### Step 2: ContentView.swift を変更

```swift
// 追加
@Environment(\.modelContext) private var modelContext

// .task 内を変更
.task {
    await viewModel.loadInitialData()
    loadSampleDataIfNeeded()
}

// メソッド追加
private func loadSampleDataIfNeeded() {
    let key = "AsaFamilyTree_SampleDataLoaded_v1"
    guard !UserDefaults.standard.bool(forKey: key) else { return }
    
    let service = SampleDataService(modelContext: modelContext)
    do {
        try service.loadSampleData()
        UserDefaults.standard.set(true, forKey: key)
        Task { await viewModel.loadInitialData() }  // リフレッシュ
    } catch {
        print("サンプルデータ投入エラー: \(error)")
    }
}
```

### Step 3: ビルド確認

```bash
cd Apps/AsaFamilyTree
xcodegen generate
xcodebuild -project AsaFamilyTree.xcodeproj -scheme AsaFamilyTree -sdk iphonesimulator build
```

## 検証項目

1. **初回起動**: EmptyStateView ではなく家系図が表示される
2. **家系図タブ**: 4世代のツリーが正しく描画、配偶者が横並び
3. **メンバータブ**: 15人が世代別にグループ表示
4. **統計タブ**: 総メンバー数・性別分布・年齢分布・世代別チャートが表示
5. **2回目起動**: サンプルデータが重複投入されない（UserDefaultsフラグ）
6. **設定タブ**: 家系図削除後も再投入されない

## 参考: 既存パターンとの一貫性

| 観点 | AsaCommunityKit | AsaPapaHub | 今回 |
|------|----------------|------------|------|
| サービス配置 | パッケージ内 | アプリ内 | **パッケージ内** |
| フラグ管理 | データ有無チェック | UserDefaults | **UserDefaults** |
| 呼び出し元 | ContentView.task | ContentView.init | **ContentView.task** |
| クラス名 | SampleDataService | SampleDataLoader | **SampleDataService** |
