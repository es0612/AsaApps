# Day 9: SwiftUI 学習メモ - Building Lists and Navigation

## 学んだこと
- **データモデル**:
  - `Identifiable` プロトコルを採用し、`id` でデータを識別。
  - 構造体を使ってデータモデルを定義（例: `Landmark`）。
- **リストの作成**:
  - `List` ビューでデータを動的に表示。
  - `ForEach` のように動作し、`Identifiable` なデータを利用。
- **ナビゲーション**:
  - `NavigationView` でナビゲーション構造を構築。
  - `NavigationLink` でリストから詳細画面に遷移。
  - `.navigationTitle` でナビゲーションバーのタイトルを設定。
- **UI のカスタマイズ**:
  - リスト行に画像を追加（`.clipShape(Circle())` で丸く）。
  - 詳細画面に画像やテキストを配置。

## アサパパらぼ。への応用アイデア
- `AsaTimer` にタイマー履歴リストを追加（例: 過去のタイマー時間をリスト表示）。
  - 履歴データを `Identifiable` な構造体で管理。
  - `List` で表示し、`NavigationLink` で詳細（例: 開始時刻、終了時刻）を表示。
- `AsaGreeting` に挨拶履歴リストを追加（例: 過去に入力した名前をリスト表示）。
- アプリ選択画面を作成し、`AsaCounter`, `AsaGreeting`, `AsaTimer` をリストで表示。
  - 各アプリへの `NavigationLink` を設定。
- ブランドロゴ（`AsaLogo`）をリストや詳細画面に活用し、統一感を強化。