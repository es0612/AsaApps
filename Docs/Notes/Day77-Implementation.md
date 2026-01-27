# Day 77: AsaLiveChat - リアルタイムチャットアプリ

## 概要

AsaLiveChatは、WebSocketを使用したリアルタイムチャットアプリです。URLSessionWebSocketTaskを活用し、複数ユーザー間でのリアルタイムメッセージングを実現します。

**カテゴリ**: 上級アプリ (#77)
**技術レベル**: Advanced

## 主要機能

### 1. チャットルーム機能
- ルームの作成（6文字のランダムコード生成）
- ルームコードによる参加
- ルーム一覧表示（最終メッセージ、未読バッジ）
- ルームの削除

### 2. リアルタイムメッセージング
- WebSocket接続によるリアルタイム通信
- メッセージ送受信
- タイピングインジケータ
- 接続状態表示

### 3. メッセージ管理
- Swift Dataによるメッセージ永続化
- 既読/未読管理
- 送信状態表示（送信中/送信済み/失敗）

### 4. ユーザー設定
- ユーザー名・アバター設定
- 通知設定（サウンド、バイブレーション）
- プライバシー設定（入力中表示、既読送信）
- サーバー選択（Echo Server、カスタム）

## 技術スタック

### アーキテクチャ
- **MVVM + Service Layer**
- **@Observable + @MainActor**

### データ管理
- **Swift Data**: メッセージ、ルーム、設定の永続化
- **Codable**: WebSocket通信用メッセージ

### 通信
- **URLSessionWebSocketTask**: iOS 13+のネイティブWebSocket API
- **自動再接続**: 指数バックオフ（最大5回）
- **ハートビート**: Ping/Pongによる接続監視

### UI
- **AsaUIKit**: AsaButton, AsaCard, AsaColors
- **SwiftUI**: ScrollViewReader, LazyVStack

## ディレクトリ構造

```
Apps/AsaLiveChat/
├── project.yml
├── AsaLiveChat/
│   ├── AsaLiveChatApp.swift
│   ├── Models/
│   │   ├── ChatRoom.swift         # @Model チャットルーム
│   │   ├── Message.swift          # @Model メッセージ
│   │   ├── ChatUser.swift         # ユーザー情報
│   │   ├── WebSocketMessage.swift # WebSocket通信用
│   │   └── UserSettings.swift     # ユーザー設定
│   ├── ViewModels/
│   │   ├── ChatRoomListViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── ChatRoomListView.swift
│   │   ├── ChatView.swift
│   │   ├── SettingsView.swift
│   │   └── Components/
│   │       ├── MessageBubble.swift
│   │       ├── TypingIndicator.swift
│   │       ├── ConnectionStatusView.swift
│   │       └── UserAvatarView.swift
│   └── Services/
│       ├── WebSocketServiceProtocol.swift
│       ├── WebSocketService.swift
│       └── ChatDataService.swift
└── Tests/
    └── AsaLiveChatTests/
```

## 実装のポイント

### 1. WebSocketService設計

```swift
protocol WebSocketServiceProtocol: AnyObject, Sendable {
    var connectionState: ConnectionState { get }
    var onMessageReceived: (@Sendable (WebSocketMessage) -> Void)? { get set }
    func connect(to url: URL, roomCode: String, user: ChatUser) async throws
    func disconnect()
    func send(_ message: WebSocketMessage) async throws
}
```

- プロトコル駆動設計でモック切り替え可能
- `MockWebSocketService`で実サーバーなしでテスト可能

### 2. Swift Dataモデル

```swift
@Model
final class ChatRoom {
    @Attribute(.unique) var id: UUID
    var name: String
    var roomCode: String
    @Relationship(deleteRule: .cascade, inverse: \Message.room)
    var messages: [Message] = []
}
```

- `@Relationship`による1対多リレーション
- `deleteRule: .cascade`でルーム削除時にメッセージも削除

### 3. メッセージバブルUI

```swift
struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isSentByMe {
                Spacer()
                bubbleView  // 右寄せ（自分のメッセージ）
            } else {
                bubbleView  // 左寄せ（相手のメッセージ）
                Spacer()
            }
        }
    }
}
```

- 送信者/受信者で配置・スタイルを分離
- `BubbleShape`でLINE風の角丸バブル

### 4. 接続状態管理

```swift
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(String)
}
```

- 状態ごとのUI表示
- 自動再接続ロジック

## 使用コマンド

```bash
# プロジェクト生成
cd Apps/AsaLiveChat
xcodegen generate

# ビルド
xcodebuild -project AsaLiveChat.xcodeproj \
  -scheme AsaLiveChat \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# テスト
swift test
```

## WebSocketサーバーについて

本アプリはWebSocketクライアント実装です。動作確認には以下を使用します：

1. **MockWebSocketService**: 自己返信モード（デフォルト）
2. **Echo Server**: `wss://echo.websocket.org`
3. **カスタムサーバー**: 任意のWebSocketサーバー

## 今後の拡張

- 画像送信機能
- プッシュ通知対応
- グループビデオ通話（WebRTC）
- E2E暗号化
- オフラインメッセージキュー

## 学んだこと

1. **URLSessionWebSocketTask**の使い方とライフサイクル管理
2. **Swift Data**でのリレーションシップ設計
3. **プロトコル駆動設計**によるテスト容易性の向上
4. **リアルタイムUI**の状態管理パターン

## スクリーンショット

（後日追加予定）

---

作成日: 2026年1月27日
実装時間: 約2時間
