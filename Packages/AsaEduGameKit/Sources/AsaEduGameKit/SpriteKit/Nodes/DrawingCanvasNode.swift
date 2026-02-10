import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 手書き入力キャンバスノード

/// ひらがな手書き練習用のキャンバスノード
/// タッチストロークを記録し、SKShapeNodeで線を描画する
public class DrawingCanvasNode: SKNode {

    // MARK: - Properties

    /// 全ストロークの座標データ（ストローク単位の配列）
    public var drawingPoints: [[CGPoint]] = []

    /// 現在描画中のストローク座標
    private var currentStroke: [CGPoint] = []

    /// キャンバスサイズ
    private let canvasSize: CGSize

    /// キャンバス背景
    private let backgroundNode: SKShapeNode

    /// 描画線の色（濃い灰色）
    private let strokeColor = SKColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0)

    /// 描画線の太さ
    private let strokeWidth: CGFloat = 4.0

    /// 現在描画中の線ノード
    private var currentLineNode: SKShapeNode?

    /// 描画済みの線ノード配列
    private var lineNodes: [SKShapeNode] = []

    // MARK: - Initialization

    /// キャンバスノードを初期化
    /// - Parameter size: キャンバスサイズ
    public init(size: CGSize) {
        canvasSize = size

        // 背景（白色、薄い枠線）
        let bgRect = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        backgroundNode = SKShapeNode(rect: bgRect, cornerRadius: 12)
        backgroundNode.fillColor = SKColor.white
        backgroundNode.strokeColor = SKColor(red: 0.78, green: 0.73, blue: 0.65, alpha: 1.0)
        backgroundNode.lineWidth = 2

        super.init()

        addChild(backgroundNode)

        // ガイド十字線（薄いグレー）
        setupGuideLines()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) は使用しません")
    }

    // MARK: - ガイド線

    /// 中央ガイド十字線をセットアップ
    private func setupGuideLines() {
        let guideColor = SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.5)

        // 横線
        let horizontalLine = SKShapeNode()
        let hPath = CGMutablePath()
        hPath.move(to: CGPoint(x: -canvasSize.width / 2 + 10, y: 0))
        hPath.addLine(to: CGPoint(x: canvasSize.width / 2 - 10, y: 0))
        horizontalLine.path = hPath
        horizontalLine.strokeColor = guideColor
        horizontalLine.lineWidth = 1
        horizontalLine.lineCap = .round
        addChild(horizontalLine)

        // 縦線
        let verticalLine = SKShapeNode()
        let vPath = CGMutablePath()
        vPath.move(to: CGPoint(x: 0, y: -canvasSize.height / 2 + 10))
        vPath.addLine(to: CGPoint(x: 0, y: canvasSize.height / 2 - 10))
        verticalLine.path = vPath
        verticalLine.strokeColor = guideColor
        verticalLine.lineWidth = 1
        verticalLine.lineCap = .round
        addChild(verticalLine)
    }

    // MARK: - 描画操作

    /// ストローク開始
    /// - Parameter point: 開始座標（キャンバスローカル座標）
    public func beginStroke(at point: CGPoint) {
        currentStroke = [point]

        // 新しい線ノードを作成
        let lineNode = SKShapeNode()
        lineNode.strokeColor = strokeColor
        lineNode.lineWidth = strokeWidth
        lineNode.lineCap = .round
        lineNode.lineJoin = .round
        lineNode.zPosition = 5
        lineNode.name = "drawing_stroke"
        addChild(lineNode)
        currentLineNode = lineNode
    }

    /// ストロークを延長（タッチ移動中に呼ばれる）
    /// - Parameter point: 現在座標（キャンバスローカル座標）
    public func continueStroke(to point: CGPoint) {
        currentStroke.append(point)
        updateCurrentLinePath()
    }

    /// ストローク終了
    public func endStroke() {
        guard !currentStroke.isEmpty else { return }

        drawingPoints.append(currentStroke)

        if let lineNode = currentLineNode {
            lineNodes.append(lineNode)
        }

        currentStroke = []
        currentLineNode = nil
    }

    /// キャンバスをクリア（全ストロークを削除）
    public func clearCanvas() {
        drawingPoints.removeAll()
        currentStroke.removeAll()
        currentLineNode = nil

        // 描画済みの線を全て削除
        for node in lineNodes {
            node.removeFromParent()
        }
        lineNodes.removeAll()

        // 残留ノードもクリーンアップ
        enumerateChildNodes(withName: "drawing_stroke") { node, _ in
            node.removeFromParent()
        }
    }

    // MARK: - 内部ヘルパー

    /// 現在描画中の線パスを更新
    private func updateCurrentLinePath() {
        guard let lineNode = currentLineNode, currentStroke.count >= 2 else { return }

        let path = CGMutablePath()
        path.move(to: currentStroke[0])

        for i in 1 ..< currentStroke.count {
            path.addLine(to: currentStroke[i])
        }

        lineNode.path = path
    }
}
