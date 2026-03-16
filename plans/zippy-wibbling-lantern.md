# AsaSmartAlarm カラー参照エラー修正プラン

## Context

AsaSmartAlarm アプリ実行時に以下のランタイムエラーが大量発生：
```
No color named 'AsaCoffeeBrown' found in asset catalog for main bundle
```

**原因**: 全16箇所で `Color("AsaCoffeeBrown", bundle: nil)` を使用しているが、アプリのメインバンドルにカラー定義の Asset Catalog が存在しない。AsaUIKit パッケージは `project.yml` に依存として定義済みだが、コード側で `import AsaUIKit` されていない。

**修正方針**: `Color("AsaCoffeeBrown", bundle: nil)` → `AsaColors.coffeeBrown` に全置換し、各ファイルに `import AsaUIKit` を追加する。

## 修正対象ファイル（7ファイル、16箇所）

### 1. `Apps/AsaSmartAlarm/AsaSmartAlarm/ContentView.swift`
- L8: `import AsaUIKit` 追加
- L54: `Color("AsaCoffeeBrown", bundle: nil)` → `AsaColors.coffeeBrown`

### 2. `Apps/AsaSmartAlarm/AsaSmartAlarm/Views/AlarmDetailView.swift`
- L8: `import AsaUIKit` 追加
- L114, L119, L214: 各箇所を `AsaColors.coffeeBrown` に置換

### 3. `Apps/AsaSmartAlarm/AsaSmartAlarm/Views/AddAlarmView.swift`
- L8: `import AsaUIKit` 追加
- L65, L76: 各箇所を `AsaColors.coffeeBrown` に置換

### 4. `Apps/AsaSmartAlarm/AsaSmartAlarm/Views/SettingsView.swift`
- L8: `import AsaUIKit` 追加
- L43, L90, L98, L125, L133, L141: 各箇所を `AsaColors.coffeeBrown` に置換

### 5. `Apps/AsaSmartAlarm/AsaSmartAlarm/Views/Components/AdjustmentRuleView.swift`
- L8: `import AsaUIKit` 追加
- L85: `AsaColors.coffeeBrown` に置換

### 6. `Apps/AsaSmartAlarm/AsaSmartAlarm/Views/Components/AlarmRowView.swift`
- L8: `import AsaUIKit` 追加
- L65: `AsaColors.coffeeBrown` に置換

### 7. `Apps/AsaSmartAlarm/AsaSmartAlarm/Views/Components/WeekdayPickerView.swift`
- L8: `import AsaUIKit` 追加
- L79, L119: `AsaColors.coffeeBrown` に置換

## 変更パターン

```swift
// Before (各ファイル)
import SwiftUI

// After
import SwiftUI
import AsaUIKit

// Before (全16箇所)
Color("AsaCoffeeBrown", bundle: nil)

// After
AsaColors.coffeeBrown
```

## 検証手順

1. `cd Apps/AsaSmartAlarm && xcodegen generate`
2. `xcodebuild -project AsaSmartAlarm.xcodeproj -scheme AsaSmartAlarm -sdk iphonesimulator build`
3. ビルド成功を確認
4. シミュレータ実行時にコンソールにカラーエラーが出ないことを確認
