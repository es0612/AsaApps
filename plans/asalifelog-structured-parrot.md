# AsaLifeLog SNSデモ動画用サンプルデータ充実化

## Context（背景）

AsaLifeLog（App #99）のSNSデモ動画を撮影するため、各画面が「映える」状態にする必要がある。

現状の `Apps/AsaLifeLog/Sources/Services/SampleDataLoader.swift` には以下の課題がある:

1. **データ量不足**: 投入されるのは「当日分の5エントリー＋1日次サマリー＋1場所ログ」のみ。Dashboard/Insights タブは過去2週間〜1ヶ月のチャート(`ChartPeriod`: week/month/threeMonths/year)・週次サマリー・トレンド比較を表示する設計のため、現状のデータでは全期間で**ほぼ空表示**になる。
2. **判定方式が UserDefaults フラグ**: `AsaLifeLog_SampleDataLoaded_v1` で初回判定。ストア削除/シミュレータリセット時に**フラグだけ残ってデータが消える**事故が発生する（プロジェクトメモリ `feedback_seed_data_pattern.md` に記録の既知パターン）。
3. **Widget用データが未投入**: `SharedDefaults.saveWidgetData()` が呼ばれず、Widget 5種は placeholder データを表示している（実データではない）。
4. **WeeklySummary が0件**: Insights タブの「週次トレンド」「前週比較」が常に空表示。

本作業ではこれら4つを一括で解決し、デモ動画撮影に十分な「現実感のあるサンプルデータ」を投入する。

## Goal（達成イメージ）

- 起動直後から、過去14日分の自然なライフログが入っており、全タブ・Widget・各 ChartPeriod が映える
- ストア再生成時も**同じデータが冪等に再投入**される
- 既存の挙動への影響なし（Widget配信用データ更新は副作用として追加）

## 修正方針

### 1. 判定方式を `fetch().isEmpty` に変更

UserDefaults フラグ廃止。`LifeLogEntry` を fetch して空ならば投入。AsaCrowdsource 改修（コミット 27ce846）と同じパターン。

### 2. 過去14日分のリアルなデータを投入

| モデル | 件数 | 内容 |
|---|---|---|
| `LifeLogEntry` | 約60〜80件 | 14日 × 1日4〜6件（朝活/気分/健康/位置/活動/手動メモを混ぜる） |
| `DailySummary` | 14件 | 各日のentryCount/moodAverage/totalSteps/sleepHoursを集約値で投入 |
| `WeeklySummary` | 2件 | 直近2週間（今週・先週）。trendInsight・前週比較テキスト付き |
| `PlaceLog` | 5〜6件 | 自宅/職場/カフェ/公園/ジム/駅 各カテゴリを1件ずつ。visitCount は現実的な値 |
| `UserPreferences` | 1件 | 既存と同等 |

### 3. Widget データ書き出しを追加

投入直後に「今日分」を集約して `LifeLogWidgetData` を組み立て、`SharedDefaults.saveWidgetData(_:)` で永続化。Widget が起動時から実データを表示する。

### 4. データのリアリティ

- 朝活時間帯（5〜7時台）にエントリーが集中
- moodScore は `.good` / `.great` を基本に、平日中盤に `.neutral` を混ぜる
- totalSteps は 6,000〜12,000 のレンジでばらつき
- sleepHours は 6.5〜8.0 のレンジ
- タグ: `["朝活","運動","読書","家族","学習","食事"]` から自然に組み合わせ
- 場所カテゴリ: 自宅・職場・公園・カフェ・ジムを偏りなく
- aiInsightText / aiSummary を一部に挿入（デモで「AIインサイト」感を出す）

## 修正対象ファイル

| ファイル | 変更内容 |
|---|---|
| `Apps/AsaLifeLog/Sources/Services/SampleDataLoader.swift` | 全面書き換え。判定を isEmpty に変更し、14日分のジェネレータ関数群を追加。Widget保存も実施 |
| `Apps/AsaLifeLog/Sources/ContentView.swift` | 呼び出しはそのまま（`SampleDataLoader.loadIfNeeded(into:)` のシグネチャ維持） |

新規ファイル作成は**しない**（既存`SampleDataLoader.swift`内に`private static func generate*`関数群を追加するだけ）。

## 重要な実装メモ

- `SampleDataLoader` は既に `@MainActor struct`。これを維持。
- `loadIfNeeded(into:)` のシグネチャは変更しない（呼び出し側を触らないため）。
- 投入対象モデル `LifeLogEntry / DailySummary / WeeklySummary / PlaceLog / UserPreferences` のうち、**いずれか1つでも空なら全件投入**ではなく、**`LifeLogEntry` のみで判定**して全モデル投入する（部分破損を避けるシンプル戦略）。
- Widget データ書き出しは `SharedDefaults.saveWidgetData(buildWidgetData(...))` を投入末尾で呼ぶ。`LifeLogWidgetData.placeholder` の構造を参考に、当日エントリー上位3件を `WidgetEntry` に変換。
- 日付計算は `Calendar.current` + `date(byAdding:)`。既存実装と同じスタイル。
- enum値は確認済み: `EntryType.{manual,health,location,photo,activity,mood}` / `MoodScore.{terrible,bad,neutral,good,great}` / `ActivityType.{stationary,walking,running,cycling,driving}` / `PlaceCategory.{home,work,restaurant,shop,park,gym,other}` / `DataSource.{manual,healthKit,coreLocation,photoLibrary,coreMotion}`。

## 既存の再利用可能な実装

- `LifeLogEntry.init` (Packages/AsaLifeLogKit/Sources/AsaLifeLogKit/Models/LifeLogEntry.swift:67-106) — 全プロパティ対応の名前付き引数イニシャライザ
- `DailySummary.init` (Packages/AsaLifeLogKit/Sources/AsaLifeLogKit/Models/DailySummary.swift:48-75)
- `WeeklySummary.init` (Packages/AsaLifeLogKit/Sources/AsaLifeLogKit/Models/WeeklySummary.swift:24-45)
- `PlaceLog.init` (Packages/AsaLifeLogKit/Sources/AsaLifeLogKit/Models/PlaceLog.swift:32-53)
- `SharedDefaults.saveWidgetData(_:)` (Apps/AsaLifeLog/Shared/SharedDefaults.swift:22-27)
- `LifeLogWidgetData.placeholder` (Apps/AsaLifeLog/Shared/LifeLogWidgetData.swift:36-48) — Widget用構造の参考

## 検証手順

1. **ストアリセット**: `xcrun simctl erase all` または該当シミュレータの「コンテンツと設定をリセット」で SwiftData のストアを削除
2. **再ビルド・起動**:
   ```bash
   cd Apps/AsaLifeLog
   xcodegen generate -s project.yml
   xcodebuild -project AsaLifeLog.xcodeproj -scheme AsaLifeLog \
     -sdk iphonesimulator \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
   ```
3. **タブ確認**:
   - Timeline: 過去14日のエントリーが時系列で並ぶ
   - Dashboard: ChartPeriod=週/月でチャートに山が出る、朝活スコアが0以外
   - Insights: 週次トレンド・前週比較テキストが表示される
   - Settings → 場所ログ: 5〜6件の場所が異なるカテゴリで並ぶ
4. **Widget確認**: ホーム画面に Small / Medium / Large Widget を追加し、placeholder ではなく実データが表示されるか
5. **冪等性確認**: アプリを起動→終了後、再起動してデータが二重投入されていないこと（`fetch().isEmpty` 判定が効いている）
6. **ストア削除後の再投入確認**: シミュレータの該当アプリを削除→再インストールで、再びサンプルデータが入ること（フラグ依存ではないので必ず投入される）

## デモ撮影推奨フロー

1. **起動画面**（タイムライン） — 朝活エントリーが目に入る
2. **タイムラインスクロール** — 過去2週間の自然なログ
3. **エントリー詳細タップ** — タグ・気分・位置情報の表示
4. **ダッシュボードタブ** — 朝活スコア・週/月チャートが映える
5. **インサイトタブ** — AIインサイト・週次トレンドの提示
6. **設定タブ → 場所ログ** — カテゴリ別の場所一覧
7. **ホーム画面に戻る → Widget表示** — 実データを反映したWidget

## 補足: 影響範囲

- 既存の本番ユーザー体験への影響: なし（初回 isEmpty 時のみ投入）
- 既存 UserDefaults フラグ `AsaLifeLog_SampleDataLoaded_v1` は不要になるので未使用フラグとして残す（既存ストア互換性のため `removeObject(forKey:)` は不要、無視されるだけ）
- ビルド設定 / project.yml / Widget Extension の Info.plist 等への変更なし
