# Day 78: AsaExpenseSync - 複数デバイスで収支同期

## 概要

**AsaExpenseSync**は、Firebase Firestoreを使って複数デバイス間で収支データをリアルタイム同期する上級アプリです。オフライン対応や競合解決機能も備えています。

## 主要機能

- **ユーザー認証**: Firebase Authによるメール/パスワード認証
- **リアルタイム同期**: Firestore Snapshot Listenerによる即時同期
- **オフライン対応**: Firestoreのオフライン永続化（100MBキャッシュ）
- **競合解決**: syncVersionによる楽観的ロック + 競合解決戦略
- **収支管理**: 取引追加/編集/削除、カテゴリ管理、予算設定

## アーキテクチャ

```
Views (SwiftUI + AsaUIKit)
        ↓
ViewModels (@Observable + @MainActor)
        ↓
Services (Protocol-based DI)
        ↓
Firestore (Remote) + Swift Data (Local)
```

## 技術スタック

| 項目 | 技術 |
|------|------|
| UI | SwiftUI + AsaUIKit + Charts |
| 状態管理 | @Observable + @MainActor |
| ローカル永続化 | Swift Data |
| リモート同期 | Firebase Firestore 11.0+ |
| 認証 | Firebase Auth（Email/Password） |
| 条件付きコンパイル | `#if FIREBASE_ENABLED` |
| テスト | Swift Testing（@Test構文） |

## ディレクトリ構造

```
Apps/AsaExpenseSync/
├── project.yml
├── AsaExpenseSync/
│   ├── AsaExpenseSyncApp.swift
│   ├── Models/
│   │   ├── ExpenseTransaction.swift
│   │   ├── ExpenseCategory.swift
│   │   ├── Budget.swift
│   │   ├── SyncMetadata.swift
│   │   └── LocalTransaction.swift
│   ├── Services/
│   │   ├── Protocols/
│   │   ├── Firebase/
│   │   ├── Local/
│   │   └── Sync/
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   └── ExpenseViewModel.swift
│   └── Views/
│       ├── Auth/
│       ├── Dashboard/
│       ├── Transactions/
│       ├── Reports/
│       ├── Settings/
│       └── Components/
└── AsaExpenseSyncTests/
```

## データモデル

### ExpenseTransaction

```swift
struct ExpenseTransaction: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    var amount: Double
    var typeRawValue: String      // 収入/支出
    var title: String
    var note: String?
    var date: Date
    var categoryId: String?

    // 同期プロパティ
    var userId: String
    var deviceId: String
    var syncVersion: Int          // 楽観的ロック用
    var isDeleted: Bool           // 論理削除
}
```

## 同期戦略

### リアルタイム同期フロー

1. ユーザーが取引を作成
2. ローカル（Swift Data）に保存
3. Firestoreにプッシュ
4. 他デバイスのSnapshot Listenerが更新を受信
5. 各デバイスのUIが更新

### 競合解決戦略

```swift
enum ConflictResolutionStrategy {
    case lastWriteWins   // デフォルト：updatedAt比較
    case localWins       // ローカル優先
    case remoteWins      // リモート優先
    case userChoice      // ユーザー選択UI表示
}
```

## 実装のポイント

### 1. プロトコルベース設計

```swift
protocol ExpenseDataServiceProtocol: AnyObject, Sendable {
    func fetchTransactions(userId: String) async throws -> [ExpenseTransaction]
    func createTransaction(_ transaction: ExpenseTransaction) async throws -> ExpenseTransaction
    func observeTransactions(userId: String, handler: @escaping ([ExpenseTransaction]) -> Void) -> Any
    // ...
}
```

これにより、Firebase/Mock実装を簡単に切り替え可能。テスト容易性も向上。

### 2. 条件付きコンパイル

```swift
#if FIREBASE_ENABLED
import FirebaseCore
// Firebase実装
#else
// Mock実装
#endif
```

Firebase設定なしでもアプリを動作確認可能。

### 3. 楽観的ロック

```swift
// Firestore Transaction内で
if remoteSyncVersion > transaction.syncVersion {
    // 競合検出 - ConflictResolverで解決
}
updatedTransaction.syncVersion = remoteSyncVersion + 1
```

## 使用方法

### ビルド

```bash
cd Apps/AsaExpenseSync
xcodegen generate
open AsaExpenseSync.xcodeproj
# Cmd+B でビルド
```

### Firebase設定（本番用）

1. Firebaseコンソールでプロジェクト作成
2. iOS アプリを追加
3. `GoogleService-Info.plist`をダウンロード
4. `AsaExpenseSync/`フォルダに配置

### テスト実行

```bash
xcodebuild test -project AsaExpenseSync.xcodeproj -scheme AsaExpenseSync -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## 学んだこと

1. **Firestoreのオフライン永続化**: `PersistentCacheSettings`で100MBキャッシュ設定
2. **Snapshot Listener**: リアルタイム同期のパターン
3. **楽観的ロック**: `syncVersion`による競合検出
4. **Swift Concurrency**: `@MainActor`、`async/await`、`Sendable`の活用
5. **プロトコルベースDI**: テスト容易性と柔軟性の両立

## 今後の改善点

- Apple Sign In対応
- プッシュ通知（Firebase Cloud Messaging）
- カテゴリのカスタマイズUI
- 予算アラート機能
- データエクスポート（CSV/PDF）

## 関連ファイル

- [計画ファイル](../../plans/melodic-pondering-fairy.md)
- [AsaFamilyBudget（参考実装）](../AsaFamilyBudget/)
- [AsaSocialFeed（Firebase参考）](../AsaSocialFeed/)
