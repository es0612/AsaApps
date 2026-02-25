# AsaMultiplayerGame AIプレイヤー対戦機能

## Context
AsaMultiplayerGame（お絵かきバトル #81）でシミュレータ1台でのテスト・デモができない。
- **バグ**: `GameSettings.isLocalMode`のデフォルトが`false`のため`MockGameWebSocketService.connect()`が呼ばれず、AIプレイヤーが参加しない
- **未実装**: AIプレイヤーのゲーム中の行動（描画・回答）が存在しない
- **ゴール**: AI対戦モードと対人モードを選択でき、AI対戦で全フローを1人で確認できるように

## 修正ファイル一覧

### 1. `Models/GameState.swift` — isLocalMode維持（変更なし）
`isLocalMode`のデフォルトは`false`のまま維持。AI対戦選択時にのみ`true`にセットする。

### 2. `Views/MainMenuView.swift` — モード選択UI追加
現在の「ルーム作成」「ルーム参加」に加えて「AI対戦」ボタンを追加。

```
メニュー構成（上から）:
🤖 AIと対戦    ← 新規追加（AsaColors.coffeeBrownボタン）
━━━━ or ━━━━  ← 区切り
＋ ルームを作成  ← 既存（AsaColors.darkSlateに変更）
👥 ルームに参加  ← 既存（アウトラインスタイルに変更）
```

AI対戦タップ時の処理:
- `viewModel.settings.isLocalMode = true`
- 名前入力用のシート表示（既存createRoomSheetの簡略版）
- 決定後に`viewModel.createRoom()`呼び出し → ロビーへ

### 3. `Services/AIDrawingPatterns.swift` — 新規作成
AIが描く側の時に使う描画パターンを定義する構造体。
- 主要お題（りんご、ねこ、たいよう等）に対応する事前定義パターン（10-15個）
- 未知のお題用の汎用パターン（ジグザグ、円、四角等のランダム図形）
- `static func generateStrokes(for word: String) -> [DrawingStroke]`
- 各パターンは300x300キャンバス前提で座標定義

### 4. `ViewModels/GameViewModel.swift` — AI行動ロジック追加

**追加プロパティ:**
- `private var aiActionTask: Task<Void, Never>?` — AI行動の非同期タスク参照

**追加ヘルパー:**
- `private var aiPlayerId: String?` — AIプレイヤーのID取得（"opponent-"プレフィックスで判別）

**追加メソッド:**
- `scheduleAIAction()` — ラウンド開始時にAIの役割に応じた行動をスケジュール
  - isLocalMode時のみ動作
  - AIがguesser → performAIGuessing()
  - AIがdrawer → performAIDrawing()
- `performAIGuessing()` — 5-15秒後にランダム回答（正解率40%）
  - 正解時: `currentRound.word`をそのまま使用
  - 不正解時: `WordProvider.randomWord()`で別の単語を選択
  - `processAIAnswer()`でスコア処理
- `performAIDrawing()` — 2秒後から0.8-1.5秒間隔で段階的にストローク追加
  - `AIDrawingPatterns.generateStrokes(for: word)`でパターン取得
  - `canvas.addStroke(stroke)`で直接追加（UI自動更新）
- `processAIAnswer(answer:)` — AIの回答を処理してスコア更新
  - 既存の`submitAnswer()`と同等のスコア計算ロジック

**変更箇所:**
- `startNextRound()` — 末尾に`scheduleAIAction()`呼び出し追加
- `resetGameState()` — `aiActionTask?.cancel()`追加
- `processRoundResult()` — `aiActionTask?.cancel()`追加
- `handleTimeUp()` — `guard gamePhase == .drawing`ガード追加（競合防止）

### 5. `ViewModels/GameViewModel.swift` — createRoom/joinRoom時のモード設定
- `createRoom()`: `isLocalMode`チェックは既存のまま。対人モード時はconnect()スキップ
- 対人モード選択時は`settings.isLocalMode = false`のまま（デフォルト）

## メインメニューのフロー

### AI対戦フロー
1. 「AIと対戦」タップ → 名前入力シート表示
2. 名前入力・絵文字選択 → 「対戦開始」
3. `settings.isLocalMode = true` → `createRoom()` → ロビー画面
4. 0.5秒後にAIプレイヤー参加、1秒後にReady
5. 「ゲーム開始」→ 全フロー実行

### 対人モードフロー（既存維持）
1. 「ルームを作成」→ 既存のcreateRoomSheet（`isLocalMode = false`）
2. 「ルームに参加」→ 既存のjoinRoomSheet

## AIの行動設計

### AIが当てる側（Guesser）の場合
```
ラウンド開始 → 5-15秒ランダム待機 → 回答送信
- 40%の確率で正解（currentRound.wordを使用）
- 60%の確率で不正解（WordProviderから別の単語を選択）
```

### AIが描く側（Drawer）の場合
```
ラウンド開始 → 2秒待機 → AIDrawingPatternsからストローク取得
→ 0.8-1.5秒間隔で1ストロークずつcanvas.addStroke()
（ユーザーには段階的に絵が見える）
```

## 検証方法
1. `xcodebuild -project AsaMultiplayerGame.xcodeproj -scheme AsaMultiplayerGame -sdk iphonesimulator build`
2. シミュレータで実行:
   - **AI対戦**: ルーム作成→AI参加→ゲーム全フロー完走
   - **対人モード**: 「ルーム作成」「ルーム参加」が従来通り動作すること
   - コンソールに"No color named"エラーが出ないこと
