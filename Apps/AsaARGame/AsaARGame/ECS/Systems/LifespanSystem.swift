import Foundation
import RealityKit

// MARK: - LifespanSystem
/// 寿命管理System - フレームごとにエンティティの寿命をチェック
/// Entity-Component-Systemパターンで効率的な一括更新を実現
final class LifespanSystem: System {
    // MARK: - Query

    /// LifespanComponentを持つエンティティを検索するクエリ
    static let query = EntityQuery(where: .has(LifespanComponent.self))

    // MARK: - Properties

    /// 期限切れエンティティを通知するコールバック
    var onEntityExpired: ((Entity, UUID?) -> Void)?

    // MARK: - Initialization

    required init(scene: Scene) {
        // シーン初期化時の設定があればここに記述
    }

    // MARK: - System Update

    /// フレームごとに呼ばれる更新処理
    func update(context: SceneUpdateContext) {
        let currentTime = Date().timeIntervalSince1970

        // LifespanComponentを持つ全エンティティを処理
        context.scene.performQuery(Self.query).forEach { entity in
            guard var lifespanComponent = entity.components[LifespanComponent.self] else {
                return
            }

            // 期限切れチェック
            if lifespanComponent.isExpired(currentTime: currentTime) {
                // まだ消滅処理を開始していない場合
                if !lifespanComponent.isDisappearing {
                    lifespanComponent.isDisappearing = true
                    entity.components[LifespanComponent.self] = lifespanComponent

                    // ターゲットIDを取得（あれば）
                    let targetId = entity.components[TargetComponent.self]?.targetId

                    // コールバックで通知
                    onEntityExpired?(entity, targetId)

                    // フェードアウトアニメーション後に削除
                    performDisappearAnimation(entity: entity)
                }
            } else {
                // 残り寿命に応じた視覚的フィードバック（点滅など）
                let ratio = lifespanComponent.remainingLifeRatio(currentTime: currentTime)
                updateVisualFeedback(entity: entity, lifeRatio: ratio)
            }
        }
    }

    // MARK: - Private Methods

    /// 消滅アニメーションを実行
    private func performDisappearAnimation(entity: Entity) {
        // スケールを縮小しながらフェードアウト
        var transform = entity.transform
        transform.scale = .zero

        entity.move(
            to: transform,
            relativeTo: entity.parent,
            duration: 0.3,
            timingFunction: .easeIn
        )

        // アニメーション完了後に削除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            entity.removeFromParent()
        }
    }

    /// 残り寿命に応じた視覚的フィードバック
    private func updateVisualFeedback(entity: Entity, lifeRatio: Double) {
        // 残り寿命が少なくなったら点滅させる
        guard lifeRatio < 0.5 else { return }

        // 点滅頻度を残り寿命に応じて調整
        let blinkFrequency = 1.0 + (1.0 - lifeRatio) * 4.0 // 1Hz〜5Hz
        let shouldShow = sin(Date().timeIntervalSince1970 * .pi * blinkFrequency) > 0

        // ModelEntityの場合は点滅効果を適用
        if entity is ModelEntity {
            // 点滅効果（スケール変更で表現）
            entity.transform.scale = SIMD3<Float>(repeating: shouldShow ? 1.0 : 0.9)
        }
    }
}
