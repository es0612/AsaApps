# AsaPhotoEditor パフォーマンス改善プラン

## Context

AsaPhotoEditor（アプリ#80）で画像編集時のプレビュー反映に大きなラグが発生している。
スライダー操作やフィルター適用後、処理中ダイアログが長時間表示され、「忘れた頃に反映される」ような体験になっている。

**原因調査の結果、5つの重大なボトルネックを特定した。**
推定で **2〜3倍の高速化** が可能。

---

## 特定されたボトルネック

### 1. プレビューにフル解像度画像を処理している（最大の原因）
- **場所**: `PhotoEditorViewModel.swift:186` → `ImageProcessingService.applyAllEdits()`
- **問題**: `resizeForPreview()` メソッドが存在する（:156行目）のに、`updatePreview()` ではオリジナル画像（例: 4000x3000 = 12MP）をそのまま処理に渡している
- **影響**: 画像サイズに比例して処理時間が増大。画面プレビューは300〜400pt程度なのに、フル解像度で全フィルターを適用している
- **推定効果**: プレビュー用リサイズだけで **4〜10倍の高速化**

### 2. CIImage ↔ UIImage の不要な変換が3回発生
- **場所**: `ImageProcessingService.applyAllEdits()` (:171-195)
- **問題**: 3つのステップが独立した関数で、各関数がUIImage入力→CIImage変換→処理→CGImage変換→UIImage出力を行う
  ```
  UIImage → [applyCropAndRotation: UIGraphicsImageRenderer(CPU)] → UIImage
  UIImage → [applyAdjustments: CIImage chain → createCGImage(GPU sync)] → UIImage
  UIImage → [applyFilter: CIImage chain → createCGImage(GPU sync)] → UIImage
  ```
- **影響**: `context.createCGImage()` はGPU同期ポイント。3回呼ばれると3回GPUフラッシュが発生
- **推定効果**: 1回の統合パイプラインにすれば **30〜50%の高速化**

### 3. デバウンスなし＋前タスク未キャンセル
- **場所**: `PhotoEditorViewModel.schedulePreviewUpdate()` (:207-211)
- **問題**: `Task { await updatePreview() }` が毎回新規生成。スライダー操作中に数十個のTaskが並行して生成・実行される
- **影響**: CPU/GPU リソースの浪費、メモリスパイク、UI応答性の低下
- **推定効果**: デバウンス＋キャンセルで **不要な処理を90%以上削減**

### 4. スライダー操作中に毎フレーム履歴記録
- **場所**: `AdjustmentPanelView.swift:58-61`
- **問題**: `.onChange(of: viewModel.adjustment)` で `recordHistory()` + `schedulePreviewUpdate()` が毎回発火
- **影響**: スライダーを1秒ドラッグするだけで60個の中間状態が履歴に記録される。メモリ浪費と処理オーバーヘッド
- **推定効果**: onEnded のみに変更で **履歴処理のオーバーヘッド除去**

### 5. レイヤー合成がCPU（UIGraphicsImageRenderer）
- **場所**: `LayerCompositorService.swift:19`
- **問題**: Metal GPUで処理した結果をCPUのUIGraphicsImageRendererでレイヤー合成 → GPU→CPU転送が発生
- **影響**: 高解像度画像でのレイヤー合成がCPU律速
- **優先度低**: プレビューサイズ縮小（改善1）が実装されれば影響は軽微

---

## 改善プラン

### 改善1: プレビュー用ダウンサンプリングの導入（効果: 最大）

**ファイル**: `PhotoEditorViewModel.swift`

`updatePreview()` で処理に渡す前に、画像をプレビュー表示サイズにリサイズする。
既存の `resizeForPreview()` を活用するが、ターゲットサイズを画面解像度に合わせて調整する（300→800〜1200程度）。

```swift
func updatePreview() async {
    guard let original = originalImage else { return }
    isProcessing = true

    // プレビュー用にダウンサンプリング（既存メソッドを活用）
    let previewSource = await imageProcessor.resizeForPreview(
        original,
        targetSize: CGSize(width: 1200, height: 1200)
    )

    var result = await imageProcessor.applyAllEdits(
        to: previewSource,  // ← originalImage ではなくリサイズ済み画像
        adjustment: adjustment,
        filterSettings: filterSettings,
        cropSettings: cropSettings
    ) ?? previewSource

    // ... レイヤー合成
    previewImage = result
    isProcessing = false
}
```

### 改善2: CIImage統合パイプラインの構築（効果: 大）

**ファイル**: `ImageProcessingService.swift`

現在の3段階の独立処理を、CIImageチェーンで統合し、`createCGImage()` を最後の1回だけに抑える。

新しいメソッド `applyAllEditsCombined()` を追加:

```swift
func applyAllEditsCombined(
    to image: UIImage,
    adjustment: ImageAdjustment,
    filterSettings: FilterSettings,
    cropSettings: CropSettings
) -> UIImage? {
    // 1. クロップ・回転は先に UIImage レベルで適用（CIImage では回転が複雑）
    var source = image
    if !cropSettings.isDefault {
        source = applyCropAndRotation(to: source, settings: cropSettings) ?? source
    }

    // 2. CIImage に変換（ここから最後まで CIImage チェーン）
    guard var ciImage = CIImage(image: source) else { return nil }

    // 3. 調整フィルターチェーン（CIImage のまま）
    if !adjustment.isDefault {
        ciImage = applyAdjustmentChain(to: ciImage, adjustment: adjustment)
    }

    // 4. フィルター適用（CIImage のまま）
    if !filterSettings.isDefault {
        ciImage = applyFilterChain(to: ciImage, filter: filterSettings.preset, intensity: filterSettings.intensity) ?? ciImage
    }

    // 5. 最後に1回だけ CGImage に変換（GPU同期は1回のみ）
    return createUIImage(from: ciImage)
}
```

また、内部メソッドとして `applyAdjustmentChain()` と `applyFilterChain()` を追加。
これらは CIImage → CIImage で、中間的な UIImage 変換を行わない。

### 改善3: デバウンス＋タスクキャンセルの導入（効果: 大）

**ファイル**: `PhotoEditorViewModel.swift`

```swift
// プレビュー更新タスクの参照を保持
private var previewUpdateTask: Task<Void, Never>?

func schedulePreviewUpdate() {
    // 前回のタスクをキャンセル
    previewUpdateTask?.cancel()

    previewUpdateTask = Task {
        // デバウンス: 150ms待機
        try? await Task.sleep(for: .milliseconds(150))

        // キャンセルされていなければ実行
        guard !Task.isCancelled else { return }
        await updatePreview()
    }
}
```

`updatePreview()` 内でもキャンセルチェックを追加:
```swift
func updatePreview() async {
    guard let original = originalImage else { return }
    guard !Task.isCancelled else { return }

    isProcessing = true
    // ... 処理 ...

    guard !Task.isCancelled else {
        isProcessing = false
        return
    }
    previewImage = result
    isProcessing = false
}
```

### 改善4: 履歴記録をスライダー操作完了時のみに変更（効果: 中）

**ファイル**: `AdjustmentPanelView.swift`, `FilterPanelView.swift`

`.onChange` で毎フレーム `recordHistory()` を呼ぶのをやめ、スライダー操作完了時のみ記録する。

```swift
Slider(
    value: bindingForType(selectedType),
    in: selectedType.range
)
.tint(Color.asaCoffeeBrown)
.onChange(of: viewModel.adjustment) { _, _ in
    // プレビュー更新のみ（デバウンス付き）
    viewModel.schedulePreviewUpdate()
}
.onReceive(
    // スライダー操作が止まってから履歴記録
    NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
) { _ in }

// ※ 注: SwiftUI の Slider には onEditingChanged が使える
// より良い方法:
Slider(
    value: bindingForType(selectedType),
    in: selectedType.range,
    onEditingChanged: { isEditing in
        if !isEditing {
            viewModel.recordHistory()
        }
    }
)
.onChange(of: viewModel.adjustment) { _, _ in
    viewModel.schedulePreviewUpdate()
}
```

`FilterPanelView.swift` の強度スライダーも同様に修正。

---

## 修正対象ファイル一覧

| ファイル | 変更内容 |
|---------|---------|
| `AsaPhotoEditor/ViewModels/PhotoEditorViewModel.swift` | デバウンス導入、プレビューリサイズ追加、タスクキャンセル |
| `AsaPhotoEditor/Services/ImageProcessingService.swift` | CIImage統合パイプライン追加 |
| `AsaPhotoEditor/Views/Adjustment/AdjustmentPanelView.swift` | 履歴記録タイミング変更 |
| `AsaPhotoEditor/Views/Filter/FilterPanelView.swift` | 履歴記録タイミング変更 |

## 既存の再利用可能なコード

- `ImageProcessingService.resizeForPreview()` (:156-168) - 既存だが未使用。ターゲットサイズを調整して活用
- `ImageProcessingService.context` (:13) - Metal CIContext は既に再利用パターンで実装済み
- 各 CIFilter 適用メソッド（applyColorControls, applyExposure 等）- CIImage→CIImage の内部ロジックはそのまま再利用

## 変更しないもの

- `LayerCompositorService.swift` - プレビューサイズ縮小で十分な改善が見込まれるため、今回は変更しない
- `ExportService.swift` - エクスポートはフル解像度が必要で、ユーザーが能動的に実行するため問題なし
- `HistoryManager.swift` - ロジック自体は問題なし（呼び出し頻度を改善で対応）

## 検証方法

1. **ビルド確認**: `xcodegen generate && xcodebuild -project AsaPhotoEditor.xcodeproj -scheme AsaPhotoEditor -sdk iphonesimulator build`
2. **動作確認**: スライダー操作時のプレビュー応答速度が体感で改善されることを確認
3. **既存テスト**: `xcodebuild test` で回帰テストが通ることを確認
4. **確認ポイント**:
   - スライダーをドラッグ中に処理中ダイアログが出ないこと（デバウンスが効いている）
   - スライダーを離してから150ms程度でプレビューに反映されること
   - Undo/Redoが正常に動作すること（スライダー中間値が履歴に大量に入らないこと）
   - エクスポートはフル解像度で正常に出力されること（プレビューリサイズの影響を受けない）
