## メモ
- `UIViewControllerRepresentable` を使って `UIPageViewController` を SwiftUI に統合。
- `makeUIViewController`：UIKit コンポーネントを作成。
- `updateUIViewController`：状態の更新（例: ページの変更）。
- `Coordinator`：SwiftUI と UIKit 間のデータバインディングやイベント処理を管理。
- `UIPageViewControllerDataSource` と `UIPageViewControllerDelegate` でページナビゲーションを実現。

## 学び
- SwiftUI では利用できない UIKit コンポーネント（例: `UIPageViewController`）を簡単に統合可能。
- `Coordinator` を使うことで、双方向のデータバインディング（例: `currentPage` の更新）がスムーズ。
- UIKit の強力な機能を SwiftUI で活用できるため、デザインの自由度が向上。

## AsaTimer への適用アイデア
- **カスタムプログレスバー**：
  - UIKit の `UIProgressView` または `CAShapeLayer` を使って、タイマーのプログレスバーをカスタマイズ。
  - `UIViewRepresentable` で SwiftUI に統合。
  - 例: アニメーション付きの円形プログレスバー。
- **チュートリアルページ**：
  - 初回起動時に `UIPageViewController` を使って、使い方ガイドを表示。
  - ページ内容：タイマー設定、スライダー操作、履歴確認など。