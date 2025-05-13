# Day 15: SwiftUI 学習メモ - Working with UI Controls

## 学んだこと
- **UI コントロール**:
  - `Picker`: 選択肢を表示（例: `.segmented` スタイルで季節選択）。
  - `DatePicker`: 日付選択（例: 目標日の設定）。
  - `Button`: アクション実行（例: プロフィール保存）。
- **カスタマイズ**:
  - `Toggle`, `Picker`, `Button` にカスタムスタイルを適用。
  - `.tint` や `.background` で視覚的な統一感を。
- **データ管理**:
  - `Profile` 構造体でユーザー設定を管理。
  - 列挙型（`Season`）を `CaseIterable` と `Identifiable` に準拠。

## アサパパらぼ。への応用アイデア
- `AsaTimer`:
  - `Picker` でタイマー時間をプリセットから選択（例: 1分、5分、10分）。
  - `Slider` でタイマー時間を直感的に調整（例: 1〜60分の範囲）。
  - `DatePicker` でタイマー履歴のフィルタリング（例: 特定の日付範囲を表示）。
- `AsaGreeting`:
  - `Picker` で挨拶の種類を選択（例: "おはよう", "こんにちは"）。
  - `Button` で挨拶履歴をエクスポート。
- `AsaCounter`:
  - `Slider` でカウントの増分を調整（例: +1, +5, +10）。
- 全体:
  - アプリ設定画面を作成し、`Picker` でテーマ選択（例: ライト/ダークモード）。