# /plan - 新規アプリ調査＆計画スキル

AsaAppsプロジェクトの新規アプリを調査・計画するスキルです。

## 使い方

```
/plan AsaNewAppName アプリの概要説明
```

## 実行手順

### Phase 1: 既存コードベース分析
1. `Apps/` ディレクトリの既存アプリパターンを調査
   - MVVM構造、ファイル構成、命名規則を確認
   - 類似機能を持つアプリがあれば参考にする
2. `Packages/AsaUIKit/` と `Packages/AsaTaskKit/` の利用可能コンポーネントを確認
3. `Docs/Notes/` の最近の実装ノートからパターンを抽出

### Phase 2: 最新iOS技術調査
1. アプリのコンセプトに関連するiOS/SwiftUI最新技術をWebSearchで調査
2. 調査結果を計画に反映（ただし以下の制約を遵守）

### Phase 3: 技術制約の明記
以下を計画に必ず含める：
- **最新APIを積極的に使用**し、使用するAPIに合わせてデプロイメントターゲットを設定する
- **標準デプロイメントターゲット: iOS 18.0**（必要に応じて調整）
- **標準シミュレータ: iPhone 17 Pro**（`-sdk iphonesimulator` 必須）
- プラットフォーム固有コードには `#if os(iOS)` を使用
- SwiftDataを使う場合は全ファイルで `import SwiftData` を明記
- `Equatable`/`Hashable` 準拠が必要な箇所を事前に特定
- システム型との命名衝突を避ける（Scene、ProgressView等）
- CLAUDE.mdの「Swift ビルドエラー防止ルール」を参照して既知パターンを回避

### Phase 4: 計画ドキュメント作成
`Apps/[AppName]/PLAN.md` に以下の構成で作成：

```markdown
# [AppName] 実装計画

## 概要
- アプリの目的と主要機能
- ターゲットユーザー

## 技術スタック
- iOS 17.0+ / SwiftUI
- 使用フレームワーク一覧
- AsaUIKit/AsaTaskKitの利用コンポーネント

## アーキテクチャ
- MVVM構造
- データフロー図（テキスト）

## 実装フェーズ
### Phase 1: Models（推定ファイル数・行数）
### Phase 2: Services（推定ファイル数・行数）
### Phase 3: ViewModels（推定ファイル数・行数）
### Phase 4: Views（推定ファイル数・行数）
### Phase 5: Tests（推定ファイル数・行数）
### Phase 6: Documentation

## ファイル一覧
- 全ファイルのパスと役割を列挙

## 既知の技術的注意点
- API互換性の制約
- パフォーマンス考慮事項
- actor isolation に注意が必要な箇所
```

### Phase 5: project.yml 作成
XcodeGenの設定ファイルも計画と一緒に作成する。

## 重要な注意事項
- 計画段階ではコードを書かない（PLAN.mdとproject.ymlのみ）
- 必ず日本語で作成する
- 既存のAsaAppsパターンに従う
