# Day 76 - AsaSocialFeed Firebase連携アップグレード

## 概要
AsaSocialFeedをローカル専用SNSアプリから、Firebase連携によるリアルタイム同期対応ソーシャルアプリにアップグレードしました。

## 実装機能

### 1. Firebase Authentication（Sign in with Apple）
- Apple IDでのサインイン
- ユーザープロファイル管理（Firestore）
- 認証状態のリアルタイム監視

### 2. Firestore連携
- リアルタイム投稿同期（スナップショットリスナー）
- 投稿のCRUD操作
- いいね機能（トランザクション処理）

### 3. Firebase Storage
- 画像付き投稿
- 画像圧縮（500KB以下に自動圧縮）
- 投稿削除時の画像自動削除

### 4. Push通知（FCM）
- FCMトークン管理
- フォアグラウンド/バックグラウンド通知対応
- 通知タップ時のハンドリング

## 技術スタック

### 依存関係
```yaml
packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    from: 11.0.0
    products:
      - FirebaseAuth
      - FirebaseFirestore
      - FirebaseStorage
      - FirebaseMessaging
```

### アーキテクチャ
- **MVVM + Protocol-Based Services**
- **条件コンパイル**: `#if FIREBASE_ENABLED` でローカル/Firebase切り替え
- **@Observable**: SwiftUIのモダンな状態管理

## ファイル構成

### 新規作成ファイル（12個）
```
AsaSocialFeed/
├── Models/
│   ├── User.swift                    # Firebaseユーザーモデル
│   └── FirebasePost.swift            # Firestore投稿モデル
├── Services/
│   ├── AuthService.swift             # 認証プロトコル
│   ├── FirebaseAuthService.swift     # Firebase認証実装
│   ├── SocialFeedDataServiceProtocol.swift  # データプロトコル
│   └── FirestoreSocialFeedDataService.swift # Firestore実装
├── ViewModels/
│   ├── AuthViewModel.swift           # 認証ViewModel
│   └── FirebaseFeedViewModel.swift   # Firebaseフィード管理
└── Views/
    ├── AuthView.swift                # 認証画面
    ├── ProfileView.swift             # プロフィール画面
    ├── FirebaseContentView.swift     # メイン画面
    ├── FirebasePostCardView.swift    # 投稿カード
    └── FirebaseNewPostView.swift     # 投稿作成
```

### 修正ファイル
- `project.yml` - Firebase依存関係追加
- `Info.plist` - バックグラウンドモード追加
- `AsaSocialFeedApp.swift` - Firebase初期化

## Firestoreデータ構造

```
firestore/
├── users/{userId}
│   ├── email: String
│   ├── displayName: String
│   ├── photoURL: String?
│   ├── fcmToken: String?
│   ├── createdAt: Timestamp
│   └── updatedAt: Timestamp
│
└── posts/{postId}
    ├── content: String
    ├── authorId: String
    ├── authorName: String
    ├── authorPhotoURL: String?
    ├── imageURL: String?
    ├── likeCount: Int
    ├── likedByUserIds: [String]
    ├── createdAt: Timestamp
    └── updatedAt: Timestamp
```

## 実装上の注意点

### 1. Swift Concurrencyとdeinit
```swift
// ❌ NG: deinitでMainActorプロパティにアクセス不可
deinit {
    stopObservingPosts() // エラー
}

// ✅ OK: Viewのライフサイクルでクリーンアップ
.onDisappear {
    feedViewModel.stopObservingPosts()
}
```

### 2. Sendable警告の抑制
```swift
// @preconcurrencyでFirebase型のSendable警告を抑制
@preconcurrency import FirebaseFirestore
```

### 3. 画像圧縮
```swift
private func compressImage(_ data: Data, maxSizeKB: Int = 500) -> Data {
    guard let image = UIImage(data: data) else { return data }
    var compression: CGFloat = 0.8
    var compressedData = image.jpegData(compressionQuality: compression) ?? data

    while compressedData.count > maxSizeKB * 1024 && compression > 0.1 {
        compression -= 0.1
        compressedData = image.jpegData(compressionQuality: compression) ?? data
    }
    return compressedData
}
```

## セットアップ手順

### 1. Firebase Console設定
1. [Firebase Console](https://console.firebase.google.com/)でプロジェクト作成
2. iOSアプリを追加（Bundle ID: com.asapapa.apps.asasocialfeed）
3. `GoogleService-Info.plist`をダウンロード
4. Authentication: Sign in with Apple を有効化
5. Firestore Database作成
6. Storage有効化
7. Cloud Messaging設定

### 2. Xcodeプロジェクト設定
1. `GoogleService-Info.plist`をプロジェクトに追加
2. Apple Developer: Sign in with Apple Capability追加
3. Push通知用APNsキー設定

### 3. Firestoreセキュリティルール（本番用）
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        resource.data.authorId == request.auth.uid;
    }
  }
}
```

## 今後の拡張可能性

1. **フォロー機能**: ユーザー間のフォロー関係
2. **コメント機能**: 投稿へのコメント
3. **ハッシュタグ**: 投稿のカテゴリ分け
4. **Cloud Functions**: いいね通知の自動送信

## 学習ポイント

- Firebase SDK統合（SPM経由）
- Sign in with Apple実装
- Firestoreリアルタイムリスナー
- Firebase Storage画像管理
- FCMプッシュ通知
- Swift Concurrency（MainActor、Sendable）
- 条件コンパイル（#if）によるビルド分離
