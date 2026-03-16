# AsaBudgetAI サンプルデータ投入機能

## Context

AsaBudgetAIはデモ時にデータが空の状態で起動するため、ダッシュボード・分析・AI機能の魅力を見せることが難しい。設定画面からワンタップで3ヶ月分のリアルな家計データを投入できる機能を追加し、デモ体験を劇的に向上させる。

## 変更ファイル一覧

| ファイル | 変更種別 | 内容 |
|--------|---------|------|
| `Services/SampleDataGenerator.swift` | **新規** | サンプルデータ生成ロジック |
| `ViewModels/SettingsViewModel.swift` | 修正 | `insertSampleData()` メソッド追加（約5行） |
| `Views/Settings/SettingsView.swift` | 修正 | ボタン + confirmationDialog 追加（約25行） |

## 実装ステップ

### 1. `SampleDataGenerator.swift` を新規作成

`Apps/AsaBudgetAI/AsaBudgetAI/Services/SampleDataGenerator.swift`

- `@MainActor final class SampleDataGenerator` として DataService を依存注入
- `func insertSampleData()` で以下を一括生成:

**収入データ（3ヶ月 × 毎月25日）**:
- 給与 350,000円/月

**支出データ（合計 60〜80件）**:

| カテゴリ | 月次件数 | 金額範囲 | タイトル例 |
|---------|---------|---------|----------|
| 食費 | 8-10件 | 300-5,000 | スーパー, コンビニ, ランチ, カフェ |
| 交通費 | 3-4件 | 200-15,000 | 電車定期, バス, タクシー |
| 日用品 | 2-3件 | 500-3,000 | ドラッグストア, 100均 |
| 娯楽 | 2-3件 | 500-5,000 | 映画, 本, サブスク |
| 医療費 | 0-1件 | 1,000-5,000 | 病院, 薬局 |
| 教育 | 1-2件 | 1,000-15,000 | 参考書, オンライン講座 |
| 光熱費 | 3件 | 3,000-15,000 | 電気代, ガス代, 水道代 |
| 通信費 | 2件 | 3,000-10,000 | スマホ代, インターネット |
| 住居費 | 1件 | 80,000-100,000 | 家賃 |
| その他 | 1-2件 | 500-3,000 | 雑貨, プレゼント |

**異常データ（AI分析デモ用、3件）**:
- 記念日ディナー 25,000円（anomalyScore: 0.85）
- コート購入 45,000円（anomalyScore: 0.78）
- コンサートチケット 30,000円（anomalyScore: 0.72）

**予算データ（3ヶ月分）**:
- 当月: 200,000円（isActive = true）
- 前月/前々月: 各200,000円（isActive = false）
- 各TransactionにBudgetリレーションを設定

**設計ポイント**:
- カテゴリは `dataService.fetchCategories()` で既存のものを取得（新規生成しない）
- `DataService.addTransaction()` を直接使用（BudgetAIViewModel経由だとAI分析が走り低速）
- 金額に ±10% のランダム変動、日付は月内ランダム分散で自然なグラフ表示

### 2. `SettingsViewModel.swift` にメソッド追加

```swift
func insertSampleData() {
    isLoading = true
    let generator = SampleDataGenerator(dataService: dataService)
    generator.insertSampleData()
    categories = dataService.fetchCategories()
    isLoading = false
}
```

### 3. `SettingsView.swift` にUI追加

「データ」セクション（149行目）のエクスポートボタンと削除ボタンの間に配置:
- `@State private var showSampleDataConfirmation = false`
- サンプルデータ投入ボタン（アイコン: `tray.and.arrow.down.fill`）
- 確認ダイアログ（既存の `showResetConfirmation` と同じパターン）
- 投入後 `mainViewModel.refreshData()` でダッシュボード更新

## 検証方法

1. `cd Apps/AsaBudgetAI && xcodegen generate`
2. `xcodebuild -project AsaBudgetAI.xcodeproj -scheme AsaBudgetAI -sdk iphonesimulator build`
3. シミュレータで 設定 > データ > サンプルデータを投入 → 確認ダイアログ → 投入
4. ダッシュボード: 今月の支出/収入が表示される
5. 取引一覧: 3ヶ月分の取引が表示される
6. 分析: 月次トレンドグラフ、カテゴリ別円グラフが表示される
7. AI: 異常取引が3件検出される
