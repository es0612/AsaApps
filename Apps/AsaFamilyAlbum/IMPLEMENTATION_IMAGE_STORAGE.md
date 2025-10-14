# AsaFamilyAlbum - 画像ローカルストレージ実装

## 📅 実装日
2025年10月14日

## 🎯 実装の目的

写真追加機能における2つの重大な問題を解決：
1. **追加した写真が即座に反映されない問題**
2. **画像データがローカルストレージに保存されていない問題**

---

## ❌ 問題点の詳細

### 問題1: 画像情報が即座に反映されない

**根本原因**：
```swift
// 旧実装
let photo = Photo(
    assetID: UUID().uuidString,  // ← PHAssetのlocalIdentifierではない！
    createdAt: Date(),
    location: nil
)
```

- `UUID().uuidString` を `PHAsset` のlocalIdentifierとして扱っていた
- `PhotoLibraryService.getAsset(for: photo)` が常に `nil` を返す
- 結果として画像が表示されない

### 問題2: ローカルストレージに保存されていない

**影響**：
- アプリ再起動後に画像が表示できない
- PhotosKitアクセス権限変更で画像が消える
- ユーザーが元の写真を削除すると参照が壊れる

---

## ✅ 実装した機能

### 1. Photoモデルの拡張

**ファイル**: `Apps/AsaFamilyAlbum/AsaFamilyAlbum/Models/Photo.swift`

```swift
// 新規プロパティ
var localImagePath: String?  // ローカル保存された画像のファイルパス

// 計算プロパティ
var hasLocalImage: Bool {
    localImagePath != nil
}
```

### 2. ImageStorageServiceの新規作成

**ファイル**: `Apps/AsaFamilyAlbum/AsaFamilyAlbum/Services/ImageStorageService.swift`

**主要機能**：
- Documents/Photos/ ディレクトリへの画像保存
- JPEGフォーマット（品質80%）で圧縮保存
- ファイル名: `{UUID}.jpg`
- 最大解像度4096x4096（自動リサイズ）
- 画像読み込み機能（リサイズ対応）
- 画像削除機能
- ストレージ使用量取得機能

**主要メソッド**：
```swift
// 画像保存
func saveImage(_ image: UIImage) async -> String?

// 画像読み込み
func loadImage(from relativePath: String) async -> UIImage?
func loadImage(from relativePath: String, targetSize: CGSize) async -> UIImage?

// 画像削除
func deleteImage(at relativePath: String) -> Bool

// ストレージ情報
func getStorageInfo() -> (totalSize: Int64, fileCount: Int)
```

### 3. ViewModelの改善

**ファイル**: `Apps/AsaFamilyAlbum/AsaFamilyAlbum/ViewModels/FamilyAlbumViewModel.swift`

#### addPhotoFromImage メソッドの修正

**旧実装**：
```swift
func addPhotoFromImage(_ image: UIImage, to album: Album) async {
    let photo = Photo(assetID: UUID().uuidString, ...)
    photo.album = album
    try await dataService.savePhoto(photo)
    await loadAlbums()
}
```

**新実装**：
```swift
func addPhotoFromImage(_ image: UIImage, to album: Album) async {
    // 1. 画像をローカルストレージに保存
    guard let imagePath = await ImageStorageService.shared.saveImage(image) else {
        errorMessage = "画像の保存に失敗しました"
        return
    }

    // 2. Photoモデルを作成
    let photo = Photo(assetID: UUID().uuidString, ...)
    photo.localImagePath = imagePath  // ← ローカルパス設定
    photo.album = album

    // 3. Swift Dataに保存
    do {
        try await dataService.savePhoto(photo)
        await loadAlbums()
        await loadAllPhotos()
    } catch {
        errorMessage = "写真の追加に失敗しました"
        _ = ImageStorageService.shared.deleteImage(at: imagePath)  // ← rollback
    }
}
```

#### loadImage メソッドの改善

**新実装の優先順位**：
1. ローカル保存画像を優先
2. PHAsset fallback（既存写真）

```swift
func loadImage(for photo: Photo, size: CGSize) async -> UIImage? {
    // 優先順位1: ローカル保存画像
    if let localPath = photo.localImagePath {
        return await ImageStorageService.shared.loadImage(
            from: localPath,
            targetSize: size
        )
    }

    // 優先順位2: PHAsset fallback
    guard let asset = photoLibraryService.getAsset(for: photo) else {
        return nil
    }
    return await photoLibraryService.loadImage(for: asset, targetSize: size)
}
```

---

## 🗂️ ディレクトリ構造

```
Documents/
└── Photos/
    ├── 550e8400-e29b-41d4-a716-446655440000.jpg
    ├── 6ba7b810-9dad-11d1-80b4-00c04fd430c8.jpg
    └── ...
```

---

## 📝 変更ファイル一覧

### 新規作成
1. `Apps/AsaFamilyAlbum/AsaFamilyAlbum/Services/ImageStorageService.swift` (268行)
2. `Apps/AsaFamilyAlbum/IMPLEMENTATION_IMAGE_STORAGE.md` (このファイル)

### 修正
1. `Apps/AsaFamilyAlbum/AsaFamilyAlbum/Models/Photo.swift`
   - `localImagePath` プロパティ追加
   - `hasLocalImage` 計算プロパティ追加

2. `Apps/AsaFamilyAlbum/AsaFamilyAlbum/ViewModels/FamilyAlbumViewModel.swift`
   - `addPhotoFromImage()` メソッド完全書き換え
   - `loadImage()` メソッド改善（ローカル優先）
   - `loadFullSizeImage()` メソッド改善（ローカル優先）

---

## 🔧 技術仕様

### 画像保存仕様
- **フォーマット**: JPEG
- **圧縮品質**: 0.8 (80%)
- **最大解像度**: 4096x4096ピクセル
- **ファイル名**: UUID + ".jpg"
- **保存場所**: `Documents/Photos/`

### エラーハンドリング
- ディスク容量不足時のエラー
- ファイル書き込み失敗時のロールバック
- 破損画像の検出

### パフォーマンス最適化
- 大きすぎる画像の自動リサイズ
- サムネイル表示用の軽量読み込み
- 非同期処理による UI ブロック回避

---

## ✅ 動作確認

### ビルド結果
```
** BUILD SUCCEEDED **
```

### 警告
既存コードからの警告のみ（今回の実装には影響なし）

---

## 📱 使用方法

### 写真の追加
1. アルバム詳細画面で「📸」ボタンをタップ
2. PhotosPickerで写真を選択（最大50枚）
3. 「追加」ボタンで保存
4. → 画像がDocuments/Photos/に保存される
5. → 即座にアルバムに表示される

### 画像の表示
- ローカル保存画像が優先的に表示される
- 既存のPHAsset連携も継続動作

### アプリ再起動後
- ローカル保存された画像は永続的に表示可能
- PhotosKitアクセス権限に依存しない

---

## 🎨 UI/UX改善

### 即時反映
- 写真追加後、即座にアルバムに表示
- リアルタイム進行状況表示
- 成功/失敗のフィードバック

### エラーメッセージ
- 画像保存失敗時の明確なメッセージ
- ロールバック処理による一貫性保持

---

## 🔮 将来の改善案

### 短期
- [ ] 画像圧縮品質の設定オプション
- [ ] ストレージ容量警告（残り＜100MB時）
- [ ] 画像の一括削除機能

### 中期
- [ ] iCloud同期サポート
- [ ] HEIC フォーマットサポート
- [ ] 画像メタデータの抽出・保存

### 長期
- [ ] 画像の自動バックアップ機能
- [ ] 顔認識との統合
- [ ] スマートアルバム自動生成

---

## 🧪 テスト項目

### 基本機能
- [x] 写真追加が正常に動作
- [x] ローカルストレージに画像が保存される
- [x] アルバムに即座に表示される
- [x] アプリ再起動後も画像が表示される

### エラーハンドリング
- [ ] ディスク容量不足時の適切なエラー表示
- [ ] 保存失敗時のロールバック動作
- [ ] ファイル破損時の復旧

### パフォーマンス
- [ ] 大量写真（50枚）の追加時の動作
- [ ] 大きな画像（>10MB）の処理
- [ ] メモリ使用量の最適化

---

## 📚 関連ドキュメント

- [AsaFamilyAlbum README](../../README.md)
- [ブランドガイドライン](../../Docs/BrandGuidelines.md)
- [CRASH_FIX_REPORT.md](./CRASH_FIX_REPORT.md)

---

## 🤝 貢献者

- **実装**: Claude Code
- **日付**: 2025年10月14日
- **バージョン**: v1.1.0
