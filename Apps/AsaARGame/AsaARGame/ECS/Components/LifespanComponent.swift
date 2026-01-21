import Foundation
import RealityKit

// MARK: - LifespanComponent
/// エンティティの寿命を管理するComponent
/// Entity-Component-Systemパターンで自動消滅を実現
struct LifespanComponent: Component {
    // MARK: - Properties

    /// 生成時刻（TimeInterval）
    let createdAt: TimeInterval

    /// 寿命（秒）
    let lifespan: TimeInterval

    /// 消滅開始フラグ（フェードアウト中かどうか）
    var isDisappearing: Bool = false

    // MARK: - Computed Properties

    /// 期限切れかどうか
    func isExpired(currentTime: TimeInterval) -> Bool {
        currentTime - createdAt >= lifespan
    }

    /// 残り寿命の割合（0.0〜1.0）
    func remainingLifeRatio(currentTime: TimeInterval) -> Double {
        let elapsed = currentTime - createdAt
        let remaining = max(0, lifespan - elapsed)
        return remaining / lifespan
    }

    /// 残り時間（秒）
    func remainingTime(currentTime: TimeInterval) -> TimeInterval {
        max(0, lifespan - (currentTime - createdAt))
    }

    // MARK: - Initialization

    init(
        createdAt: TimeInterval = Date().timeIntervalSince1970,
        lifespan: TimeInterval = 3.0
    ) {
        self.createdAt = createdAt
        self.lifespan = lifespan
    }

    /// Targetモデルから初期化
    init(from target: Target) {
        self.createdAt = target.createdAt
        self.lifespan = target.lifespan
    }
}

