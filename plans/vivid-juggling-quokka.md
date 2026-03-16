# AsaMultiplayerGame カラー参照修正プラン

## Context
AsaMultiplayerGame (#81) のビルドは成功するが、実行時に全ブランドカラーが見つからずUIが正しく表示されない。
原因: `Color("AsaCoffeeBrown")` 等のAsset Catalog文字列参照を使っているが、AsaUIKitではstatic property (`AsaColors.coffeeBrown`) として定義されており、Asset Catalogにカラーは存在しない。

## 修正内容

### 置換ルール
| 現在の記述 | 修正後 |
|---|---|
| `Color("AsaCoffeeBrown")` | `AsaColors.coffeeBrown` |
| `Color("AsaMocha")` | `AsaColors.mocha` |
| `Color("AsaSoftCream")` | `AsaColors.softCream` |
| `Color("AsaDarkSlate")` | `AsaColors.darkSlate` |
| `Color("AsaMutedSage")` | `AsaColors.mutedSage` |

### 修正対象ファイル (10ファイル)
1. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/MainMenuView.swift` - `import AsaUIKit` 追加 + カラー置換
2. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/LobbyView.swift` - 同上
3. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/GameView.swift` - 同上
4. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/ResultView.swift` - 同上
5. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/Components/AnswerInputView.swift` - 同上
6. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/Components/DrawingToolbar.swift` - 同上
7. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/Components/DrawingCanvasView.swift` - 同上
8. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/Components/TimerView.swift` - 同上
9. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/Components/ScoreboardView.swift` - 同上
10. `Apps/AsaMultiplayerGame/AsaMultiplayerGame/Views/Components/ConnectionStatusView.swift` - 確認が必要

### 既存リソース
- `Packages/AsaUIKit/Sources/AsaUIKit/Colors/AsaColors.swift` - ブランドカラー定義（変更不要）

## 検証方法
1. `cd Apps/AsaMultiplayerGame && xcodegen generate && xcodebuild -project AsaMultiplayerGame.xcodeproj -scheme AsaMultiplayerGame -sdk iphonesimulator build`
2. シミュレータで実行し、カラーが正しく表示されることを確認
3. コンソールログに "No color named" エラーが出ないことを確認
4. メインメニュー → ルーム作成 → AIプレイヤー参加 → ゲーム開始の一連のフローが動作すること
