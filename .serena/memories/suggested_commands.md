# 推奨開発コマンド

## プロジェクトナビゲーション

### 特定のアプリを開く
```bash
cd Apps/[AppName]
open [AppName].xcodeproj
```

例：
```bash
cd Apps/AsaCounter
open AsaCounter.xcodeproj
```

## ビルドとテスト

### コマンドラインビルド
```bash
# プロジェクトをビルド
xcodebuild -project [AppName].xcodeproj -scheme [AppName] build

# シミュレータでビルド・実行
xcodebuild -project [AppName].xcodeproj -scheme [AppName] -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 15" build
```

### テスト実行
```bash
# 単体テスト実行
xcodebuild test -project [AppName].xcodeproj -scheme [AppName] -destination "platform=iOS Simulator,name=iPhone 15"

# 特定のテストクラス実行
xcodebuild test -project [AppName].xcodeproj -scheme [AppName] -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:[AppName]Tests/[TestClass]
```

## 開発環境確認

### システム情報
```bash
# Xcode バージョン確認
xcodebuild -version

# Swift バージョン確認
swift --version

# インストール済みシミュレータ一覧
xcrun simctl list devices
```

## ファイル・ディレクトリ操作（macOS）

### 基本コマンド
```bash
# ファイル一覧
ls -la

# ディレクトリ移動
cd [path]

# ファイル検索
find . -name "*.swift" -type f

# 内容検索（ripgrepがインストール済みの場合）
rg "pattern" --type swift

# ファイルコピー
cp source destination

# ディレクトリ作成
mkdir -p path/to/directory
```

## Git操作

### 基本的なGit操作
```bash
# 状態確認
git status

# 変更をステージ
git add .

# コミット
git commit -m "commit message"

# プッシュ
git push origin main

# ログ確認
git log --oneline -10
```

## プロジェクト固有の操作

### 新しいアプリの追加
1. `Apps/`に新しいディレクトリを作成
2. Xcodeで新しいプロジェクトを作成
3. 共有コンポーネント（AsaButton, AsaCard）を活用
4. ブランドカラーを適用

### 共有アセットの使用
- `Shared/`ディレクトリの共有コンポーネントをインポート
- `Color("AsaCoffeeBrown")`でブランドカラーを使用
- 一貫したUIのために`AsaButton`と`AsaCard`を活用