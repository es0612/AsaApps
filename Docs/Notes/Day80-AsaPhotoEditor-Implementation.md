# Day 80 - AsaPhotoEditor 実装ノート

**日付**: 2026-01-28
**アプリ番号**: #80（上級アプリ）
**カテゴリ**: 生産性・クリエイティブツール

---

## 概要

AsaPhotoEditorは、高度な画像編集機能を持つSwiftUIアプリです。非破壊編集、プロジェクト保存、バッチエクスポートなど、プロフェッショナルな機能を備えています。

---

## 主要機能

### 1. 画像調整（Adjustment）
- **明るさ** (-1.0 ~ 1.0)
- **コントラスト** (0.5 ~ 2.0)
- **彩度** (0.0 ~ 2.0)
- **露出** (-2.0 ~ 2.0)
- **シャープネス** (0.0 ~ 1.0)
- **ハイライト** (-1.0 ~ 1.0)
- **シャドウ** (-1.0 ~ 1.0)

### 2. フィルター（Filter）
14種類のプリセット：
- オリジナル、セピア、ノワール、ビンテージ
- ビビッド、ドラマチック、モノクロ、トーナル
- フェード、クローム、プロセス、トランスファー
- ぼかし、モザイク

### 3. クロップ・回転（Crop）
- 90度単位の回転（時計回り/反時計回り）
- 水平・垂直反転
- アスペクト比固定（自由、1:1、4:3、16:9など）

### 4. テキストレイヤー（Text）
- フォント選択（日本語・英語フォント対応）
- サイズ・カラー調整
- 透明度・回転設定
- ドラッグによる位置調整

### 5. 描画機能（Drawing）
- 4種類のツール：ペン、ブラシ、蛍光ペン、消しゴム
- カラーピッカー + プリセットカラー
- 線幅調整
- 最大10レイヤーのマルチレイヤー対応
- レイヤーの表示/非表示、ロック機能

### 6. Undo/Redo
- 最大20ステップの履歴管理
- ジェネリック型 `HistoryManager<State>` で実装

### 7. プロジェクト管理
- SwiftDataによる永続化
- 編集状態の完全保存・復元
- プロジェクト検索・複製機能

### 8. エクスポート
- 5種類の解像度：オリジナル、2048px、1024px、512px、256px
- 3種類の形式：JPEG、PNG、HEIC
- バッチエクスポート対応
- 写真ライブラリへの保存

---

## アーキテクチャ

### ディレクトリ構造
```
AsaPhotoEditor/
├── AsaPhotoEditorApp.swift
├── ContentView.swift
├── Models/
│   ├── EditProject.swift          # @Model - SwiftData
│   ├── ImageAdjustment.swift      # 調整パラメータ
│   ├── FilterPreset.swift         # フィルター定義
│   ├── CropSettings.swift         # クロップ設定
│   ├── TextLayer.swift            # テキストレイヤー
│   └── DrawingStroke.swift        # 描画ストローク・レイヤー
├── Services/
│   ├── ImageProcessingService.swift  # Core Image処理（actor）
│   ├── LayerCompositorService.swift  # レイヤー合成
│   ├── HistoryManager.swift          # Undo/Redo管理
│   ├── ProjectDataService.swift      # SwiftData操作
│   └── ExportService.swift           # バッチエクスポート
├── ViewModels/
│   └── PhotoEditorViewModel.swift    # メインViewModel
└── Views/
    ├── Editor/                       # メインエディター
    ├── Adjustment/                   # 調整パネル
    ├── Filter/                       # フィルターパネル
    ├── Crop/                         # クロップパネル
    ├── Layer/                        # テキストパネル
    ├── Drawing/                      # 描画パネル
    ├── Project/                      # プロジェクト一覧
    └── Export/                       # エクスポートシート
```

### 設計パターン
- **MVVM**: ViewModelでビジネスロジックを分離
- **@Observable**: モダンな状態管理
- **Actor**: ImageProcessingServiceで非同期処理を分離
- **SwiftData**: プロジェクトの永続化

---

## 技術的ハイライト

### 1. 非破壊編集
```swift
@Model
final class EditProject {
    @Attribute(.externalStorage)
    var originalImageData: Data?      // オリジナル画像を保持
    var adjustmentData: Data?         // パラメータのみJSON保存
    // ...
}
```

### 2. Core Imageフィルター処理
```swift
actor ImageProcessingService {
    private let context: CIContext  // Metal対応で高速化

    func applyAdjustments(to image: UIImage, adjustment: ImageAdjustment) -> UIImage? {
        // CIColorControls, CIExposureAdjust等を組み合わせ
    }
}
```

### 3. ジェネリック履歴管理
```swift
@Observable
final class HistoryManager<State: Equatable & Codable> {
    private var undoStack: [State] = []
    private var redoStack: [State] = []
    let maxHistoryCount: Int

    func record(_ state: State) { ... }
    func undo(currentState: State) -> State? { ... }
    func redo(currentState: State) -> State? { ... }
}
```

### 4. レイヤー合成
```swift
actor LayerCompositorService {
    func compositeAllLayers(
        baseImage: UIImage,
        drawingLayers: [DrawingLayer],
        textLayers: [TextLayer]
    ) -> UIImage {
        // UIGraphicsImageRendererで全レイヤーを合成
    }
}
```

---

## テスト

Swift Testingを使用した包括的なユニットテスト：
- `ImageAdjustmentTests` - 調整パラメータのテスト
- `FilterPresetTests` - フィルター設定のテスト
- `HistoryManagerTests` - Undo/Redo履歴のテスト
- `CropSettingsTests` - クロップ設定のテスト
- `DrawingStrokeTests` - 描画機能のテスト

---

## UI/UXの特徴

### ブランドガイドライン準拠
- AsaCoffeeBrown (#C68C53) - アクセントカラー
- AsaMocha (#8B5A2B) - ツールバー背景
- AsaSoftCream (#E8D5B9) - テキスト・アイコン
- AsaDarkSlate (#2F3E46) - 背景色

### インタラクション
- 0.2秒のeaseInOutアニメーション
- ダブルタップでズームトグル
- ピンチでズーム操作
- スワイプでプロジェクト削除

---

## 使用フレームワーク

- **SwiftUI** - UI構築
- **SwiftData** - データ永続化
- **Core Image** - 画像処理
- **PhotosUI** - 写真ピッカー
- **Photos** - 写真ライブラリアクセス

---

## ビルド・実行方法

```bash
cd Apps/AsaPhotoEditor
xcodegen generate
open AsaPhotoEditor.xcodeproj

# またはコマンドラインビルド
xcodebuild -project AsaPhotoEditor.xcodeproj -scheme AsaPhotoEditor build
```

---

## 今後の拡張可能性

1. **AIフィルター** - Core MLを使用したスタイル転送
2. **クラウド同期** - iCloudでのプロジェクト同期
3. **バッチ編集** - 複数画像への一括編集適用
4. **カスタムフィルター** - ユーザー定義フィルターの保存
5. **動画対応** - 静止画から動画編集への拡張

---

## 学習ポイント

### Core Imageの活用
- CIFilterチェーンによる複数エフェクトの組み合わせ
- Metalバックエンドによるパフォーマンス最適化
- CIContextの再利用による効率化

### 非破壊編集の設計
- オリジナルデータと編集パラメータの分離
- いつでも元に戻せる安心感
- メモリ効率の良い実装

### SwiftDataの実践
- @Model による簡潔なモデル定義
- @Query でのリアクティブなデータ取得
- Codable型のData保存による柔軟性

---

## まとめ

AsaPhotoEditorは、上級アプリとして複数の高度な機能を統合した画像編集アプリです。Core Imageによる画像処理、SwiftDataによるプロジェクト管理、ジェネリック型による再利用可能な履歴管理など、モダンなSwift/SwiftUIの技術を総合的に活用しています。

プロフェッショナルな画像編集アプリの基盤として、今後の機能拡張にも対応できる設計となっています。
