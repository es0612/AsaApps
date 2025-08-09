# AsaApps プロジェクト概要

## プロジェクトの目的
AsaAppsは「朝活パパエンジニア」によるSwiftUI学習プロジェクトで、1年間で100のSwiftUIアプリを作成することを目標としています。家族、生産性、朝活をテーマに、シンプルで温かみのあるデザイン原則に焦点を当てています。

## 技術スタック
- **言語**: Swift 6.1.2
- **フレームワーク**: SwiftUI
- **開発環境**: Xcode 16.4 (Build version 16F6)
- **プラットフォーム**: iOS/macOS
- **データ管理**: 
  - シンプルなアプリ: UserDefaults
  - 複雑なアプリ: Swift Data（@Observable使用）
- **テストフレームワーク**: Swift Testing（モダンな@Test構文使用）

## プロジェクト構造
```
AsaApps/
├── Apps/                    # 個別のSwiftUIアプリ（40+個実装済み）
├── Shared/                  # 共有UIコンポーネントとアセット
│   ├── AsaButton.swift     # 再利用可能なボタンコンポーネント
│   ├── AsaCard.swift       # カードラッパーコンポーネント
│   ├── AsaLaunchScreen.swift
│   └── Assets.xcassets/    # 共有デザインアセット（ブランドカラー）
├── Docs/                   # ドキュメントと学習ノート
│   ├── BrandGuidelines.md  # ブランドカラーとUIガイドライン
│   ├── Notes/              # 日次実装ノート
│   └── Screenshot/         # アプリデモ動画とスクリーンショット
├── Designs/                # デザインアセット（ロゴ、アイコン）
└── README.md              # 100アプリのアイデアを含むプロジェクトロードマップ
```

## 現在の進捗
- 実装済みアプリ: 40+個
- 初級（1-30）: 基本的なSwiftUIコンポーネント学習
- 中級（31-70）: Core Data、API、アニメーション、デバイス機能
- 上級（71-100）: 複雑なアーキテクチャ、クラウド同期、AI/ML（予定）

## 開発アプローチ
- モダンiOS開発プラクティスの採用
- @Observableパターンの活用
- Swift Dataによるデータ永続化
- Swift Testingによる単体テスト