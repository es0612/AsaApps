# AsaPhotoStory ビルドエラー修正プラン

## Context

Xcode で `AsaPhotoStory` をビルドすると以下のエラーが発生する。

```
Missing package product 'AsaUIKit'
```

ユーザのスクリーンショットでは `iPhone 17 Pro (26.4.1)` 向けビルドが今日 17:08 に Failed。AsaPhotoStory は README の line 112 に登録されている既存アプリで、AsaUIKit と AsaPhotoStoryKit の2つのローカル Swift Package に依存している。

このエラーを解消し、シミュレータ向けビルドを成功させることが目的。

## 調査結果（根本原因の特定）

### プロジェクト構成は正しい

| 確認対象 | パス | 状態 |
|---|---|---|
| project.yml の packages 定義 | `Apps/AsaPhotoStory/project.yml:13-17` | ✅ AsaUIKit, AsaPhotoStoryKit 両方定義済み |
| project.yml の dependencies 定義 | `Apps/AsaPhotoStory/project.yml:32-36` | ✅ `package: AsaUIKit, product: AsaUIKit` 定義済み |
| AsaUIKit の Package.swift | `Packages/AsaUIKit/Package.swift:9-14` | ✅ `.library(name: "AsaUIKit", targets: ["AsaUIKit"])` 定義済み |
| AsaPhotoStoryKit の Package.swift | `Packages/AsaPhotoStoryKit/Package.swift:10-15` | ✅ products 定義済み（Swift Tools 5.9） |
| pbxproj の SPM 参照 | `Apps/AsaPhotoStory/AsaPhotoStory.xcodeproj/project.pbxproj` | ✅ `XCLocalSwiftPackageReference "../../Packages/AsaUIKit"` および `XCSwiftPackageProductDependency productName = AsaUIKit` 共に存在（10箇所で `AsaUIKit` を参照） |

### 原因

**設定ファイル・生成ファイルは全て正しいため、問題は Xcode 側の SPM 解決キャッシュにある。**

具体的には以下のいずれか（または併発）:

1. `~/Library/Developer/Xcode/DerivedData/` 配下の AsaPhotoStory 用エントリで、過去の SPM 解決失敗結果がキャッシュされている
2. `.xcodeproj/project.xcworkspace/xcuserdata/` 配下の `WorkspaceSettings` が古い状態
3. プロジェクトを Xcode で開いた直後に SPM の resolve が走っておらず、未解決のままビルドが走った

タイムスタンプの裏付け:
- `project.pbxproj`: Apr 6 13:52（再生成済み、AsaUIKit 参照を含む）
- `xcuserdata/`: May 4 17:02（今日 Xcode を開いた時刻）
- ビルド失敗: 17:08（Xcode 起動から約6分後 → 解決処理が間に合わなかった可能性）

## 修正手順

### Step 1: DerivedData の AsaPhotoStory 関連を削除

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/AsaPhotoStory-*
```

これだけで直るケースが多いが、確実を期して以降のステップも実施する。

### Step 2: SPM キャッシュ・xcodeproj を完全にリセットして再生成

```bash
cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaPhotoStory

# 既存の xcodeproj を削除（pbxproj は git 管理外なので安全）
rm -rf AsaPhotoStory.xcodeproj

# project.yml から再生成
xcodegen generate
```

重要ファイル:
- `Apps/AsaPhotoStory/project.yml`（編集不要、再生成のソース）

### Step 3: パッケージ依存を明示的に解決

```bash
cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaPhotoStory

xcodebuild -project AsaPhotoStory.xcodeproj \
  -scheme AsaPhotoStory \
  -sdk iphonesimulator \
  -resolvePackageDependencies
```

このコマンドが成功すれば、SPM 側で AsaUIKit / AsaPhotoStoryKit が認識されたことになる。

### Step 4: シミュレータ向けビルドで確認

```bash
xcodebuild -project AsaPhotoStory.xcodeproj \
  -scheme AsaPhotoStory \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

`** BUILD SUCCEEDED **` が出れば修正完了。

### Step 5（補助）: もし Step 1-4 でも直らない場合の追加対応

万一 Step 4 でもエラーが続く場合の追加調査ポイント（ファイル編集は最小限に留める方針）:

1. `Packages/AsaPhotoStoryKit/Package.swift` の Swift Tools Version を `5.9` → `6.0` に統一（AsaUIKit と揃える）
2. AsaPhotoStoryKit に副次的なビルドエラー（Sources/ 内の Swift コンパイルエラー）が無いか個別に確認:
   ```bash
   cd Packages/AsaPhotoStoryKit && swift build
   ```
3. AsaUIKit 単体でも `swift build` が通るか:
   ```bash
   cd Packages/AsaUIKit && swift build
   ```

これらは「Step 4 が通らなかった場合のみ」着手する。最初から手を入れるとデグレの恐れあり。

## 重要な変更対象ファイル

このプランで**編集が必要なファイルは原則ゼロ**。すべて Xcode の状態リセット + 再生成で完結する想定。

唯一の例外として Step 5 の追加対応に進む場合:
- `Packages/AsaPhotoStoryKit/Package.swift:1` （`swift-tools-version` の修正）

## 検証方法

### コマンドライン検証（必須）

Step 4 のコマンドが `** BUILD SUCCEEDED **` で終了すること。

### Xcode UI での検証（推奨）

```bash
open /Users/shinya/workspace/claude/AsaApps/Apps/AsaPhotoStory/AsaPhotoStory.xcodeproj
```

1. Xcode 上部の Issue ナビゲータ（⚠️ ボタン）でエラーが 0 件であること
2. Cmd+B でビルドが成功すること
3. Cmd+R でシミュレータ起動 → AsaPhotoStory のメイン画面が表示されること

### リグレッション確認

AsaUIKit / AsaPhotoStoryKit 自体の他アプリでの利用箇所が壊れていないか念のため確認:

```bash
# AsaUIKit を import している他のアプリで適当に1つビルド
cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaCounter
xcodegen generate
xcodebuild -project AsaCounter.xcodeproj -scheme AsaCounter -sdk iphonesimulator build
```

→ こちらも成功すれば、AsaUIKit パッケージ自体には影響なし。
