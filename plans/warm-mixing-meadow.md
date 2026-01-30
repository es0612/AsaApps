# AsaEventLive 実装計画

## 概要

**AsaEventLive**（アプリ #85）は、家族や友人とイベント（誕生日、運動会、旅行等）の進行状況や写真・コメントをリアルタイムで共有するアプリです。

### コンセプト
- 「その場にいなくても、一緒にイベントを楽しめる」
- 家族向け・生産性重視のAsaAppsブランドに沿った設計
- Firebase Firestoreによるリアルタイム同期（既存パターン活用）

---

## 主要機能

| 機能 | 説明 |
|------|------|
| **イベント作成** | タイトル、日時、場所、カテゴリ、カバー画像 |
| **招待コード参加** | 6文字のコードでイベントに参加 |
| **リアルタイムタイムライン** | 写真・コメントをライブ更新 |
| **参加者管理** | オンライン状態表示、ロール管理 |
| **アクティビティフィード** | 「〇〇さんが写真を追加」等の通知 |
| **オフライン対応** | ローカルキャッシュ、後で同期 |

---

## 技術スタック

- **UI**: SwiftUI + AsaUIKit（共有コンポーネント）
- **状態管理**: @Observable + @MainActor
- **リアルタイム同期**: Firebase Firestore Snapshot Listener
- **認証**: Firebase Auth（Sign in with Apple）
- **永続化**: Firestoreオフラインキャッシュ（100MB）
- **テスト**: Swift Testing（@Test構文）

---

## ディレクトリ構造

```
Apps/AsaEventLive/
├── project.yml
├── AsaEventLive/
│   ├── AsaEventLiveApp.swift
│   ├── Models/
│   │   ├── Event.swift              # イベントモデル
│   │   ├── EventPost.swift          # タイムライン投稿
│   │   ├── Participant.swift        # 参加者
│   │   └── Activity.swift           # アクティビティ
│   ├── Services/
│   │   ├── Protocols/
│   │   │   └── EventDataServiceProtocol.swift
│   │   ├── Firebase/
│   │   │   └── FirestoreEventDataService.swift
│   │   ├── Local/
│   │   │   └── MockEventDataService.swift
│   │   └── Utilities/
│   │       ├── InviteCodeGenerator.swift
│   │       └── NetworkMonitor.swift
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── EventListViewModel.swift
│   │   ├── EventDetailViewModel.swift
│   │   └── TimelineViewModel.swift
│   └── Views/
│       ├── ContentView.swift
│       ├── Auth/AuthView.swift
│       ├── Events/
│       │   ├── EventListView.swift
│       │   ├── CreateEventView.swift
│       │   └── JoinEventView.swift
│       ├── EventDetail/
│       │   └── EventDetailView.swift
│       ├── Timeline/
│       │   ├── TimelineView.swift
│       │   ├── TimelinePostCard.swift
│       │   └── CreatePostView.swift
│       ├── Participants/
│       │   ├── ParticipantListView.swift
│       │   └── InviteView.swift
│       └── Components/
│           └── (共通UIコンポーネント)
└── AsaEventLiveTests/
    ├── Models/
    ├── ViewModels/
    └── Services/
```

---

## 実装フェーズ（6日間）

### Phase 1: 基盤構築（Day 1）
- [ ] project.yml作成（Firebase依存関係含む）
- [ ] データモデル実装（Event, EventPost, Participant, Activity）
- [ ] AsaUIKit依存関係設定
- [ ] Assets.xcassets準備

### Phase 2: サービス層（Day 2）
- [ ] EventDataServiceProtocol定義
- [ ] MockEventDataService実装（テスト用）
- [ ] FirestoreEventDataService実装（条件コンパイル）
- [ ] InviteCodeGenerator実装
- [ ] NetworkMonitor移植

### Phase 3: 認証・イベント管理（Day 3）
- [ ] AuthViewModel実装
- [ ] AuthView（サインイン画面）
- [ ] EventListViewModel実装
- [ ] EventListView（イベント一覧）
- [ ] CreateEventView（イベント作成）
- [ ] JoinEventView（招待コード参加）

### Phase 4: イベント詳細・タイムライン（Day 4）
- [ ] EventDetailViewModel実装
- [ ] EventDetailView（タブ構成）
- [ ] TimelineViewModel実装
- [ ] TimelineView（リアルタイム投稿）
- [ ] CreatePostView（投稿作成）
- [ ] TimelinePostCard（投稿カード）

### Phase 5: 参加者・アクティビティ（Day 5）
- [ ] ParticipantViewModel実装
- [ ] ParticipantListView（参加者一覧）
- [ ] InviteView（招待画面）
- [ ] OnlineStatusBadge（オンライン状態）
- [ ] ActivityFeedView（アクティビティ）

### Phase 6: 仕上げ・テスト（Day 6）
- [ ] Unit Tests実装（40テスト目標）
- [ ] UIコンポーネント調整
- [ ] エラーハンドリング強化
- [ ] ドキュメント作成（Day85-Implementation.md）

---

## 重要な参照ファイル

| 目的 | ファイル |
|------|---------|
| Firestoreリアルタイム同期 | `Apps/AsaSocialFeed/AsaSocialFeed/Services/FirestoreSocialFeedDataService.swift` |
| サービスプロトコル設計 | `Apps/AsaExpenseSync/AsaExpenseSync/Services/Protocols/ExpenseDataServiceProtocol.swift` |
| Firebase project.yml | `Apps/AsaSocialFeed/project.yml` |
| Mock実装パターン | `Apps/AsaExpenseSync/AsaExpenseSync/Services/Local/MockExpenseDataService.swift` |

---

## 検証方法

### 1. ビルド確認
```bash
cd Apps/AsaEventLive
xcodegen generate
open AsaEventLive.xcodeproj
# Cmd+B でビルド
```

### 2. テスト実行
```bash
# Xcodeから: Cmd+U
# または
xcodebuild test -project AsaEventLive.xcodeproj -scheme AsaEventLive -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 3. 機能確認チェックリスト
- [ ] イベント作成 → 招待コード生成
- [ ] 招待コードでイベント参加
- [ ] タイムラインにテキスト投稿
- [ ] リアルタイムで投稿が反映
- [ ] 参加者一覧表示
- [ ] オフライン時のバナー表示
- [ ] オンライン復帰時の自動同期

---

## 技術的考慮事項

### Firebase Sparkプラン制限
- Firebase Storageは使用しない（画像URLは将来対応）
- Firestoreオフラインキャッシュ活用（100MB）
- リスナーの適切な管理（メモリリーク防止）

### セキュリティ
- Firestore Security Rulesでアクセス制御
- 参加者のみがイベントにアクセス可能
- ホスト/共同ホストのみが設定変更可能

### パフォーマンス
- LazyVStackによる遅延読み込み
- Firestoreクエリのlimit設定（50件）
- AsyncImageによる画像キャッシング
