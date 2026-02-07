# Day 95 - AsaPhotoStory: 写真でストーリーを作成

## アプリ概要
家族の思い出を写真ストーリーとして残す、温かみのあるアプリ。写真を選んでページに配置し、テキストやステッカーで装飾、スライドショーとしてプレビュー・エクスポートできる。

## 使用技術
- **SwiftData**: @Model でストーリー、ページ、要素のリレーション管理（@Relationship cascade）
- **Vision Framework**: 画像分類（VNClassifyImageRequest）、テキスト検出（VNRecognizeTextRequest）
- **AVFoundation**: スライドショー動画（MP4）生成
- **PencilKit**: 手書き注釈機能
- **TipKit**: 初回ユーザーガイダンス
- **PhotosUI**: PhotosPicker での写真選択
- **Swift Testing**: @Test構文で46テスト

## アーキテクチャ
- **MVVM + ローカルパッケージ化**
- **AsaPhotoStoryKit**: ドメインパッケージ（Models, ViewModels, Services, Errors, Protocols）
- **Apps/AsaPhotoStory**: View層 + App Entry
- **Protocol-based DI**: テスト可能性とモジュール性の両立

## 画面構成（10画面）
1. StoryListView - ストーリー一覧（LazyVGrid、検索、フィルター）
2. TemplateGalleryView - テンプレート選択
3. StoryEditorView - メイン編集画面（ページサムネイルストリップ + キャンバス）
4. PageCanvasView - 要素配置・編集（ドラッグ&リサイズ&回転）
5. PhotoPickerSheetView - 写真選択
6. TextEditorSheetView - テキスト編集（フォント、色、サイズ）
7. CaptionSuggestionView - AIキャプション提案
8. StoryPreviewView - スライドショープレビュー
9. ExportSheetView - エクスポート設定 + ShareLink
10. StorySettingsView - メタデータ編集

## データモデル
- PhotoStory → StoryPage → StoryElement の3層リレーション
- StoryElement: 単一テーブル設計（photo/text/sticker/drawing）
- 正規化座標（0.0-1.0）で画面サイズ非依存
- .externalStorage で大容量画像データ管理

## サービス設計
- StoryDataService: SwiftData CRUD
- ImageStorageService: 画像ファイル管理（actor）
- PhotoPickerService: PhotosPicker連携（actor）
- ImageAnalysisService: Vision Framework画像分析（actor）
- CaptionService: Protocol + Factory パターン（将来のFoundation Models対応）
- SlideshowExportService: AVFoundation動画生成（actor）
- HistoryManager: ジェネリック undo/redo

## テスト
- 46テスト（Swift Testing）
- ModelTests: 26テスト
- ServiceTests: 10テスト
- ViewModelTests: 8テスト（MockStoryDataService使用）
- カバレッジ目標: 95%

## 学んだこと・技術的チャレンジ
- SwiftData の @Relationship で cascade 削除を実装し、データ整合性を確保
- Vision Framework の VNClassifyImageRequest で画像を自動分類し、AIキャプションの基礎データに活用
- actor パターンで画像処理・ファイル操作のスレッド安全性を保証
- Protocol + Factory パターンで将来のiOS 26 Foundation Models対応を準備
- 正規化座標（0.0-1.0）で任意の画面サイズに対応するキャンバス設計
- HistoryManager のジェネリック設計でundo/redoを型安全に実装
