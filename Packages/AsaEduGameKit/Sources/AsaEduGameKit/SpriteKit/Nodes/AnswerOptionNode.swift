import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 選択肢ボタンノード

/// タップ可能な選択肢ボタンノード（子供向けに大きめデザイン）
public class AnswerOptionNode: SKNode {

    // MARK: - Properties

    /// この選択肢の回答テキスト
    public let answer: String

    /// 背景の角丸長方形
    private let backgroundNode: SKShapeNode

    /// テキストラベル
    private let textLabel: SKLabelNode

    /// タップ可能かどうか
    public var isEnabled: Bool = true

    /// フォント名
    private let fontName = "HiraginoSans-W6"

    /// ノードサイズ
    private let nodeSize: CGSize

    // MARK: - 色定数

    /// 通常状態の背景色（薄い水色）
    private let normalColor = SKColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 1.0)

    /// 正解時の背景色（緑）
    private let correctColor = SKColor(red: 0.60, green: 0.90, blue: 0.60, alpha: 1.0)

    /// 不正解時の背景色（赤）
    private let incorrectColor = SKColor(red: 0.95, green: 0.60, blue: 0.60, alpha: 1.0)

    /// 枠線の色
    private let borderColor = SKColor(red: 0.65, green: 0.78, blue: 0.90, alpha: 1.0)

    // MARK: - Initialization

    /// 選択肢ノードを初期化
    /// - Parameters:
    ///   - answer: 回答テキスト
    ///   - size: ノードサイズ
    ///   - fontSize: フォントサイズ（デフォルト: 24）
    public init(answer: String, size: CGSize, fontSize: CGFloat = 24) {
        self.answer = answer
        self.nodeSize = size

        // 子供向けに最小高さを60ptに設定
        let adjustedHeight = max(size.height, 60)
        let adjustedSize = CGSize(width: size.width, height: adjustedHeight)

        // 背景ノード
        let rect = CGRect(
            x: -adjustedSize.width / 2,
            y: -adjustedSize.height / 2,
            width: adjustedSize.width,
            height: adjustedSize.height
        )
        backgroundNode = SKShapeNode(rect: rect, cornerRadius: 16)
        backgroundNode.fillColor = SKColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 1.0)
        backgroundNode.strokeColor = SKColor(red: 0.65, green: 0.78, blue: 0.90, alpha: 1.0)
        backgroundNode.lineWidth = 2

        // テキストラベル
        textLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
        textLabel.fontSize = fontSize
        textLabel.fontColor = SKColor(red: 0.18, green: 0.24, blue: 0.27, alpha: 1.0)
        textLabel.text = answer
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center

        super.init()

        // タップ検出用のname設定
        self.name = "answer_option"

        // ノード階層構築
        addChild(backgroundNode)
        addChild(textLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    // MARK: - 状態表示

    /// 正解表示（緑色ハイライト + チェックマーク）
    public func showCorrect() {
        isEnabled = false
        backgroundNode.fillColor = correctColor
        backgroundNode.strokeColor = SKColor(red: 0.30, green: 0.70, blue: 0.30, alpha: 1.0)

        // チェックマーク追加
        let checkMark = SKLabelNode(fontNamed: fontName)
        checkMark.fontSize = 24
        checkMark.text = " \u{2713}" // チェックマーク
        checkMark.fontColor = SKColor(red: 0.15, green: 0.55, blue: 0.15, alpha: 1.0)
        checkMark.position = CGPoint(x: nodeSize.width / 2 - 25, y: 0)
        checkMark.horizontalAlignmentMode = .center
        checkMark.verticalAlignmentMode = .center
        checkMark.name = "check_mark"
        addChild(checkMark)

        // スケールアニメーション
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        run(SKAction.sequence([scaleUp, scaleDown]))
    }

    /// 不正解表示（赤色ハイライト + バツマーク）
    public func showIncorrect() {
        isEnabled = false
        backgroundNode.fillColor = incorrectColor
        backgroundNode.strokeColor = SKColor(red: 0.75, green: 0.25, blue: 0.25, alpha: 1.0)

        // バツマーク追加
        let crossMark = SKLabelNode(fontNamed: fontName)
        crossMark.fontSize = 24
        crossMark.text = " \u{2717}" // バツマーク
        crossMark.fontColor = SKColor(red: 0.70, green: 0.15, blue: 0.15, alpha: 1.0)
        crossMark.position = CGPoint(x: nodeSize.width / 2 - 25, y: 0)
        crossMark.horizontalAlignmentMode = .center
        crossMark.verticalAlignmentMode = .center
        crossMark.name = "cross_mark"
        addChild(crossMark)

        // 揺れアニメーション
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -4, y: 0, duration: 0.05),
            SKAction.moveBy(x: 8, y: 0, duration: 0.05),
            SKAction.moveBy(x: -8, y: 0, duration: 0.05),
            SKAction.moveBy(x: 4, y: 0, duration: 0.05),
        ])
        run(shake)
    }

    /// 遅延付きバウンスインアニメーション
    /// - Parameter delay: アニメーション開始の遅延時間
    public func animateIn(delay: TimeInterval) {
        setScale(0)
        alpha = 0

        let wait = SKAction.wait(forDuration: delay)
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        scaleUp.timingMode = .easeOut

        run(SKAction.sequence([
            wait,
            SKAction.group([fadeIn, scaleUp]),
            scaleDown,
        ]))
    }

    /// 状態をリセット（通常表示に戻す）
    public func reset() {
        isEnabled = true
        backgroundNode.fillColor = normalColor
        backgroundNode.strokeColor = borderColor

        // マーク類を削除
        enumerateChildNodes(withName: "check_mark") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "cross_mark") { node, _ in
            node.removeFromParent()
        }

        setScale(1.0)
        alpha = 1.0
    }
}
