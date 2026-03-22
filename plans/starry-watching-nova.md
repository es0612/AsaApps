# AsaLanguageLearn: AsaUIKit カラー統合

## Context

AsaLanguageLearnアプリで「Missing package product 'AsaUIKit'」ビルドエラーが発生。
`project.yml`でAsaUIKitを依存関係として宣言済みだが、ソースコード内で`import AsaUIKit`が一切なく、
`Color("AsaCoffeeBrown")`のようにアセットカタログ文字列経由でカラーを参照している。
パッケージ宣言と実装が不一致のため、XcodeGenがパッケージ解決に失敗してビルドエラーとなっている。

**修正方針**: AsaUIKitを本格統合し、全カラー参照を`AsaColors`定数に移行する。

## カラーマッピング

| 変更前 | 変更後 | 使用回数 |
|--------|--------|---------|
| `Color("AsaCoffeeBrown")` | `AsaColors.coffeeBrown` | 48回 |
| `Color("AsaDarkSlate")` | `AsaColors.darkSlate` | 19回 |
| `Color("AsaSoftCream")` | `AsaColors.softCream` | 14回 |
| `Color("AsaMocha")` | `AsaColors.mocha` | 4回 |
| `Color("AsaMutedSage")` | `AsaColors.mutedSage` | 1回 |
| **合計** | | **86回・25ファイル** |

## 実装手順

### Step 1: カラー参照の一括置換（25ファイル・86箇所）

対象ファイルすべてで以下の置換を実施:
- `Color("AsaCoffeeBrown")` → `AsaColors.coffeeBrown`
- `Color("AsaDarkSlate")` → `AsaColors.darkSlate`
- `Color("AsaSoftCream")` → `AsaColors.softCream`
- `Color("AsaMocha")` → `AsaColors.mocha`
- `Color("AsaMutedSage")` → `AsaColors.mutedSage`

### Step 2: `import AsaUIKit` 追加（25ファイル）

カラー参照を含む全ファイルに `import AsaUIKit` を追加。
既存の `import SwiftUI` の直後に配置。

### 対象ファイル一覧

**Views/Home/**
- HomeView.swift (14箇所: coffeeBrown×9, darkSlate×3, softCream×1, mocha×1)
- CourseListView.swift (6箇所: coffeeBrown×3, darkSlate×2, softCream×1)
- LessonListView.swift (7箇所: coffeeBrown×4, darkSlate×2, softCream×1)

**Views/Practice/**
- PracticeView.swift (8箇所: coffeeBrown×5, darkSlate×1, softCream×2)
- FeedbackView.swift (7箇所: coffeeBrown×3, darkSlate×2, softCream×2)
- RecordingView.swift (5箇所: coffeeBrown×2, darkSlate×2, mocha×1)

**Views/Review/**
- ReviewDeckView.swift (10箇所: coffeeBrown×5, darkSlate×2, softCream×3)
- ReviewCardView.swift (4箇所: coffeeBrown×3, softCream×1)

**Views/Dashboard/**
- DashboardView.swift (5箇所: coffeeBrown×2, darkSlate×2, softCream×1)
- WeeklyChartView.swift (3箇所: coffeeBrown×2, darkSlate×1)

**Views/Components/**
- MicButtonView.swift (5箇所: coffeeBrown×4, darkSlate×1)
- PlaybackButton.swift (5箇所: coffeeBrown×3, softCream×2)
- WaveformView.swift (3箇所: coffeeBrown×1, mocha×1, mutedSage×1)

**Models/Enums/**
- ContentCategory.swift (3箇所: coffeeBrown×1, darkSlate×1, mocha×1)
- MasteryLevel.swift (1箇所: coffeeBrown×1)

**残りのファイル** (上記以外のColor("Asa...")を含むファイル)

### Step 3: project.yml に `product` 明記

```yaml
# 現在
dependencies:
  - package: AsaUIKit

# 修正後
dependencies:
  - package: AsaUIKit
    product: AsaUIKit
```

### Step 4: ビルド検証

```bash
cd Apps/AsaLanguageLearn
xcodegen generate
xcodebuild -project AsaLanguageLearn.xcodeproj -scheme AsaLanguageLearn -sdk iphonesimulator build
```

## 互換性確認済み

- AsaUIKit: iOS 17.0+ / swift-tools-version 6.0
- AsaLanguageLearn: iOS 17.0 → **完全互換**

## スコープ外（将来の改善候補）

- AsaButton統合（4ファイル・約10箇所のカスタムボタン）
- AsaCard統合（5ファイル・約20箇所のカードUI）
