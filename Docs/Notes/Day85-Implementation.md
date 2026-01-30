# Day 85: AsaEventLive - リアルタイムイベント共有アプリ

## 概要

**AsaEventLive**は、家族や友人とイベント（誕生日、運動会、旅行等）の進行状況や写真・コメントをリアルタイムで共有するアプリです。

### コンセプト
「その場にいなくても、一緒にイベントを楽しめる」をテーマに、離れた家族も同じ瞬間を共有できる体験を提供します。

---

## 主要機能

| 機能 | 説明 |
|------|------|
| **イベント作成** | タイトル、日時、場所、カテゴリ、説明を設定 |
| **招待コード参加** | 6文字のコードでイベントに簡単参加 |
| **リアルタイムタイムライン** | 投稿・コメントをライブ更新 |
| **参加者管理** | オンライン状態表示、ロール管理 |
| **アクティビティフィード** | 「〇〇さんが写真を追加」等の通知 |
| **オフライン対応** | ローカルキャッシュ、後で自動同期 |

---

## 技術スタック

- **UI**: SwiftUI + AsaUIKit（共有コンポーネント）
- **状態管理**: @Observable + @MainActor
- **リアルタイム同期**: Firebase Firestore Snapshot Listener
- **認証**: Firebase Auth（Sign in with Apple）+ デモモード
- **永続化**: Firestoreオフラインキャッシュ（100MB）
- **テスト**: Swift Testing（@Test構文）

---

## アーキテクチャ

### ディレクトリ構造

```
AsaEventLive/
├── AsaEventLiveApp.swift           # アプリエントリーポイント
├── Models/
│   ├── Event.swift                 # イベントモデル
│   ├── EventPost.swift             # タイムライン投稿
│   ├── Participant.swift           # 参加者
│   └── Activity.swift              # アクティビティ
├── Services/
│   ├── Protocols/
│   │   └── EventDataServiceProtocol.swift
│   ├── Firebase/
│   │   └── FirestoreEventDataService.swift
│   ├── Local/
│   │   └── MockEventDataService.swift
│   └── Utilities/
│       ├── InviteCodeGenerator.swift
│       └── NetworkMonitor.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── EventListViewModel.swift
│   ├── EventDetailViewModel.swift
│   └── TimelineViewModel.swift
└── Views/
    ├── ContentView.swift
    ├── Auth/AuthView.swift
    ├── Events/
    │   ├── EventListView.swift
    │   ├── CreateEventView.swift
    │   └── JoinEventView.swift
    ├── EventDetail/EventDetailView.swift
    ├── Timeline/
    │   ├── TimelineView.swift
    │   ├── TimelinePostCard.swift
    │   └── CreatePostView.swift
    ├── Participants/
    │   ├── ParticipantListView.swift
    │   └── InviteView.swift
    └── Components/
        └── ActivityFeedView.swift
```

### 設計パターン

1. **Protocol-Oriented Service Layer**
   - `EventDataServiceProtocol`でサービス層を抽象化
   - テスト用Mock、本番用Firestoreを切り替え可能

2. **条件コンパイル**
   ```swift
   #if FIREBASE_ENABLED
   let dataService = FirestoreEventDataService()
   #else
   let dataService = MockEventDataService()
   #endif
   ```

3. **リアルタイム同期**
   - Firestoreの`addSnapshotListener`でリアルタイム更新
   - `Any`型でリスナーを返し、解除時にキャスト

---

## 実装のポイント

### 1. 招待コードシステム

```swift
enum InviteCodeGenerator {
    // 読み間違いを避けるため0, O, 1, I を除外
    private static let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

    static func generate(length: Int = 6) -> String {
        String((0..<length).map { _ in characters.randomElement()! })
    }

    static func formatted(_ code: String) -> String {
        // "ABC-123" 形式で表示
        let normalized = normalize(code)
        let midIndex = normalized.index(normalized.startIndex, offsetBy: 3)
        return "\(normalized[..<midIndex])-\(normalized[midIndex...])"
    }
}
```

### 2. オプティミスティックUI

いいね等の操作は即座にUIを更新し、サーバー同期は非同期で実行：

```swift
func toggleLike(on post: EventPost) async {
    // 即座にUIを更新
    if let index = posts.firstIndex(where: { $0.id == post.id }) {
        var updatedPost = posts[index]
        if updatedPost.likedByUserIds.contains(userId) {
            updatedPost.likedByUserIds.removeAll { $0 == userId }
        } else {
            updatedPost.likedByUserIds.append(userId)
        }
        posts[index] = updatedPost
    }

    // サーバーに同期（エラー時はリスナーから最新データが来る）
    try? await dataService.toggleLike(postId: post.id, eventId: eventId, userId: userId)
}
```

### 3. オンライン状態管理

参加者のオンライン状態をリアルタイムで反映：

```swift
enum OnlineStatus: String, Codable {
    case online = "online"   // 緑色バッジ
    case away = "away"       // 黄色バッジ
    case offline = "offline" // グレーバッジ
}

// 画面表示時にオンラインに更新
func startObserving() {
    updateOnlineStatus(.online)
    // ... リスナー設定
}

// 画面離脱時にオフラインに更新
func stopObserving() {
    updateOnlineStatus(.offline)
    // ... リスナー解除
}
```

---

## テスト

### テストカバレッジ

| カテゴリ | テスト数 |
|---------|---------|
| Models | 30+ |
| Services | 25+ |
| ViewModels | 15+ |
| **合計** | **72** |

### テスト例

```swift
@Test("イベントステータス - ライブ中")
func testLiveStatus() {
    let pastDate = Date().addingTimeInterval(-3600)
    let futureEndDate = Date().addingTimeInterval(3600)
    let event = Event(
        title: "進行中のイベント",
        startDate: pastDate,
        endDate: futureEndDate,
        hostId: "host-1",
        hostName: "ホスト"
    )

    #expect(event.status == .live)
    #expect(event.status.displayName == "ライブ中")
}
```

---

## ビルド方法

```bash
cd Apps/AsaEventLive
xcodegen generate
open AsaEventLive.xcodeproj
# Cmd+B でビルド
# Cmd+U でテスト実行
```

---

## スクリーンショット

| イベント一覧 | タイムライン | 参加者 |
|------------|------------|--------|
| ライブ中/予定/過去のイベントをカテゴリ別表示 | リアルタイム投稿フィード | オンライン状態バッジ付き |

---

## 今後の拡張予定

1. **写真投稿機能**: Firebase Storage連携（Blazeプラン必要）
2. **プッシュ通知**: FCMで新着投稿通知
3. **コメント機能**: 投稿へのリプライ
4. **リアクション**: 絵文字リアクション
5. **ライブストリーミング**: WebRTC連携

---

## 学んだこと

1. **Firestoreリアルタイム同期**: Snapshot Listenerの適切な管理
2. **オプティミスティックUI**: ユーザー体験を損なわない更新
3. **Protocol-Oriented Design**: テスト容易性の向上
4. **条件コンパイル**: Firebase有効/無効の切り替え
5. **Swift Testing**: @Test構文によるモダンなテスト記述

---

## 参考資料

- [Firebase Firestore ドキュメント](https://firebase.google.com/docs/firestore)
- [SwiftUI Observable](https://developer.apple.com/documentation/observation)
- [Swift Testing](https://developer.apple.com/documentation/testing)
