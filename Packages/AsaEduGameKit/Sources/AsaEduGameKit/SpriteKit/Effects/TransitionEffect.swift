import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 画面遷移エフェクト

/// 画面遷移・ノード登場時のアニメーションエフェクト集
@MainActor
public class TransitionEffect {

    // MARK: - フェード遷移

    /// フェードイン/アウトで遷移（0.3秒 easeInEaseOut）
    /// - Parameters:
    ///   - scene: エフェクトを適用するシーン
    ///   - completion: フェードアウト後のコールバック（コンテンツ差し替えタイミング）
    public static func fadeTransition(in scene: SKScene, completion: @escaping @MainActor () -> Void) {
        // フェード用オーバーレイ
        let overlay = SKShapeNode(rectOf: scene.size)
        overlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        overlay.fillColor = SKColor(red: 0.97, green: 0.93, blue: 0.87, alpha: 1.0)
        overlay.strokeColor = .clear
        overlay.zPosition = 1000
        overlay.alpha = 0
        scene.addChild(overlay)

        // フェードアウト → コンテンツ差し替え → フェードイン
        let fadeOut = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
        fadeOut.timingMode = .easeIn
        let callCompletion = SKAction.run {
            completion()
        }
        let fadeIn = SKAction.fadeAlpha(to: 0.0, duration: 0.15)
        fadeIn.timingMode = .easeOut
        let cleanup = SKAction.removeFromParent()

        overlay.run(SKAction.sequence([fadeOut, callCompletion, fadeIn, cleanup]))
    }

    // MARK: - 右からスライドイン

    /// 右からスライドインアニメーション（0.4秒 easeOut）
    /// - Parameters:
    ///   - node: アニメーション対象ノード
    ///   - scene: シーン（幅計算用）
    ///   - delay: 開始遅延時間
    public static func slideInFromRight(node: SKNode, in scene: SKScene, delay: TimeInterval) {
        let targetPosition = node.position
        let startX = scene.size.width + 50 // 画面外右側

        node.position = CGPoint(x: startX, y: targetPosition.y)
        node.alpha = 0

        let wait = SKAction.wait(forDuration: delay)
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let slide = SKAction.moveTo(x: targetPosition.x, duration: 0.4)
        slide.timingMode = .easeOut

        node.run(SKAction.sequence([
            wait,
            SKAction.group([fadeIn, slide]),
        ]))
    }

    // MARK: - バウンスイン

    /// バウンスインアニメーション（スケール 0→1.1→1.0, 0.3秒）
    /// - Parameters:
    ///   - node: アニメーション対象ノード
    ///   - delay: 開始遅延時間
    public static func bounceIn(node: SKNode, delay: TimeInterval) {
        node.setScale(0)
        node.alpha = 0

        let wait = SKAction.wait(forDuration: delay)
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.2)
        scaleUp.timingMode = .easeOut
        let scaleBounce = SKAction.scale(to: 1.0, duration: 0.1)
        scaleBounce.timingMode = .easeIn

        node.run(SKAction.sequence([
            wait,
            SKAction.group([fadeIn, scaleUp]),
            scaleBounce,
        ]))
    }

    // MARK: - スケールポップイン

    /// スケールポップインアニメーション（スケール 0→1.2→0.95→1.0, 0.4秒）
    /// - Parameters:
    ///   - node: アニメーション対象ノード
    ///   - delay: 開始遅延時間
    public static func scalePopIn(node: SKNode, delay: TimeInterval) {
        node.setScale(0)
        node.alpha = 0

        let wait = SKAction.wait(forDuration: delay)
        let fadeIn = SKAction.fadeIn(withDuration: 0.05)

        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        scaleUp.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        scaleDown.timingMode = .easeIn
        let scaleNormal = SKAction.scale(to: 1.0, duration: 0.1)
        scaleNormal.timingMode = .easeOut

        node.run(SKAction.sequence([
            wait,
            SKAction.group([fadeIn, scaleUp]),
            scaleDown,
            scaleNormal,
        ]))
    }
}
