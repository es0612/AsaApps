# Day 71: AsaFamilySync - 家族の予定をクラウド同期

## 概要
AsaFamilySyncは、Firebase を活用した家族向けの予定共有アプリです。上級レベル（アプリ #71）として、リアルタイム同期、認証、複雑なデータ管理を実装しています。

## 主要機能

### 1. Firebase認証
- メールアドレス/パスワード認証
- ユーザープロファイル管理
- セッション管理とオートログイン

### 2. 家族グループ管理
- グループ作成・参加機能
- 6文字の招待コードによる安全な参加
- メンバー権限管理（オーナー、管理者、メンバー）
- 最大10名までのメンバー制限

### 3. 予定管理
- イベントの作成・編集・削除
- 9つのカテゴリ分類（仕事、学校、家事、レジャー等）
- 繰り返し予定の設定
- リマインダー機能（複数時間設定可能）
- メンバーへの予定割り当て

### 4. カレンダー表示
- 月間カレンダービュー
- 日付選択による予定フィルタリング
- カテゴリ別の色分け表示

### 5. リアルタイム同期
- Firestore リアルタイムリスナー
- 家族間での即座な予定共有
- オフライン対応（ローカルキャッシュ）

## 技術実装

### アーキテクチャ
```
MVVM + Firebase
├── Models (Codable データ構造)
├── ViewModels (@Observable パターン)
├── Views (SwiftUI)
├── Services (Firebase統合)
└── Utils (ヘルパー関数)
```

### 使用技術
- **SwiftUI**: 最新のUI宣言的開発
- **Firebase SDK**: Authentication, Firestore, Analytics
- **@Observable**: モダンな状態管理（@StateObject から移行）
- **Swift Concurrency**: async/await
- **AsaUIKit**: 共有UIコンポーネント

### データベース設計
```
Firestore構造:
families/
  └── {familyId}/
      ├── info: グループ情報
      ├── members/: メンバーリスト
      └── events/: 予定データ

users/
  └── {userId}/
      ├── profile: ユーザー情報
      └── settings: 設定データ
```

## 実装のポイント

### 1. @Observable パターンの採用
```swift
@MainActor
@Observable
final class FamilyGroupViewModel {
    var familyGroup: FamilyGroup?
    var familyMembers: [FamilyMember] = []
    // リアクティブな状態管理
}
```

### 2. Firebase リアルタイム同期
```swift
groupListener = db.collection("families").document(groupId)
    .addSnapshotListener { [weak self] documentSnapshot, error in
        // 自動的にUIが更新
    }
```

### 3. 招待コードシステム
- 6文字の英数字コード自動生成
- グループ検索と参加の簡易化
- セキュアな家族グループ形成

### 4. 権限管理
- オーナー: 全権限
- 管理者: メンバー管理、イベント削除
- メンバー: 基本的な読み書き権限

## セットアップ手順

### 1. Firebase設定
1. Firebase Consoleで新規プロジェクト作成
2. iOS アプリを追加（Bundle ID: com.asaapps.asafamilysync）
3. GoogleService-Info.plist をダウンロード
4. AsaFamilySync/AsaFamilySync/ に配置

### 2. Firebaseルール設定
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 認証済みユーザーのみアクセス可能
    match /families/{familyId}/{document=**} {
      allow read, write: if request.auth != null
        && request.auth.uid in resource.data.members;
    }

    match /users/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }
  }
}
```

### 3. ビルドと実行
```bash
cd Apps/AsaFamilySync
xcodegen generate
open AsaFamilySync.xcodeproj
```

## 今後の拡張案

### 機能追加
- [ ] プッシュ通知（Firebase Cloud Messaging）
- [ ] 写真付きイベント
- [ ] タスクの完了機能
- [ ] チャット機能
- [ ] 複数グループ対応

### 技術改善
- [ ] Swift Data 統合
- [ ] WidgetKit 対応
- [ ] CloudKit バックアップ
- [ ] Apple Watch アプリ

## 学習ポイント

### 1. Firebase統合の基礎
- Authentication のセットアップ
- Firestore のデータ設計
- リアルタイムリスナーの実装

### 2. 状態管理のモダン化
- @StateObject → @Observable への移行
- @MainActor による UI 更新の保証
- Swift Concurrency の活用

### 3. セキュリティ考慮
- 招待コードによる安全な参加
- Firestore セキュリティルール
- 権限ベースのアクセス制御

## トラブルシューティング

### Firebase SDK エラー
```
対処法:
1. GoogleService-Info.plist の確認
2. Bundle IDの一致確認
3. Firebase Console での iOS アプリ設定確認
```

### ビルドエラー
```
対処法:
1. XcodeGen で project.yml を再生成
2. Firebase SDK のバージョン確認
3. AsaUIKit パッケージのパス確認
```

## まとめ
AsaFamilySyncは、上級レベルのアプリとして、Firebase によるクラウド同期、リアルタイム更新、複雑な権限管理を実装しました。モダンな @Observable パターンと Firebase の組み合わせにより、スケーラブルで保守性の高いアプリ設計を実現しています。

## 作成日
2025年1月20日

## 作成者
朝活パパエンジニア / Asa Apps