import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 応援キャラクターノード

/// ゲーム案内役の応援キャラクター（絵文字ベース）
/// お祝い・励まし・アイドル状態のアニメーションを持つ
public class CharacterNode: SKNode {

    // MARK: - Properties

    /// キャラクター絵文字ラベル
    private let emojiLabel: SKLabelNode

    /// 現在の絵文字
    private var currentEmoji: String = "🐱"

    /// キャラクターサイズ
    private let characterSize: CGFloat

    /// フォント名
    private let fontName = "HiraginoSans-W6"

    /// 吹き出しノード
    private var speechBubble: SKNode?

    // MARK: - Initialization

    /// キャラクターノードを初期化
    /// - Parameters:
    ///   - emoji: キャラクターの絵文字（デフォルト: 🐱）
    ///   - size: 表示サイズ（デフォルト: 60）
    public init(emoji: String = "🐱", size: CGFloat = 60) {
        currentEmoji = emoji
        characterSize = size

        emojiLabel = SKLabelNode()
        emojiLabel.fontSize = size
        emojiLabel.text = emoji
        emojiLabel.horizontalAlignmentMode = .center
        emojiLabel.verticalAlignmentMode = .center

        super.init()

        addChild(emojiLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    // MARK: - アニメーション

    /// お祝いアニメーション（正解時に跳ねる + パーティクル）
    public func celebrate() {
        // 既存アクションを停止
        removeAllActions()
        emojiLabel.removeAllActions()

        // 跳ねるアニメーション
        let jumpUp = SKAction.moveBy(x: 0, y: 30, duration: 0.15)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.moveBy(x: 0, y: -30, duration: 0.15)
        jumpDown.timingMode = .easeIn
        let jump = SKAction.sequence([jumpUp, jumpDown])

        // 3回ジャンプ
        emojiLabel.run(SKAction.repeat(jump, count: 3))

        // キラキラパーティクル
        let sparkle = ParticleEffects.sparkle(at: .zero)
        sparkle.zPosition = -1
        addChild(sparkle)

        // パーティクルは一定時間後に削除
        sparkle.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent(),
        ]))

        // お祝い後にアイドル状態に戻る
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.idle()
            },
        ]))
    }

    /// 励ましアニメーション（不正解時に優しく揺れる + 吹き出し）
    public func encourage() {
        // 既存アクションを停止
        removeAllActions()
        emojiLabel.removeAllActions()

        // 優しく揺れるアニメーション
        let tiltLeft = SKAction.rotate(byAngle: 0.15, duration: 0.15)
        let tiltRight = SKAction.rotate(byAngle: -0.30, duration: 0.30)
        let tiltBack = SKAction.rotate(byAngle: 0.15, duration: 0.15)
        let rock = SKAction.sequence([tiltLeft, tiltRight, tiltBack])
        emojiLabel.run(SKAction.repeat(rock, count: 2))

        // 「がんばれ！」吹き出し
        showSpeechBubble(text: "がんばれ！", duration: 2.0)

        // 励まし後にアイドル状態に戻る
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in
                self?.idle()
            },
        ]))
    }

    /// アイドルアニメーション（ゆっくり揺れる待機状態）
    public func idle() {
        // 既存アクションを停止
        removeAllActions()
        emojiLabel.removeAllActions()

        // ゆっくり上下に揺れる
        let moveUp = SKAction.moveBy(x: 0, y: 5, duration: 1.0)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = SKAction.moveBy(x: 0, y: -5, duration: 1.0)
        moveDown.timingMode = .easeInEaseOut
        let breathe = SKAction.sequence([moveUp, moveDown])

        emojiLabel.run(SKAction.repeatForever(breathe))
    }

    /// 吹き出しを表示
    /// - Parameters:
    ///   - text: 吹き出し内テキスト
    ///   - duration: 表示時間（秒）
    public func showSpeechBubble(text: String, duration: TimeInterval) {
        // 既存の吹き出しを削除
        speechBubble?.removeFromParent()

        let bubbleContainer = SKNode()
        bubbleContainer.zPosition = 20

        // 吹き出し背景
        let bubbleWidth: CGFloat = CGFloat(text.count) * 22 + 30
        let bubbleHeight: CGFloat = 40
        let bubbleRect = CGRect(
            x: -bubbleWidth / 2,
            y: -bubbleHeight / 2,
            width: bubbleWidth,
            height: bubbleHeight
        )
        let bubbleBg = SKShapeNode(rect: bubbleRect, cornerRadius: 12)
        bubbleBg.fillColor = SKColor.white
        bubbleBg.strokeColor = SKColor(red: 0.80, green: 0.75, blue: 0.68, alpha: 1.0)
        bubbleBg.lineWidth = 1.5
        bubbleContainer.addChild(bubbleBg)

        // 吹き出しの三角（しっぽ）
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -8, y: -bubbleHeight / 2))
        tailPath.addLine(to: CGPoint(x: 0, y: -bubbleHeight / 2 - 10))
        tailPath.addLine(to: CGPoint(x: 8, y: -bubbleHeight / 2))
        tailPath.closeSubpath()
        let tailNode = SKShapeNode(path: tailPath)
        tailNode.fillColor = SKColor.white
        tailNode.strokeColor = SKColor(red: 0.80, green: 0.75, blue: 0.68, alpha: 1.0)
        tailNode.lineWidth = 1.5
        bubbleContainer.addChild(tailNode)

        // テキスト
        let bubbleText = SKLabelNode(fontNamed: fontName)
        bubbleText.fontSize = 18
        bubbleText.fontColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        bubbleText.text = text
        bubbleText.horizontalAlignmentMode = .center
        bubbleText.verticalAlignmentMode = .center
        bubbleContainer.addChild(bubbleText)

        // キャラクターの上に配置
        bubbleContainer.position = CGPoint(x: 0, y: characterSize / 2 + 35)

        addChild(bubbleContainer)
        speechBubble = bubbleContainer

        // フェードイン
        bubbleContainer.alpha = 0
        bubbleContainer.setScale(0.5)
        bubbleContainer.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2),
        ]))

        // 一定時間後にフェードアウト
        bubbleContainer.run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 0.5, duration: 0.3),
            ]),
            SKAction.removeFromParent(),
        ]))
    }
}
