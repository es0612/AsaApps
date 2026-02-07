# AsaPhotoStory（#95）実装計画

## Context

README.mdの100本ノック95番「AsaPhotoStory: 写真でストーリーを作成」を上級アプリとして設計・実装する。家族の思い出を写真ストーリーとして残す、温かみのあるアプリを目指す。

**最新iOS技術リサーチの結果**、以下を積極採用する：
- **Vision Framework**: 画像分類・テキスト検出による写真分析
- **Foundation Models** (iOS 26+): AIキャプション自動生成（条件付き）
- **SwiftData**: モダンデータ永続化
- **TipKit**: ユーザーガイダンス
- **AVFoundation**: スライドショー動画生成
- **PencilKit**: 手書き注釈

---

## アーキテクチャ概要

### パッケージ構成

```
Packages/AsaPhotoStoryKit/        # ドメインパッケージ（テスト可能）
├── Package.swift                  # swift-tools-version: 5.9, iOS 17+
├── Sources/AsaPhotoStoryKit/
│   ├── Models/                    # SwiftData @Model + 補助型
│   ├── ViewModels/                # @MainActor @Observable
│   ├── Services/                  # actor / Protocol
│   ├── Errors/                    # エラー定義
│   └── Protocols/                 # DI用プロトコル
└── Tests/AsaPhotoStoryKitTests/   # Swift Testing

Apps/AsaPhotoStory/
├── project.yml
├── Sources/                       # View層 + App Entry
│   ├── AsaPhotoStoryApp.swift
│   ├── ContentView.swift
│   └── Views/                     # 画面別サブフォルダ
├── AsaPhotoStoryTests/
└── AsaPhotoStoryUITests/
```

**参照パターン**: `Packages/AsaSmartReminderKit/Package.swift`, `Apps/AsaSmartReminder/project.yml`

---

## データモデル設計

### PhotoStory（ストーリー本体） - @Model

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| id | UUID | 一意識別子 |
| title | String | ストーリータイトル |
| storyDescription | String? | 説明文 |
| templateRawValue | String | StoryTemplate.rawValue |
| themeRawValue | String | StoryTheme.rawValue |
| createdAt / updatedAt | Date | タイムスタンプ |
| isFavorite | Bool | お気に入りフラグ |
| tagsJSON | Data? | タグ配列（JSON） |
| thumbnailData | Data? (.externalStorage) | サムネイル画像 |
| pages | [StoryPage] | @Relationship(deleteRule: .cascade) |

### StoryPage（1ページ） - @Model

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| id | UUID | 一意識別子 |
| order | Int | ページ順序 |
| layoutRawValue | String | PageLayout.rawValue |
| backgroundColorHex | String? | 背景色（HEXコード） |
| transitionRawValue | String | PageTransition.rawValue |
| duration | TimeInterval | スライドショー表示秒数（デフォルト3.0） |
| backgroundImageData | Data? (.externalStorage) | 背景画像 |
| elements | [StoryElement] | @Relationship(deleteRule: .cascade) |
| story | PhotoStory? | 親ストーリー |

### StoryElement（ページ上の要素） - @Model

単一テーブル設計（`typeRawValue`で区別）。AsaPhotoEditorの`TextLayer`パターン（正規化座標0.0-1.0）を踏襲。

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| id | UUID | 一意識別子 |
| typeRawValue | String | ElementType: photo/text/sticker/drawing |
| positionX / positionY | Double | 正規化座標 (0.0-1.0) |
| width / height | Double | 正規化サイズ |
| rotation | Double | ラジアン |
| zOrder | Int | レイヤー順序 |
| opacity | Double | 不透明度 |
| text / fontName / fontSize / textColorHex | String?等 | テキスト要素用 |
| imageData | Data? (.externalStorage) | 写真要素用 |
| captionText | String? | AIキャプション or ユーザー入力 |
| stickerName | String? | SF Symbol名 |
| drawingData | Data? | PencilKitデータ |
| page | StoryPage? | 親ページ |

**参照実装**: `Apps/AsaPhotoEditor/AsaPhotoEditor/Models/EditProject.swift` (JSON Data + computed properties), `TextLayer.swift` (正規化座標)

### 補助型（enum / struct）

- **StoryTemplate**: blank, travel, familyEvent, dailyLife, birthday, season, milestone
- **StoryTheme**: warm(AsaCoffeeBrown系), cool, classic, pastel, monochrome, natural
- **PageLayout**: singlePhoto, twoHorizontal, twoVertical, threeGrid, fourGrid, photoWithText, textOnly, freeform
- **PageTransition**: none, fade, slide, dissolve, push
- **ElementType**: photo, text, sticker, drawing
- **ExportSettings**: format(images/pdf/video), resolution(1080p/1440p/4K)

---

## 主要画面（10画面）

| # | 画面 | 概要 |
|---|------|------|
| 1 | StoryListView | ストーリー一覧（LazyVGrid、検索、フィルター） |
| 2 | TemplateGalleryView | テンプレート選択（.sheet） |
| 3 | StoryEditorView | メイン編集画面（ページサムネイルストリップ + キャンバス） |
| 4 | PageCanvasView | ページ内要素の配置・編集（ドラッグ&リサイズ） |
| 5 | PhotoPickerSheetView | PHPicker写真選択（.sheet） |
| 6 | TextEditorSheetView | テキスト要素編集（フォント、色、サイズ） |
| 7 | CaptionSuggestionView | AIキャプション提案（.sheet） |
| 8 | StoryPreviewView | スライドショープレビュー（.fullScreenCover） |
| 9 | ExportSheetView | エクスポート設定 + ShareLink |
| 10 | StorySettingsView | ストーリーメタデータ編集 |

**ナビゲーション**: NavigationStack → StoryListView → (テンプレート選択sheet) → StoryEditorView → (各シート)

---

## Service層設計

| Service | 責務 | パターン |
|---------|------|---------|
| StoryDataService | SwiftData CRUD操作 | actor (@ModelActor相当) |
| PhotoPickerService | PHPicker連携、画像リサイズ | actor |
| ImageAnalysisService | Vision Framework画像分類・テキスト検出 | actor |
| CaptionService | AIキャプション生成（Protocol + Factory） | Protocol + @available分岐 |
| SlideshowExportService | AVFoundation動画生成 | actor |
| ImageStorageService | 画像ファイルのローカル保存 | actor |

**CaptionService設計** (Foundation Models条件付き):
```
protocol CaptionGenerating: Sendable
├── @available(iOS 26, *) FoundationModelCaptionService  # Foundation Models API
└── VisionCaptionService                                  # VNClassifyImageRequest フォールバック
CaptionServiceFactory.create() で自動切替
```

**HistoryManager再利用**: `Apps/AsaPhotoEditor/AsaPhotoEditor/Services/HistoryManager.swift` のジェネリック undo/redo クラスをAsaPhotoStoryKit内にコピーして活用

---

## 実装フェーズ

### Phase 1: 基盤構築
**成果物**:
- `Packages/AsaPhotoStoryKit/` Package.swift + Models + StoryDataService + ImageStorageService
- `Apps/AsaPhotoStory/` project.yml + App Entry + StoryListView + StoryListViewModel
- 空状態表示、基本CRUD

**テスト**: モデル26 + Service10 + ViewModel8 = **44テスト**

### Phase 2: エディター機能
**成果物**:
- TemplateGalleryView + StoryEditorView + PageCanvasView
- PhotoPickerService + 写真選択シート
- テキスト編集、ステッカー追加、手書き注釈（PencilKit）
- ページサムネイルストリップ、ツールバー
- undo/redo（HistoryManager活用）

**テスト**: ViewModel32 = **32テスト**

### Phase 3: AI・エクスポート・プレビュー
**成果物**:
- ImageAnalysisService (Vision Framework) + CaptionService (Protocol + Factory)
- StoryPreviewView（スライドショー再生、ページ遷移アニメーション）
- SlideshowExportService (AVFoundation MP4動画)
- ExportSheetView + ShareLink/Transferable共有
- ExportProgressView

**テスト**: Service16 + ViewModel12 = **28テスト**

### Phase 4: 拡張・品質
**成果物**:
- TipKit統合（初回ガイダンス）
- VoiceOver / Dynamic Type対応
- パフォーマンス最適化（画像キャッシュ、LazyVStack、プリフェッチ）
- XCUITest（主要フロー）
- ドキュメント: `Docs/Notes/Day95-Implementation.md`

**テスト**: UITest6 + その他6 = **12テスト**

### テスト総計: 約116テスト（95%カバレッジ目標）

---

## project.yml

```yaml
name: AsaPhotoStory
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
packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit
  AsaPhotoStoryKit:
    path: ../../Packages/AsaPhotoStoryKit
targets:
  AsaPhotoStory:
    type: application
    platform: iOS
    sources: [Sources]
    resources: [Sources/Assets.xcassets]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.asapapa.apps.asaphotostory
      GENERATE_INFOPLIST_FILE: true
      INFOPLIST_KEY_UIApplicationSceneManifest_Generation: true
      INFOPLIST_KEY_UILaunchScreen_Generation: true
      INFOPLIST_KEY_CFBundleDisplayName: "AsaPhotoStory"
      INFOPLIST_KEY_NSPhotoLibraryUsageDescription: "写真を選択してストーリーを作成するために写真ライブラリへのアクセスが必要です"
      INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription: "作成したストーリーを写真ライブラリに保存するために書き込み権限が必要です"
    dependencies:
      - package: AsaUIKit
        product: AsaUIKit
      - package: AsaPhotoStoryKit
        product: AsaPhotoStoryKit
  AsaPhotoStoryTests:
    type: bundle.unit-test
    platform: iOS
    sources: [AsaPhotoStoryTests]
    settings:
      GENERATE_INFOPLIST_FILE: true
    dependencies:
      - target: AsaPhotoStory
  AsaPhotoStoryUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [AsaPhotoStoryUITests]
    settings:
      GENERATE_INFOPLIST_FILE: true
    dependencies:
      - target: AsaPhotoStory
```

---

## 重要な参照ファイル

| ファイル | 参照理由 |
|---------|---------|
| `Apps/AsaSmartReminder/project.yml` | project.yml構成テンプレート |
| `Packages/AsaSmartReminderKit/Package.swift` | ドメインパッケージ構成テンプレート |
| `Apps/AsaPhotoEditor/Models/EditProject.swift` | @Model + .externalStorage + JSON Data パターン |
| `Apps/AsaPhotoEditor/Models/TextLayer.swift` | 正規化座標 + Codable struct パターン |
| `Apps/AsaPhotoEditor/Services/HistoryManager.swift` | undo/redo ジェネリッククラス（再利用） |
| `Apps/AsaPhotoEditor/Services/ImageProcessingService.swift` | actor + CIContext(Metal) 画像処理 |
| `Apps/AsaPhotoEditor/Services/ExportService.swift` | エクスポートサービスパターン |
| `Packages/AsaUIKit/Sources/AsaUIKit/Components/` | AsaButton, AsaCard 共有コンポーネント |

---

## 検証方法

1. **パッケージビルド**: `cd Packages/AsaPhotoStoryKit && swift build`
2. **パッケージテスト**: `cd Packages/AsaPhotoStoryKit && swift test`
3. **プロジェクト生成**: `cd Apps/AsaPhotoStory && xcodegen generate`
4. **アプリビルド**: `xcodebuild -project AsaPhotoStory.xcodeproj -scheme AsaPhotoStory -destination 'platform=iOS Simulator,name=iPhone 16'`
5. **UIテスト**: Xcode > Product > Test (Cmd+U)
6. **手動検証**: ストーリー作成 → 写真追加 → テキスト追加 → プレビュー → エクスポートの全フロー確認

---

## エージェントチーム構成（実装時）

| エージェント | 担当 | subagent_type |
|------------|------|---------------|
| package-builder | AsaPhotoStoryKit パッケージ + Models + Services | general-purpose |
| app-builder | Apps/AsaPhotoStory View層 + project.yml | general-purpose |
| test-builder | テスト実装（Unit + UI） | general-purpose |
