# Day 6: SwiftUI 学習メモ - Creating and Combining Views

## 学んだこと
- **ビューの基本**:
  - `Text`, `Image` ビューのカスタマイズ（`.font`, `.foregroundColor`, `.resizable`）。
  - モディファイアの順序が結果に影響（例: `.font` の後に `.foregroundColor`）。
- **スタックビュー**:
  - `VStack`: 縦並び。
  - `HStack`: 横並び。
  - `ZStack`: 重ね合わせ（背景などに便利）。
  - `spacing` で間隔調整。
- **レイアウトとインタラクション**:
  - `.padding()` で余白を追加。
  - `Button` にアクションを追加（例: タップでカウントアップ）。
  - `@State` を使ってビューの状態を管理。

## アサパパらぼ。への応用アイデア
- `VStack` と `HStack` を活用して、AsaCounter のボタンを横に並べるレイアウトを試す。
- `ZStack` を使って、AsaGreeting の背景に薄いパターンを追加（例: コーヒーカップのイラスト）。
- ボタンのスタイルを `AsaButton` に統一し、チュートリアルで学んだカスタマイズ（例: 角丸、シャドウ）を強化。
- `.padding()` を適切に使い、UI の余白をブランドガイドラインに沿って統一。