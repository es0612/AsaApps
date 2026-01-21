import Foundation
import RealityKit
import UIKit

// MARK: - TargetRenderer
/// 3Dターゲットエンティティを生成するレンダラー
final class TargetRenderer {
    // MARK: - Color Definitions

    /// ブランドカラー定義
    private struct Colors {
        static let coffeeBrown = UIColor(red: 0.776, green: 0.549, blue: 0.325, alpha: 1.0)
        static let mocha = UIColor(red: 0.545, green: 0.353, blue: 0.169, alpha: 1.0)
        static let gold = UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0)
        static let softCream = UIColor(red: 0.910, green: 0.835, blue: 0.725, alpha: 1.0)
    }

    // MARK: - Public Methods

    /// ターゲットエンティティを生成
    /// - Parameter target: ターゲットデータ
    /// - Returns: 3Dエンティティ
    func createTargetEntity(target: Target) -> Entity {
        // メッシュを生成
        let mesh = MeshResource.generateSphere(radius: target.size.radius)

        // マテリアルを生成（サイズに応じた色）
        let material = createMaterial(for: target.size)

        // ModelEntityを生成
        let entity = ModelEntity(mesh: mesh, materials: [material])

        // 位置を設定
        entity.position = target.position

        // コリジョン形状を追加（ヒット検出用）
        let shape = ShapeResource.generateSphere(radius: target.size.radius)
        entity.collision = CollisionComponent(shapes: [shape])

        // ECS Componentsを追加
        entity.components.set(TargetComponent(from: target))
        entity.components.set(LifespanComponent(from: target))

        // ホバー効果のためのアニメーションを追加
        addHoverAnimation(to: entity)

        return entity
    }

    /// ヒットエフェクトを生成
    /// - Parameters:
    ///   - position: エフェクトの位置
    ///   - size: ターゲットサイズ
    /// - Returns: エフェクトエンティティ
    func createHitEffect(at position: SIMD3<Float>, size: TargetSize) -> Entity {
        // パーティクル風のエフェクト（複数の小さな球体）
        let effectEntity = Entity()
        effectEntity.position = position

        let particleCount = 8
        let particleRadius: Float = size.radius * 0.2

        for i in 0..<particleCount {
            let mesh = MeshResource.generateSphere(radius: particleRadius)
            var material = SimpleMaterial()
            material.color = .init(tint: Colors.gold, texture: nil)
            material.metallic = .init(floatLiteral: 0.8)
            material.roughness = .init(floatLiteral: 0.2)

            let particle = ModelEntity(mesh: mesh, materials: [material])

            // 放射状に配置
            let angle = Float(i) * (2 * .pi / Float(particleCount))
            particle.position = SIMD3<Float>(
                cos(angle) * size.radius * 0.5,
                sin(angle) * size.radius * 0.5,
                0
            )

            effectEntity.addChild(particle)

            // 外側に広がるアニメーション
            var targetTransform = particle.transform
            targetTransform.translation = SIMD3<Float>(
                cos(angle) * size.radius * 2,
                sin(angle) * size.radius * 2,
                0
            )
            targetTransform.scale = .zero

            particle.move(
                to: targetTransform,
                relativeTo: effectEntity,
                duration: 0.4,
                timingFunction: .easeOut
            )
        }

        // 一定時間後に削除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            effectEntity.removeFromParent()
        }

        return effectEntity
    }

    /// ヒット時のアニメーションを実行
    /// - Parameter entity: 対象エンティティ
    func performHitAnimation(on entity: Entity, completion: @escaping () -> Void) {
        // スケールアップ後に消失
        var transform = entity.transform
        transform.scale = SIMD3<Float>(repeating: 1.5)

        entity.move(
            to: transform,
            relativeTo: entity.parent,
            duration: 0.1,
            timingFunction: .easeOut
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var shrinkTransform = entity.transform
            shrinkTransform.scale = .zero

            entity.move(
                to: shrinkTransform,
                relativeTo: entity.parent,
                duration: 0.15,
                timingFunction: .easeIn
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                completion()
            }
        }
    }

    // MARK: - Private Methods

    /// サイズに応じたマテリアルを生成
    private func createMaterial(for size: TargetSize) -> SimpleMaterial {
        var material = SimpleMaterial()

        let color: UIColor
        switch size {
        case .large:
            color = Colors.coffeeBrown
        case .medium:
            color = Colors.mocha
        case .small:
            color = Colors.gold
        }

        material.color = .init(tint: color, texture: nil)

        // サイズが小さいほどメタリック感を強く
        switch size {
        case .large:
            material.metallic = .init(floatLiteral: 0.3)
            material.roughness = .init(floatLiteral: 0.7)
        case .medium:
            material.metallic = .init(floatLiteral: 0.5)
            material.roughness = .init(floatLiteral: 0.5)
        case .small:
            material.metallic = .init(floatLiteral: 0.9)
            material.roughness = .init(floatLiteral: 0.1)
        }

        return material
    }

    /// ホバーアニメーションを追加
    private func addHoverAnimation(to entity: Entity) {
        // 上下にゆっくり浮遊するアニメーション
        let originalY = entity.position.y
        let hoverHeight: Float = 0.02
        let duration: TimeInterval = 1.0

        func animateUp() {
            var upTransform = entity.transform
            upTransform.translation.y = originalY + hoverHeight

            entity.move(
                to: upTransform,
                relativeTo: entity.parent,
                duration: duration,
                timingFunction: .easeInOut
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak entity] in
                guard entity?.parent != nil else { return }
                animateDown()
            }
        }

        func animateDown() {
            var downTransform = entity.transform
            downTransform.translation.y = originalY - hoverHeight

            entity.move(
                to: downTransform,
                relativeTo: entity.parent,
                duration: duration,
                timingFunction: .easeInOut
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak entity] in
                guard entity?.parent != nil else { return }
                animateUp()
            }
        }

        // アニメーション開始
        animateUp()
    }
}
