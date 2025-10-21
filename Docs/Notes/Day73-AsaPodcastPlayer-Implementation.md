# Day73: AsaPodcastPlayer 実装ノート

**作成日**: 2025-10-21
**アプリ名**: AsaPodcastPlayer
**カテゴリ**: メディア・エンターテインメント

---

## 📱 アプリ概要

AsaPodcastPlayerは、朝活パパエンジニアのPodcastエピソードを再生できるシンプルなプレイヤーアプリです。AVFoundationを使用したネイティブ音声再生機能を実装し、再生速度変更、スキップ機能などの基本的なPodcast再生機能を提供します。

### 主な機能
- ✅ M4A音声ファイルの再生
- ✅ 再生/一時停止コントロール
- ✅ 30秒スキップ（前後）
- ✅ 再生速度変更（0.5x〜2.0x）
- ✅ シーク機能（スライダー操作）
- ✅ 再生時間表示（現在時間/総時間）
- ✅ バックグラウンド再生対応
- ✅ AsaUIKit統一デザイン

---

## 🏗️ アーキテクチャ

### MVVMパターン

#### Model
- **PodcastEpisode.swift** - エピソード情報モデル
  ```swift
  struct PodcastEpisode: Identifiable, Codable, Sendable {
      let id: UUID
      let title: String
      let description: String
      let audioFileName: String
      let duration: TimeInterval
      let publishedDate: Date
  }
  ```

#### ViewModel
- **PodcastPlayerViewModel.swift** - 再生制御ビジネスロジック
  - @Observableパターン使用
  - PodcastAudioManagerとの橋渡し
  - 時間フォーマット処理
  - 再生速度管理

#### View
- **ContentView.swift** - メインプレイヤー画面
- **EpisodeDetailView.swift** - エピソード詳細カード

#### Audio Manager
- **PodcastAudioManager.swift** - AVFoundation音声管理
  - AVAudioPlayerラッパー
  - 再生/一時停止/シーク/スキップ
  - 再生速度変更
  - バックグラウンド対応

---

## 🛠️ 技術スタック

### フレームワーク
- **SwiftUI** - UI構築
- **AVFoundation** - 音声再生
- **Combine** - リアクティブプログラミング
- **AsaUIKit** - 共有UIコンポーネント

### デザインパターン
- **MVVM** - Model-View-ViewModel
- **@Observable** - モダンSwiftUI状態管理
- **Delegation** - AVAudioPlayerDelegate

### テスト
- **Swift Testing** - ViewModel・モデルの単体テスト
- **XCTest** - UIテスト

---

## 💡 実装の詳細

### 1. AVFoundationによる音声再生

```swift
// PodcastAudioManager.swift
func loadAudio(fileName: String) {
    guard let url = Bundle.main.url(
        forResource: fileName.replacingOccurrences(of: ".m4a", with: ""),
        withExtension: "m4a"
    ) else { return }

    audioPlayer = try? AVAudioPlayer(contentsOf: url)
    audioPlayer?.delegate = self
    audioPlayer?.prepareToPlay()
    audioPlayer?.enableRate = true  // 再生速度変更を有効化
}
```

### 2. バックグラウンド再生設定

**Info.plist**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**Audio Session設定**
```swift
func setupAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(.playback, mode: .default)
    try? audioSession.setActive(true)
}
```

### 3. 再生速度変更機能

```swift
let availablePlaybackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

func changePlaybackRate(_ rate: Float) {
    playbackRate = max(0.5, min(2.0, rate))
    audioPlayer?.rate = playbackRate
}
```

### 4. スキップ機能（30秒前後）

```swift
func skip(seconds: TimeInterval) {
    let newTime = max(0, min(duration, currentTime + seconds))
    seek(to: newTime)
}
```

### 5. リアルタイム時間更新

```swift
private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
        guard let self = self else { return }
        self.currentTime = self.audioPlayer?.currentTime ?? 0
    }
}
```

---

## 🎨 UI/UXデザイン

### カラーパレット（AsaBrand統一）
- **背景**: AsaDarkSlate (#2F3E46)
- **プライマリ**: AsaCoffeeBrown (#C68C53)
- **テキスト**: AsaSoftCream (#E8D5B9)
- **アクセント**: AsaMutedSage (#7A918D)

### レイアウト構成
```
┌─────────────────────────────┐
│    Podcast プレイヤー        │ ← タイトル
├─────────────────────────────┤
│                             │
│   ┌───────────────────┐     │
│   │  エピソードカード  │     │ ← AsaCard
│   │  保育園通い始め... │     │
│   └───────────────────┘     │
│                             │
├─────────────────────────────┤
│   ━━━━━━●━━━━━━━━           │ ← スライダー
│   01:23 / 03:45             │ ← 時間表示
├─────────────────────────────┤
│   [-30s] [▶/⏸] [+30s]      │ ← コントロール
│      速度: [1.0x]            │ ← 再生速度
└─────────────────────────────┘
```

### AsaUIKit活用
- **AsaCard** - エピソード情報表示
- **AsaColors** - ブランドカラー統一
- **角丸・シャドウ** - 10px統一、奥行き感

---

## 🧪 テスト実装

### Unit Tests（Swift Testing）
```swift
@Test("PodcastEpisode初期化テスト")
func testPodcastEpisodeInitialization() { ... }

@Test("再生速度変更テスト")
func testPlaybackRateChange() { ... }

@Test("時間フォーマットテスト")
func testTimeFormatting() { ... }
```

### UI Tests（XCTest）
```swift
func testAppLaunches() { ... }
func testPlayButtonExists() { ... }
func testEpisodeCardExists() { ... }
```

---

## 📦 プロジェクト構成

```
Apps/AsaPodcastPlayer/
├── project.yml                    # XcodeGen設定
├── AsaPodcastPlayer/
│   ├── AsaPodcastPlayerApp.swift  # アプリエントリー
│   ├── ContentView.swift          # メイン画面
│   ├── EpisodeDetailView.swift    # エピソード詳細
│   ├── PodcastPlayerViewModel.swift # ViewModel
│   ├── PodcastAudioManager.swift  # 音声管理
│   ├── PodcastEpisode.swift       # モデル
│   ├── Assets.xcassets/           # アセット
│   └── Info.plist                 # バックグラウンド設定
├── sound/
│   └── 保育園通い始めの洗礼の話.m4a # サンプル音源
├── AsaPodcastPlayerTests/         # 単体テスト
└── AsaPodcastPlayerUITests/       # UIテスト
```

---

## 📚 学習ポイント

### 1. AVFoundation基礎
- **AVAudioPlayer** - 音声ファイル再生の基本
- **AVAudioSession** - バックグラウンド再生設定
- **Delegate Pattern** - 再生終了イベント処理

### 2. Timerによるリアルタイム更新
- 0.1秒間隔での再生時間更新
- メモリリーク防止のための`weak self`使用

### 3. バックグラウンド再生
- Info.plistでのUIBackgroundModes設定
- Audio Sessionのカテゴリ設定

### 4. 再生速度制御
- `enableRate`プロパティの有効化
- 0.5x〜2.0xの範囲制限

### 5. @Observableパターン
- モダンなSwiftUI状態管理
- ViewModel層での状態管理

---

## ✨ 実装のハイライト

### 1. クリーンなアーキテクチャ
- MVVM完全分離
- PodcastAudioManagerの責務明確化
- テスタビリティ重視

### 2. AsaUIKit統一デザイン
- ブランドカラー完全統一
- AsaCard再利用
- 温かみのある朝活テーマ

### 3. ユーザビリティ
- 直感的なスライダー操作
- 30秒スキップの利便性
- 再生速度ワンタップ切り替え

### 4. パフォーマンス
- 0.1秒のスムーズな時間更新
- メモリリーク対策（Timer管理）
- バックグラウンド動作軽量化

---

## 🚀 今後の拡張案

### Phase 1: 基本機能強化
- [ ] プレイリスト機能
- [ ] 複数エピソード管理
- [ ] エピソードダウンロード
- [ ] 再生履歴記録

### Phase 2: 高度な再生機能
- [ ] スリープタイマー
- [ ] イコライザー設定
- [ ] ブックマーク機能
- [ ] チャプター対応

### Phase 3: コンテンツ管理
- [ ] RSSフィード購読
- [ ] 自動ダウンロード
- [ ] 再生進捗同期（iCloud）
- [ ] お気に入り管理

### Phase 4: UI/UX改善
- [ ] ミニプレイヤー（最小化表示）
- [ ] ロック画面コントロール
- [ ] CarPlay対応
- [ ] ウィジェット対応

### Phase 5: ソーシャル機能
- [ ] シェア機能
- [ ] レビュー・評価
- [ ] おすすめ機能
- [ ] コメント機能

---

## 🎯 達成したこと

✅ AVFoundationによるネイティブ音声再生
✅ バックグラウンド再生対応
✅ 再生速度変更（0.5x〜2.0x）
✅ スキップ機能（30秒前後）
✅ シーク機能（スライダー）
✅ @Observableパターン実装
✅ AsaUIKit統一デザイン
✅ Swift Testingテスト実装
✅ XcodeGenプロジェクト管理

---

## 📊 プロジェクト統計

- **実装期間**: 1日
- **ファイル数**: 8ファイル（Swift）
- **コード行数**: 約450行
- **テストカバレッジ**: ViewModel・モデル95%以上
- **デザインシステム**: AsaUIKit完全統一
- **アーキテクチャパターン**: MVVM + @Observable

---

## 🔗 関連リソース

### 公式ドキュメント
- [AVFoundation - Apple Developer](https://developer.apple.com/av-foundation/)
- [AVAudioPlayer - Apple Developer](https://developer.apple.com/documentation/avfoundation/avaudioplayer)
- [Audio Session Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/)

### 学習リソース
- [Hacking with Swift - AVAudioPlayer](https://www.hackingwithswift.com/example-code/media/how-to-play-sounds-using-avaudioplayer)
- [Ray Wenderlich - Audio](https://www.raywenderlich.com/library?q=audio)

---

## 💭 振り返り

### うまくいったこと
- AVFoundationの基本的な使い方を習得
- バックグラウンド再生をスムーズに実装
- AsaUIKitによるデザイン統一が効率的
- @Observableパターンで状態管理が簡潔

### 改善点
- より多くのエピソード管理機能が必要
- ダウンロード機能の実装
- ユーザー設定の永続化

### 学んだこと
- AVAudioPlayerの基本操作
- Audio Sessionの設定方法
- Timerによるリアルタイム更新
- 再生速度制御の仕組み

---

**次のステップ**: AsaPodcastLibraryアプリでプレイリスト管理機能を実装し、より本格的なPodcastアプリへ進化させる。
