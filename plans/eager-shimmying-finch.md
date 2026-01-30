# AsaMultiplayerGame 実装計画

**アプリ #81**: オンライン対戦ゲーム（上級）
**ゲームタイプ**: お絵かきバトル（リアルタイム描画対戦）

---

## 1. ゲームコンセプト

### お絵かきバトル
二人のプレイヤーがリアルタイムで絵しりとりを行い、制限時間内に描いた絵を相手が当てる対戦ゲーム。

**ゲームルール**:
1. ルームコードで友達と接続
2. 交互に「描く側」と「当てる側」を担当
3. 描く側: ランダムなお題を30秒以内に描く
4. 当てる側: リアルタイムで表示される絵を見て回答
5. スコアリング: 正解で得点、早く当てるほどボーナス
6. 5ラウンド終了後、合計スコアで勝敗決定

---

## 2. アーキテクチャ

### ファイル構造
```
Apps/AsaMultiplayerGame/
├── project.yml
├── AsaMultiplayerGame/
│   ├── AsaMultiplayerGameApp.swift
│   ├── ContentView.swift
│   │
│   ├── Models/
│   │   ├── GameState.swift          # ゲーム状態（idle, lobby, playing, finished）
│   │   ├── Player.swift             # プレイヤーモデル
│   │   ├── GameRoom.swift           # ルーム管理
│   │   ├── DrawingData.swift        # 描画ストローク
│   │   ├── GameScore.swift          # スコア管理
│   │   └── GameMessage.swift        # WebSocketメッセージ
│   │
│   ├── Services/
│   │   ├── GameWebSocketService.swift       # WebSocket通信
│   │   ├── GameWebSocketProtocol.swift      # プロトコル定義
│   │   ├── MockGameWebSocketService.swift   # テスト用モック
│   │   └── WordProvider.swift               # お題提供
│   │
│   ├── ViewModels/
│   │   ├── GameViewModel.swift       # メインゲームロジック
│   │   ├── LobbyViewModel.swift      # ロビー管理
│   │   └── DrawingViewModel.swift    # 描画管理
│   │
│   ├── Views/
│   │   ├── MainMenuView.swift        # メインメニュー
│   │   ├── LobbyView.swift           # ロビー画面
│   │   ├── GameView.swift            # ゲームプレイ
│   │   ├── ResultView.swift          # 結果画面
│   │   └── Components/
│   │       ├── DrawingCanvasView.swift    # 描画キャンバス
│   │       ├── DrawingToolbar.swift       # 描画ツール
│   │       ├── TimerView.swift            # タイマー
│   │       ├── AnswerInputView.swift      # 回答入力
│   │       ├── ScoreboardView.swift       # スコアボード
│   │       └── ConnectionStatusView.swift # 接続状態
│   │
│   └── Assets.xcassets/
│
└── Tests/
    ├── AsaMultiplayerGameTests/
    └── AsaMultiplayerGameUITests/
```

### レイヤー構成
- **Presentation**: Views + Components（SwiftUI）
- **ViewModel**: @Observable + @MainActor（MVVM）
- **Service**: WebSocket通信、お題提供
- **Model**: データ構造（Codable, Sendable）

---

## 3. 通信プロトコル

### WebSocketメッセージ形式
```swift
struct GameMessage: Codable, Sendable {
    let type: GameMessageType
    let roomCode: String
    let payload: GamePayload
    let timestamp: Date
}

enum GameMessageType: String, Codable {
    // 接続管理
    case join, leave, ready, playerList
    // ゲーム進行
    case gameStart, roundStart, roundEnd, gameEnd
    // 描画同期
    case drawingStroke, drawingClear, drawingUndo
    // 回答
    case answer, answerResult
    // システム
    case ping, pong, error, sync
}
```

### 描画データ
```swift
struct DrawingStroke: Codable, Sendable, Identifiable {
    let id: String
    let points: [CGPoint]
    let color: StrokeColor
    let lineWidth: CGFloat
    let timestamp: Date
}
```

---

## 4. 重要な参照ファイル

| ファイル | 用途 |
|----------|------|
| `Apps/AsaLiveChat/AsaLiveChat/Services/WebSocketService.swift` | WebSocket通信パターン |
| `Apps/AsaLiveChat/AsaLiveChat/Models/WebSocketMessage.swift` | メッセージ形式 |
| `Apps/AsaARGame/AsaARGame/ViewModels/ARGameViewModel.swift` | ゲーム状態・タイマー管理 |
| `Apps/AsaTicTacToe/AsaTicTacToe/TicTacToeViewModel.swift` | ターン制ロジック |
| `Apps/AsaLiveChat/project.yml` | XcodeGen設定テンプレート |

---

## 5. 実装フェーズ

### Phase 1: 基盤構築（Day 1-2）
- [ ] XcodeGen `project.yml` 作成
- [ ] ディレクトリ構造・ファイル作成
- [ ] Models定義（Player, GameRoom, GameState, DrawingData, GameScore, GameMessage）
- [ ] GameWebSocketProtocol定義
- [ ] GameWebSocketService実装（AsaLiveChatパターン流用）
- [ ] MockGameWebSocketService実装

### Phase 2: ロビー機能（Day 3-4）
- [ ] MainMenuView実装
- [ ] LobbyView実装
- [ ] LobbyViewModel実装
- [ ] ルームコード生成/参加ロジック
- [ ] Ready状態管理
- [ ] ConnectionStatusView

### Phase 3: ゲームコア（Day 5-7）
- [ ] DrawingCanvasView実装（Canvas + DragGesture）
- [ ] DrawingToolbar（色選択、線幅、消去、Undo）
- [ ] DrawingViewModel実装
- [ ] 描画ストロークのリアルタイム同期
- [ ] GameViewModel実装
- [ ] ラウンド進行・タイマー管理
- [ ] WordProvider（お題提供）
- [ ] AnswerInputView
- [ ] 正解判定（ひらがな/カタカナ変換対応）
- [ ] スコア計算（時間ボーナス含む）

### Phase 4: 仕上げ（Day 8-9）
- [ ] ResultView実装
- [ ] 勝敗演出アニメーション
- [ ] ローカル対戦モード（WebSocket不要）
- [ ] エラーハンドリング・再接続ロジック
- [ ] Unit Tests（95%カバレッジ目標）
- [ ] UI Tests
- [ ] ドキュメント作成（Docs/Notes/Day81-Implementation.md）

---

## 6. テスト戦略

### Unit Tests（Swift Testing）
```swift
@Test("ルーム作成成功")
@MainActor
func testCreateRoom() async {
    let mockService = MockGameWebSocketService()
    let viewModel = GameViewModel(webSocketService: mockService)
    await viewModel.createRoom(playerName: "テストプレイヤー")
    #expect(viewModel.roomCode != nil)
}

@Test("描画ストローク送信")
@MainActor
func testSendDrawingStroke() async {
    // ...
}

@Test("正解判定ロジック")
func testAnswerCorrectness() {
    // ひらがな/カタカナ変換対応
}
```

### テスト対象
- GameViewModel: ゲーム進行、状態遷移
- DrawingViewModel: 描画操作、Undo
- GameScore: ポイント計算、勝者判定
- GameMessage: JSON encode/decode

---

## 7. 検証方法

### 動作確認
1. **ローカルモード**: MockServiceでシングルプレイヤーテスト
2. **シミュレータ2台**: 同一Macで2つのシミュレータ起動して対戦テスト
3. **実機テスト**: 2台のiPhoneで実際の対戦テスト

### テスト実行
```bash
cd Apps/AsaMultiplayerGame
xcodegen generate
swift test  # Unit Tests
# Xcode: Cmd+U for UI Tests
```

### ビルド確認
```bash
xcodebuild -project AsaMultiplayerGame.xcodeproj \
  -scheme AsaMultiplayerGame \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

---

## 8. 技術的考慮事項

### WebSocket再接続
- 指数バックオフ（最大5回、2^n秒）
- ハートビート30秒間隔
- 状態同期メッセージで復帰

### 描画パフォーマンス
- ストローク完了時に送信（ポイント毎送信は負荷高）
- Canvas APIで効率的な描画

### サーバー要件
**注意**: 本実装はクライアントサイドのみ。実際の対戦には別途WebSocketサーバーが必要。開発・テストはMockServiceで対応可能。

---

## 9. project.yml

```yaml
name: AsaMultiplayerGame
options:
  bundleIdPrefix: com.asapapa.apps
  deploymentTarget:
    iOS: "17.0"

packages:
  AsaUIKit:
    path: ../../Packages/AsaUIKit

targets:
  AsaMultiplayerGame:
    type: application
    platform: iOS
    sources: [AsaMultiplayerGame]
    dependencies:
      - package: AsaUIKit
    settings:
      SWIFT_VERSION: "5.9"
      INFOPLIST_KEY_CFBundleDisplayName: "お絵かきバトル"

  AsaMultiplayerGameTests:
    type: bundle.unit-test
    platform: iOS
    sources: [Tests/AsaMultiplayerGameTests]
    dependencies:
      - target: AsaMultiplayerGame

  AsaMultiplayerGameUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [Tests/AsaMultiplayerGameUITests]
    dependencies:
      - target: AsaMultiplayerGame
```
