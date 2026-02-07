# AsaVRDiary 実装計画

## 概要

**AsaVRDiary**（アプリ #92）は、VR/AR空間で日記を振り返るSwiftUIアプリです。RealityKitを活用して日記エントリーを3Dオブジェクトとして表示し、感情に応じた視覚エフェクトで思い出を立体的に体験できます。

---

## 技術スタック

| 技術 | バージョン | 用途 |
|------|-----------|------|
| SwiftUI | iOS 17+ | UI構築 |
| RealityKit | iOS 17+ | 3D/VR描画（RealityView使用） |
| ARKit | iOS 17+ | AR機能（拡張用） |
| Swift Data | iOS 17+ | データ永続化 |
| Swift Testing | iOS 17+ | テストフレームワーク |
| AsaUIKit | - | 共有UIコンポーネント |

---

## 機能一覧

### P0: 必須機能（MVP）
- 日記エントリーCRUD（タイトル、本文、日付、カテゴリ、気分）
- 日記一覧表示（時系列）
- RealityViewで日記を3Dカードとして配置
- 基本ジェスチャー（タップ選択、ピンチズーム）

### P1: 重要機能
- 感情に応じた視覚効果（色、発光、パーティクル）
- タイムライン表示（時間軸に沿った3D配置）
- 検索・フィルタリング
- 統計ダッシュボード

### P2: 拡張機能
- 写真添付
- ARモード（実空間配置）
- visionOS対応準備

---

## ディレクトリ構造

```
Apps/AsaVRDiary/
├── project.yml
├── AsaVRDiary/
│   ├── AsaVRDiaryApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── DiaryEntry.swift          # @Model
│   │   ├── DiaryCategory.swift       # enum
│   │   ├── DiaryMood.swift           # enum + VRエフェクト
│   │   └── DiaryStats.swift
│   ├── ViewModels/
│   │   ├── DiaryViewModel.swift      # @Observable @MainActor
│   │   ├── VRSceneViewModel.swift    # VR状態管理
│   │   └── StatsViewModel.swift
│   ├── Services/
│   │   ├── DiaryDataService.swift    # Swift Data永続化
│   │   ├── VRSceneService.swift      # 3Dシーン構築
│   │   └── DiaryEntityRenderer.swift # 日記3Dエンティティ生成
│   ├── Views/
│   │   ├── Diary/                    # 日記CRUD画面
│   │   ├── VR/                       # VR空間表示
│   │   ├── Stats/                    # 統計画面
│   │   └── Components/               # 共通コンポーネント
│   └── Extensions/
├── AsaVRDiaryTests/                  # Unit Tests
└── AsaVRDiaryUITests/                # UI Tests
```

---

## データモデル

### DiaryEntry (@Model)

```swift
@Model
final class DiaryEntry {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    // カテゴリ・感情
    var categoryRawValue: String
    var moodRawValue: String
    var moodIntensity: Int  // 1-5

    // VR表示用座標
    var vrPositionX: Float?
    var vrPositionY: Float?
    var vrPositionZ: Float?
}
```

### DiaryMood (enum)

10種類の感情（veryHappy, happy, neutral, sad, verySad, excited, calm, anxious, grateful, tired）それぞれにVRエフェクト（glow, particles, pulse, shimmer）を対応付け。

---

## VR実装アプローチ

### RealityView統合（iOS 17+）

```swift
RealityView { content in
    // 日記エントリーを3Dカードとして配置
    for entry in entries {
        let entity = DiaryEntityRenderer.createDiaryEntity(for: entry)
        entity.position = calculateTimelinePosition(for: entry)
        content.add(entity)
    }
}
.gesture(TapGesture().targetedToAnyEntity())
.gesture(MagnifyGesture().targetedToAnyEntity())
```

### DiaryEntityRenderer（AsaARCard参考）

- `MeshResource.generateBox()` で3Dカードメッシュ生成
- CoreGraphicsで日記内容をテクスチャとして描画
- `SimpleMaterial` で感情に応じた色・質感設定
- `CardFlipComponent` でフリップアニメーション管理

### タイムライン配置

- X軸: 日付（1日 = 0.3m間隔）
- Y軸: 感情強度（強いほど高い位置）
- Z軸: カテゴリ（奥行きで分類）

---

## 画面フロー

```
ContentView (TabView)
├── Tab 1: DiaryListView → DiaryDetailView → EditDiaryView
├── Tab 2: VRDiaryView (RealityView + 操作パネル)
└── Tab 3: StatsView (Charts統合)
```

---

## テスト戦略

| 層 | テスト数目標 | 内容 |
|----|------------|------|
| Models | 20 | DiaryEntry初期化、Computed Properties |
| ViewModels | 30 | CRUD、フィルタ、シーン構築 |
| Services | 20 | 永続化、エンティティ生成 |
| Integration | 10 | 作成→VR表示フロー |
| **合計** | **80+** | **カバレッジ95%目標** |

---

## 実装フェーズ

### Phase 1: 基盤構築（2-3日）
- プロジェクト作成（XcodeGen）
- Swift Dataモデル実装
- DiaryDataService実装

### Phase 2: 日記UI実装（2-3日）
- DiaryViewModel実装
- 日記一覧・詳細・追加・編集画面

### Phase 3: VR機能実装（3-4日）
- VRSceneViewModel実装
- DiaryEntityRenderer実装（AsaARCard参考）
- RealityView統合

### Phase 4: 感情エフェクト（1-2日）
- 感情に応じた色・マテリアル
- アニメーション実装

### Phase 5: 統計機能（1-2日）
- StatsViewModel実装
- Charts統合

### Phase 6: 仕上げ（1-2日）
- テストカバレッジ確認
- ドキュメント作成

**総所要時間: 10-16日**

---

## 重要な参考ファイル

- `Apps/AsaARCard/AsaARCard/ARCardRenderer.swift` - RealityKit 3Dエンティティ生成
- `Apps/AsaARCard/project.yml` - XcodeGen設定
- `Apps/AsaSmartTodo/AsaSmartTodo/Services/DataService.swift` - Swift Data永続化
- `Packages/AsaUIKit/Sources/AsaUIKit/Colors/AsaColors.swift` - ブランドカラー

---

## 検証方法

1. **ビルド確認**: `xcodegen generate && xcodebuild -scheme AsaVRDiary`
2. **テスト実行**: `swift test`
3. **シミュレータ動作確認**:
   - 日記CRUD操作
   - VR空間での3Dカード表示
   - ジェスチャー操作（タップ、ピンチ）
   - 感情エフェクトの視覚確認

---

## visionOS対応への配慮

- RealityView使用（visionOSネイティブ）
- UIViewRepresentable回避
- ジェスチャー抽象化
- 座標系統一
