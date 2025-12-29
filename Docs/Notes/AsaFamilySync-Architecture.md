# AsaFamilySync - アーキテクチャドキュメント

AsaFamilySyncアプリケーションのアーキテクチャ設計、技術的判断、および実装パターンを説明します。

## 目次

1. [アーキテクチャ概要](#1-アーキテクチャ概要)
2. [MVVMアーキテクチャ](#2-mvvmアーキテクチャ)
3. [プロトコル指向設計](#3-プロトコル指向設計)
4. [データフロー](#4-データフロー)
5. [Firestoreデータモデル](#5-firestoreデータモデル)
6. [セキュリティ設計](#6-セキュリティ設計)
7. [条件付きコンパイル戦略](#7-条件付きコンパイル戦略)
8. [パフォーマンス最適化](#8-パフォーマンス最適化)
9. [エラーハンドリング](#9-エラーハンドリング)
10. [将来の拡張性](#10-将来の拡張性)

---

## 1. アーキテクチャ概要

AsaFamilySyncは、家族間でイベントやスケジュールを共有するためのiOSアプリケーションです。

### 主要技術スタック

- **フレームワーク**: SwiftUI
- **言語**: Swift 5.9+
- **最小OS**: iOS 17.0+
- **バックエンド**: Firebase (Authentication + Cloud Firestore)
- **パターン**: MVVM (Model-View-ViewModel)
- **依存性管理**: Swift Package Manager (SPM)
- **プロジェクト管理**: XcodeGen

### 設計原則

1. **プロトコル指向**: サービス層をプロトコルで抽象化
2. **依存性注入**: ViewModelにサービスを注入
3. **Single Source of Truth**: Firebaseを唯一の真実とする
4. **オフライン対応**: Firestoreのオフラインキャッシュ活用
5. **型安全**: Codableによる型安全なデータ変換

---

## 2. MVVMアーキテクチャ

AsaFamilySyncは、MVVMアーキテクチャパターンを採用しています。

### レイヤー構造

```
┌─────────────────────────────────────────┐
│             View Layer                   │  SwiftUI Views
│  (ContentView, LoginView, etc.)         │
└─────────────────────────────────────────┘
                    ↕ @EnvironmentObject
┌─────────────────────────────────────────┐
│          ViewModel Layer                 │  Business Logic
│  (AuthViewModel, FamilyGroupViewModel)  │  @Observable / @Published
└─────────────────────────────────────────┘
                    ↕ Protocol
┌─────────────────────────────────────────┐
│          Service Layer                   │  Data Operations
│  (AuthService, FamilyDataService)       │  Protocol Abstraction
└─────────────────────────────────────────┘
                    ↕ Firebase SDK
┌─────────────────────────────────────────┐
│          Backend Layer                   │  Cloud Services
│  (Firebase Auth, Cloud Firestore)       │
└─────────────────────────────────────────┘
```

### View (SwiftUI Views)

**責務**:
- ユーザーインターフェースの表示
- ユーザー入力の受付
- ViewModelの状態に基づく画面更新

**例**:
```swift
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack {
            TextField("メールアドレス", text: $email)
            SecureField("パスワード", text: $password)

            AsaButton(
                title: "ログイン",
                action: {
                    Task {
                        await authViewModel.signIn(email: email, password: password)
                    }
                }
            )
        }
    }
}
```

### ViewModel (Business Logic)

**責務**:
- ビジネスロジックの実装
- Viewの状態管理
- Serviceレイヤーとの連携
- エラーハンドリング

**例**:
```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
        setupAuthStateObserver()
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
```

### Service (Data Layer)

**責務**:
- データの取得・保存・更新・削除（CRUD操作）
- Firebase SDKとの直接連携
- エラーマッピング

**プロトコル定義**:
```swift
protocol AuthService {
    var isAuthenticated: Bool { get }
    var currentUser: UserProfile? { get }
    func signIn(email: String, password: String) async throws
    func signOut() throws
}
```

---

## 3. プロトコル指向設計

プロトコル指向設計により、実装の切り替えと将来の拡張が容易になっています。

### 設計の利点

1. **実装の透過性**: ViewModelはプロトコルに依存し、具体的な実装を知らない
2. **テスト容易性**: Mockサービスを簡単に作成可能
3. **切り替え可能性**: Local ⇔ Firebase の切り替えが容易
4. **将来の拡張**: 新しいバックエンド（AWS、Azure等）の追加が容易

### プロトコル階層

```
AuthService (Protocol)
    ├── LocalAuthService (UserDefaults実装)
    └── FirebaseAuthService (Firebase Auth実装)

FamilyDataService (Protocol)
    ├── LocalFamilyDataService (UserDefaults実装)
    └── FirebaseDataService (Firestore実装)
```

### 依存性注入パターン

```swift
@main
struct AsaFamilySyncApp: App {
    private let authService: AuthService
    private let dataService: FamilyDataService

    init() {
        // Firebaseサービスを使用
        let firebaseAuthService = FirebaseAuthService()
        let firebaseDataService = FirebaseDataService()

        self.authService = firebaseAuthService
        self.dataService = firebaseDataService

        // ViewModelに注入
        _authViewModel = StateObject(
            wrappedValue: AuthViewModel(authService: firebaseAuthService)
        )
        _familyGroupViewModel = StateObject(
            wrappedValue: FamilyGroupViewModel(dataService: firebaseDataService)
        )
    }
}
```

---

## 4. データフロー

### 認証フロー

```
┌────────────┐
│   View     │  ユーザーがログインボタンをタップ
└─────┬──────┘
      │ Task { await authViewModel.signIn() }
      ↓
┌────────────┐
│ ViewModel  │  isLoading = true
└─────┬──────┘
      │ await authService.signIn()
      ↓
┌────────────┐
│  Service   │  Firebase Auth.auth().signIn()
└─────┬──────┘
      │ AuthStateListener発火
      ↓
┌────────────┐
│  Service   │  Firestoreからユーザープロファイル取得
└─────┬──────┘
      │ currentUser更新
      ↓
┌────────────┐
│ ViewModel  │  authStateHandler呼び出し
└─────┬──────┘
      │ isAuthenticated = true, currentUser更新
      ↓
┌────────────┐
│   View     │  @Published変更により自動的に再描画
└────────────┘
```

### データ同期フロー（Firestore）

```
┌────────────┐
│  App 1     │  イベント作成
└─────┬──────┘
      │ createEvent()
      ↓
┌────────────┐
│ Firestore  │  events/{eventId} に保存
└─────┬──────┘
      │ サーバータイムスタンプ記録
      ├──────────────┐
      ↓              ↓
┌────────────┐  ┌────────────┐
│  App 1     │  │  App 2     │  リアルタイムリスナー
└────────────┘  └────────────┘  （将来の拡張）
```

---

## 5. Firestoreデータモデル

### コレクション構造

```
firestore/
├── users/                          # ユーザープロファイル（ルートコレクション）
│   └── {userId}/                   # Document: UserProfile
│       ├── uid: String
│       ├── email: String
│       ├── displayName: String
│       ├── familyId: String?
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
├── groups/                         # 家族グループ（ルートコレクション）
│   └── {groupId}/                  # Document: FamilyGroup
│       ├── name: String
│       ├── description: String?
│       ├── ownerId: String
│       ├── inviteCode: String
│       ├── maxMembers: Int
│       ├── createdAt: Timestamp
│       ├── updatedAt: Timestamp
│       │
│       ├── members/                # Subcollection: メンバー
│       │   └── {memberId}/         # Document: FamilyMember
│       │       ├── userId: String
│       │       ├── name: String
│       │       ├── email: String
│       │       ├── role: String (owner/admin/member)
│       │       └── joinedAt: Timestamp
│       │
│       └── events/                 # Subcollection: イベント
│           └── {eventId}/          # Document: FamilyEvent
│               ├── title: String
│               ├── description: String?
│               ├── category: String
│               ├── startDate: Timestamp
│               ├── endDate: Timestamp?
│               ├── isAllDay: Bool
│               ├── location: String?
│               ├── createdBy: String
│               ├── createdAt: Timestamp
│               └── updatedAt: Timestamp
```

### サブコレクション採用理由

1. **データ取得効率化**
   - グループ単位でメンバーとイベントを取得可能
   - 不要なデータの読み込みを回避

2. **セキュリティルール簡潔化**
   - `groups/{groupId}/members/{memberId}` のパスでメンバー判定
   - ルール記述が直感的

3. **スケーラビリティ**
   - グループごとに独立したデータ構造
   - 大量のイベントにも対応可能

4. **クエリ最適化**
   - 期間指定イベント取得が効率的
   - インデックスが効果的に機能

### Codableモデル定義

```swift
struct FamilyGroup: Codable, Identifiable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?
    #else
    var id: String?
    #endif

    var name: String
    var description: String?
    var ownerId: String
    var inviteCode: String
    var maxMembers: Int
    var createdAt: Date?
    var updatedAt: Date?

    init(name: String, description: String?, ownerId: String) {
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.inviteCode = generateInviteCode()
        self.maxMembers = 10
    }
}
```

---

## 6. セキュリティ設計

### Firestore セキュリティルール

AsaFamilySyncでは、**最小権限の原則**に基づいてセキュリティルールを設計しています。

#### 基本方針

1. **認証必須**: すべての操作で認証が必須
2. **プライバシー保護**: ユーザープロファイルは本人のみアクセス可能
3. **グループベース**: 家族グループメンバーのみがデータにアクセス可能
4. **権限ベース**: オーナー/管理者のみが実行できる操作を制限

#### ルール詳細

**ユーザープロファイル**:
```javascript
match /users/{userId} {
  // 本人のみ読み書き可能
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

**家族グループ**:
```javascript
match /groups/{groupId} {
  function isMember() {
    return request.auth != null &&
           exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid));
  }

  // メンバーのみ読み取り可能
  allow read: if isMember();
  // 認証済みユーザーは新規グループ作成可能
  allow create: if request.auth != null;
  // メンバーのみ更新可能
  allow update: if isMember();
}
```

**メンバー管理**:
```javascript
match /members/{memberId} {
  allow read: if isMember();
  allow create: if isMember();
  // オーナー/管理者のみ削除・権限変更可能
  allow update, delete: if isMember() &&
    get(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)).data.role in ['owner', 'admin'];
}
```

**イベント管理**:
```javascript
match /events/{eventId} {
  allow read: if isMember();
  allow create, update: if isMember();
  // 作成者またはオーナー/管理者のみ削除可能
  allow delete: if isMember() &&
    (get(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)).data.role in ['owner', 'admin'] ||
     resource.data.createdBy == request.auth.uid);
}
```

### 脅威モデル

| 脅威 | 対策 |
|------|------|
| 未認証アクセス | Firebase Authenticationによる認証必須 |
| 他グループへの不正アクセス | メンバーシップチェック（`isMember()`） |
| 権限昇格 | ロールベースアクセス制御（RBAC） |
| データ漏洩 | Firestoreセキュリティルールによる厳格な制限 |
| CSRF攻撃 | Firebase SDKの自動トークン管理 |

---

## 7. 条件付きコンパイル戦略

AsaFamilySyncでは、条件付きコンパイルを使用してFirebase統合を管理しています。

### コンパイルフラグ

**設定**（project.yml）:
```yaml
settings:
  OTHER_SWIFT_FLAGS: "$(inherited) -DFIREBASE_ENABLED"
```

### 使用箇所

**Firebase SDKのインポート**:
```swift
#if FIREBASE_ENABLED
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
#endif
```

**AppDelegate**:
```swift
#if FIREBASE_ENABLED
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 Firebase初期化完了")
        return true
    }
}
#endif
```

**モデル定義**:
```swift
struct FamilyGroup: Codable, Identifiable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?  // Firestore用
    #else
    var id: String?               // ローカル用
    #endif
}
```

### 利点

1. **バイナリサイズ削減**: 未使用コードがバイナリから除外
2. **明確な切り替え**: フラグの有無で動作が明確
3. **将来の拡張**: 他のバックエンド追加が容易
4. **開発効率**: ローカル開発も選択可能

---

## 8. パフォーマンス最適化

### オフライン永続化

Firestoreのオフライン永続化を有効化することで、以下の利点があります:

**実装**:
```swift
init() {
    let settings = FirestoreSettings()
    settings.isPersistenceEnabled = true  // オフライン永続化有効化
    db.settings = settings
}
```

**利点**:
1. **オフライン時のデータ閲覧**: ネットワークなしでもデータ参照可能
2. **高速読み込み**: ローカルキャッシュから即座にデータ取得
3. **ネットワーク使用量削減**: 変更されたデータのみ同期
4. **UX向上**: 待ち時間の短縮

### サーバータイムスタンプ

クライアント時刻ではなく、サーバータイムスタンプを使用:

**実装**:
```swift
try await db.collection("users").document(userId).updateData([
    "familyId": familyId,
    "updatedAt": FieldValue.serverTimestamp()  // サーバー時刻使用
])
```

**利点**:
1. **時刻の整合性**: クライアント時刻のずれを回避
2. **正確なイベント順序**: サーバー時刻による厳密なソート
3. **タイムゾーン問題の回避**: UTC基準での統一

### クエリ最適化

**複合インデックス**: 期間指定クエリ用のインデックス作成
```swift
let snapshot = try await eventsCollection(groupId: groupId)
    .whereField("startDate", isGreaterThanOrEqualTo: Timestamp(date: startDate))
    .whereField("startDate", isLessThanOrEqualTo: Timestamp(date: endDate))
    .order(by: "startDate", descending: false)
    .getDocuments()
```

**必要なインデックス**:
- `events`: `startDate` (Ascending) + `__name__` (Ascending)
- Firebase Consoleで自動作成可能

---

## 9. エラーハンドリング

### エラーマッピング

Firebase例外を独自のエラー型にマッピングし、ユーザーフレンドリーなメッセージを提供:

**AuthError**:
```swift
enum AuthError: Error, LocalizedError {
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case networkError
    case notAuthenticated
    case updateFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse:
            return "このメールアドレスは既に使用されています"
        case .invalidEmail:
            return "メールアドレスの形式が正しくありません"
        // ...
        }
    }
}
```

**エラーマッピング実装**:
```swift
private func mapAuthError(_ error: Error) -> AuthError {
    let nsError = error as NSError

    if nsError.domain == AuthErrorDomain {
        switch AuthErrorCode(_nsError: nsError).code {
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .invalidEmail:
            return .invalidEmail
        // ...
        default:
            return .unknown(error.localizedDescription)
        }
    }

    return .unknown(error.localizedDescription)
}
```

### ViewModelでのエラーハンドリング

```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?

    func signIn(email: String, password: String) async {
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            // LocalizedErrorのerrorDescriptionを使用
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## 10. 将来の拡張性

### リアルタイムリスナー対応

将来的にリアルタイム同期を追加する場合の実装例:

```swift
func listenToEvents(groupId: String, handler: @escaping ([FamilyEvent]) -> Void) -> ListenerRegistration {
    return eventsCollection(groupId: groupId)
        .order(by: "startDate", descending: false)
        .addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot else { return }

            let events = snapshot.documents.compactMap { doc in
                var event = try? doc.data(as: FamilyEvent.self)
                event?.id = doc.documentID
                return event
            }

            handler(events)
        }
}
```

### 他のバックエンド追加

プロトコル指向設計により、新しいバックエンドの追加が容易:

```swift
// AWS Amplify実装例
class AmplifyAuthService: AuthService {
    func signIn(email: String, password: String) async throws {
        // AWS Amplify実装
    }
}

class AmplifyDataService: FamilyDataService {
    func createEvent(groupId: String, event: FamilyEvent) async throws -> String {
        // AWS Amplify実装
    }
}
```

### マルチプラットフォーム対応

- **macOS**: SwiftUIの共通コードベース活用
- **watchOS**: 簡易版イベント表示
- **iPad**: マルチウィンドウ対応

### 新機能追加

1. **プッシュ通知**: Firebase Cloud Messaging統合
2. **カレンダー統合**: EventKit連携
3. **位置情報**: イベントの位置情報共有
4. **ファイル共有**: Firebase Storage統合

---

## まとめ

AsaFamilySyncは、**プロトコル指向設計**と**MVVMアーキテクチャ**により、保守性と拡張性を両立したアプリケーションです。

**主な設計決定**:
- ✅ プロトコル抽象化によるバックエンド切り替え可能性
- ✅ サブコレクションによる効率的なデータモデル
- ✅ 厳格なセキュリティルールによるデータ保護
- ✅ オフライン永続化によるUX向上
- ✅ 条件付きコンパイルによる柔軟な構成

この設計により、将来的な機能追加やバックエンド変更にも柔軟に対応できます。
