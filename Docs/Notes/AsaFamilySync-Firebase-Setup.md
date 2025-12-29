# AsaFamilySync - Firebase手動セットアップガイド

このガイドでは、AsaFamilySyncアプリでFirebaseを使用するための手動セットアップ手順を説明します。

## 目次

1. [Firebase Consoleでのプロジェクト作成](#1-firebase-consoleでのプロジェクト作成)
2. [iOSアプリの追加](#2-iOsアプリの追加)
3. [GoogleService-Info.plistのダウンロードと配置](#3-googleservice-infoplistのダウンロードと配置)
4. [Firebase Authenticationの有効化](#4-firebase-authenticationの有効化)
5. [Cloud Firestoreの有効化](#5-cloud-firestoreの有効化)
6. [セキュリティルールの設定](#6-セキュリティルールの設定)
7. [動作確認](#7-動作確認)
8. [トラブルシューティング](#8-トラブルシューティング)

---

## 1. Firebase Consoleでのプロジェクト作成

### 手順

1. **Firebase Consoleにアクセス**
   - URL: https://console.firebase.google.com/
   - Googleアカウントでログイン

2. **新規プロジェクト作成**
   - 「プロジェクトを追加」ボタンをクリック
   - プロジェクト名: `AsaFamilySync`（任意の名前で可）
   - プロジェクトIDは自動生成されます（確認のみ）
   - 「続行」をクリック

3. **Google Analyticsの設定（オプション）**
   - Google Analyticsを有効化する場合はトグルをON
   - 推奨: 有効化（アプリの使用状況分析に有用）
   - Googleアナリティクスアカウントを選択（または新規作成）
   - 「プロジェクトを作成」をクリック

4. **プロジェクト作成完了**
   - 数秒待つとプロジェクトが作成されます
   - 「次へ」をクリックしてプロジェクトダッシュボードに移動

---

## 2. iOSアプリの追加

### 手順

1. **iOSアプリ追加画面を開く**
   - プロジェクトダッシュボードで「iOSアプリを追加」アイコンをクリック
   - または、プロジェクト設定 → 全般 → アプリを追加 → iOS

2. **アプリ情報の入力**
   - **Apple バンドルID**: `com.asaapps.asafamilysync`
     - ⚠️ **重要**: 正確に入力してください（project.ymlのPRODUCT_BUNDLE_IDENTIFIERと一致）
   - **アプリのニックネーム**: `AsaFamilySync`（任意）
   - **App Store ID**: 空欄のまま（開発段階のため不要）

3. **アプリの登録**
   - 「アプリを登録」ボタンをクリック

---

## 3. GoogleService-Info.plistのダウンロードと配置

### 手順

1. **GoogleService-Info.plistをダウンロード**
   - 「GoogleService-Info.plistをダウンロード」ボタンをクリック
   - ファイルがダウンロードフォルダに保存されます

2. **ファイルの配置**
   - ダウンロードしたファイルを以下のパスに配置:
     ```
     /Users/shinya/workspace/claude/AsaApps/Apps/AsaFamilySync/AsaFamilySync/GoogleService-Info.plist
     ```
   - 既存のplaceholderファイル（`GoogleService-Info.plist`）を **置き換え** してください

3. **セキュリティ注意事項**
   - ⚠️ GoogleService-Info.plistには機密情報が含まれています
   - Gitにコミットしないよう、`.gitignore`に既に登録されていることを確認
   - バージョン管理から除外されていることを確認:
     ```bash
     git status
     ```
     - `GoogleService-Info.plist`が表示されないことを確認

4. **次のステップ**
   - Firebase Console画面で「次へ」をクリック
   - SDK初期化コードの確認（既にコードに実装済みなので確認のみ）
   - 「次へ」→「コンソールに進む」をクリック

---

## 4. Firebase Authenticationの有効化

### 手順

1. **Authenticationページに移動**
   - 左サイドメニューから「構築」→「Authentication」をクリック
   - 初回は「始める」ボタンが表示されるのでクリック

2. **メール/パスワード認証の有効化**
   - 「Sign-in method」タブをクリック
   - プロバイダーのリストから「メール / パスワード」を選択
   - 「有効にする」トグルをON
   - 「保存」ボタンをクリック

3. **（オプション）その他の認証プロバイダ**
   - 将来的にGoogle Sign-In等を追加する場合はここで設定可能
   - 現時点では「メール / パスワード」のみで十分

4. **確認**
   - Sign-in methodタブで「メール / パスワード」が有効になっていることを確認

---

## 5. Cloud Firestoreの有効化

### 手順

1. **Firestoreページに移動**
   - 左サイドメニューから「構築」→「Firestore Database」をクリック
   - 「データベースを作成」ボタンをクリック

2. **セキュリティルールの選択**
   - **本番環境モード** を選択（推奨）
     - 理由: セキュリティルールを明示的に設定する必要があり、安全
   - テストモードは選択しないでください（セキュリティリスク）
   - 「次へ」をクリック

3. **ロケーションの選択**
   - ロケーション: `asia-northeast1`（東京）または `asia-northeast2`（大阪）
   - 推奨: `asia-northeast1`（東京）
   - ⚠️ **注意**: ロケーションは後から変更できません
   - 「有効にする」ボタンをクリック

4. **データベース作成完了**
   - 数秒待つとFirestoreが有効化されます
   - 空のデータベースダッシュボードが表示されます

---

## 6. セキュリティルールの設定

### 手順

1. **セキュリティルールエディタを開く**
   - Firestoreダッシュボードで「ルール」タブをクリック

2. **セキュリティルールをコピー&ペースト**
   - エディタの既存の内容を **すべて削除**
   - 以下のルールをコピーしてエディタに貼り付け:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザープロファイル: 本人のみ読み書き可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // 家族グループ: メンバーのみアクセス可能
    match /groups/{groupId} {
      // メンバーかどうかを判定するヘルパー関数
      function isMember() {
        return request.auth != null &&
               exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid));
      }

      // グループ自体の読み取りはメンバーのみ
      allow read: if isMember();
      // グループ作成は認証済みユーザー全員
      allow create: if request.auth != null;
      // グループ更新はメンバーのみ
      allow update: if isMember();

      // メンバーサブコレクション
      match /members/{memberId} {
        allow read: if isMember();
        allow create: if isMember();
        // 削除・権限変更はオーナーまたは管理者のみ
        allow update, delete: if isMember() &&
          get(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)).data.role in ['owner', 'admin'];
      }

      // イベントサブコレクション
      match /events/{eventId} {
        allow read: if isMember();
        allow create, update: if isMember();
        // 削除は作成者またはオーナー/管理者のみ
        allow delete: if isMember() &&
          (get(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)).data.role in ['owner', 'admin'] ||
           resource.data.createdBy == request.auth.uid);
      }
    }
  }
}
```

3. **ルールの公開**
   - 「公開」ボタンをクリック
   - 確認ダイアログが表示されたら「公開」をクリック

4. **セキュリティルールの説明**
   - `users/{userId}`: ユーザープロファイルは本人のみアクセス可能
   - `groups/{groupId}`: 家族グループはメンバーのみアクセス可能
   - `groups/{groupId}/members/{memberId}`: メンバー情報の管理（権限ベース）
   - `groups/{groupId}/events/{eventId}`: イベント情報の管理（作成者・管理者のみ削除可能）

---

## 7. 動作確認

### ビルドと実行

1. **プロジェクトのビルド**
   ```bash
   cd /Users/shinya/workspace/claude/AsaApps/Apps/AsaFamilySync
   xcodegen generate
   xcodebuild -project AsaFamilySync.xcodeproj -scheme AsaFamilySync
   ```

2. **シミュレータで実行**
   - Xcodeでプロジェクトを開く
   - シミュレータ（iPhone 16等）を選択
   - ビルド&実行（⌘R）

3. **コンソールログ確認**
   - Xcodeのコンソールで以下のメッセージを確認:
     ```
     🔥 Firebase初期化完了
     🔥 Firebase モード: Firebaseサービスを使用します
     ```

### アプリでのテスト

1. **サインアップテスト**
   - アプリを起動
   - サインアップ画面でメールアドレス、パスワード、表示名を入力
   - 「アカウントを作成」ボタンをタップ

2. **Firebase Console確認**
   - Authentication → Users タブを開く
   - 作成したユーザーが表示されることを確認

3. **グループ作成テスト**
   - アプリで「グループを作成」を選択
   - グループ名を入力して作成

4. **Firestore確認**
   - Firestore Database → データ タブを開く
   - `groups/{groupId}` コレクションにグループが作成されていることを確認
   - `groups/{groupId}/members/{userId}` にメンバー情報があることを確認

---

## 8. トラブルシューティング

### よくあるエラーと解決策

#### エラー1: "Firebase not initialized"

**症状**: アプリ起動時にクラッシュ、または "Firebase app has not been configured" エラー

**原因**: GoogleService-Info.plistが正しく配置されていない

**解決策**:
1. GoogleService-Info.plistがプロジェクトルートに配置されていることを確認
2. ファイルがXcodeプロジェクトに追加されていることを確認
3. ビルド設定でコピーされていることを確認

#### エラー2: "Permission denied" エラー（Firestore）

**症状**: データ読み書き時に "permission-denied" エラー

**原因**: セキュリティルールが正しく設定されていない、またはユーザーが認証されていない

**解決策**:
1. セキュリティルールが正しく公開されていることを確認
2. ユーザーが正しくサインインしていることを確認
3. Firebase Consoleのルールエディタでシミュレーターを使ってテスト

#### エラー3: "Index required" エラー

**症状**: イベント取得時に "The query requires an index" エラー

**原因**: 複合クエリに必要なインデックスが作成されていない

**解決策**:
1. エラーメッセージに含まれるリンクをクリック
2. Firebase Consoleで自動的にインデックス作成画面が開く
3. 「インデックスを作成」ボタンをクリック
4. インデックス作成完了まで数分待つ

#### エラー4: GoogleService-Info.plistが変更される

**症状**: Gitで変更が検出される

**原因**: .gitignoreが正しく設定されていない

**解決策**:
1. `.gitignore`に以下を追加:
   ```
   **/GoogleService-Info.plist
   ```
2. すでにコミットされている場合は削除:
   ```bash
   git rm --cached Apps/AsaFamilySync/AsaFamilySync/GoogleService-Info.plist
   git commit -m "Remove GoogleService-Info.plist from version control"
   ```

#### エラー5: ビルドエラー "Missing package product 'FirebaseAuth'"

**症状**: ビルド時にFirebaseパッケージが見つからない

**原因**: XcodeGen後にパッケージがダウンロードされていない

**解決策**:
1. Xcodeでプロジェクトを開く
2. File → Packages → Resolve Package Versions
3. パッケージダウンロード完了を待つ
4. 再度ビルド

---

## 次のステップ

✅ Firebase手動セットアップ完了！

次は以下を実施してください:

1. **機能テスト**
   - サインアップ / サインイン
   - グループ作成 / 参加
   - イベント作成 / 編集 / 削除

2. **セキュリティ確認**
   - 認証なしでのアクセスが拒否されることを確認
   - 他のグループのデータにアクセスできないことを確認

3. **パフォーマンス確認**
   - オフライン時の動作確認（オフラインキャッシュ有効化済み）
   - 複数デバイスでの同期確認

---

## 参考リンク

- [Firebase iOS SDK ドキュメント](https://firebase.google.com/docs/ios/setup)
- [Cloud Firestore セキュリティルール](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Authentication ドキュメント](https://firebase.google.com/docs/auth)
