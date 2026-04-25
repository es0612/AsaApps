# AsaVRDiary 画面黒帯問題の修正計画

## Context（なぜこの変更が必要か）

ユーザーから「AsaVRDiary がシミュレータで起動した際、画面が全画面表示にならず上下に黒帯が出る」という報告とスクリーンショットを受け取った。スクリーンショット（`image-1`）では:

- 上部の時計 (16:21) より下のコンテンツ領域が iPhone 4/5 サイズに縮小
- 下部にも黒い余白
- 結果として「日記」リスト・タブバー・カード型 UI が中央の小さなパネルに押し込まれて表示

これは iOS のいわゆる **互換モード起動**（Launch Screen が見つからないと、フレームワークが古い iPhone サイズの safe area を仮定する）の典型症状である。

加えて「このアプリはシミュレータでも動くか」という質問もあった。これは「VR」という名前から AR/VR ハードウェアを要求するか不安に感じたため。

### 根本原因（Root Cause）

`Apps/AsaVRDiary/project.yml` (行31-35) が以下のように設定されている:

```yaml
GENERATE_INFOPLIST_FILE: NO
INFOPLIST_FILE: AsaVRDiary/Info.plist
INFOPLIST_KEY_UILaunchScreen_Generation: true
```

ところが `GENERATE_INFOPLIST_FILE: NO` の場合、`INFOPLIST_KEY_*` 系の設定は **完全に無視され**、`INFOPLIST_FILE` で指定された手動管理の Info.plist が唯一の真実となる。そして該当の `Apps/AsaVRDiary/AsaVRDiary/Info.plist` には `UILaunchScreen` キーが一切存在しない（`NSCameraUsageDescription` のみ）。

→ Launch Screen 設定が事実上欠落 → iOS が互換モード起動 → 黒帯発生。

これは `CLAUDE.md` の「エラーパターン #3: Info.plist / UILaunchScreen 未設定」そのもの。AsaVRDiary はリポジトリ内で **唯一手動 Info.plist を持つアプリ** なので、自動生成に頼っている他アプリでは発生していない。

### シミュレータ動作可否の結論

- `ARKit` は import されていない（grep で 0 件）
- `RealityView` も `ARWorldTrackingConfiguration` も使っていない
- `Apps/AsaVRDiary/AsaVRDiary/Views/VR/VRDiaryView.swift:215` で `arView.cameraMode = .nonAR` を明示しており、実カメラ・ジャイロ・LiDAR を一切要求しない

→ **iOS Simulator (iPhone 17 Pro 等) で問題なくフル動作する**。修正後は「黒帯」だけが消えて、3D カード VR 空間も問題なく描画されるはず。

## 修正方針（推奨アプローチ）

**手動管理の Info.plist に `UILaunchScreen` ディクショナリを 1 ブロック追加するだけ** の最小変更で解決する。

理由:
1. 既存の `NSCameraUsageDescription` は将来の AR モード拡張に向けた予約として残しておきたい（消すと、後で再設定が必要）
2. `GENERATE_INFOPLIST_FILE: true` に切り替える方法もあるが、手動 Info.plist を捨てる必要があり変更範囲が広がる
3. 他アプリと「方式」は揃わないが、AsaVRDiary だけ手動管理にしている既存ポリシーを尊重する

## 変更対象ファイル

### `Apps/AsaVRDiary/AsaVRDiary/Info.plist`

`</dict>` の直前（`NSCameraUsageDescription` の後）に以下を追加:

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string></string>
    <key>UIImageName</key>
    <string></string>
</dict>
```

空ディクショナリでも構わないが、`UILaunchScreen` キー自体が存在することが必須。これだけで iOS は「明示的に空の Launch Screen を持つ」と認識し、互換モードを抜ける。

> 補足: 共通ブランディングの `AsaLaunchScreen` (Packages/AsaUIKit) を Launch Screen に表示したい場合は、別途 LaunchScreen.storyboard を組むか `UILaunchScreen` 内で `UIImageName` に Asset 名を指定する必要があるが、まずは黒帯を消す目的なら空 dict で十分。

## 検証手順（実装後の確認方法）

1. **プロジェクト再生成**
   ```bash
   cd Apps/AsaVRDiary
   xcodegen generate
   ```
   project.yml は変更しないので生成内容は変わらないが、念のため再生成しておく。

2. **シミュレータ向けビルド**
   ```bash
   xcodebuild -project AsaVRDiary.xcodeproj -scheme AsaVRDiary \
     -sdk iphonesimulator \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
     build
   ```
   エラー 0 件であることを確認。

3. **シミュレータ起動 & 画面確認**
   - iPhone 17 Pro シミュレータで起動
   - **黒帯が消えて画面全体に UI が広がっている** こと
   - 「日記」タブで日記カードが画面幅いっぱいに表示
   - 「VR 空間」タブに切り替え → RealityKit の 3D ビューが描画される（黒/グレー背景の中に 3D カードが浮かぶ）
   - 「統計」タブに切り替え → Charts が描画される

4. **スクリーンショット比較**
   - 修正前: `image-1` のように iPhone 4/5 サイズに縮小されて黒帯
   - 修正後: 画面全幅・全高に UI が広がる

## 関連メモ・既存資産

- `CLAUDE.md` 「エラーパターン #3」: 今回の根本原因をまさに記述している箇所。今後手動 Info.plist を作る際の参照に
- `Packages/AsaUIKit/Sources/AsaUIKit/AsaLaunchScreen.swift`: 必要なら本格的な LaunchScreen を組む際の流用元
- `Apps/AsaLifeLog/project.yml`, `Apps/AsaFamilyTree/project.yml`: `GENERATE_INFOPLIST_FILE: true` の標準パターン参照例

## やらないこと（スコープ外）

- `GENERATE_INFOPLIST_FILE` を `true` に切り替えて Info.plist を捨てる、というリファクタは行わない（既存予約 `NSCameraUsageDescription` を尊重するため）
- `deploymentTarget` の iOS 17 → 18 への引き上げは行わない（このアプリで使っている API は iOS 17 で十分）
- LaunchScreen のブランディング（Asa ロゴ表示）は別タスクとして扱う
