import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - お祝いエフェクト

/// 正解時・コンボ時・レベルアップ時のお祝いエフェクト集
@MainActor
public class CelebrationEffect {

    /// 共通フォント名
    private static let fontName = "HiraginoSans-W6"

    // MARK: - 正解エフェクト

    /// 正解時のエフェクト（starBurst + 星テキストアニメーション）
    /// - Parameters:
    ///   - scene: エフェクトを追加するシーン
    ///   - position: 表示位置
    public static func showCorrectAnswer(in scene: SKScene, at position: CGPoint) {
        // スターバーストパーティクル
        let emitter = ParticleEffects.starBurst(at: position)
        scene.addChild(emitter)

        // 星テキストアニメーション
        let starLabel = SKLabelNode(fontNamed: fontName)
        starLabel.fontSize = 50
        starLabel.text = "\u{2B50}" // 星
        starLabel.position = position
        starLabel.horizontalAlignmentMode = .center
        starLabel.verticalAlignmentMode = .center
        starLabel.zPosition = 110
        starLabel.setScale(0)
        scene.addChild(starLabel)

        // ポップイン → 浮き上がりながらフェードアウト
        let popIn = SKAction.scale(to: 1.2, duration: 0.2)
        popIn.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.8)
        moveUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let cleanup = SKAction.removeFromParent()

        starLabel.run(SKAction.sequence([
            popIn,
            scaleDown,
            SKAction.group([moveUp, fadeOut]),
            cleanup,
        ]))

        // パーティクルの自動削除
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent(),
        ]))
    }

    // MARK: - コンボエフェクト

    /// コンボ達成時のエフェクト（コンボ数に応じて演出を変化）
    /// - Parameters:
    ///   - scene: エフェクトを追加するシーン
    ///   - combo: 現在のコンボ数
    ///   - position: 表示位置
    public static func showCombo(in scene: SKScene, combo: Int, at position: CGPoint) {
        if combo >= 10 {
            // 10コンボ以上: 大きい花火 + スーパーコンボテキスト
            showSuperCombo(in: scene, combo: combo, at: position)
        } else if combo >= 5 {
            // 5コンボ以上: 花火 + コンボテキスト
            showFireCombo(in: scene, combo: combo, at: position)
        } else if combo >= 3 {
            // 3コンボ以上: 小さなエフェクト
            showSmallCombo(in: scene, combo: combo, at: position)
        }
    }

    /// 3-4コンボ: 小さなコンボ表示
    private static func showSmallCombo(in scene: SKScene, combo: Int, at position: CGPoint) {
        let comboLabel = createAnimatedText(
            text: "\(combo)コンボ!",
            fontSize: 30,
            color: SKColor(red: 0.95, green: 0.65, blue: 0.10, alpha: 1.0),
            position: position
        )
        scene.addChild(comboLabel)
        runTextPopAnimation(on: comboLabel)
    }

    /// 5-9コンボ: 花火 + コンボテキスト
    private static func showFireCombo(in scene: SKScene, combo: Int, at position: CGPoint) {
        // 花火パーティクル
        let emitter = ParticleEffects.fireworks(at: position)
        scene.addChild(emitter)
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.removeFromParent(),
        ]))

        // コンボテキスト
        let comboLabel = createAnimatedText(
            text: "\u{1F525} \(combo)コンボ!",
            fontSize: 36,
            color: SKColor(red: 1.0, green: 0.45, blue: 0.10, alpha: 1.0),
            position: position
        )
        scene.addChild(comboLabel)
        runTextPopAnimation(on: comboLabel)
    }

    /// 10コンボ以上: 大きい花火 + スーパーコンボテキスト
    private static func showSuperCombo(in scene: SKScene, combo: Int, at position: CGPoint) {
        // 複数の花火パーティクル
        let offsets: [CGPoint] = [
            CGPoint(x: -60, y: 30),
            CGPoint(x: 60, y: 30),
            CGPoint(x: 0, y: -20),
        ]

        for offset in offsets {
            let emitterPos = CGPoint(x: position.x + offset.x, y: position.y + offset.y)
            let emitter = ParticleEffects.fireworks(at: emitterPos)
            scene.addChild(emitter)
            emitter.run(SKAction.sequence([
                SKAction.wait(forDuration: 3.0),
                SKAction.removeFromParent(),
            ]))
        }

        // スーパーコンボテキスト
        let comboLabel = createAnimatedText(
            text: "\u{1F4A5} スーパーコンボ!",
            fontSize: 40,
            color: SKColor(red: 0.95, green: 0.20, blue: 0.20, alpha: 1.0),
            position: CGPoint(x: position.x, y: position.y + 10)
        )
        scene.addChild(comboLabel)

        // より派手なアニメーション
        comboLabel.setScale(0)
        let popIn = SKAction.scale(to: 1.4, duration: 0.2)
        popIn.timingMode = .easeOut
        let bounce = SKAction.scale(to: 1.0, duration: 0.15)
        let hold = SKAction.wait(forDuration: 1.0)
        let moveUpFade = SKAction.group([
            SKAction.moveBy(x: 0, y: 50, duration: 0.6),
            SKAction.fadeOut(withDuration: 0.6),
        ])
        let cleanup = SKAction.removeFromParent()

        comboLabel.run(SKAction.sequence([popIn, bounce, hold, moveUpFade, cleanup]))
    }

    // MARK: - パーフェクトエフェクト

    /// パーフェクト達成時のエフェクト（紙吹雪 + パーフェクトテキスト）
    /// - Parameter scene: エフェクトを追加するシーン
    public static func showPerfect(in scene: SKScene) {
        // 紙吹雪
        let emitter = ParticleEffects.confetti(in: scene.frame)
        scene.addChild(emitter)
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 4.0),
            SKAction.removeFromParent(),
        ]))

        // パーフェクトテキスト
        let perfectLabel = createAnimatedText(
            text: "\u{1F4AF} パーフェクト!",
            fontSize: 44,
            color: SKColor(red: 1.0, green: 0.84, blue: 0.00, alpha: 1.0),
            position: CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        )
        scene.addChild(perfectLabel)

        // 豪華なアニメーション
        perfectLabel.setScale(0)
        let popIn = SKAction.scale(to: 1.5, duration: 0.25)
        popIn.timingMode = .easeOut
        let shrink = SKAction.scale(to: 1.0, duration: 0.15)
        let hold = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.group([
            SKAction.moveBy(x: 0, y: 60, duration: 0.8),
            SKAction.fadeOut(withDuration: 0.8),
        ])
        let cleanup = SKAction.removeFromParent()

        perfectLabel.run(SKAction.sequence([popIn, shrink, hold, fadeOut, cleanup]))
    }

    // MARK: - レベルアップエフェクト

    /// レベルアップ時のエフェクト
    /// - Parameters:
    ///   - scene: エフェクトを追加するシーン
    ///   - level: 新しいレベル
    public static func showLevelUp(in scene: SKScene, level: Int) {
        let centerX = scene.size.width / 2
        let centerY = scene.size.height / 2

        // スターバースト
        let emitter = ParticleEffects.starBurst(at: CGPoint(x: centerX, y: centerY))
        scene.addChild(emitter)
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.removeFromParent(),
        ]))

        // レベルアップテキスト
        let levelLabel = createAnimatedText(
            text: "\u{2B06}\u{FE0F} レベル\(level)!",
            fontSize: 38,
            color: SKColor(red: 0.20, green: 0.70, blue: 0.95, alpha: 1.0),
            position: CGPoint(x: centerX, y: centerY)
        )
        scene.addChild(levelLabel)
        runTextPopAnimation(on: levelLabel, holdDuration: 1.5)
    }

    // MARK: - 励ましエフェクト

    /// 不正解時の励ましエフェクト（優しいテキスト表示）
    /// - Parameters:
    ///   - scene: エフェクトを追加するシーン
    ///   - position: 表示位置
    public static func showEncouragement(in scene: SKScene, at position: CGPoint) {
        let messages = [
            "がんばれ！",
            "もういっかい！",
            "だいじょうぶ！",
            "つぎはできるよ！",
            "おしい！",
        ]

        let message = messages.randomElement() ?? "がんばれ！"

        let encourageLabel = createAnimatedText(
            text: message,
            fontSize: 28,
            color: SKColor(red: 0.55, green: 0.45, blue: 0.35, alpha: 1.0),
            position: position
        )
        scene.addChild(encourageLabel)

        // 優しいフェードイン → フェードアウト
        encourageLabel.alpha = 0
        encourageLabel.setScale(0.8)

        let fadeIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3),
        ])
        let hold = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.moveBy(x: 0, y: 20, duration: 0.4),
        ])
        let cleanup = SKAction.removeFromParent()

        encourageLabel.run(SKAction.sequence([fadeIn, hold, fadeOut, cleanup]))
    }

    // MARK: - ヘルパーメソッド

    /// アニメーション用テキストラベルを生成
    private static func createAnimatedText(
        text: String,
        fontSize: CGFloat,
        color: SKColor,
        position: CGPoint
    ) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.fontSize = fontSize
        label.fontColor = color
        label.text = text
        label.position = position
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 120
        return label
    }

    /// テキストのポップアニメーション（共通パターン）
    private static func runTextPopAnimation(on label: SKLabelNode, holdDuration: TimeInterval = 0.8) {
        label.setScale(0)
        let popIn = SKAction.scale(to: 1.2, duration: 0.2)
        popIn.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let hold = SKAction.wait(forDuration: holdDuration)
        let moveUpFade = SKAction.group([
            SKAction.moveBy(x: 0, y: 40, duration: 0.6),
            SKAction.fadeOut(withDuration: 0.6),
        ])
        let cleanup = SKAction.removeFromParent()

        label.run(SKAction.sequence([popIn, scaleDown, hold, moveUpFade, cleanup]))
    }
}
