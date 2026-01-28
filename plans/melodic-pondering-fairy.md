# AsaExpenseSync 実装計画

## 概要
**AsaExpenseSync**（#78）は、複数デバイス間で収支データをリアルタイム同期する上級アプリです。Firebase Firestoreをバックエンドとし、オフライン対応も実現します。

---

## アーキテクチャ

### ディレクトリ構造
```
Apps/AsaExpenseSync/
├── project.yml
├── AsaExpenseSync/
│   ├── AsaExpenseSyncApp.swift
│   ├── Models/
│   │   ├── ExpenseTransaction.swift    # Firestore対応取引モデル
│   │   ├── ExpenseCategory.swift       # カテゴリ
│   │   ├── Budget.swift                # 予算
│   │   ├── SyncMetadata.swift          # 同期メタデータ
│   │   └── LocalTransaction.swift      # Swift Data用ローカルモデル
│   ├── Services/
│   │   ├── Protocols/
│   │   │   ├── ExpenseDataServiceProtocol.swift
│   │   │   └── AuthServiceProtocol.swift
│   │   ├── Firebase/
│   │   │   ├── FirestoreExpenseDataService.swift
│   │   │   └── FirebaseExpenseAuthService.swift
│   │   ├── Local/
│   │   │   └── MockExpenseDataService.swift
│   │   └── Sync/
│   │       ├── SyncEngine.swift        # 同期エンジン
│   │       └── ConflictResolver.swift  # 競合解決
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── ExpenseViewModel.swift
│   │   ├── DashboardViewModel.swift
│   │   └── SyncStatusViewModel.swift
│   └── Views/
│       ├── ContentView.swift
│       ├── Auth/AuthView.swift
│       ├── Dashboard/DashboardView.swift
│       ├── Transactions/
│       │   ├── TransactionListView.swift
│       │   └── AddTransactionView.swift
│       ├── Reports/ReportsView.swift
│       └── Components/
│           ├── SyncStatusBadge.swift
│           └── OfflineIndicator.swift
└── AsaExpenseSyncTests/
```

### レイヤー構成
```
Views (SwiftUI + AsaUIKit)
        ↓
ViewModels (@Observable + @MainActor)
        ↓
Services (Protocol-based DI)
        ↓
Firestore (Remote) + Swift Data (Local)
```

---

## データモデル

### Firestoreデータ構造
```
users/{userId}/
├── profile
├── transactions/{txId}/
├── categories/{categoryId}/
└── budgets/{budgetId}/
```

### ExpenseTransaction（主要モデル）
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

---

## 同期戦略

### リアルタイム同期
- Firestore Snapshot Listenerで変更を即時反映
- `syncVersion`による楽観的ロック

### オフライン対応
- Firestoreのオフライン永続化（100MBキャッシュ）
- ネットワーク復帰時に自動同期

### 競合解決（Last-Write-Wins + User Choice）
```swift
enum ConflictResolutionStrategy {
    case lastWriteWins   // デフォルト：updatedAt比較
    case localWins       // ローカル優先
    case remoteWins      // リモート優先
    case userChoice      // ユーザー選択UI表示
}
```

---

## 主要画面

| 画面 | 機能 |
|------|------|
| AuthView | ログイン/サインアップ（Firebase Auth） |
| DashboardView | 残高サマリー、最近の取引、同期ステータス |
| TransactionListView | 取引一覧、フィルタ、検索 |
| AddTransactionView | 取引追加フォーム |
| ReportsView | 支出グラフ、カテゴリ別分析 |
| SettingsView | 同期設定、アカウント管理 |

---

## 実装フェーズ

### Phase 1: 基盤構築（1-2日）
- [ ] プロジェクト作成（project.yml）
- [ ] データモデル実装
- [ ] プロトコル定義
- [ ] AsaUIKit統合

### Phase 2: ローカル機能（2-3日）
- [ ] MockExpenseDataService実装
- [ ] ExpenseViewModel実装
- [ ] 基本UI（Dashboard, TransactionList, AddTransaction）
- [ ] 単体テスト

### Phase 3: Firebase統合（2-3日）
- [ ] Firebase設定（GoogleService-Info.plist）
- [ ] FirestoreExpenseDataService実装
- [ ] 認証フロー（FirebaseExpenseAuthService）
- [ ] Snapshot Listenerによるリアルタイム同期

### Phase 4: オフライン対応（1-2日）
- [ ] Firestoreオフライン永続化設定
- [ ] SyncEngine実装
- [ ] NetworkMonitor実装

### Phase 5: 競合解決（1-2日）
- [ ] ConflictResolver実装
- [ ] 競合検出ロジック（syncVersion比較）
- [ ] ConflictResolutionView（ユーザー選択UI）

### Phase 6: 仕上げ（1日）
- [ ] UI/UX改善
- [ ] エラーハンドリング強化
- [ ] ドキュメント作成
- [ ] 最終テスト

---

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

---

## 参照ファイル（実装時の参考）

- [FirestoreSocialFeedDataService.swift](Apps/AsaSocialFeed/AsaSocialFeed/Services/FirestoreSocialFeedDataService.swift) - Snapshot Listenerパターン
- [Transaction.swift](Apps/AsaFamilyBudget/AsaFamilyBudget/Models/Transaction.swift) - 取引モデル設計
- [FirebaseDataService.swift](Apps/AsaFamilySync/AsaFamilySync/Services/FirebaseDataService.swift) - オフライン永続化設定
- [project.yml](Apps/AsaSocialFeed/project.yml) - Firebase依存関係設定

---

## 検証方法

### ビルド確認
```bash
cd Apps/AsaExpenseSync
xcodegen generate
open AsaExpenseSync.xcodeproj
# Cmd+B でビルド
```

### テスト実行
```bash
swift test
# または Xcode で Cmd+U
```

### 同期動作確認
1. シミュレータ2台で同時起動
2. 片方で取引を追加
3. もう片方に即時反映されることを確認
4. 機内モードでオフライン動作を確認
