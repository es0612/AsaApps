# AsaCrowdsource

家族でアイデアを共有するクラウドソーシングアプリ

## 概要

AsaCrowdsourceは、家族やグループでアイデアを投稿・共有・投票できるアプリです。旅行の計画、週末の過ごし方、買い物リストなど、みんなのアイデアを集めて、最適な選択を見つけましょう。

## 機能

### 家族グループ管理
- グループの作成・参加（招待コード方式）
- メンバー管理（オーナー/メンバーロール）
- 複数グループへの参加対応

### アイデア管理
- アイデアの投稿（タイトル、説明、カテゴリ）
- ステータス管理（提案中→議論中→承認→実行→完了）
- カテゴリ別フィルタリング・検索

### 投票機能
- 3種類の投票（👍いいね、❤️大好き、🤔興味あり）
- 投票の重み付けスコア計算
- リアルタイム集計表示

### コメント機能
- コメントの投稿・削除
- 投稿日時の相対表示

## カテゴリ一覧

| カテゴリ | 絵文字 | 説明 |
|---------|--------|------|
| 家族旅行 | ✈️ | 旅行の計画やアイデア |
| 週末の過ごし方 | ☀️ | 週末のアクティビティ |
| 子育て | 👨‍👩‍👧 | 子育てに関するアイデア |
| 買い物 | 🛒 | 購入予定のもの |
| 住まい | 🏠 | 家の改善やDIY |
| 食事・レシピ | 🍽️ | 料理やレストラン |
| イベント | 📅 | 誕生日、記念日など |
| 健康・運動 | ❤️ | 健康やフィットネス |
| その他 | 💡 | その他のアイデア |

## 技術スタック

- **UI**: SwiftUI
- **状態管理**: @Observable (iOS 17+)
- **データ永続化**: SwiftData
- **リモート同期**: Firebase Firestore (準備済み)
- **認証**: Firebase Auth (準備済み)
- **共有UI**: AsaUIKit

## 画面構成

```
📱 AsaCrowdsource
├── 🔐 認証画面
│   ├── ログイン
│   └── サインアップ
├── 💡 アイデア一覧（メインタブ）
│   ├── 検索・フィルター
│   ├── アイデアカード
│   ├── 新規作成
│   └── 詳細表示
│       ├── 投票
│       └── コメント
├── 👨‍👩‍👧 グループ管理（タブ）
│   ├── ダッシュボード
│   ├── グループ作成
│   ├── グループ参加
│   └── 招待コード共有
└── ⚙️ 設定（タブ）
    ├── プロフィール
    ├── グループ設定
    └── ログアウト
```

## セットアップ

### 必要条件
- Xcode 15.0以上
- iOS 17.0以上
- XcodeGen

### ビルド手順

```bash
# プロジェクトディレクトリに移動
cd Apps/AsaCrowdsource

# XcodeGenでプロジェクト生成
xcodegen generate

# Xcodeで開く
open AsaCrowdsource.xcodeproj
```

### Firebase設定（オプション）

1. Firebase Consoleでプロジェクトを作成
2. `GoogleService-Info.plist`をダウンロード
3. プロジェクトに追加
4. `AsaCrowdsourceApp.swift`でFirebase初期化コードを有効化

## アーキテクチャ

```
AsaCrowdsource/
├── Models/           # データモデル（SwiftData @Model）
│   ├── Idea.swift
│   ├── Comment.swift
│   ├── Vote.swift
│   ├── LocalFamilyGroup.swift
│   └── LocalMember.swift
├── ViewModels/       # ビジネスロジック（@Observable）
│   ├── AuthViewModel.swift
│   ├── FamilyGroupViewModel.swift
│   ├── IdeaListViewModel.swift
│   ├── IdeaDetailViewModel.swift
│   └── CreateIdeaViewModel.swift
├── Views/            # UI（SwiftUI）
│   ├── Authentication/
│   ├── Family/
│   ├── Ideas/
│   ├── Comments/
│   ├── Voting/
│   └── Settings/
└── Services/         # データサービス
    ├── CrowdsourceDataService.swift  # プロトコル
    └── LocalDataService.swift        # SwiftData実装
```

## ブランドカラー

- **AsaCoffeeBrown** (#C68C53) - プライマリカラー
- **AsaMocha** (#8B5A2B) - セカンダリカラー
- **AsaSoftCream** (#E8D5B9) - ハイライト
- **AsaDarkSlate** (#2F3E46) - テキスト
- **AsaMutedSage** (#7A918D) - アクセント

## 今後の拡張予定

- [ ] Firebase Firestoreによるリアルタイム同期
- [ ] プッシュ通知（新しいアイデア、コメント通知）
- [ ] 画像添付機能
- [ ] タイムライン表示
- [ ] SharePlay対応（FaceTimeでブレインストーミング）

## ライセンス

このプロジェクトはAsaApps学習プロジェクトの一部です。

---

Created with ❤️ by 朝活パパエンジニア
