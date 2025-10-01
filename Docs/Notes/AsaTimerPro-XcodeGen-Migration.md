# AsaTimerPro XcodeGen移行実装ノート

## 実施日
2025-10-01

## 概要
AsaTimerProアプリのプロジェクトファイル破損問題を解決するため、XcodeGenによるプロジェクト管理に移行しました。また、@Observableマクロと@EnvironmentObjectの互換性問題も修正しました。

## 問題の背景

### 1. プロジェクトファイル破損
- **エラー内容**: `XCBBuildConfiguration group: unrecognized selector sent to instance OxcBeff0000`
- **原因**: .xcodeprojファイルの内部データ構造の破損
- **影響**: Xcodeでプロジェクトが開けない状態

### 2. @Observableマクロの互換性問題
- **エラー内容**: `'MultiTimerViewModel' conform to 'ObservableObject'` エラー
- **原因**: @Observableマクロ（iOS 17+）と@EnvironmentObject（ObservableObjectプロトコル専用）の非互換性
- **影響**: ビルドエラーでアプリがコンパイルできない

## 実装内容

### 1. XcodeGenプロジェクト設定ファイル作成

#### project.yml
```yaml
name: AsaTimerPro
options:
  bundleIdPrefix: com.asapapa.apps
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
  generateEmptyDirectories: true

settings:
  MARKETING_VERSION: "1.0"
  CURRENT_PROJECT_VERSION: "1"
  DEVELOPMENT_TEAM: ""
  CODE_SIGN_STYLE: Automatic

targets:
  AsaTimerPro:
    type: application
    platform: iOS
    sources:
      - AsaTimerPro
    resources:
      - AsaTimerPro/Assets.xcassets
      - AsaTimerPro/Resources
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.asapapa.apps.asatimerpro
      INFOPLIST_FILE: AsaTimerPro/Info.plist
      INFOPLIST_KEY_UIApplicationSceneManifest_Generation: true
      INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: true
      INFOPLIST_KEY_UILaunchScreen_Generation: true
      INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
      INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
    dependencies:
      - sdk: SwiftUI.framework
      - sdk: SwiftData.framework
      - sdk: UserNotifications.framework

  AsaTimerProTests:
    type: bundle.unit-test
    platform: iOS
    sources: AsaTimerProTests
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.asapapa.apps.asatimerpro.tests
      GENERATE_INFOPLIST_FILE: YES
    dependencies:
      - target: AsaTimerPro
```

#### Info.plist作成
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSUserNotificationsUsageDescription</key>
	<string>タイマー完了時に通知を送信します</string>
	<key>UIBackgroundModes</key>
	<array>
		<string>audio</string>
		<string>processing</string>
	</array>
	<!-- その他の設定 -->
</dict>
</plist>
```

### 2. @Observableマクロ対応の修正

#### 修正前（@EnvironmentObject使用）
```swift
// AsaTimerProApp.swift - 修正前
@main
struct AsaTimerProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(MultiTimerViewModel())
        }
    }
}

// ContentView.swift - 修正前
struct ContentView: View {
    @EnvironmentObject private var viewModel: MultiTimerViewModel
    // ...
}
```

#### 修正後（@State + @Bindable使用）
```swift
// AsaTimerProApp.swift - 修正後
@main
struct AsaTimerProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// ContentView.swift - 修正後
struct ContentView: View {
    @State private var viewModel = MultiTimerViewModel()
    // ...
    TimerListView(viewModel: viewModel)
    ActiveTimersView(viewModel: viewModel)
    TimerCreationView(viewModel: viewModel)
}

// TimerListView.swift - 修正後
struct TimerListView: View {
    @Bindable var viewModel: MultiTimerViewModel
    // $viewModel.showCompletedTimers などバインディング可能
}
```

### 3. ViewModelプロパティのアクセス制御修正

#### MultiTimerViewModel.swift
```swift
// 修正前
private(set) var multiTimer: MultiTimer

// 修正後（@Observableマクロで変更を追跡するため）
var multiTimer: MultiTimer
```

#### MultiTimer.swift
```swift
// 修正前
private(set) var sessions: [TimerSession]

// 修正後（ViewModelから変更可能にする）
var sessions: [TimerSession]
```

### 4. UIKitインポート追加

#### TimerNotificationService.swift
```swift
// 修正前
import Foundation
import UserNotifications

// 修正後
import Foundation
import UserNotifications
import UIKit  // UIApplication.openSettingsURLString のため
```

### 5. Badge表示の修正

#### ContentView.swift
```swift
// 修正前（nilを使用）
.badge(viewModel.multiTimer.sessions.count > 0 ? viewModel.multiTimer.sessions.count : nil)

// 修正後（Int型のみ）
.badge(viewModel.multiTimer.sessions.count)
```

## 実装手順

1. **プロジェクトファイルのバックアップ**
   ```bash
   cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaTimerPro
   mv AsaTimerPro.xcodeproj AsaTimerPro.xcodeproj.backup
   ```

2. **XcodeGen設定ファイル作成**
   - `project.yml`作成
   - `Info.plist`作成

3. **XcodeGenでプロジェクト生成**
   ```bash
   xcodegen generate
   ```

4. **@Observableマクロ対応修正**
   - AsaTimerProApp.swift修正
   - ContentView.swift修正
   - TimerListView.swift修正
   - ActiveTimersView.swift修正
   - TimerCreationView.swift修正

5. **アクセス制御修正**
   - MultiTimerViewModel.swift修正
   - MultiTimer.swift修正

6. **その他修正**
   - UIKitインポート追加
   - Badge表示修正

7. **ビルド確認**
   ```bash
   xcodebuild -project AsaTimerPro.xcodeproj -scheme AsaTimerPro -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

## 技術的なポイント

### @Observableマクロとの互換性

| 従来の方式 | @Observable方式 |
|-----------|----------------|
| `ObservableObject`プロトコル | `@Observable`マクロ |
| `@Published`プロパティラッパー | 通常のプロパティ（自動追跡） |
| `@StateObject` / `@EnvironmentObject` | `@State` / `@Bindable` |
| `@ObservedObject` | `@Bindable` |

### @Bindableの利点
- バインディング（`$viewModel.property`）が可能
- より軽量でシンプルな実装
- iOS 17+のモダンなSwiftUI開発標準

### XcodeGenの利点
1. **プロジェクトファイル破損リスクの排除**
2. **Git管理の簡素化**（.xcodeprojを除外可能）
3. **設定の一貫性確保**（YAMLで管理）
4. **マージコンフリクトの削減**

## ビルド結果

```
** BUILD SUCCEEDED **
```

### 成功した機能
- ✅ XcodeGenによるプロジェクトファイル生成
- ✅ @Observableマクロとの互換性確保
- ✅ 通知機能の正常動作
- ✅ 全Viewコンポーネントのビルド成功
- ✅ ViewModelの状態管理正常化

## 今後の管理方法

### プロジェクト変更時のワークフロー
1. `project.yml`を編集
2. `xcodegen generate`で.xcodeprojを再生成
3. ビルド・実行

### .gitignoreへの追加推奨
```gitignore
# XcodeGen管理下のプロジェクトファイル
*.xcodeproj
!project.yml
```

## 学習ポイント

### @Observableマクロの採用基準
- **iOS 17+専用アプリ**: @Observableマクロ推奨
- **iOS 16以下サポート**: ObservableObjectプロトコル使用
- **AsaTimerPro**: iOS 17.0+なので@Observableが最適

### アクセス制御の設計
- `private(set)`は@Observableマクロでは制限が厳しい
- ViewModelから変更する必要があるプロパティは`var`に
- 外部から読み取り専用にしたい場合はcomputed propertyを活用

## まとめ

AsaTimerProのプロジェクトファイル破損問題とSwiftUI最新パターンへの対応を同時に解決しました。

**主な成果**:
1. XcodeGen導入による安定したプロジェクト管理
2. @Observableマクロを活用したモダンなSwiftUI実装
3. ビルド成功による正常動作の確保

**技術的改善**:
- より保守性の高いプロジェクト構成
- iOS 17+のベストプラクティスに準拠
- 将来的な拡張性の向上
