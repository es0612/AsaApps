# AsaLanguageLearn: マイク権限ダイアログが表示されない問題の修正

## Context

AsaLanguageLearnアプリで録音ボタンをタップすると「マイクへのアクセスが許可されていません。設定アプリから許可してください。」というエラーが表示される。しかし、そもそもiOSの権限許可ダイアログが一度も表示されないため、ユーザーは許可のしようがない。

**原因:** `SpeechRecognitionService.requestPermissions()` メソッドは正しく実装されているが、アプリのどこからも呼ばれていない。`startRecognition()` は権限を **チェック（read-only）** するだけで、**リクエスト** していない。

## 修正内容

### 修正ファイル: `PracticeViewModel.swift`
- パス: `Apps/AsaLanguageLearn/AsaLanguageLearn/ViewModels/PracticeViewModel.swift`
- 修正箇所: `startListening()` メソッド（159行目〜）

**現在のコード:**
```swift
func startListening() async {
    state = .listening
    speechRecognitionService.reset()

    do {
        try await speechRecognitionService.startRecognition()
    } catch {
        state = .error(error.localizedDescription)
    }
}
```

**修正後のコード:**
```swift
func startListening() async {
    state = .listening
    speechRecognitionService.reset()

    // 権限をリクエスト（未許可の場合はシステムダイアログが表示される）
    let granted = await speechRecognitionService.requestPermissions()
    guard granted else {
        state = .error(SpeechRecognitionError.microphonePermissionDenied.localizedDescription)
        return
    }

    do {
        try await speechRecognitionService.startRecognition()
    } catch {
        state = .error(error.localizedDescription)
    }
}
```

### 修正の流れ

```
修正後のフロー:
ユーザーが録音ボタンをタップ
  ↓
startListening() → requestPermissions()
  ↓
初回: iOS権限ダイアログ「マイクへのアクセスを許可しますか？」表示
  ↓
許可 → startRecognition() → 音声認識開始
拒否 → エラーメッセージ表示（設定アプリへ誘導）
```

### 修正しないファイル

- `SpeechRecognitionService.swift` — `requestPermissions()` は正しく実装済み。`startRecognition()` 内の権限チェックは二重チェックとして残す（防御的プログラミング）
- `project.yml` — Info.plistの `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` は正しく設定済み

## 検証方法

1. `xcodegen generate` でプロジェクト再生成
2. `xcodebuild -project AsaLanguageLearn.xcodeproj -scheme AsaLanguageLearn -sdk iphonesimulator build` でビルド確認
3. シミュレータで起動 → レッスン選択 → 録音ボタンタップ → 権限ダイアログが表示されることを確認
