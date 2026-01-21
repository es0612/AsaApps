import Foundation
import RealityKit

// MARK: - TargetComponent
/// ターゲットエンティティに付与するComponent
/// Entity-Component-Systemパターンでターゲットの状態を管理
struct TargetComponent: Component {
    // MARK: - Properties

    /// ターゲットのID（Targetモデルとの紐付け用）
    let targetId: UUID

    /// ターゲットのサイズ
    let size: TargetSize

    /// 基本得点
    let points: Int

    /// ヒット済みかどうか
    var isHit: Bool = false

    // MARK: - Initialization

    init(targetId: UUID, size: TargetSize) {
        self.targetId = targetId
        self.size = size
        self.points = size.basePoints
    }

    /// Targetモデルから初期化
    init(from target: Target) {
        self.targetId = target.id
        self.size = target.size
        self.points = target.points
    }
}

