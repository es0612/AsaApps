# AsaFamilyTree 家系図表示 刷新プラン

## Context

SNSデモ動画撮影の一環として AsaFamilyTree を起動したところ、家系図ビューで以下の視認性問題が確認された：

1. **離別配偶者線が混入**：山田一郎と遠方の山田美咲を結ぶ赤線が画面中央を斜めに横切り、他の配線と交差してごちゃごちゃ見える（`Marriage.divorceDate` が配線生成で無視されている）
2. **配偶者ペアが離れ、兄弟が中央に集まらない**：世代別横一列配置だけで血縁の近さを無視しているため、配線距離が長くなる
3. **色分けが不明瞭**：配偶者線（ピンク #CC6680）と女性ノード枠（同色）が被って判別できず、離別/現配偶者の区別もない。凡例も存在しない
4. **ブランド分断**：AsaColors（温かい茶系）を使わず独自RGB で原色寄りの青・ピンク。他アプリと世界観が揃っていない

目標は「SNSデモ動画でも映える、スタイリッシュで関係性が直感的に読み取れる家系図」に刷新することである。スコープは **Level 1（バグ修正）+ Level 2（配置改善）+ 視覚刷新（AsaColors 化・凡例・選択ハイライト）** の3層で、Level 3（Reingold-Tilford 等の本格的木レイアウト刷新）は見送る（現行データ規模 13 人で過剰）。

---

## 確定した設計判断（ユーザー合意済み）

| 項目 | 確定内容 |
|---|---|
| スコープ | 視覚刷新 + 配置改善 + バグ修正（Level 1+2） |
| 選択ハイライト | 直系血族以外を opacity 0.35 にする機能を入れる |
| 性別色 | AsaColors の暖色系に統一（青・ピンクを廃止） |

### 最終色パレット

| 用途 | 色 | 備考 |
|---|---|---|
| 男性ノード枠 | `#C68C53` coffeeBrown | ブランドプライマリ |
| 女性ノード枠 | `#D9A679` softCream を濃くした暖色 | `Color(red: 0.85, green: 0.65, blue: 0.47)` |
| その他ノード枠 | `#7A918D` mutedSage | |
| 現配偶者線（二重） | `#C68C53` coffeeBrown | 2px オフセットの平行2本 |
| 離別配偶者線（破線） | `#7A918D` mutedSage | dash: [6, 4], 1pt |
| 親子線 / 兄弟バス線 | `#8B5A2B` mocha | 階段状 / T字 |
| 故人バッジ背景 | `softCream` / 文字は `mocha` | カード左上 8pt 角丸 |

---

## 実装タスク

### Phase 1: モデル・エンジン層（AsaFamilyTreeKit）

#### 1. `TreeConnection` / `ConnectionType` 拡張
**ファイル**: `Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Layout/TreeNode.swift`（L150-171周辺）

- `ConnectionType` を 4 case に拡張：`.parentChild` / `.currentSpouse` / `.divorcedSpouse` / `.siblingBus`
- `TreeConnection` に `isAdjacent: Bool` を追加（配偶者が隣接しているかを保持、描画判断に使う）
- `lineColor` は `CGColor` で返す既存方式を維持しつつ、`lineWidth: CGFloat`、`isDashed: Bool`、`isDouble: Bool` を computed property で追加

#### 2. `TreeLayoutEngine.generateConnections()` の修正
**ファイル**: `Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Services/TreeLayoutEngine.swift`（L223-251）

- 配偶者接続生成時に `marriage.isCurrentlyMarried`（`divorceDate == nil`）をチェック
  - 現婚：`.currentSpouse`、`isAdjacent` を「X 座標差が `nodeSize.width + horizontalSpacing * 1.2` 以内か」で判定
  - 離婚：`.divorcedSpouse`、遠距離でも破線は引く（あくまで副次線として）
- 同一親ペアから 2 人以上の子がいる場合、親子線を個別に引くのではなく **`.siblingBus` 接続を親ペア中間Y に一本 + 各子の上端から垂直線** の形で生成
  - 親が 1 人だけの子、兄弟が 1 人のみの子は従来どおり `.parentChild` 階段

#### 3. `groupBySpouse()` と `adjustChildPositions()` の強化
**ファイル**: 同上 L99-162

- `groupBySpouse()`: 「前世代のペアごとに子をグルーピング → ペア単位で currentX を進める」に変更。同じ親ペアの兄弟が常に隣接する
- `adjustChildPositions()`: トップダウン→ボトムアップの 2 パス化
  - **パス 1**: 兄弟グループのトータル幅（= 兄弟数 × (nodeWidth + horizontalSpacing)）を計算、親ペア中心 X に一括オフセット
  - **パス 2**: `resolveOverlaps()` を世代ごとに通す（既存関数流用）

#### 4. `FamilyTree.directBloodline(of:)` の追加
**ファイル**: `Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Models/FamilyTree.swift`（既存）

- `public func directBloodline(of member: FamilyMember) -> Set<UUID>` を追加
- BFS で祖先（親 → 親 → …）、子孫（子 → 子 → …）、現配偶者を集める
- 本人の UUID も含める
- **Schema 変更なし**（計算のみのメソッド）

#### 5. `Gender` の色刷新
**ファイル**: `Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Models/Gender.swift`

- `nodeBorderColor` / `nodeBackgroundColor` の RGB を以下に差し替え：
  - male: coffeeBrown `Color(red: 0.78, green: 0.55, blue: 0.33)`
  - female: `Color(red: 0.85, green: 0.65, blue: 0.47)`（softCream を濃くした暖色）
  - other: mutedSage `Color(red: 0.48, green: 0.57, blue: 0.55)`
- `Package.swift` に AsaUIKit 依存を**追加しない**（循環回避）。代わりにコメントで対応する AsaColors 名を明記

---

### Phase 2: View 層（AsaFamilyTree アプリ）

#### 6. `ConnectionStyle.swift` 新規作成
**ファイル（新規）**: `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/ConnectionStyle.swift`

- `ConnectionType` → `SwiftUI.Color` / `StrokeStyle` の変換を提供する extension
- Kit 層と AsaUIKit を分離するためアプリ側で集約マッピング
- `AsaUIKit.AsaColors` を import して利用

#### 7. `ConnectionLineView` の描画刷新
**ファイル**: `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/TreeVisualizationView.swift`（L169-198）

- switch を 4 ケースに拡張：
  - `.parentChild`: 現行の階段状、`lineCap: .round` 追加
  - `.currentSpouse`: 2px オフセットの平行 Path を 2 本（= 記号風）
  - `.divorcedSpouse`: `StrokeStyle(lineWidth: 1, dash: [6, 4])` で直線。`isAdjacent == false` なら中央にラベル無しの小マーカー（◇）を置いてもよい
  - `.siblingBus`: 親の下端中央 → 下に verticalSpacing/2 降りた共通Y で横線 → 各子の上端へ垂直線（T字）
- `dimmed: Bool` プロパティを追加、`true` なら全体 `.opacity(0.25)`

#### 8. `MemberNodeView` の刷新
**ファイル**: `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/MemberNodeView.swift`

- 故人判定（`member.deathDate != nil`）でカード全体を `.saturation(0.15)` + `.opacity(0.85)`、左上に「没」バッジ（softCream 背景、mocha 文字、8pt 角丸、10pt フォント）
- カード背景を `AsaColors.cardBackground`、影を `.shadow(color: AsaColors.mocha.opacity(0.15), radius: 3, x: 0, y: 1)`
- `dimmed: Bool` プロパティを追加：`true` なら `.opacity(0.35)` + `.saturation(0.3)`
- プロフィール画像のアイコン色もブランド化（`Color(AsaColors.coffeeBrown)`）

#### 9. `FamilyTreeViewModel` に選択ハイライト状態を追加
**ファイル**: `Apps/AsaFamilyTree/AsaFamilyTree/ViewModels/FamilyTreeViewModel.swift`

- `var highlightedIDs: Set<UUID>?` を追加（nil なら全員通常表示）
- `selectedMember` 変更時に `tree.directBloodline(of: member)` を呼んで `highlightedIDs` をセット
- `clearSelection()` で nil に戻す

#### 10. `TreeVisualizationView` に選択ハイライトを伝搬
**ファイル**: `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/TreeVisualizationView.swift`

- `MemberNodeView` / `ConnectionLineView` の各呼び出しに `dimmed: viewModel.shouldDim(node.member.id)` を渡す
- `shouldDim` は `highlightedIDs != nil && !highlightedIDs!.contains(id)`
- 接続線の dimmed 判定は「`from` か `to` のいずれかが非ハイライト」なら dimmed
- ノードタップで `selectedMember = member` / 2 回目で解除、空白タップで全解除（`onTapGesture` の `contentShape(Rectangle())`）

#### 11. `TreeLegendView` 新規作成
**ファイル（新規）**: `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/TreeLegendView.swift`

- 画面右下に `safeAreaInset(edge: .bottom)` または `overlay(alignment: .bottomTrailing)` で配置（`ScrollView` の**外側**、zoom/pan の影響を受けない）
- 折りたたみ：`@State private var isExpanded = false`、初期はアイコンのみ、タップで展開
- 項目：
  - 親子線（mocha 階段）
  - 現配偶者（coffeeBrown 二重線 =）
  - 離別配偶者（mutedSage 破線）
  - 兄弟バス（mocha T字）
  - 男性カード色
  - 女性カード色
  - 故人バッジ
- 背景 `AsaColors.cardBackground`、`shadow`、12pt 角丸

---

## データモデル変更サマリ

- `Marriage` / `FamilyMember`: **変更なし**（`divorceDate` は既存、参照を増やすだけ）
- `TreeConnection`: `isAdjacent: Bool` 追加、`ConnectionType` に `.currentSpouse` / `.divorcedSpouse` / `.siblingBus` を追加
- `FamilyTree`: `directBloodline(of:)` メソッド追加（スキーマ変更なし）
- `Gender.nodeBorderColor` / `nodeBackgroundColor`: RGB 値の差し替えのみ

---

## 新規ファイル

| パス | 責務 |
|---|---|
| `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/ConnectionStyle.swift` | `ConnectionType` → SwiftUI Color / StrokeStyle マッピング |
| `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/TreeLegendView.swift` | 折りたたみ式凡例オーバーレイ |

---

## 重要ファイル（修正対象）

- `Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Services/TreeLayoutEngine.swift`
- `Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Layout/TreeNode.swift`
- `Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Models/Gender.swift`
- `Packages/AsaFamilyTreeKit/Sources/AsaFamilyTreeKit/Models/FamilyTree.swift`
- `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/TreeVisualizationView.swift`
- `Apps/AsaFamilyTree/AsaFamilyTree/Views/Tree/MemberNodeView.swift`
- `Apps/AsaFamilyTree/AsaFamilyTree/ViewModels/FamilyTreeViewModel.swift`

---

## 動作確認手順

### ビルド
```bash
cd Apps/AsaFamilyTree
xcodegen generate
xcodebuild -project AsaFamilyTree.xcodeproj -scheme AsaFamilyTree \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

- Swift 6 strict concurrency 警告なし
- `@Model` + Sendable 衝突なし（既存通り）

### ユニットテスト（AsaFamilyTreeKit）
```bash
cd Packages/AsaFamilyTreeKit
swift test
```

- `TreeLayoutEngine` のテストで離婚配偶者が `.divorcedSpouse` になることを確認
- `FamilyTree.directBloodline(of:)` で BFS 結果が期待どおりか確認（山田一郎 → 太郎・花子・さくら・翔太・陽翔・結菜・美咲が含まれ、鈴木幸子は含まれない 等）

### 目視確認（iPhone 17 Pro シミュレータ）
`SampleDataService.loadSampleData()` の山田家 4 世代 13 人で：
1. 現配偶者のペア（太郎-花子、一郎-美咲、健太-幸子、翔太-由美）に **coffeeBrown の二重線**が出る
2. `setupMarriages` に暫定で 1 組 `divorceDate` を追加して**破線表示**を確認、元に戻す
3. 兄弟（翔太・さくら、大輝・あかり、陽翔・結菜）が**親ペア中央揃え**で **T字バス線**で接続される
4. ノードをタップ → 直系以外が薄くなる。再タップまたは背景タップで全員通常に戻る
5. 凡例が右下に表示され、ズーム/パンで動かない
6. 故人（山田太郎 1935-2020）に「没」バッジが出て、カードが少し彩度落ちで表示される

### Chrome / SNS デモ動画想定
- 画面録画で関係性が「色・線種・位置」から一目でわかることを確認
- 凡例を開いた状態・閉じた状態の両方を撮る

---

## スコープ外

- **Level 3（Reingold-Tilford 木レイアウト + スーパーノード展開）**：13 人規模では過剰。将来 50 人超データで再検討
- **再婚で配偶者が別世代に現れるケースの完全補正**：サンプルにないため、現状は `.divorcedSpouse` 破線と `isAdjacent == false` マーカーで対処
- **DAG 完全対応（連れ子・兄弟半血などの交差最小化）**：`resolveOverlaps()` の単純押し出しで止める
- **レイアウト変更時のアニメーション**：描画負荷懸念、デモ動画用途では不要
- **プロフィール画像表示**（`MemberNodeView` L22 の TODO）：既存 TODO のまま据え置き
- **AsaFamilyTreeKit から AsaUIKit への Package 依存追加**：循環・公開範囲を避けるため、色値は複製定義する

---

## 実装順の推奨

1. Kit 層のモデル拡張（`TreeConnection` / `ConnectionType`、`Gender` 色、`FamilyTree.directBloodline`）
2. `TreeLayoutEngine` のロジック修正（`generateConnections` → `groupBySpouse` → `adjustChildPositions`）
3. アプリ層の `ConnectionStyle.swift` / `ConnectionLineView` / `MemberNodeView` 刷新
4. `FamilyTreeViewModel` の選択ハイライト対応と `TreeVisualizationView` 伝搬
5. `TreeLegendView` 追加
6. ビルド → サンプルデータで目視確認 → デモ動画撮影

各フェーズ終了時に `xcodebuild build` を通しつつ進めること（Swift 6 Sendable 警告に注意）。
