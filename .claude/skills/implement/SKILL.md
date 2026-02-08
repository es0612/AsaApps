# /implement - アプリ実装スキル

PLAN.mdに基づいてAsaAppsの新規アプリを実装するスキルです。

## 使い方

```
/implement AsaNewAppName
```

## 実行手順

### Step 1: 計画の読み込み
1. `Apps/[AppName]/PLAN.md` を読み込む
2. ファイル一覧と各フェーズの内容を把握
3. `project.yml` が存在しない場合は作成

### Step 2: Phase別実装（各Phase後にビルドチェック）

#### Phase 1: Models
1. データモデルを全て作成
2. `import SwiftData`、`import Foundation` を必ず含める
3. `Equatable`/`Hashable`/`Codable` 準拠を忘れずに
4. **ビルドチェック**: `xcodegen generate && xcodebuild build` でエラー確認・修正

#### Phase 2: Services
1. データサービス、APIサービス等を作成
2. actor isolationに注意（`@MainActor`の適用箇所を確認）
3. `deinit` 内で `@MainActor` が必要な処理を避ける
4. **ビルドチェック**: エラー確認・修正

#### Phase 3: ViewModels
1. `@Observable` パターンで実装
2. `@MainActor` を適切に適用
3. `@Bindable` の使用パターンに注意
4. **ビルドチェック**: エラー確認・修正

#### Phase 4: Views
1. ContentView、各画面、コンポーネントを作成
2. AsaUIKit（AsaButton, AsaCard, AsaColors）を活用
3. ブランドカラー（AsaCoffeeBrown等）を使用
4. システム型との命名衝突を避ける
5. **ビルドチェック**: エラー確認・修正

#### Phase 5: Tests
1. Swift Testingフレームワーク（`@Test` 構文）で記述
2. `#expect` マクロを使用（XCTAssertではなく）
3. 浮動小数点比較には精度パラメータを使用
4. 日付関連のエッジケースをカバー
5. **テスト実行**: `swift test` で全テストパス確認

#### Phase 6: Documentation
1. `Docs/Notes/DayXX-Implementation.md` を作成
2. アプリの概要、技術的決定、学んだことを記録

### Step 3: 最終検証
1. `xcodegen generate` でプロジェクト再生成
2. `xcodebuild build` でクリーンビルド確認
3. `swift test` で全テストパス確認
4. ビルドエラーがあれば自律的に修正（ユーザーに聞かない）

### Step 4: コミット
詳細な日本語コミットメッセージでコミット：
```
feat: [AppName]（アプリの説明）実装完了

- 主要機能の箇条書き
- 使用技術
- テスト結果
```

## ビルドエラー対処の優先順位
1. `import` 漏れ → 該当ファイルにimport追加
2. iOS バージョン非互換 → project.yml のデプロイメントターゲットを使用APIに合わせて引き上げ
3. actor isolation → `@MainActor` 適用または `nonisolated` 指定
4. `Equatable`/`Hashable` 未準拠 → プロトコル準拠追加
5. 命名衝突 → リネームして衝突回避
6. `@Bindable` 問題 → バインディングパターン見直し

※ 具体例はCLAUDE.mdの「Swift ビルドエラー防止ルール」を参照

## 重要な制約
- 最新APIを積極的に使用し、使用するAPIに合わせてデプロイメントターゲットを設定する
- 標準シミュレータ: iPhone 17 Pro（`-sdk iphonesimulator` 必須）
- 各Phase完了後に必ずビルドチェック（全ファイル作成後ではなく）
- テストが全てパスするまでコミットしない
- エラーは自律的に解決する（繰り返しビルド→修正ループ）
- 必ず日本語でドキュメント作成
