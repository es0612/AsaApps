# AsaSmartHome (App #87) SNSデモ動画準備プラン

## Context

AsaSmartHome（スマートホームコントロール）をSNSデモ動画撮影可能な状態にする。
アプリは完全なシミュレーターベースで外部依存なし。サンプルデータ（6部屋、13デバイス、7シーン）は初回起動時に自動生成される。

## 発見した問題点

### 問題: デバイス詳細画面のコントロールが全て表示されない（重要度: 致命的）

- `DeviceDetailView.swift:141-146` の `getService()` が常に `nil` を返す
- `controlViewModel` が生成されず、照明スライダー/エアコン温度/カーテン開度など**全デバイスコントロールが非表示**
- デバイスカードをタップしてもヘッダー（アイコンと名前）しか表示されない
- ダッシュボード・部屋詳細の両方から遷移する全てのDeviceDetailViewが影響を受ける

**原因**: `SmartHomeViewModel` が `service` を `private` で保持しており、DeviceDetailView からアクセスする手段がない

## 修正計画（2ファイル、約5行の変更）

### Step 1: SmartHomeViewModel.swift にサービスアクセサ追加

`SmartHomeViewModel` に `service` への公開アクセサを追加:
```swift
var smartHomeService: SmartHomeServiceProtocol { service }
```

### Step 2: DeviceDetailView.swift の getService() を修正

`getService()` が `viewModel.smartHomeService` を返すように修正

### Step 3: ビルド検証

## 影響範囲

- ダッシュボード → デバイスタップ → 詳細画面のコントロール表示が修正される
- 部屋詳細 → デバイスタップ → 同上
- 8種類全てのデバイスコントロール（照明/エアコン/テレビ/スピーカー/ロック/カメラ/サーモスタット/カーテン）が操作可能になる

## 検証方法

- シミュレータでアプリ起動
- ダッシュボードからデバイスカードをタップし、コントロールが表示されることを確認
- 照明の明るさスライダー、エアコンの温度操作など動作確認
