# AsaFamilyAlbum - クラッシュ修正レポート

## 問題概要
AsaFamilyAlbumアプリが起動時に`DataPersistenceError.contextNotAvailable`でクラッシュする問題が発生。

## 原因
SwiftDataのModelContext初期化において、二重管理が発生していたため：

1. **AsaFamilyAlbumApp.swift** - SwiftUIの`.modelContainer`修飾子でModelContainer作成
2. **DataPersistenceService.swift** - 独自にModelContainerを非同期で作成

これにより、DataPersistenceServiceのmodelContextがnilとなり、データアクセス時にクラッシュが発生。

## 修正内容

### 1. DataPersistenceService.swift
```swift
// Before
init() {
    Task { @MainActor in
        setupModelContext()  // 独自のModelContainer作成
    }
}

// After
init() {
    // ModelContextは外部から設定されるため、ここでは初期化しない
}
```

### 2. ContentView.swift
```swift
// Before
@State private var viewModel = FamilyAlbumViewModel()

// After
@Environment(\.modelContext) private var modelContext
@State private var viewModel: FamilyAlbumViewModel?

// ViewModelの初期化時にModelContextを設定
let vm = FamilyAlbumViewModel()
vm.dataService.setModelContext(modelContext)
self.viewModel = vm
```

### 3. FamilyAlbumViewModel.swift
```swift
// dataServiceプロパティを公開
let dataService: DataPersistenceService  // privateを削除
```

## 修正後のデータフロー
1. SwiftUIが`.modelContainer`でModelContainerを作成
2. ContentViewが`@Environment`でModelContextを取得
3. ViewModelのdataServiceにModelContextを設定
4. すべてのデータ操作が単一のModelContextを使用

## 確認方法
```bash
cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaFamilyAlbum
xcodegen generate
open AsaFamilyAlbum.xcodeproj
# ⌘+R でビルド＆実行
```

## 学習ポイント
- SwiftDataでは単一のModelContainerを使用する設計が重要
- SwiftUIの環境値システムを活用してModelContextを共有
- 非同期初期化によるタイミング問題を回避

## 修正日
2025年10月12日