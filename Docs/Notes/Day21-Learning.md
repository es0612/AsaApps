# Day 21: SwiftUI 学習メモ - App Essentials

## 学んだこと
- **アプリ構造**:
  - `App` プロトコル: アプリのエントリーポイントを定義。
  - `Scene`: アプリのシーン（例: `WindowGroup`）を管理。
- **状態管理**:
  - `@StateObject`: アプリ全体のデータモデルを管理。
  - `@Published`: データ変更をビューに通知。
  - `@EnvironmentObject`: サブビュー間でデータを共有。
  - `@Environment`: システム環境（例: ダークモード）にアクセス。
- **データ共有**:
  - 親ビューから子ビューにデータを注入（`.environmentObject`）。
  - 双方向バインディングでデータを更新。

## アサパパらぼ。への応用アイデア
- `AsaTimer`:
  - `ModelData` を導入し、タイマー履歴や設定をアプリ全体で共有。
  - `@EnvironmentObject` で履歴データを `TimerHistoryView` と共有。
  - `@Environment(\.colorScheme)` でダークモード対応（例: 背景色を調整）。
- `AsaGreeting`:
  - 挨拶履歴を `ModelData` で管理し、アプリ全体でアクセス。
  - ダークモードでテキスト色を自動調整。
- `AsaCounter`:
  - カウントデータを `ModelData` で永続化（例: UserDefaults に保存）。
  - 環境値（例: ロケール）を使ってカウンター表示を多言語対応。
- 全体:
  - アプリ構造を整理し、複数シーン（例: タイマー + 設定画面）をサポート。