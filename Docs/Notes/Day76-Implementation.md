# Day 76 - AsaARGame（AR的当てゲーム）

## 概要

AR空間に出現するターゲットをタップして得点を稼ぐ60秒タイムアタック形式のゲームを実装しました。RealityKit 4とARKit 6を使用したモダンなAR実装です。

## 完成アプリの機能

### ゲームルール
- **制限時間**: 60秒
- **ターゲット出現間隔**: 1.5秒
- **ターゲット寿命**: 3秒（消えると得点機会を逃す）
- **コンボシステム**: 連続ヒットでボーナス（最大+25点）

### ターゲット種類と得点
| サイズ | 半径 | 基本得点 | 色 | 出現確率 |
|--------|------|----------|-----|---------|
| 大 | 0.08m | 10点 | CoffeeBrown | 50% |
| 中 | 0.05m | 25点 | Mocha | 35% |
| 小 | 0.03m | 50点 | Gold | 15% |

### 主要機能
1. **平面検出**: ARCoachingOverlayで直感的なガイド
2. **ターゲット出現**: ランダムな位置・サイズで出現
3. **タップヒット判定**: RealityKitのhitTestで正確な判定
4. **コンボボーナス**: 連続ヒットで+5点/回（最大+25点）
5. **視覚エフェクト**: 出現/消滅/ヒット時のアニメーション
6. **ハイスコア保存**: UserDefaultsで永続化

## 技術スタック

### フレームワーク
- **iOS 17.0+** / **Swift 5.9+**
- **RealityKit 4**: 3Dレンダリング・物理演算
- **ARKit 6**: AR基盤・平面検出
- **SwiftUI**: UI構築
- **AsaUIKit**: 共有UIコンポーネント

### アーキテクチャ
- **ECS (Entity-Component-System)**: RealityKitのモダンな設計パターン
- **MVVM**: @Observable + @MainActorでの状態管理
- **Sendable準拠**: Swift Concurrency対応

## ファイル構成

```
AsaARGame/
├── project.yml
├── AsaARGame/
│   ├── AsaARGameApp.swift          # アプリエントリポイント
│   ├── ContentView.swift           # メインUI統合
│   ├── Info.plist                  # ARKit権限設定
│   │
│   ├── Models/
│   │   ├── GameState.swift         # ゲーム状態列挙型
│   │   ├── Target.swift            # ターゲットモデル（Sendable）
│   │   └── GameScore.swift         # スコア管理（Codable, Sendable）
│   │
│   ├── ECS/
│   │   ├── Components/
│   │   │   ├── TargetComponent.swift    # ターゲット状態Component
│   │   │   └── LifespanComponent.swift  # 寿命管理Component
│   │   └── Systems/
│   │       ├── TargetSpawnSystem.swift  # ターゲット出現System
│   │       └── LifespanSystem.swift     # 寿命更新System
│   │
│   ├── ViewModels/
│   │   └── ARGameViewModel.swift   # @Observable @MainActor
│   │
│   ├── Views/
│   │   ├── ARViewContainer.swift   # UIViewRepresentable + Coordinator
│   │   ├── GameHUDView.swift       # スコア・タイマー・コンボ表示
│   │   ├── GameOverView.swift      # 結果表示・統計
│   │   ├── OnboardingView.swift    # チュートリアル
│   │   └── ARPlaneGuideView.swift  # 平面検出ガイド
│   │
│   └── Renderers/
│       └── TargetRenderer.swift    # 3Dターゲット生成
│
├── AsaARGameTests/                 # ユニットテスト
└── AsaARGameUITests/               # UIテスト
```

## 実装のポイント

### 1. ECSアーキテクチャの採用

RealityKitのEntity-Component-Systemパターンを活用：

```swift
// Component: データのみを持つ
struct TargetComponent: Component {
    let targetId: UUID
    let size: TargetSize
    let points: Int
    var isHit: Bool = false
}

// System: フレームごとの一括更新
class LifespanSystem: System {
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query) {
            // 寿命チェック・消滅処理
        }
    }
}
```

**利点**:
- パフォーマンス効率（一括処理）
- 関心の分離（データとロジックの分離）
- visionOS拡張への準備

### 2. @Observable + @MainActorパターン

モダンなSwiftUI状態管理：

```swift
@Observable @MainActor
final class ARGameViewModel {
    var gameState: GameState = .idle
    var score: GameScore = GameScore()

    func startGame() { /* ... */ }
    func handleTap(at: CGPoint) { /* ... */ }
}
```

**利点**:
- 自動的なUI更新
- メインスレッド安全性
- Sendable準拠との相性

### 3. コンボシステムの実装

プレイヤーのモチベーションを高めるコンボボーナス：

```swift
mutating func addHit(points: Int) {
    comboCount += 1
    maxCombo = max(maxCombo, comboCount)
    let totalPoints = points + min(comboCount * 5, 25) // 最大+25点
    currentScore += totalPoints
    targetsHit += 1
}

mutating func addMiss() {
    comboCount = 0  // コンボリセット
    targetsMissed += 1
}
```

### 4. 視覚的フィードバック

ターゲットの状態を視覚的に伝える：

```swift
// ホバーアニメーション（上下に浮遊）
func addHoverAnimation(to entity: Entity) {
    // 1秒周期で上下に0.02m浮遊
}

// ヒットエフェクト（放射状のパーティクル）
func createHitEffect(at position: SIMD3<Float>) {
    // 8方向に広がる金色のパーティクル
}

// 残り寿命の点滅（50%以下で点滅開始）
func updateVisualFeedback(entity: Entity, lifeRatio: Double) {
    // 残り寿命に応じて点滅頻度を調整
}
```

## 学習ポイント

### RealityKit ECS

1. **Component**: 状態データのみを持つ構造体
2. **Entity**: Componentの集合体
3. **System**: フレームごとにEntityを一括処理

従来の継承ベース設計と比べ、より柔軟で高パフォーマンスな設計が可能。

### ARKit + SwiftUI統合

`UIViewRepresentable`と`Coordinator`パターンでARViewをSwiftUIに統合：

```swift
struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView { /* ... */ }
    func makeCoordinator() -> Coordinator { /* ... */ }

    class Coordinator: NSObject, ARSessionDelegate {
        // タップ処理、セッションイベント
    }
}
```

### ヒット判定

RealityKitの`hitTest`でタップ位置から3Dオブジェクトを検出：

```swift
let results = arView.hitTest(location, query: .nearest, mask: .default)
for result in results {
    if let targetComponent = result.entity.components[TargetComponent.self] {
        // ヒット処理
    }
}
```

## テストカバレッジ

### ユニットテスト（Swift Testing）
- `GameScoreTests`: スコア計算、コンボボーナス、命中率
- `TargetTests`: 位置、サイズ、得点、期限切れ判定
- `ARGameViewModelTests`: 状態遷移、一時停止/再開
- `TargetComponentTests`: ECS Component動作
- `LifespanComponentTests`: 寿命計算

### 注意点
- ARKitは**実機でのみ**動作（シミュレータ非対応）
- 平面検出テストは実機必須

## 今後の拡張案

1. **難易度設定**: Easy/Normal/Hard
2. **サウンドエフェクト**: ヒット音、BGM
3. **パワーアップ**: 時間延長、スコア倍率
4. **リーダーボード**: Game Center連携
5. **visionOS対応**: 空間コンピューティング対応

## 参考資料

- [RealityKit Overview - Apple Developer](https://developer.apple.com/augmented-reality/realitykit/)
- [Understanding the modular architecture of RealityKit](https://developer.apple.com/documentation/visionos/understanding-the-realitykit-modular-architecture)
- [WWDC25 - What's new in RealityKit](https://developer.apple.com/videos/play/wwdc2025/287/)

## 使用コマンド

```bash
# プロジェクト生成
cd Apps/AsaARGame
xcodegen generate

# ビルド（シミュレータ）
xcodebuild -project AsaARGame.xcodeproj -scheme AsaARGame \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# テスト実行（シミュレータ）
xcodebuild test -project AsaARGame.xcodeproj -scheme AsaARGameTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# 実機ビルド（ARKit動作確認）
xcodebuild -project AsaARGame.xcodeproj -scheme AsaARGame \
  -destination 'generic/platform=iOS'
```
