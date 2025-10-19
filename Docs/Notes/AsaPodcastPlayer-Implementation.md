# AsaPodcastPlayer - 実装ノート

## アプリ概要

**AsaPodcastPlayer**は朝活パパエンジニアのためのポッドキャストプレイヤーアプリです。シンプルで使いやすいインターフェースで、ポッドキャストの再生、管理、ブックマーク機能を提供します。

### 主な機能

- ✅ **音声ファイル再生**: m4a、mp3、mp4、aac形式の音声ファイルをサポート
- ✅ **再生コントロール**: 再生/一時停止、スキップ、早送り/巻き戻し、再生速度調整
- ✅ **プレイリスト管理**: エピソードの順次再生、自動再生機能
- ✅ **進捗管理**: 再生位置の自動保存、再生済み/未再生マーク
- ✅ **ブックマーク**: お気に入りエピソードのブックマーク機能
- ✅ **スリープタイマー**: 指定時間後に自動停止する機能
- ✅ **バックグラウンド再生**: アプリがバックグラウンドでも音声が再生可能

## アーキテクチャ

### MVVM パターン

```
ContentView (View)
    ↓
PodcastPlayerViewModel (ViewModel)
    ↓
PodcastAudioManager (Model/Service)
PodcastLibraryManager (Model/Service)
```

### 主要コンポーネント

#### 1. ContentView
- メインのUIを提供
- プレイヤーコントロール、エピソード情報、進捗表示
- ライブラリとエピソード詳細のモーダル表示

#### 2. PodcastPlayerViewModel
- アプリの主要なビジネスロジックを管理
- オーディオマネージャーとライブラリマネージャーの調整
- 再生状態、プレイリスト、設定の管理

#### 3. PodcastAudioManager
- AVAudioPlayerを使用した音声再生機能
- 再生制御、シーク、再生速度調整
- オーディオセッション管理とイベントハンドリング

#### 4. PodcastLibraryManager
- ポッドキャストとエピソードのデータ管理
- バンドルリソースからの音声ファイル読み込み
- UserDefaultsを使用した永続化

## 技術スタック

### フレームワーク
- **SwiftUI**: UIフレームワーク
- **AVFoundation**: 音声再生
- **Combine**: リアクティブプログラミング
- **@Observable**: 状態管理

### 使用技術
- **XcodeGen**: プロジェクト設定管理
- **AsaUIKit**: 共有UIコンポーネントライブラリ
- **UserDefaults**: データ永続化
- **AVAsset**: メタデータ抽出

## バンドルリソースからの音声ファイル読み込み

### 実装詳細

アプリは起動時に以下の手順で音声ファイルを読み込みます：

1. **リソースディレクトリの検索**
   ```swift
   guard let soundURL = Bundle.main.resourceURL?.appendingPathComponent("sound")
   ```

2. **対応ファイルの検出**
   - サポート形式: m4a, mp3, mp4, aac
   - FileManagerを使用してディレクトリ内のファイルを列挙

3. **メタデータ抽出**
   - AVAssetを使用して以下を取得：
     - タイトル (メタデータまたはファイル名)
     - アーティスト
     - アートワーク
     - デュレーション

4. **エピソード作成**
   - 各音声ファイルからPodcastEpisodeオブジェクトを作成
   - Podcastオブジェクトにまとめて管理

### ファイル配置

音声ファイルは以下の場所に配置：
```
Apps/AsaPodcastPlayer/AsaPodcastPlayer/sound/
└── 保育園通い始めの洗礼の話.m4a
```

## UI/UX 改善

### プレイヤーコントロールの改善

1. **視覚的フィードバックの強化**
   - ボタンのフォントウェイト強化
   - 無効時のグレーアウト表示
   - 再生ボタンのシャドウ効果

2. **ローディング状態の表示**
   - ProgressViewによるローディングインジケーター
   - スムーズなアニメーション効果

3. **再生状態の視覚化**
   - 再生中は再生ボタンがわずかにスケールアップ
   - 進捗バーとタイムラインの明確な表示

## データ管理

### PodcastEpisode
```swift
struct PodcastEpisode {
    let id: UUID
    let title: String
    let duration: TimeInterval
    let filePath: URL
    var playbackPosition: TimeInterval
    var isPlayed: Bool
    var isBookmarked: Bool
}
```

### Podcast
```swift
struct Podcast {
    let id: UUID
    let name: String
    let author: String
    var episodes: [PodcastEpisode]
    var isSubscribed: Bool
}
```

### 永続化

- **UserDefaults**を使用してPodcastとEpisodeのデータを保存
- Codableプロトコルでシリアライゼーション
- アートワークは永続化せず、起動時に再読み込み

## オーディオセッション管理

### AVAudioSession設定

```swift
try session.setCategory(.playback, mode: .spokenAudio, options: [])
```

- **カテゴリ**: `.playback` - 再生専用
- **モード**: `.spokenAudio` - ポッドキャストに最適化
- **バックグラウンド再生**: Info.plistで`audio`を指定

### イベントハンドリング

1. **オーディオ割り込み**
   - 電話着信時に一時停止
   - 割り込み終了後に再開

2. **ルート変更**
   - ヘッドフォン抜き取り時に一時停止
   - ユーザー体験の向上

## 再生機能

### 基本コントロール

- **再生/一時停止**: `togglePlayPause()`
- **スキップ**: `skipForward()`, `skipBackward()`
- **シーク**: `seek(to:)`
- **再生速度**: 0.5x ~ 2.0x (0.25x刻み)

### プレイリスト機能

- **自動再生**: エピソード終了後に次のエピソードを自動再生
- **前後移動**: `nextEpisode()`, `previousEpisode()`
- **プレイリスト管理**: `playPlaylist(_:startingAt:)`

### スリープタイマー

```swift
func setSleepTimer(duration: TimeInterval)
```

- 指定時間後に自動停止
- 残り時間の表示
- キャンセル機能

## プロジェクト設定

### project.yml

```yaml
resources:
  - AsaPodcastPlayer/Assets.xcassets
  - AsaPodcastPlayer/sound
```

### Info.plist

重要な設定項目：

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

バックグラウンド再生を有効化

## ビルド・実行

### プロジェクト生成

```bash
cd Apps/AsaPodcastPlayer
xcodegen generate
```

### ビルド

```bash
xcodebuild -project AsaPodcastPlayer.xcodeproj -scheme AsaPodcastPlayer
```

### シミュレーターで実行

```bash
xcodebuild -project AsaPodcastPlayer.xcodeproj \
  -scheme AsaPodcastPlayer \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## トラブルシューティング

### 音声ファイルが再生できない

1. **soundディレクトリの確認**
   ```bash
   ls Apps/AsaPodcastPlayer/AsaPodcastPlayer/sound/
   ```

2. **project.ymlのresources設定確認**
   - `AsaPodcastPlayer/sound`が含まれているか確認

3. **XcodeGenでプロジェクト再生成**
   ```bash
   xcodegen generate
   ```

### ボタンが反応しない

- エピソードが選択されているか確認
- プレイヤーの状態を確認（ローディング中は無効化）

### メタデータが表示されない

- 音声ファイルにメタデータが埋め込まれているか確認
- ファイル名がタイトルとして使用される

## 今後の改善案

### 機能拡張

- [ ] RSSフィードからのポッドキャスト購読
- [ ] オンラインストリーミング再生
- [ ] ダウンロード管理
- [ ] プレイリスト作成・編集
- [ ] エピソードの検索とフィルタリング

### UI/UX改善

- [ ] カスタマイズ可能なテーマ
- [ ] ウィジェット対応
- [ ] CarPlay対応
- [ ] 音声波形の表示
- [ ] チャプターマーカー

### パフォーマンス最適化

- [ ] SwiftDataへの移行（より高度なデータ管理）
- [ ] アートワークのキャッシング
- [ ] バックグラウンドでのメタデータ更新

## 参考リンク

- [AVFoundation Documentation](https://developer.apple.com/av-foundation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Audio Session Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/)

## 実装日時

- **初回実装**: 2025年10月（Day 40-50）
- **バンドルリソース対応**: 2025年10月19日
- **UI改善**: 2025年10月19日

## ライセンス

このアプリは朝活パパエンジニアによる学習プロジェクトの一部です。
