# AsaLifeLog Widget Extension インストールエラー修正計画

## Context

AsaLifeLog をシミュレータで実行しようとすると、以下のエラーで Xcode がアプリのインストールに失敗する：

```
Simulator device failed to install the application.
Domain: IXErrorDomain  Code: 2
Failure Reason: Invalid placeholder attributes.

Failed to create app extension placeholder for
.../AsaLifeLog.app/PlugIns/LifeLogWidgetExtension.appex

Failed to set placeholder attributes
com.asapapa.apps.asalifelog.widget
```

### 原因分析

`Apps/AsaLifeLog/project.yml:53-63` の `LifeLogWidgetExtension` ターゲットは
`GENERATE_INFOPLIST_FILE: true` を使うが、**`NSExtensionPointIdentifier`
を生成 Info.plist に注入する設定が欠けている**。

その結果、ビルドされた `.appex` の `Info.plist` に `NSExtension` 辞書が含まれず、
シミュレータの IXService は extension の種類を判定できず "Invalid placeholder
attributes" でインストールを拒否する。

同リポジトリの動作する widget extension（`Apps/AsaPapaHub/project.yml:77`）には、
以下の指定がある：
```yaml
INFOPLIST_KEY_NSExtension_NSExtensionPointIdentifier: com.apple.widgetkit-extension
```
この差分が、AsaLifeLog 側に欠落している。

### 二次的な問題（同時に修正する）

`Apps/AsaLifeLog/Shared/SharedDefaults.swift:7` で App Group
`group.com.asapapa.apps.asalifelog` を使って widget とデータ共有しているが、
- `Apps/AsaLifeLog/Sources/AsaLifeLog.entitlements` に App Group の宣言なし
- widget extension 側に entitlements ファイル自体が存在しない

この状態だと `UserDefaults(suiteName:)` は `?? .standard` で標準
UserDefaults にフォールバックし、widget と本体アプリ間でデータ共有が
できない（widget が常に空データを表示する）。

参照すべき動作例: `Apps/AsaPapaHub/PapaHubWidgetExtension/PapaHubWidgetExtension.entitlements`、
`Apps/AsaPapaHub/Sources/AsaPapaHub.entitlements`。

### 期待される結果

- シミュレータで AsaLifeLog がエラーなく起動する
- ホーム画面の widget gallery に AsaLifeLog widget が表示される
- 本体アプリで保存した `LifeLogWidgetData` が widget に正しく反映される

## 変更対象ファイル

### 1. `Apps/AsaLifeLog/project.yml` （メイン修正）

`LifeLogWidgetExtension` ターゲットの `settings` に以下を追加する：

```yaml
LifeLogWidgetExtension:
  type: app-extension
  platform: iOS
  sources: [LifeLogWidgetExtension, Shared]
  settings:
    PRODUCT_BUNDLE_IDENTIFIER: com.asapapa.apps.asalifelog.widget
    GENERATE_INFOPLIST_FILE: true
    SKIP_INSTALL: "YES"
    LD_RUNPATH_SEARCH_PATHS: "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks"
    SWIFT_STRICT_CONCURRENCY: complete
    INFOPLIST_KEY_CFBundleDisplayName: "AsaLifeLog Widget"
    INFOPLIST_KEY_NSExtension_NSExtensionPointIdentifier: com.apple.widgetkit-extension   # 追加
    CODE_SIGN_ENTITLEMENTS: LifeLogWidgetExtension/LifeLogWidgetExtension.entitlements   # 追加
  dependencies:
    - package: AsaUIKit
```

`AsaLifeLog` ターゲット側の `SWIFT_STRICT_CONCURRENCY: complete` は既存維持。

### 2. `Apps/AsaLifeLog/Sources/AsaLifeLog.entitlements` （App Group 追加）

既存の HealthKit エントリは保持しつつ App Group を追加：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
    <key>com.apple.developer.healthkit.access</key>
    <array/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.asapapa.apps.asalifelog</string>
    </array>
</dict>
</plist>
```

### 3. `Apps/AsaLifeLog/LifeLogWidgetExtension/LifeLogWidgetExtension.entitlements` （新規）

App Group のみを宣言する新規ファイル：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.asapapa.apps.asalifelog</string>
    </array>
</dict>
</plist>
```

## 再利用する既存資産

新規コードは追加しない。以下の既存実装はそのまま利用：

- `Apps/AsaLifeLog/Shared/SharedDefaults.swift` — App Group entitlement が
  揃えば現状コードのまま正しく動作する
- `Apps/AsaLifeLog/LifeLogWidgetExtension/LifeLogWidget.swift` — `@main
  WidgetBundle` パターンは正しく書かれており、Info.plist に
  `NSExtensionPointIdentifier` が入れば iOS 17+ では追加実装不要
- `Apps/AsaPapaHub/project.yml` — 設定パターンの参照ソース

## 検証手順

```bash
# 1. プロジェクト再生成
cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaLifeLog
xcodegen generate

# 2. ビルド確認（シミュレータ向け）
xcodebuild -project AsaLifeLog.xcodeproj -scheme AsaLifeLog -sdk iphonesimulator build

# 3. .appex の Info.plist に NSExtension が含まれているか確認
plutil -p ~/Library/Developer/Xcode/DerivedData/AsaLifeLog-*/Build/Products/Debug-iphonesimulator/AsaLifeLog.app/PlugIns/LifeLogWidgetExtension.appex/Info.plist | grep -A 2 NSExtension
# 期待: NSExtensionPointIdentifier => "com.apple.widgetkit-extension" が表示される

# 4. シミュレータで起動確認
xcodebuild -project AsaLifeLog.xcodeproj -scheme AsaLifeLog \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
# Xcode から ▶︎ ボタンで実行 → エラーダイアログが出ないこと
```

### Widget 動作確認

1. シミュレータでアプリを起動し、ライフログデータを 1 件以上記録
2. ホーム画面に戻り、長押し → 「+」 → AsaLifeLog widget を追加
3. small/medium/large の各サイズで、本体アプリの最新データが表示されることを確認
4. ロック画面 widget（accessoryCircular / accessoryRectangular）も追加して同様に確認

### 既知のリスク

- `DEVELOPMENT_TEAM: ""` の状態で App Group capability がシミュレータでは
  自動付与されるが、実機ビルドにはチーム設定が別途必要になる。今回は
  シミュレータ動作が目標なので影響なし。
- `CodeSigning` で entitlements 不整合エラーが出た場合は
  `xcrun simctl uninstall booted com.asapapa.apps.asalifelog` で旧バージョンを
  削除してから再インストールする。
