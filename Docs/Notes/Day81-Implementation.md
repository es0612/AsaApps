# Day 81 - AsaMultiplayerGame 実装ノート

## アプリ情報

| 項目 | 内容 |
|------|------|
| アプリ名 | AsaMultiplayerGame (お絵かきバトル) |
| カテゴリ | 上級 - オンライン対戦ゲーム |
| 実装日 | Day 81 |
| 難易度 | ★★★★★ |

## 概要

二人のプレイヤーがリアルタイムでお絵かき対戦を行うマルチプレイヤーゲーム。交互に「描く側」と「当てる側」を担当し、制限時間内に描いた絵を相手が当てる。

## ゲームルール

1. **ルーム作成/参加**: 6桁のルームコードで友達と接続
2. **Ready状態**: 全員がReadyになるとゲーム開始
3. **交互に対戦**:
   - 描く側: ランダムなお題を制限時間内に描く
   - 当てる側: リアルタイムで表示される絵を見て回答
4. **スコアリング**:
   - 正解: 100ポイント + 時間ボーナス（最大50ポイント）
   - 描画者: 正解されたら50ポイントボーナス
5. **勝敗**: 設定ラウンド終了後、合計スコアで決定

## アーキテクチャ

### ファイル構造

```
AsaMultiplayerGame/
├── AsaMultiplayerGameApp.swift
├── ContentView.swift
├── Models/
│   ├── Player.swift           # プレイヤーモデル
│   ├── GameState.swift        # ゲーム状態（フェーズ、設定）
│   ├── GameRoom.swift         # ルーム管理
│   ├── DrawingData.swift      # 描画ストローク
│   ├── GameScore.swift        # スコア計算
│   └── GameMessage.swift      # WebSocketメッセージ
├── Services/
│   ├── GameWebSocketProtocol.swift    # プロトコル定義
│   ├── GameWebSocketService.swift     # WebSocket実装
│   ├── MockGameWebSocketService.swift # テスト用モック
│   └── WordProvider.swift             # お題提供
├── ViewModels/
│   ├── GameViewModel.swift    # メインゲームロジック
│   └── DrawingViewModel.swift # 描画管理
└── Views/
    ├── MainMenuView.swift     # メインメニュー
    ├── LobbyView.swift        # ロビー画面
    ├── GameView.swift         # ゲームプレイ
    ├── ResultView.swift       # 結果画面
    └── Components/
        ├── DrawingCanvasView.swift   # 描画キャンバス
        ├── DrawingToolbar.swift      # 描画ツール
        ├── TimerView.swift           # タイマー
        ├── AnswerInputView.swift     # 回答入力
        ├── ScoreboardView.swift      # スコアボード
        └── ConnectionStatusView.swift # 接続状態
```

### 設計パターン

- **MVVM**: View - ViewModel - Model の明確な分離
- **@Observable**: Swift 5.9のモダンな状態管理
- **Protocol-based Service**: WebSocketServiceをプロトコルで抽象化
- **Dependency Injection**: テスト時にMockServiceを注入

## 技術的ハイライト

### 1. Canvas API による描画

```swift
Canvas { context, size in
    for stroke in canvas.strokes {
        var path = Path()
        path.move(to: stroke.cgPoints[0])

        // スムーズな曲線描画
        for i in 1..<stroke.cgPoints.count {
            let mid = CGPoint(
                x: (stroke.cgPoints[i-1].x + stroke.cgPoints[i].x) / 2,
                y: (stroke.cgPoints[i-1].y + stroke.cgPoints[i].y) / 2
            )
            path.addQuadCurve(to: mid, control: stroke.cgPoints[i-1])
        }

        context.stroke(path, with: .color(stroke.color.color),
                      style: StrokeStyle(lineWidth: stroke.lineWidth,
                                        lineCap: .round,
                                        lineJoin: .round))
    }
}
```

### 2. WebSocket通信パターン

```swift
protocol GameWebSocketServiceProtocol: AnyObject, Sendable {
    var connectionState: ConnectionState { get }
    var onMessageReceived: (@Sendable (GameMessage) -> Void)? { get set }
    func connect(to url: URL, roomCode: String, player: Player) async throws
    func send(_ message: GameMessage) async throws
}
```

### 3. ひらがな/カタカナ対応の正解判定

```swift
static func toHiragana(_ text: String) -> String {
    var result = ""
    for char in text.unicodeScalars {
        // カタカナ(U+30A0-30FF) → ひらがな(U+3040-309F)
        if char.value >= 0x30A0 && char.value <= 0x30FF {
            if let hiragana = UnicodeScalar(char.value - 0x60) {
                result.append(Character(hiragana))
            }
        } else {
            result.append(Character(char))
        }
    }
    return result
}
```

### 4. スコア計算ロジック

```swift
static func calculateGuesserScore(
    isCorrect: Bool,
    answerTimeSeconds: TimeInterval,
    roundTimeLimit: Int
) -> Int {
    guard isCorrect else { return 0 }

    let basePoints = 100
    let remainingTime = max(0, TimeInterval(roundTimeLimit) - answerTimeSeconds)
    let timeBonusPoints = min(Int(remainingTime) * 3, 50)

    return basePoints + timeBonusPoints
}
```

## お題データ

8カテゴリ、100以上のお題を用意：
- 動物: いぬ、ねこ、ぞう、きりん、ライオン...
- 食べ物: りんご、バナナ、ケーキ、すし...
- 自然: たいよう、つき、やま、うみ...
- もの: でんわ、テレビ、かさ...
- 乗り物: くるま、ひこうき、しんかんせん...
- 建物: いえ、がっこう、えき...
- 動作: およぐ、はしる、ねる...
- キャラクター: おうさま、にんじゃ、ロボット...

## テスト

### Unit Tests（Swift Testing）

- GameViewModelTests: ルーム作成、Ready状態、ゲーム開始条件
- GameScoreCalculatorTests: スコア計算、時間ボーナス、勝者判定
- WordProviderTests: お題取得、正解判定、ひらがな/カタカナ変換
- DrawingDataTests: ストローク操作、キャンバス操作
- GameMessageTests: JSON エンコード/デコード

### UI Tests

- メインメニュー表示
- ルーム作成フロー
- ルーム参加フロー
- ロビー画面遷移

## 使用したSwiftUI機能

- `Canvas`: 高パフォーマンスな2D描画
- `DragGesture`: タッチ入力による描画
- `@Observable`: モダンな状態管理
- `@MainActor`: UIスレッドセーフな処理
- `GeometryReader`: レスポンシブレイアウト
- `withAnimation`: スムーズなトランジション

## 学んだこと

1. **Protocol-based Architecture**: WebSocketServiceをプロトコルで抽象化することで、テスト時にMockに差し替え可能
2. **Canvas API**: SwiftUIのCanvas APIは60fpsでスムーズな描画が可能
3. **ひらがな/カタカナ変換**: Unicodeスカラ値の差分を利用した変換
4. **リアルタイム通信設計**: 描画データの効率的な同期方法
5. **ゲーム状態管理**: 複数の状態（waiting, countdown, drawing, result）の適切な遷移

## 今後の拡張案

- [ ] 実際のWebSocketサーバー実装
- [ ] 観戦モード（3人以上の参加）
- [ ] カスタムお題の追加
- [ ] 描画履歴のリプレイ機能
- [ ] ゲーム結果の共有機能
- [ ] 音声チャット機能

## ビルド・実行

```bash
cd Apps/AsaMultiplayerGame
xcodegen generate
open AsaMultiplayerGame.xcodeproj

# テスト実行
swift test
```

## スクリーンショット

（実機でのスクリーンショットを追加予定）

---

**作成者**: 朝活パパエンジニア
**作成日**: Day 81
