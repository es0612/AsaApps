# AsaBookTracker - サンプルデータ実装ノート

## 実装日
2025年10月6日

## 概要
AsaBookTrackerアプリの動作確認用に、10冊の多様なサンプル本データとその読書進捗・セッションデータを実装しました。

## 実装内容

### 1. サンプルデータヘルパークラスの作成

**ファイル**: [AsaBookTracker/PreviewData/SampleBookData.swift](../../Apps/AsaBookTracker/AsaBookTracker/PreviewData/SampleBookData.swift)

- 10冊の多様なジャンルの本データを生成
- 各本に適切な読書進捗状態（未読、読書中、完読、中断）を設定
- リアルな読書セッションデータを自動生成

### 2. サンプルデータの内訳

#### 完読本（4冊）
1. **リーダブルコード** (技術書/評価5)
   - 総ページ数: 260ページ
   - 読書期間: 15日間
   - 読書セッション数: 自動生成

2. **人を動かす** (ビジネス/評価4)
   - 総ページ数: 320ページ
   - 読書期間: 20日間

3. **ハリー・ポッターと賢者の石** (小説/評価5)
   - 総ページ数: 464ページ
   - 読書期間: 10日間

4. **スタンフォード式 最高の睡眠** (健康/評価4)
   - 総ページ数: 251ページ
   - 読書期間: 8日間

#### 読書中（3冊）
5. **1984年** (小説/進捗65%)
   - 現在ページ: 260/400ページ
   - 開始日: 10日前

6. **サピエンス全史** (歴史/進捗40%)
   - 現在ページ: 200/506ページ
   - 開始日: 20日前
   - 目標完了日: 30日後

7. **嫌われる勇気** (自己啓発/進捗30%)
   - 現在ページ: 90/296ページ
   - 開始日: 5日前

#### 未読（2冊）
8. **君たちはどう生きるか** (小説)
   - 総ページ数: 320ページ

9. **影響力の武器** (ビジネス)
   - 総ページ数: 490ページ

#### 中断（1冊）
10. **三体** (科学/進捗20%)
    - 現在ページ: 94/470ページ
    - 開始日: 45日前

### 3. 読書セッションデータの特徴

各本のステータスに応じて、異なる特性の読書セッションを生成：

- **完読本**: 定期的なセッション、高い集中度（3-5）、良好な気分
- **読書中**: 進行中の複数セッション、中〜高集中度
- **中断本**: 短時間セッション（15-30分）、低い集中度（2-3）、疲労気味の気分

### 4. ViewModelへの統合

**ファイル**: [BookTrackerViewModel.swift](../../Apps/AsaBookTracker/AsaBookTracker/ViewModels/BookTrackerViewModel.swift)

```swift
#if DEBUG
func loadSampleData() {
    guard let context = modelContext else { return }
    SampleBookData.loadSampleData(into: context)
    loadBooks()
}
#endif
```

デバッグビルド専用のサンプルデータ読込メソッドを追加。

### 5. SettingsViewへのUI追加

**ファイル**: [SettingsView.swift](../../Apps/AsaBookTracker/AsaBookTracker/Views/SettingsView.swift)

「データ管理」セクションに「サンプルデータ読込」ボタンを追加：
- デバッグビルドのみ表示（#if DEBUG）
- ワンタップで10冊のサンプルデータを登録
- 既存データをクリアしてから登録

### 6. プレビュー対応

**ファイル**: [ContentView.swift](../../Apps/AsaBookTracker/AsaBookTracker/ContentView.swift)

Xcodeプレビュー実行時に自動的にサンプルデータを読み込み：

```swift
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, ReadingProgress.self, ReadingSession.self, configurations: config)
    SampleBookData.loadSampleData(into: container.mainContext)
    return ContentView().modelContainer(container)
}
```

## 技術的ポイント

### SwiftDataの活用
- ModelContextを使用したデータ登録
- カスケード削除による関連データの自動削除
- inMemoryストレージによるプレビューデータ分離

### データ設計
- Book（本）とReadingProgress（進捗）の1対1関係
- Book（本）とReadingSession（セッション）の1対多関係
- リレーションシップの正しい設定

### デバッグ対応
- `#if DEBUG`によるデバッグビルド専用機能
- 本番ビルドには影響なし

## 使用方法

### アプリ内での使用
1. AsaBookTrackerアプリを起動
2. 設定タブに移動
3. 「データ管理」セクションの「サンプルデータ読込」ボタンをタップ
4. 10冊のサンプル本が自動的に登録される

### Xcodeプレビューでの使用
1. ContentView.swiftをXcodeで開く
2. プレビューを実行
3. サンプルデータが自動的に読み込まれる

## 動作確認

### ビルド
```bash
cd Apps/AsaBookTracker
xcodegen generate
xcodebuild -project AsaBookTracker.xcodeproj -scheme AsaBookTracker -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**結果**: ✅ BUILD SUCCEEDED

### 実行
```bash
xcrun simctl boot D86928B0-EE3E-4FCF-B080-94E7B1FF5067
xcrun simctl install D86928B0-EE3E-4FCF-B080-94E7B1FF5067 <app-path>
xcrun simctl launch D86928B0-EE3E-4FCF-B080-94E7B1FF5067 com.asapapa.apps.asabooktracker
```

**結果**: ✅ アプリ正常起動

## 今後の拡張可能性

1. **カスタマイズ可能なサンプルデータ**
   - ジャンル別のサンプルセット
   - ページ数別のサンプルセット
   - 読書速度別のセッションパターン

2. **エクスポート/インポート機能**
   - サンプルデータのJSON/CSV出力
   - 外部ファイルからのデータ読込

3. **パフォーマンステスト用データ**
   - 大量データ（100冊、1000冊）の生成
   - ストレステスト用シナリオ

## まとめ

AsaBookTrackerアプリの動作確認用に、リアルで多様なサンプルデータを実装しました。これにより、開発中のUI/UX確認やテストが容易になり、アプリの品質向上に貢献します。

### 主な成果
- ✅ 10冊の多様なジャンルのサンプル本
- ✅ リアルな読書進捗データ（4つのステータス）
- ✅ 自動生成される読書セッションデータ
- ✅ デバッグビルド専用の安全な実装
- ✅ Xcodeプレビュー対応
- ✅ ワンタップでのサンプルデータ登録

### ファイル変更一覧
1. 新規作成: `AsaBookTracker/PreviewData/SampleBookData.swift`
2. 更新: `BookTrackerViewModel.swift` - サンプルデータ読込メソッド追加
3. 更新: `SettingsView.swift` - デバッグボタン追加
4. 更新: `ContentView.swift` - プレビュー対応
