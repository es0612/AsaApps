# Day 100 - AsaFamilyTree 家系図ビジュアライゼーション刷新

## 概要

SNSデモ動画撮影準備の一環で、AsaFamilyTree の家系図表示が **配線のごちゃつき・色分けの不明瞭さ** という課題を抱えていたため、視覚刷新・配置改善・バグ修正の3層で刷新した。

- プラン: `plans/image-1-asafamilytree-gleaming-hinton.md`
- スコープ: Level 1（バグ修正）+ Level 2（配置改善）+ 視覚刷新

## 改善前の問題点

1. **離別配偶者線が誤って描画されていた** — `Marriage.divorceDate` が配線生成で無視されていた
2. **世代別単純横並びで兄弟・配偶者が離散** — 山田一郎と山田美咲が画面を跨ぐ斜め線で結ばれていた
3. **配偶者線ピンク (#CC6680) と女性ノード枠 (同色) が混同** — 線種区別なし、凡例なし
4. **配偶者が別家系のメンバー（鈴木健太・山田由美）が世代 0 扱い** — 親が未登録の配偶者がルート扱いされ、祖父母と同じ行に配置される不具合
5. **AsaColors 未使用** — アプリ全体のブランド（温かい茶系）と家系図部分で印象が分断

## 実装した改善

### Kit 層 (AsaFamilyTreeKit)

| 変更ファイル | 内容 |
|---|---|
| `Layout/TreeNode.swift` | `ConnectionType` を 4 case に拡張：`.parentChild` / `.currentSpouse` / `.divorcedSpouse` / `.siblingBus`。`TreeConnection` に `isAdjacent`・`memberIds` を追加。色は AsaColors 相当 RGB を複製定義（依存循環回避） |
| `Models/Gender.swift` | 色を AsaColors 暖色系に変更。男性=coffeeBrown / 女性=#D9A679（softCream 濃色） / その他=mutedSage |
| `Models/FamilyTree.swift` | `directBloodline(of:) -> Set<UUID>` を BFS で実装（祖先・子孫・現配偶者を集める）。`calculateGenerations()` に `alignSpouseGenerations()` を追加（配偶者同士の世代差解消） |
| `Services/TreeLayoutEngine.swift` | `generateConnections` を刷新：現婚/離婚の分岐、兄弟2人以上で T字バス線を生成。`groupBySpouse` を「親ペアグループでソート」して兄弟を連続配置 |
| `ViewModels/FamilyTreeViewModel.swift` | `highlightedIDs: Set<UUID>?` 追加。`selectMember` で直系血族をセット、`shouldDim(id:)` 提供。初期 zoomScale を 0.55 に |

### アプリ層 (AsaFamilyTree)

| 変更ファイル | 内容 |
|---|---|
| `Views/Tree/ConnectionStyle.swift` 【新規】 | `ConnectionType` → SwiftUI Color / StrokeStyle マッピング |
| `Views/Tree/TreeLegendView.swift` 【新規】 | 折りたたみ可能な凡例オーバーレイ。画面右下に固定、ScrollView の外側で zoom/pan の影響を受けない |
| `Views/Tree/TreeVisualizationView.swift` | `ConnectionLineView` を 4 ケースに拡張：階段状・二重線（=）・破線・T字バス。ノードタップで直系ハイライト、空白タップで解除 |
| `Views/Tree/MemberNodeView.swift` | 故人バッジ「没」（softCream 背景・mocha 文字）、故人の彩度/不透明度を調整、選択枠 coffeeBrown、`dimmed`・`isSelected` プロパティ追加 |

## 技術的ハイライト

### 1. 二重線（=記号）表現

現配偶者を強調するため、2.5pt オフセットの平行 2 本の Path を ZStack で重ねる。
`ConnectionLineView.doubleLine` 内で水平/垂直の向きを `abs(from.y - to.y) < 0.5` で判定してオフセット方向を切り替え。

### 2. 兄弟バス線（T字）

`TreeLayoutEngine.generateParentChildConnections()` で同じ親ペアの兄弟が 2 人以上いるとき、`.siblingBus` 接続を生成：

```
親 (両親中心) ─┐
              │       ← .parentChild（縦線）
              ├─────── ← .siblingBus（横線バス）
              │   │
              子1  子2   ← .parentChild（縦線）
```

`parentGroupKey` = 両親 ID を昇順連結した文字列。この Key でグルーピング・重複排除。

### 3. 配偶者世代の整合

`alignSpouseGenerations()` を `calculateGenerations()` の最後に追加。配偶者がいて世代が低い方（=計算外れたルート扱いの配偶者）を、パートナーの世代に引き上げる。`propagateGeneration` を再度呼んで子孫にも世代更新を伝播。無限ループ防止で `iterations < members.count * 2` の安全装置付き。

### 4. 直系血族ハイライト

`FamilyTree.directBloodline(of:)` が BFS で祖先・子孫・現配偶者の ID 集合を返す。`FamilyTreeViewModel.selectMember` でこれを `highlightedIDs` にセット。ノードと接続線に `dimmed:` を伝搬して opacity 0.35 / opacity 0.25 で薄く表示。

接続線の dim 判定は `TreeConnection.memberIds.isSubset(of: highlightedIDs)` で、「関連メンバー全員が直系血族に含まれていれば濃く」のシンプルなルール。

## 色パレット

| 用途 | 色 | AsaColors 名 |
|---|---|---|
| 男性ノード枠 | #C68C53 | coffeeBrown |
| 女性ノード枠 | #D9A679 | softCream 濃色相当 |
| 現配偶者線（二重） | #C68C53 | coffeeBrown |
| 離別配偶者線（破線） | #7A918D | mutedSage |
| 親子線 / 兄弟バス線 | #8B5A2B | mocha |
| 故人バッジ背景 | softCream | - |
| カード背景 | 白 0.8 透明 | cardBackground |

## ビルド・テスト結果

```bash
# ビルド
xcodebuild -project AsaFamilyTree.xcodeproj -scheme AsaFamilyTree \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
# ** BUILD SUCCEEDED **

# テスト（AsaFamilyTreeKit）
swift test
# 7 tests passed
```

## 学び

1. **プラン時の想定と実装時の現実の差** — ViewModel がアプリ側と思っていたがパッケージ側にあった。プランに書いたパスを実装時に訂正する柔軟さが必要。
2. **レビュー駆動で気づく盲点** — advisor から「divorceDate を一時追加して破線を実際に確認する」検証手順の実施漏れを指摘された。コードレビューで「ビルド成功」と「期待機能が動く」は別物、という教訓。
3. **配偶者の世代整合は家系図の根幹** — 親未登録の配偶者を世代 0 扱いする仕様のままでは、どれだけ描画ロジックを改善しても配置が破綻する。根本原因を `FamilyTree` モデルレベルで修正したのが勝因。

## スコープ外（今後の拡張候補）

- Reingold-Tilford 木レイアウト（現在は 13 人規模で不要）
- 再婚・連れ子・半血の完全交差回避
- プロフィール画像表示（`hasProfileImage` の TODO のまま）
- `fit-to-screen` 自動ズーム（現在は固定値 0.55）

## 関連リンク

- Day 91 基礎実装ノート: `Docs/Notes/Day91-AsaFamilyTree.md`
- プラン: `plans/image-1-asafamilytree-gleaming-hinton.md`
