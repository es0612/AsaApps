# Swiftビルドエラー防止ルールをCLAUDE.mdに追加する計画

## Context

インサイトレポートで37回のビルドエラーが特定された。git履歴とコード分析から12種類の具体的なエラーパターンを発見。これらをCLAUDE.md（常にコンテキストに読み込まれる）に明記することで、今後の実装時にClaudeが同じミスを繰り返すことを防止する。シミュレータ指定のミス（`-sdk iphonesimulator` 欠落、デバイス名不一致）も修正する。

**方針:**
- 最新API推奨（iOS 18+を積極的に使う、デプロイメントターゲット引き上げOK）
- 標準シミュレータ: **iPhone 17 Pro**
- iOS 18+ APIの使用時はproject.ymlのターゲットを合わせることをルール化

## 変更ファイル一覧

| ファイル | 変更内容 |
|---------|---------|
| `CLAUDE.md` | ビルドエラー防止ルール追加、ビルドコマンド修正、project.ymlテンプレート更新 |
| `.claude/agents/build-test-commit.md` | xcodebuildコマンド修正、エラールール参照追加 |
| `.claude/skills/implement/SKILL.md` | CLAUDE.md参照追加、シミュレータ名更新 |
| `.claude/skills/plan/SKILL.md` | iOS 18+制限を削除、最新API推奨に変更 |

## 1. CLAUDE.md の変更

### 1-A. ビルドコマンド修正（101〜112行目）

**現状の問題:**
- `-sdk iphonesimulator` フラグが欠落 → 実機向けビルドになりシミュレータで失敗
- `iPhone 16` → 最新シミュレータ名に合わせる

**修正後:**
```bash
# コマンドラインからビルド（シミュレータ向け）
xcodebuild -project AsaNumberGame.xcodeproj -scheme AsaNumberGame -sdk iphonesimulator build

# テスト実行（Swiftパッケージ）
swift test

# シミュレータ指定でビルド・実行
xcodebuild -project AsaNumberGame.xcodeproj -scheme AsaNumberGame \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

### 1-B. project.yml テンプレート更新（73〜99行目）

- デプロイメントターゲットを `18.0` に引き上げ
- UILaunchScreen設定を追加（黒帯防止）

```yaml
options:
  bundleIdPrefix: com.asaapps
  deploymentTarget:
    iOS: "18.0"

targets:
  AsaNewApp:
    settings:
      SWIFT_VERSION: "5.9"
      GENERATE_INFOPLIST_FILE: true
      INFOPLIST_KEY_UILaunchScreen_Generation: true
```

### 1-C. 新セクション追加（113行目の後、アーキテクチャパターンの前）

`## Swift ビルドエラー防止ルール` セクションを挿入。以下の11パターンをコード例付きで記載:

1. **@Model と Sendable** - `@Model` に `Sendable` をつけない
2. **@MainActor + Timer の deinit** - `nonisolated(unsafe)` を使う
3. **Info.plist / UILaunchScreen** - `INFOPLIST_KEY_UILaunchScreen_Generation: true` 設定必須
4. **型の不一致** - Int→TimeInterval 明示変換、Anchor<CGRect>→GeometryProxyで解決
5. **@Observable と private(set)** - publicメソッドで変更を公開
6. **Codable の id プロパティ** - `let id = UUID()` ではなく `var id: UUID`
7. **SwiftData ModelContext** - `@MainActor` でラップ
8. **Firebase互換性** - `FirebaseFirestoreSwift` → `FirebaseFirestore`
9. **命名衝突** - システム型名（Color, Scene等）を避ける、`Asa` プレフィックス推奨
10. **デプロイメントターゲットとAPIの整合性** - 使用するAPIのiOSバージョン要件に合わせてproject.ymlを更新すること
11. **import漏れ** - SwiftData, Foundation を必ず含める

### 1-D. シミュレータ標準ルール

新セクション内に明記:
```
### 標準ビルド・テストコマンド
- シミュレータ: iPhone 17 Pro
- SDKフラグ: -sdk iphonesimulator（必須）
- デバイス確認: xcrun simctl list devices available で利用可能なデバイスを確認
```

### 1-E. コミット前ビルドチェックリスト

新セクション末尾に追加:
```
1. [ ] xcodegen generate 成功
2. [ ] xcodebuild -sdk iphonesimulator build エラー0件
3. [ ] @Model に Sendable がないか確認
4. [ ] UILaunchScreen 設定済み
5. [ ] import 漏れなし（SwiftData, Foundation）
6. [ ] 使用APIのiOSバージョン要件とproject.ymlターゲットが一致
7. [ ] システム型との命名衝突なし
```

## 2. build-test-commit.md の変更

### 2-A. ビルドコマンド修正（29行目）
```bash
xcodebuild -project [AppName].xcodeproj -scheme [AppName] -sdk iphonesimulator clean build
```

### 2-B. テストコマンド修正（35行目）
```bash
xcodebuild test -project [AppName].xcodeproj -scheme [AppName] \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### 2-C. エラーハンドリングにCLAUDE.md参照追加（63行目の後）
```markdown
### ビルドエラー診断
ビルドエラーが発生した場合、CLAUDE.mdの「Swift ビルドエラー防止ルール」を参照し、
既知の11パターンに該当するか確認すること。
```

## 3. implement SKILL.md の変更

- ビルドエラー対処セクション末尾に参照追加: `※ 具体例はCLAUDE.mdの「Swift ビルドエラー防止ルール」を参照`
- シミュレータ名を `iPhone 15` → `iPhone 17 Pro` に更新
- iOS 18+ API制限ルールを削除（最新API推奨に変更）

## 4. plan SKILL.md の変更

- Phase 3「技術制約の明記」から iOS 18+ API禁止ルールを削除
- 「最新APIを積極的に使用し、使用するAPIに合わせてデプロイメントターゲットを設定する」に変更
- シミュレータ名を更新

## 検証方法

1. CLAUDE.md の変更後、新しいセッションで `/plan` や `/implement` を使って実際にアプリを作成し、ビルドエラーが減少するか確認
2. `xcodebuild` コマンドが `-sdk iphonesimulator` と `iPhone 17 Pro` を使用していることを確認
3. build-test-commit エージェントの動作確認
