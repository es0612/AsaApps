import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 問題表示ノード

/// 問題文を角丸長方形の背景付きで表示するカスタムノード
public class QuestionNode: SKNode {

    // MARK: - Properties

    /// 背景の角丸長方形
    private let backgroundNode: SKShapeNode

    /// テキストラベル
    private let textLabel: SKLabelNode

    /// フォント名
    private let fontName = "HiraginoSans-W6"

    // MARK: - Initialization

    /// 問題ノードを初期化
    /// - Parameters:
    ///   - text: 問題文テキスト
    ///   - fontSize: フォントサイズ（デフォルト: 28）
    public init(text: String, fontSize: CGFloat = 28) {
        // 背景ノード（角丸長方形）
        let bgWidth: CGFloat = 320
        let bgHeight: CGFloat = 80
        let rect = CGRect(
            x: -bgWidth / 2,
            y: -bgHeight / 2,
            width: bgWidth,
            height: bgHeight
        )
        backgroundNode = SKShapeNode(rect: rect, cornerRadius: 20)
        backgroundNode.fillColor = SKColor.white
        backgroundNode.strokeColor = SKColor(red: 0.85, green: 0.80, blue: 0.73, alpha: 1.0)
        backgroundNode.lineWidth = 2
        backgroundNode.alpha = 0.95

        // テキストラベル
        textLabel = SKLabelNode(fontNamed: fontName)
        textLabel.fontSize = fontSize
        textLabel.fontColor = SKColor(red: 0.18, green: 0.24, blue: 0.27, alpha: 1.0)
        textLabel.text = text
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = bgWidth - 40

        super.init()

        // ノード階層構築
        addChild(backgroundNode)
        addChild(textLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    // MARK: - Public Methods

    /// テキストを更新
    /// - Parameter text: 新しい問題文
    public func updateText(_ text: String) {
        textLabel.text = text
    }

    /// フェードイン + スケールアニメーションで表示
    public func animateIn() {
        setScale(0.8)
        alpha = 0

        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        scaleUp.timingMode = .easeOut
        run(SKAction.group([fadeIn, scaleUp]))
    }

    /// フェードアウトアニメーションで非表示
    /// - Parameter completion: 完了コールバック
    public func animateOut(completion: @escaping () -> Void) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.2)
        fadeOut.timingMode = .easeIn

        run(SKAction.group([fadeOut, scaleDown])) {
            completion()
        }
    }
}
