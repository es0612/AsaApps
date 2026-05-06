# AsaFinancePlanner ビルドエラー修正プラン

## Context

Xcode で AsaFinancePlanner をビルドすると `Missing package product 'AsaUIKit'` というエラーが1件発生し、Build Failed になる（添付スクショ Today at 17:49）。

調査の結果、構成ファイル類はすべて正しく設定されている:
- `Apps/AsaFinancePlanner/project.yml` の `packages.AsaUIKit.path = ../../Packages/AsaUIKit` (行14-15) と target dependencies (行37-38) は正しい
- `Apps/AsaFinancePlanner/AsaFinancePlanner.xcodeproj/project.pbxproj` 内に `AsaUIKit` 参照が10箇所存在 (`relativePath = ../../Packages/AsaUIKit`, `XCLocalSwiftPackageReference` 等)
- `Packages/AsaUIKit/Package.swift` の `products` に `AsaUIKit` ライブラリが正しく定義されている (行9-13)

つまりプロジェクト記述は正しいのに、Xcode/SPM のキャッシュ側で参照解決ができていない状態。これはメモリに記録された既知パターン「Missing package productはキャッシュリセットで解決」に一致する。決め手は次のとおり:

1. `~/Library/Developer/Xcode/DerivedData/AsaFinancePlanner-bsmkntgjjploecbwqnaykhemnvxn/` にDerivedDataが残存
2. `AsaFinancePlanner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/` 配下に `configuration` ディレクトリのみが存在し、`Package.resolved` が見当たらない（解決済みパッケージ情報が欠落）

意図する成果: ビルドエラーを解消し、`xcodebuild -sdk iphonesimulator build` がエラー0件で通る状態に戻すこと。コード自体には手を入れない（構成は正しいため）。

## 修正方針

メモリに記録された復旧手順 (DerivedData+xcodeproj削除 → xcodegen → resolvePackageDependencies → build) をそのまま適用する。これは過去の同種エラーで実証済みのため、最短で最も信頼できるアプローチ。

## 手順

すべて `Apps/AsaFinancePlanner/` ディレクトリで実施。

### Step 1: キャッシュ・生成物のクリーンアップ

```bash
cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaFinancePlanner

# Xcode の DerivedData を削除（SPM の解決結果もここに含まれる）
rm -rf ~/Library/Developer/Xcode/DerivedData/AsaFinancePlanner-*

# 生成物の .xcodeproj を削除（XcodeGen 管理なのでGit対象外、再生成可能）
rm -rf AsaFinancePlanner.xcodeproj
```

### Step 2: XcodeGen で .xcodeproj を再生成

```bash
xcodegen generate
```

`project.yml` から `.xcodeproj` を再生成し、AsaUIKit と AsaFinancePlannerKit の参照を新規にビルドする。

### Step 3: SPM の依存関係を再解決

```bash
xcodebuild -project AsaFinancePlanner.xcodeproj \
  -scheme AsaFinancePlanner \
  -resolvePackageDependencies
```

`Package.resolved` が swiftpm ディレクトリ配下に再生成されることを確認。

### Step 4: ビルド検証

```bash
xcodebuild -project AsaFinancePlanner.xcodeproj \
  -scheme AsaFinancePlanner \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

エラー0件で `BUILD SUCCEEDED` が表示されることを確認する。

### Step 5（万一 Step 4 で失敗した場合のフォールバック）

メモリの手順では解決しない場合、構成側の不備を疑って以下を確認:

- `AsaUIKit` の Swift tools version (6.0) と AsaFinancePlanner 側の Swift Concurrency 設定 (`SWIFT_STRICT_CONCURRENCY: complete`) の競合がないか
- `AsaUIKit/Sources/AsaUIKit/` 内に `AsaUIKit.swift` のような umbrella ファイルが存在するか
- 他の正常ビルド可能アプリ（例: AsaCounter）の project.yml と pbxproj を参照差分

ただし**まずは Step 1-4 のみで完結する想定**。Step 5 は保険。

## 触れる/触れないファイル

| ファイル | 操作 |
|---|---|
| `Apps/AsaFinancePlanner/AsaFinancePlanner.xcodeproj/` | 削除→再生成 (XcodeGen 管理、Git 対象外) |
| `~/Library/Developer/Xcode/DerivedData/AsaFinancePlanner-*` | 削除 (キャッシュなので安全) |
| `Apps/AsaFinancePlanner/project.yml` | **触らない**（既に正しい） |
| `Apps/AsaFinancePlanner/Sources/` 配下のSwiftコード | **触らない**（構成エラーであってコードエラーではない） |
| `Packages/AsaUIKit/Package.swift` | **触らない**（products 定義は正しい） |

## 検証

成功条件:

1. `xcodebuild ... build` が `BUILD SUCCEEDED` で終了
2. Xcode の Issue Navigator で AsaFinancePlanner のエラーが0件になる（添付スクショの状態 → エラー解消）
3. `Apps/AsaFinancePlanner/AsaFinancePlanner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` が新規生成される
4. シミュレータで起動して画面遷移できる（任意。ビルドが通れば本件は解決）

## 参考: 関連メモリ

- `feedback_spm_cache_recovery.md` — 「Missing package productはキャッシュリセットで解決」: pbxproj に参照があれば設定OK。DerivedData+xcodeproj削除→xcodegen→resolvePackageDependencies の順で復旧
