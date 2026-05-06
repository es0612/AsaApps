# AsaEduGame さんすうクイズ起動時クラッシュ修正

## Context（なぜこの変更が必要か）

ユーザーは AsaEduGame の SNS デモ動画を撮りたい。しかしホーム画面で「さんすう」をタップすると即座にクラッシュし、問題画面に到達できない。Xcode のログ:

```
AsaEduGameKit/BaseGameScene.swift:124: Fatal error:
Unexpectedly found nil while implicitly unwrapping an Optional value
```

**算数問題のロジックは未実装ではなく、完成済み**。`QuestionGeneratorService`（足し算/引き算/大小比較/穴埋め）はテスト付きで稼働している。クラッシュは SwiftUI + SpriteKit の**ライフサイクル競合**が原因。

### 根本原因

`BaseGameScene.swift:40-49` で 4 つのノードが IUO (`var questionLabel: SKLabelNode!` 等) として宣言されている。これらは `didMove(to:)` (`BaseGameScene.swift:61-65`) から呼ばれる `setupCommonNodes()` (`BaseGameScene.swift:70-114`) で初期化される。

しかし `GameContainerView.swift:125-127` の `.onAppear { setupGame() }` は SwiftUI のビュー出現時に発火し、その中で `scene.presentQuestion(question)` (`GameContainerView.swift:189-196`) を**即座に**呼び出す。SwiftUI の `SpriteView` がシーンを `SKView` にアタッチして `didMove(to:)` を起動するより前に `presentQuestion` が走るため、`questionLabel` が `nil` のまま `BaseGameScene.swift:124` で `text =` を試みて落ちる。

### 影響範囲

`BaseGameScene` を継承する 4 シーン全てが同じ罠を持つ:

- `MathQuizScene.swift:20-22` （ユーザーが踏んだ）
- `HiraganaScene.swift:32-33`
- `ShapePuzzleScene.swift:34-35`
- `LogicGameScene.swift:32-33`

すべて先頭で `super.presentQuestion(question)` を呼ぶ同一構造。基底クラスを直すだけで全モードを同時に救える。

## 採用方針: シーン内キューイング（Self-contained queue）

`BaseGameScene` に「準備完了フラグ」と「保留中の問題」を持たせ、`didMove(to:)` 完了前に `presentQuestion` が来たらキューに退避、`didMove(to:)` 末尾で再駆動する。サブクラス・呼び出し側は無変更。

### なぜこの方式か

- **最小変更**: 基底 1 ファイル +約 12 行のみ。サブクラス 4 つ・`GameContainerView`・`GameViewModel` は手付かず。
- **動的ディスパッチで全モード救済**: `didMove` 内で `self.presentQuestion(queued)` と書くと、Swift のクラスメソッド動的ディスパッチでサブクラスの override が呼ばれる。基底だけ修正してもサブクラス本来のロジック（選択肢配置等）が通る。
- **`restartGame()` 経路も自動対応**: `scene` は `@State private var scene: BaseGameScene` で初回マウント後に再生成されないため、再スタート時は `isSceneReady == true` で即時実行される。デリゲート API を足す必要なし（YAGNI）。
- **将来拡張も狭くしない**: 後で「シーン準備完了通知」が必要になったら `gameDelegate?.sceneDidBecomeReady(self)` を 1 行足すだけで拡張可能。

## 実装詳細

### 唯一の変更ファイル: `Packages/AsaEduGameKit/Sources/AsaEduGameKit/SpriteKit/Scenes/BaseGameScene.swift`

#### 1. プロパティ追加（Properties セクション末尾、`backgroundColorValue` の直後あたり）

```swift
/// シーンが didMove 完了済みか（共通ノード初期化済みか）
private var isSceneReady = false

/// didMove 前に届いた問題の保留先（マウント完了後に再駆動する）
private var pendingQuestion: GameQuestion?
```

#### 2. `didMove(to:)` を拡張（現在 line 61-65）

```swift
public override func didMove(to view: SKView) {
    super.didMove(to: view)
    backgroundColor = backgroundColorValue
    setupCommonNodes()
    isSceneReady = true

    // マウント前に届いた問題があれば再駆動（dynamic dispatch でサブクラスの override に届く）
    if let queued = pendingQuestion {
        pendingQuestion = nil
        presentQuestion(queued)
    }
}
```

#### 3. `presentQuestion(_:)` 冒頭に guard 追加（現在 line 119-130）

```swift
public func presentQuestion(_ question: GameQuestion) {
    guard isSceneReady else {
        // didMove がまだ走っていない → 最後の問題を 1 件だけ保持して帰る。
        // didMove 末尾で再駆動される。サブクラスのオーバーライド本体は実行されるが、
        // clearAnswerOptions() で再駆動時にクリアされるため副作用なし。
        pendingQuestion = question
        return
    }
    currentQuestion = question
    gameState = .playing

    questionLabel.text = question.questionText
    questionLabel.alpha = 0
    questionLabel.run(SKAction.fadeIn(withDuration: 0.3))

    characterNode.idle()
}
```

### サブクラス側について

**変更不要**。基底 `super.presentQuestion(question)` がキューイングして帰った場合、サブクラス（例: `MathQuizScene.swift:20-61`）は続行して選択肢ノードを `addChild` するが、後で `didMove` 末尾の再駆動でサブクラス自身が `clearAnswerOptions()`（`BaseGameScene.swift:225-232`、`enumerateChildNodes(withName: "answer_option")` で除去）→ 新しい選択肢配置を行うため、最終状態は正しい。

### 呼び出し側について

**`GameContainerView.swift` も変更不要**。`setupGame()`（line 189-196）と `restartGame()`（line 199-207）の両方が無修正で正しく動く。

## 検証手順

### ビルド

```bash
cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaEduGame
xcodegen generate
xcodebuild -project AsaEduGame.xcodeproj -scheme AsaEduGame \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

### 手動シミュレータ確認（デモ動画用）

iPhone 17 Pro シミュレータで以下を順に確認:

1. 「さんすう」→ 「★」を選択 → 問題画面が立ち上がりクラッシュしない ✅
2. 問題文が表示され、選択肢が 2×2 グリッドで配置される ✅
3. 正解をタップ → お祝いエフェクト → 次の問題に遷移する
4. 不正解をタップ → 励ましエフェクト → 次の問題に遷移する
5. 全問完了 → 結果画面が表示される
6. 結果画面の「もういちど」をタップ → 同一シーンインスタンスで restart される（regression check）
7. 「ひらがな」「かたち」「ろんり」も同様に開始 → クラッシュしない（連帯救済確認）

### 単体テスト追加

`Packages/AsaEduGameKit/Tests/AsaEduGameKitTests/SpriteKit/BaseGameSceneTests.swift`（新規ファイル）

Swift Testing で 3 ケース:

```swift
import Testing
import SpriteKit
@testable import AsaEduGameKit

@MainActor
struct BaseGameSceneTests {
    @Test("didMove 前の presentQuestion はクラッシュせずキューに退避される")
    func presentQuestionBeforeDidMoveQueues() {
        let scene = MathQuizScene(size: CGSize(width: 400, height: 600))
        let q = GameQuestion(
            questionType: .addition,
            questionText: "1+1=?",
            options: ["1","2","3","4"],
            correctAnswer: "2"
        )
        scene.presentQuestion(q)  // crash しないこと（暗黙アサート）
        #expect(scene.currentQuestion == nil)  // didMove 前なので未反映
    }

    @Test("didMove 後にキューが反映され currentQuestion が更新される")
    func didMoveDrainsPendingQuestion() {
        let scene = MathQuizScene(size: CGSize(width: 400, height: 600))
        let q = GameQuestion(
            questionType: .addition,
            questionText: "1+1=?",
            options: ["1","2","3","4"],
            correctAnswer: "2"
        )
        scene.presentQuestion(q)
        scene.didMove(to: SKView())
        #expect(scene.currentQuestion?.questionText == "1+1=?")
    }

    @Test("didMove 後の presentQuestion は即時反映される")
    func presentQuestionAfterDidMoveAppliesImmediately() {
        let scene = MathQuizScene(size: CGSize(width: 400, height: 600))
        scene.didMove(to: SKView())
        let q = GameQuestion(
            questionType: .addition,
            questionText: "2+3=?",
            options: ["3","4","5","6"],
            correctAnswer: "5"
        )
        scene.presentQuestion(q)
        #expect(scene.currentQuestion?.questionText == "2+3=?")
    }
}
```

実行コマンド:

```bash
cd /Users/shinya/workspace/claude/AsaApps/Packages/AsaEduGameKit
swift test --filter BaseGameSceneTests
```

## リスクとトレードオフ

| 項目 | 評価 |
|------|------|
| サブクラスの pre-mount 副作用 | `MathQuizScene` 等が pending 期間中に answer_option ノードを `addChild` する。再駆動時に `clearAnswerOptions()` で除去されるため最終状態は正しいが、一瞬の冗長作業が発生する。視覚的には問題なし（描画はマウント後）。 |
| キューが「最後の 1 件」のみ保持 | 仕様上、didMove 前に複数 `presentQuestion` が来るのはあり得ない（GameContainerView は initial で 1 回しか呼ばない）。仮に来ても最後の問題が反映されれば良い。 |
| `isSceneReady` の private アクセス | 外部から状態を観測する需要が出たら `public private(set)` に昇格すれば良い。今は不要。 |
| デリゲート API 拡張の見送り | 「sceneDidBecomeReady」通知を後で必要になったら `didMove` 末尾に 1 行追加するだけで足せる。今回は YAGNI。 |

## 参照する既存実装

- `BaseGameScene.clearAnswerOptions()` (`BaseGameScene.swift:225-232`): 再駆動時の pre-mount ノード掃除を担保する既存ユーティリティ。新規実装不要。
- `GameViewModel.startGame(mode:difficulty:profile:)` (`GameViewModel.swift:130-163`): 問題生成は既に正しく動いており、この修正の対象外。
- `QuestionGeneratorService.generateAddition()` 等: 算数問題生成ロジックは完成済みで触らない。
