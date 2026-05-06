# AsaEduGame 見直し計画

## Context

AsaEduGame アプリで以下3種類の問題が発生している。実機/シミュレータでの実行時に大量のエラーが出力されており、UX も「AI ぽい」と感じられるため見直しが必要。

1. **ランタイムエラー**: `No color named 'AsaMocha'/'AsaMutedSage'/'AsaDarkSlate' found in asset catalog` が連発
2. **CoreData エラー**: `File Device ID: 0` / `Device ID: 16777229` のミスマッチエラーが大量に出力
3. **デザイン課題**: 絵文字アイコン (🎮 📊 ⭐ 🏅 🔥 💯 など) が「AI が機械的に置いた」印象で、温かみのあるブランドガイドラインと噛み合わない

これらを根治して、4-8歳向け教育アプリとしての品質を上げる。

---

## 原因分析

### 問題1: Color アセット未定義

- **該当箇所**: `Apps/AsaEduGame/Sources/Views/Profile/BadgeCollectionView.swift:101`
- **コード**:
  ```swift
  .fill(isUnlocked
        ? Color(badge.emoji == "⭐" ? "AsaCoffeeBrown" : badge.rawValue.hashValue % 2 == 0 ? "AsaMocha" : "AsaMutedSage").opacity(0.15)
        : Color.gray.opacity(0.1))
  ```
- **理由**: `Color("AsaMocha")` 形式は Asset Catalog から色を引くが、AsaEduGame の `Assets.xcassets` には AppIcon しかなく、色定義は存在しない。本来 `AsaColors.mocha`(AsaUIKit) を使うべき箇所。
- **ファイル内の他のColor参照は全て `AsaColors.xxx` で正常**。この1箇所だけ書き方が違っている。

### 問題2: ModelContainer 二重初期化

- **該当箇所**:
  - `Apps/AsaEduGame/Sources/AsaEduGameApp.swift:15-20` — App scope で `.modelContainer(for: [...])` modifier
  - `Apps/AsaEduGame/Sources/ContentView.swift:36` — ContentView.init() 内で `EduGameDataService()` 生成
  - `Packages/AsaEduGameKit/Sources/AsaEduGameKit/Services/EduGameDataService.swift:18-38` — 内部で独自 `ModelContainer` を作成
- **理由**: 同一スキーマに対して **2つの ModelContainer が同じ SQLite ファイルを開く**。SwiftData は WAL モードで動作するため、別々の Container がメインスレッドで競合し、`File Device ID: 0` (未マウント扱い) と実 Device ID `16777229` のミスマッチが報告される。
- **ContentView の `@Environment(\.modelContext)` は宣言されているが実際の操作は dataService 経由**で行われており、App 側の modelContainer は実質使われていない。

### 問題3: 絵文字 vs SF Symbols のデザイン整合性

絵文字使用箇所(計12箇所、5ファイル)を2カテゴリに分類(ユーザー方針: アバター以外を全置換):

| 種別 | 場所 | 判定 | 理由 |
|------|------|------|------|
| **アバター絵文字** (🐱🐶🐰🐻🐼🦊🐸🐧🦁🐯🐮🐷🐵🦄🐲) | `ProfileView.swift:20-22` | **残す** | ユーザー識別子。子供向けアプリの意図的な設定/カスタマイズ要素 |
| **バッジ絵文字** (🏆⭐🔥📚🎯🎨🧩🌟🦁🦄など各バッジ固有) | `BadgeDefinition` (Kit内) | **置換** | SF Symbols + ブランドカラーで質感を統一 |
| **UI iconography** (🎮📊⭐🏅🔥💯) | ヘッダー/統計タイプ表示 | **置換** | ブランドカラー + SF Symbols でプロらしく |

アバターは「ユーザーが自分のキャラを選ぶ」明示的な選択肢なので残す。それ以外の装飾・アイコン用途は全て SF Symbols 化することで、AsaFlashcardPro と同等の質感に揃える。

---

## 実装計画

### Phase 1: ランタイムエラー解消

#### 1-1. Color アセット参照を AsaColors に統一

**対象**: `Apps/AsaEduGame/Sources/Views/Profile/BadgeCollectionView.swift:89-103`

`badgeCell(badge:)` 関数の頭でバッジカラーをローカル変数として算出し、`AsaColors.xxx` を参照する形に変更:

```swift
private func badgeCell(badge: BadgeDefinition) -> some View {
    let isUnlocked = isBadgeUnlocked(badge)
    let badgeColor: Color = {
        if badge.emoji == "⭐" { return AsaColors.coffeeBrown }
        return badge.rawValue.hashValue % 2 == 0 ? AsaColors.mocha : AsaColors.mutedSage
    }()
    return Button {
        ...
    } label: {
        ...
        .fill(isUnlocked ? badgeColor.opacity(0.15) : Color.gray.opacity(0.1))
        ...
    }
}
```

**効果**: ランタイム文字列ルックアップ → ビルド時型チェック。`No color named` エラーが完全消滅。

#### 1-2. ModelContainer 二重初期化の解消

**対象**: `Apps/AsaEduGame/Sources/AsaEduGameApp.swift` と `ContentView.swift`

最小修正で済む方針として、**App側の `.modelContainer(for:)` を削除**し、`EduGameDataService` のコンテナを Single Source of Truth にする:

`AsaEduGameApp.swift`:
```swift
@main
struct AsaEduGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // .modelContainer(for: [...]) を削除
    }
}
```

`ContentView.swift`:
- `@Environment(\.modelContext)` 宣言を削除（未使用）
- body に `.modelContainer(dataService.modelContainer)` を追加(SwiftUI Preview や子 View が `@Environment` 経由で取り出せるようにするため、念のため貼っておく)

```swift
var body: some View {
    TabView { ... }
        .modelContainer(dataService.modelContainer)  // 追加
}
```

**効果**: SQLite ファイルへのアクセスが単一 Container 経由になり、CoreData の Device ID ミスマッチエラーが消える。

### Phase 2: デザインリファイン (絵文字 → SF Symbols)

**置換ポリシー**: アバターは残す。それ以外(バッジ絵文字・UI iconography)は全て SF Symbols + ブランドカラーに統一。

#### 2-1. BadgeDefinition に systemImage プロパティを追加 (Kit層)

**対象**: `Packages/AsaEduGameKit/Sources/AsaEduGameKit/Models/BadgeDefinition.swift`

既存の `emoji: String` プロパティは後方互換のため残しつつ、`systemImage: String` を追加してバッジごとに SF Symbol を割り当て:

```swift
public extension BadgeDefinition {
    var systemImage: String {
        switch self {
        case .firstStep:        return "figure.walk"
        case .mathMaster:       return "function"
        case .hiraganaHero:     return "character.book.closed.fill"
        case .shapeExpert:      return "square.on.circle.fill"
        case .logicWizard:      return "lightbulb.fill"
        case .perfectScore:     return "star.circle.fill"
        case .speedDemon:       return "bolt.fill"
        case .weekStreak:       return "flame.fill"
        case .monthStreak:      return "rosette"
        case .allRounder:       return "trophy.fill"
        // ... 実際の case 名に合わせて全バッジ分マッピング
        }
    }
    var iconColor: Color {  // ブランドカラー割当
        switch self {
        case .perfectScore, .mathMaster: return AsaColors.coffeeBrown
        case .hiraganaHero, .shapeExpert: return AsaColors.mocha
        case .logicWizard, .allRounder: return AsaColors.mutedSage
        default: return AsaColors.coffeeBrown
        }
    }
}
```

注: Achievement モデルの `emoji` フィールドは SwiftData マイグレーションを避けるため温存(View 層で BadgeDefinition.systemImage を参照)。

#### 2-2. BadgeCollectionView の置換

**対象**: `Apps/AsaEduGame/Sources/Views/Profile/BadgeCollectionView.swift`

- 行62: `Text("🏅 バッジしゅうしゅう")` → `HStack { Image(systemName: "rosette").foregroundColor(AsaColors.coffeeBrown); Text("バッジしゅうしゅう") }`
- 行106-107: `Text(badge.emoji).font(.system(size: 36))` → `Image(systemName: badge.systemImage).font(.system(size: 36)).foregroundColor(badge.iconColor)`
- 行144-145: 詳細シート内の同様の表示も `Image(systemName:)` に置換
- 行101 の Color 文字列リテラル参照は Phase 1-1 で既に修正済み

#### 2-3. ProgressDashboardView 統計カード

**対象**: `Apps/AsaEduGame/Sources/Views/Progress/ProgressDashboardView.swift` および StatCard コンポーネント

- 行68, 76, 84: `emoji: "🎮"/"📊"/"⭐"` を `systemImage:` に変更
  - 🎮 → `gamecontroller.fill` (AsaColors.coffeeBrown)
  - 📊 → `chart.bar.xaxis` (AsaColors.mocha)
  - ⭐ → `star.fill` (AsaColors.coffeeBrown)
- StatCard 側を `emoji: String` → `systemImage: String, color: Color` に変更し、`Image(systemName:).foregroundColor(color)` で描画

#### 2-4. GameResultView 報酬表示

**対象**: `Apps/AsaEduGame/Sources/Views/Game/GameResultView.swift`

- 行176-178: `emoji:` 引数を `systemImage:` に変更
  - ⭐ → `star.fill` (AsaColors.coffeeBrown)
  - 🔥 → `flame.fill` (AsaColors.coffeeBrown 系のアクセント)
  - 💯 → `checkmark.seal.fill` (AsaColors.mutedSage)

#### 2-5. LevelBadgeView

**対象**: `Apps/AsaEduGame/Sources/Views/Components/LevelBadgeView.swift` 周辺

- 行109: `Text("あと\(starsToNextLevel)⭐")` → `HStack(spacing: 2) { Text("あと\(starsToNextLevel)"); Image(systemName: "star.fill").foregroundColor(AsaColors.coffeeBrown) }`

#### 2-6. アバター(残置箇所)

- `ProfileView.swift:20-22` の動物絵文字配列(🐱🐶🐰🐻🐼🦊🐸🐧🦁🐯🐮🐷🐵🦄🐲)はそのまま維持
- アバターは「ユーザーが選ぶアイデンティティ」として絵文字の方が温かみがあるため変更しない

### Phase 3: 検証

#### 3-1. ビルド検証
```bash
cd Apps/AsaEduGame
xcodegen generate
xcodebuild -project AsaEduGame.xcodeproj -scheme AsaEduGame -sdk iphonesimulator build
```
警告・エラー 0 件を確認。

#### 3-2. 動作検証
シミュレータ (iPhone 17 Pro) で起動し、コンソール (`xcrun simctl` 経由 または Xcode Console) を確認:

- `No color named` エラーが出ない
- `CoreData: error:` が出ない
- 全タブ(ホーム/しんちょく/プロフィール)が遷移可能
- バッジコレクション画面のセル背景色が正しく描画される(コーヒーブラウン/モカ/ミューテッドセージの3色がローテーション)
- 統計カード/結果画面のアイコンが SF Symbols 化されており、ブランドカラーで描画される

#### 3-3. ユニットテスト
```bash
cd Packages/AsaEduGameKit
swift test
```
既存の AsaEduGameKit テストが全てグリーンであることを確認(BadgeCollectionView 修正は View 層なので Kit 層テストには影響しないはず)。

---

## 修正対象ファイル一覧

### Phase 1: ランタイムエラー修正
- `Apps/AsaEduGame/Sources/AsaEduGameApp.swift` — `.modelContainer(for:)` 削除
- `Apps/AsaEduGame/Sources/ContentView.swift` — `@Environment(\.modelContext)` 削除、`.modelContainer(_:)` 追加
- `Apps/AsaEduGame/Sources/Views/Profile/BadgeCollectionView.swift` (行101) — Color 文字列リテラル → `AsaColors.xxx`

### Phase 2: デザインリファイン
- `Packages/AsaEduGameKit/Sources/AsaEduGameKit/Models/BadgeDefinition.swift` — `systemImage`/`iconColor` プロパティ追加
- `Apps/AsaEduGame/Sources/Views/Profile/BadgeCollectionView.swift` — バッジ絵文字 + ヘッダー絵文字 → SF Symbol
- `Apps/AsaEduGame/Sources/Views/Progress/ProgressDashboardView.swift` — 統計カードの絵文字 → SF Symbol
- `Apps/AsaEduGame/Sources/Views/Game/GameResultView.swift` — 報酬絵文字 → SF Symbol
- `Apps/AsaEduGame/Sources/Views/Components/LevelBadgeView.swift` — ⭐ → SF Symbol (パスは要確認)
- `Apps/AsaEduGame/Sources/Views/Components/StatCard.swift` 等 — `emoji: String` プロパティを `systemImage: String, color: Color` にリファクタ

### 参照のみ(変更しない)
- `Packages/AsaUIKit/Sources/AsaUIKit/Colors/AsaColors.swift` — 既存の AsaColors.coffeeBrown / mocha / mutedSage / softCream / darkSlate を参照
- `Apps/AsaFlashcardPro/AsaFlashcardPro/ContentView.swift` — SF Symbols 設計の参考例
- `Packages/AsaEduGameKit/Sources/.../Models/Achievement.swift` — `emoji: String` フィールドは SwiftData マイグレーション回避のため温存(View 層で BadgeDefinition.systemImage を参照)
- `Apps/AsaEduGame/Sources/Views/Profile/ProfileView.swift` (行20-22) — アバター動物絵文字は仕様により維持

---

## 期待される効果

1. **エラーゼロ**: 起動時のコンソールが綺麗になり、デモ動画撮影時のノイズが消える
2. **デザイン品質**: SF Symbols + ブランドカラーで「機械的な絵文字配置」感が消え、AsaFlashcardPro と同等の質感に
3. **再発防止**: 文字列ベースの Color 参照を排除し、ビルド時に型エラーで検知可能に
4. **データ整合性**: 単一 ModelContainer により SwiftData の挙動が予測可能になり、今後の機能追加時の不可解なクラッシュリスクが低下
