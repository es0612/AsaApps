# AsaLiveChat: 実際のWebSocketエコーサーバーに接続する

## Context

AsaLiveChatアプリは現在、`ChatViewModel`で常に`MockWebSocketService`がハードコードされており、設定画面でサーバーを選択しても実際には接続されない状態。ユーザーは実際のWebSocketエコーサーバーに接続してリアルタイム通信を体験したい。

### 課題
1. `ChatViewModel.init`で`MockWebSocketService()`が常に使われている
2. エコーサーバーは送信したJSONをそのまま返すため、`senderId`が自分と一致し、受信メッセージがスキップされる

## 実装計画

### 変更1: ChatViewModel.swift - WebSocketService切り替え（メイン変更）

**ファイル**: `Apps/AsaLiveChat/AsaLiveChat/ViewModels/ChatViewModel.swift`

#### 1a. デフォルトサービスを実際のWebSocketServiceに変更（135行目付近）

```swift
// 変更前
self.webSocketService = webSocketService ?? MockWebSocketService()

// 変更後
self.webSocketService = webSocketService ?? WebSocketService()
```

#### 1b. エコーサーバー判定プロパティを追加

```swift
/// エコーサーバーに接続中かどうか
private var isEchoServer: Bool {
    let url = userSettings.serverURL.lowercased()
    return url.contains("echo") || url.contains("socketsbay.com")
}
```

#### 1c. handleChatMessage を修正（305行目付近）

エコーサーバーから返ってきた自分のメッセージを「Echo Bot」として表示する。

```swift
private func handleChatMessage(_ wsMessage: WebSocketMessage) {
    guard let content = wsMessage.payload.content,
          let senderId = wsMessage.payload.senderId,
          let senderName = wsMessage.payload.senderName else { return }

    // 自分のメッセージが返ってきた場合
    if senderId == currentUser.id {
        if isEchoServer {
            // エコーサーバー: "Echo Bot" として表示
            let message = dataService.createMessage(
                content: content,
                senderName: "Echo 🔊",
                senderId: "echo-server",
                isSentByMe: false,
                room: room
            )
            messages.append(message)
        }
        // 通常サーバー: スキップ（既にローカル保存済み）
        return
    }

    // 他のユーザーからのメッセージ（通常処理）
    let message = dataService.createMessage(
        content: content,
        senderName: senderName,
        senderId: senderId,
        isSentByMe: false,
        room: room
    )
    messages.append(message)
    typingUsers.removeAll { $0 == senderName }
}
```

### 変更2: UserSettings.swift - サーバーURLリスト更新（任意）

**ファイル**: `Apps/AsaLiveChat/AsaLiveChat/Models/UserSettings.swift`

`echo.websocket.org`が利用不可の場合に備えて、バックアップサーバーURLを追加。

```swift
static let availableServers: [(name: String, url: String)] = [
    ("Echo Server", "wss://echo.websocket.org"),
    ("SocketsBay Echo", "wss://socketsbay.com/wss/v2/1/demo/"),
    ("ローカル開発", "ws://localhost:8080"),
    ("カスタム", "")
]
```

## 変更対象ファイルまとめ

| ファイル | 変更内容 |
|---------|---------|
| `ChatViewModel.swift` | Mock→WebSocketService切替、エコー判定、受信処理修正 |
| `UserSettings.swift` | サーバーリストにSocketsBay追加 |

## 検証方法

1. `xcodegen generate` でプロジェクト再生成
2. シミュレータでビルド・起動
3. チャットルームを作成
4. メッセージを送信 → 「Echo 🔊」からのエコー返信が表示されることを確認
5. 設定画面でサーバー切り替えが反映されることを確認
