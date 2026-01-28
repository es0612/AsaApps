# AsaPhotoEditor 実装計画書

**アプリ番号**: #80（上級アプリ）
**概要**: 高度な画像編集機能を持つSwiftUIアプリ

---

## 1. 機能概要

### 必須機能
| 機能 | 説明 |
|------|------|
| **画像調整** | 明るさ、コントラスト、彩度、露出、シャープネス、ハイライト、シャドウ |
| **フィルター** | 12種類以上のプリセット（セピア、ノワール、ビンテージ、ぼかし、モザイク等） |
| **クロップ・回転** | 自由クロップ、アスペクト比固定、90度回転、反転 |
| **テキスト追加** | フォント、色、サイズ、位置調整 |
| **描画ツール** | ペン、ブラシ、消しゴム（色・太さ調整） |
| **Undo/Redo** | 最大20ステップの履歴管理 |

### 上級機能（差別化）
- **非破壊編集**: オリジナル画像を保持、パラメータを別途保存
- **プロジェクト保存**: SwiftDataで編集状態を永続化、後から再編集可能
- **バッチエクスポート**: 複数解像度で一括書き出し

---

## 2. アーキテクチャ

```
Apps/AsaPhotoEditor/
├── project.yml
├── AsaPhotoEditor/
│   ├── AsaPhotoEditorApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── EditProject.swift          # @Model - プロジェクト管理
│   │   ├── ImageAdjustment.swift       # 調整パラメータ
│   │   ├── FilterPreset.swift          # フィルター定義
│   │   ├── CropSettings.swift          # クロップ設定
│   │   ├── TextLayer.swift             # テキストレイヤー
│   │   └── DrawingStroke.swift         # 描画ストローク
│   ├── Services/
│   │   ├── ImageProcessingService.swift  # Core Image処理（actor）
│   │   ├── LayerCompositorService.swift  # レイヤー合成
│   │   ├── HistoryManager.swift          # Undo/Redo管理
│   │   ├── ProjectDataService.swift      # SwiftData操作
│   │   └── ExportService.swift           # バッチエクスポート
│   ├── ViewModels/
│   │   ├── PhotoEditorViewModel.swift    # メインVM
│   │   ├── AdjustmentViewModel.swift
│   │   ├── FilterViewModel.swift
│   │   ├── CropViewModel.swift
│   │   └── DrawingViewModel.swift
│   └── Views/
│       ├── Editor/
│       │   ├── EditorMainView.swift
│       │   ├── ImagePreviewView.swift
│       │   └── EditorToolbar.swift
│       ├── Adjustment/
│       ├── Filter/
│       ├── Crop/
│       ├── Layer/
│       ├── Drawing/
│       ├── Project/
│       └── Export/
├── AsaPhotoEditorTests/
└── AsaPhotoEditorUITests/
```

---

## 3. 主要モデル

### EditProject（SwiftData）
```swift
@Model
final class EditProject {
    var id: UUID
    var name: String
    var originalImageData: Data      // 非破壊編集用
    var adjustmentData: Data?        // ImageAdjustment JSON
    var filterPresetData: Data?
    var cropSettingsData: Data?
    var textLayersData: Data?
    var drawingStrokesData: Data?
    var createdAt: Date
    var updatedAt: Date
}
```

### ImageAdjustment
```swift
struct ImageAdjustment: Codable, Equatable {
    var brightness: Double = 0.0     // -1.0 ~ 1.0
    var contrast: Double = 1.0       // 0.5 ~ 2.0
    var saturation: Double = 1.0     // 0.0 ~ 2.0
    var exposure: Double = 0.0       // -2.0 ~ 2.0
    var sharpness: Double = 0.0      // 0.0 ~ 1.0
    var highlights: Double = 0.0
    var shadows: Double = 0.0
}
```

---

## 4. 主要サービス

### ImageProcessingService（Core Image処理）
- `actor`で非同期処理を分離
- CIFilter: CIColorControls, CIExposureAdjust, CISharpenLuminance等
- フィルター適用: CISepiaTone, CIGaussianBlur, CIPixellate等

### HistoryManager（Undo/Redo）
- ジェネリック型で任意の状態を管理
- 最大20ステップの履歴
- `canUndo`, `canRedo` プロパティ

### LayerCompositorService
- UIGraphicsImageRenderer で全レイヤーを合成
- 描画順序: ベース画像 → 描画 → テキスト → ステッカー

---

## 5. 実装フェーズ

| Phase | 内容 | 期間目安 |
|-------|------|---------|
| **1** | プロジェクト作成、SwiftDataモデル、基本UI | 2-3日 |
| **2** | 画像調整機能（Core Image、スライダーUI） | 3-4日 |
| **3** | フィルター機能（12種類プリセット） | 2-3日 |
| **4** | クロップ・回転機能（ジェスチャー操作） | 3-4日 |
| **5** | レイヤー編集（テキスト、ステッカー） | 4-5日 |
| **6** | 描画機能（Canvas API） | 3-4日 |
| **7** | 履歴・プロジェクト管理 | 2-3日 |
| **8** | エクスポート機能 | 2-3日 |
| **9** | テスト・最適化・ドキュメント | 3-4日 |

**合計**: 約24-33日

---

## 6. 参考ファイル

| ファイル | 参考内容 |
|---------|---------|
| `Apps/AsaPhotoFilter/AsaPhotoFilter/ImageFilterService.swift` | Core Image処理パターン |
| `Apps/AsaPhotoFrame/AsaPhotoFrame/PhotoFrameViewModel.swift` | UIGraphicsImageRenderer |
| `Apps/AsaDrawingPro/` | 描画機能・レイヤー管理 |
| `Packages/AsaUIKit/` | ブランドカラー、共有コンポーネント |

---

## 7. テスト戦略

- **Unit Tests**: 95%カバレッジ目標（Swift Testing @Test構文）
- **テスト対象**: ImageAdjustment, HistoryManager, ImageProcessingService, PhotoEditorViewModel
- **UI Tests**: 主要フロー（画像読み込み→編集→エクスポート）

---

## 8. 検証方法

1. **ビルド確認**: `xcodegen generate && xcodebuild -project AsaPhotoEditor.xcodeproj -scheme AsaPhotoEditor build`
2. **テスト実行**: `swift test`
3. **動作確認**:
   - 画像を選択して各調整スライダーを操作
   - フィルター適用と強度調整
   - クロップ・回転操作
   - テキスト・描画追加
   - Undo/Redo動作
   - プロジェクト保存・再読み込み
   - 複数解像度エクスポート
