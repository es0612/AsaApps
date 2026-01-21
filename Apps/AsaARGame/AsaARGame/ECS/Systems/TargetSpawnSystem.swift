import Foundation
import RealityKit

// MARK: - TargetSpawnSystem
/// ターゲット出現管理System
/// 一定間隔でターゲットを生成し、シーンに追加
final class TargetSpawnSystem {
    // MARK: - Properties

    /// 出現間隔（秒）
    var spawnInterval: TimeInterval = 1.5

    /// 最後の出現時刻
    private var lastSpawnTime: TimeInterval = 0

    /// 出現範囲の中心座標
    var spawnCenter: SIMD3<Float> = SIMD3<Float>(0, 0, -1.0)

    /// 出現範囲の半径（水平方向）
    var spawnRadius: Float = 0.5

    /// 最小高さ
    var minHeight: Float = 0.1

    /// 最大高さ
    var maxHeight: Float = 0.5

    /// アクティブなターゲット数の上限
    var maxActiveTargets: Int = 5

    /// 現在のアクティブターゲット数
    private(set) var activeTargetCount: Int = 0

    /// ターゲット生成時のコールバック
    var onTargetSpawned: ((Target, Entity) -> Void)?

    /// ターゲットレンダラー参照
    weak var targetRenderer: TargetRenderer?

    /// 親アンカー
    weak var parentAnchor: AnchorEntity?

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// 更新処理（毎フレーム呼ばれる）
    func update(currentTime: TimeInterval, isGameActive: Bool) {
        guard isGameActive else { return }
        guard activeTargetCount < maxActiveTargets else { return }

        // 出現間隔チェック
        if currentTime - lastSpawnTime >= spawnInterval {
            spawnTarget()
            lastSpawnTime = currentTime
        }
    }

    /// 手動でターゲットを生成
    @discardableResult
    func spawnTarget() -> (Target, Entity)? {
        guard let renderer = targetRenderer, let anchor = parentAnchor else {
            return nil
        }

        // ターゲットデータを生成
        let target = Target.createRandom(
            centerX: spawnCenter.x,
            centerZ: spawnCenter.z,
            radius: spawnRadius,
            minY: minHeight,
            maxY: maxHeight
        )

        // 3Dエンティティを生成
        let entity = renderer.createTargetEntity(target: target)

        // シーンに追加
        anchor.addChild(entity)

        // 出現アニメーション
        performSpawnAnimation(entity: entity)

        // カウントを増加
        activeTargetCount += 1

        // コールバック通知
        onTargetSpawned?(target, entity)

        return (target, entity)
    }

    /// ターゲット削除時に呼ぶ（カウント減少）
    func onTargetRemoved() {
        activeTargetCount = max(0, activeTargetCount - 1)
    }

    /// リセット
    func reset() {
        lastSpawnTime = 0
        activeTargetCount = 0
    }

    // MARK: - Private Methods

    /// 出現アニメーション
    private func performSpawnAnimation(entity: Entity) {
        // 初期スケールを0に設定
        let originalScale = entity.transform.scale
        entity.transform.scale = .zero

        // 元のスケールにアニメーション
        var targetTransform = entity.transform
        targetTransform.scale = originalScale

        entity.move(
            to: targetTransform,
            relativeTo: entity.parent,
            duration: 0.2,
            timingFunction: .easeOut
        )
    }
}

// MARK: - TargetSpawnSystem Configuration
extension TargetSpawnSystem {
    /// 難易度設定
    struct Difficulty {
        let spawnInterval: TimeInterval
        let maxActiveTargets: Int
        let spawnRadius: Float
        let heightRange: ClosedRange<Float>

        static let easy = Difficulty(
            spawnInterval: 2.0,
            maxActiveTargets: 3,
            spawnRadius: 0.4,
            heightRange: 0.1...0.4
        )

        static let normal = Difficulty(
            spawnInterval: 1.5,
            maxActiveTargets: 5,
            spawnRadius: 0.5,
            heightRange: 0.1...0.5
        )

        static let hard = Difficulty(
            spawnInterval: 1.0,
            maxActiveTargets: 7,
            spawnRadius: 0.6,
            heightRange: 0.1...0.6
        )
    }

    /// 難易度を適用
    func applyDifficulty(_ difficulty: Difficulty) {
        spawnInterval = difficulty.spawnInterval
        maxActiveTargets = difficulty.maxActiveTargets
        spawnRadius = difficulty.spawnRadius
        minHeight = difficulty.heightRange.lowerBound
        maxHeight = difficulty.heightRange.upperBound
    }
}
