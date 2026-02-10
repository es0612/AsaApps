import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 図形パズルシーン

/// 図形パズル（かたちあて・パターン・くみあわせ）のSpriteKitシーン
public class ShapePuzzleScene: BaseGameScene {

    // MARK: - Properties

    /// 選択肢ノードの配列
    private var answerNodes: [AnswerOptionNode] = []

    /// 表示中の図形ノード
    private var displayedShapeNodes: [SKNode] = []

    // MARK: - 図形の色パレット（子供向けカラフル）

    private let shapeColors: [SKColor] = [
        SKColor(red: 0.95, green: 0.30, blue: 0.30, alpha: 1.0), // 赤
        SKColor(red: 0.20, green: 0.60, blue: 0.95, alpha: 1.0), // 青
        SKColor(red: 0.30, green: 0.85, blue: 0.40, alpha: 1.0), // 緑
        SKColor(red: 0.95, green: 0.75, blue: 0.10, alpha: 1.0), // 黄
        SKColor(red: 0.80, green: 0.40, blue: 0.90, alpha: 1.0), // 紫
        SKColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1.0), // オレンジ
    ]

    // MARK: - 問題表示

    public override func presentQuestion(_ question: GameQuestion) {
        super.presentQuestion(question)

        // 前の表示をクリア
        clearAnswerOptions()
        clearShapeNodes()
        answerNodes.removeAll()

        switch question.questionType {
        case .shapePattern:
            presentPatternQuestion(question)
        case .shapeCombination:
            presentCombinationQuestion(question)
        default:
            presentIdentificationQuestion(question)
        }

        gameState = .answering
    }

    // MARK: - 図形当てモード

    /// 図形を1つ表示して、名前を選択する
    private func presentIdentificationQuestion(_ question: GameQuestion) {
        // 問題の図形タイプを判定
        let shapeType = shapeTypeFromAnswer(question.correctAnswer)

        // 図形を画面中央に表示
        let shapeNode = ShapeNode.create(
            type: shapeType,
            size: 120,
            color: randomShapeColor()
        )
        shapeNode.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        shapeNode.zPosition = 10
        shapeNode.name = "display_shape"
        addChild(shapeNode)
        displayedShapeNodes.append(shapeNode)

        // 図形のポップインアニメーション
        TransitionEffect.scalePopIn(node: shapeNode, delay: 0.1)

        // 選択肢を配置
        setupAnswerOptions(question.options)
    }

    // MARK: - パターンモード

    /// 3つの図形パターンを表示して、次の図形を選択する
    private func presentPatternQuestion(_ question: GameQuestion) {
        // パターンの図形を横並びで表示
        let patternShapes = parsePatternFromQuestion(question)

        let spacing: CGFloat = 100
        let totalWidth = CGFloat(patternShapes.count) * spacing
        let startX = (size.width - totalWidth) / 2 + spacing / 2

        for (index, shapeType) in patternShapes.enumerated() {
            let shapeNode = ShapeNode.create(
                type: shapeType,
                size: 60,
                color: randomShapeColor()
            )
            shapeNode.position = CGPoint(
                x: startX + CGFloat(index) * spacing,
                y: size.height * 0.52
            )
            shapeNode.zPosition = 10
            shapeNode.name = "display_shape"
            addChild(shapeNode)
            displayedShapeNodes.append(shapeNode)

            TransitionEffect.slideInFromRight(
                node: shapeNode,
                in: self,
                delay: TimeInterval(index) * 0.15
            )
        }

        // 「?」マークを最後に表示
        let questionMark = SKLabelNode(fontNamed: fontName)
        questionMark.fontSize = 50
        questionMark.fontColor = SKColor(red: 0.55, green: 0.35, blue: 0.17, alpha: 1.0)
        questionMark.text = "?"
        questionMark.position = CGPoint(
            x: startX + CGFloat(patternShapes.count) * spacing,
            y: size.height * 0.52
        )
        questionMark.horizontalAlignmentMode = .center
        questionMark.verticalAlignmentMode = .center
        questionMark.zPosition = 10
        questionMark.name = "display_shape"
        addChild(questionMark)

        // 点滅アニメーション
        let blink = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5),
        ]))
        questionMark.run(blink)

        // 選択肢を配置
        setupAnswerOptions(question.options)
    }

    // MARK: - 組み合わせモード

    /// 図形の組み合わせ問題を表示
    private func presentCombinationQuestion(_ question: GameQuestion) {
        presentIdentificationQuestion(question)
    }

    // MARK: - 選択肢配置

    /// 選択肢ノードを2x2グリッドで配置
    private func setupAnswerOptions(_ options: [String]) {
        let optionSize = CGSize(width: size.width * 0.38, height: 65)
        let centerX = size.width / 2
        let startY = size.height * 0.28
        let horizontalSpacing = optionSize.width + 20
        let verticalSpacing = optionSize.height + 16

        for (index, option) in options.enumerated() {
            let column = index % 2
            let row = index / 2

            let x = centerX + CGFloat(column == 0 ? -1 : 1) * (horizontalSpacing / 2)
            let y = startY - CGFloat(row) * verticalSpacing

            let answerNode = AnswerOptionNode(
                answer: option,
                size: optionSize,
                fontSize: 24
            )
            answerNode.position = CGPoint(x: x, y: y)
            answerNode.zPosition = 10
            addChild(answerNode)
            answerNode.animateIn(delay: TimeInterval(index) * 0.1)
            answerNodes.append(answerNode)
        }
    }

    // MARK: - タッチ処理（iOS）

    #if os(iOS)
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState.isInteractive else { return }
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        handleTap(at: location)
    }
    #else
    // MARK: - マウス処理（macOS）

    public override func mouseDown(with event: NSEvent) {
        guard gameState.isInteractive else { return }

        let location = event.location(in: self)
        handleTap(at: location)
    }
    #endif

    // MARK: - 共通タップ処理

    /// タップ/クリック位置の処理
    private func handleTap(at location: CGPoint) {
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            if let answerNode = findAnswerOptionNode(from: node) {
                guard answerNode.isEnabled else { continue }
                handleAnswerSelected(answerNode)
                return
            }
        }
    }

    // MARK: - 回答処理

    /// 回答が選択された時の処理
    private func handleAnswerSelected(_ selectedNode: AnswerOptionNode) {
        guard let question = currentQuestion else { return }

        for node in answerNodes {
            node.isEnabled = false
        }

        let isCorrect = selectedNode.answer == question.correctAnswer

        if isCorrect {
            selectedNode.showCorrect()
        } else {
            selectedNode.showIncorrect()
            for node in answerNodes where node.answer == question.correctAnswer {
                node.showCorrect()
            }
        }

        gameDelegate?.sceneDidSelectAnswer(self, answer: selectedNode.answer)
    }

    // MARK: - ユーティリティ

    /// タッチされたノードからAnswerOptionNodeを探す
    private func findAnswerOptionNode(from node: SKNode) -> AnswerOptionNode? {
        if let answerNode = node as? AnswerOptionNode {
            return answerNode
        }
        if let parent = node.parent {
            return findAnswerOptionNode(from: parent)
        }
        return nil
    }

    /// 正解文字列からShapeTypeに変換
    private func shapeTypeFromAnswer(_ answer: String) -> ShapeNode.ShapeType {
        for shapeType in ShapeNode.ShapeType.allCases {
            if shapeType.displayName == answer || shapeType.rawValue == answer {
                return shapeType
            }
        }
        return .circle
    }

    /// 問題からパターン図形リストを解析
    private func parsePatternFromQuestion(_ question: GameQuestion) -> [ShapeNode.ShapeType] {
        guard let imageName = question.imageName else {
            return [.circle, .triangle, .circle]
        }

        return imageName.split(separator: ",").compactMap { name in
            ShapeNode.ShapeType(rawValue: String(name).trimmingCharacters(in: .whitespaces))
        }
    }

    /// ランダムな図形色を返す
    private func randomShapeColor() -> SKColor {
        shapeColors.randomElement() ?? shapeColors[0]
    }

    /// 図形ノードをクリア
    private func clearShapeNodes() {
        for node in displayedShapeNodes {
            node.removeFromParent()
        }
        displayedShapeNodes.removeAll()

        enumerateChildNodes(withName: "display_shape") { node, _ in
            node.removeFromParent()
        }
    }

    /// 選択肢クリア（オーバーライド）
    override func clearAnswerOptions() {
        for node in answerNodes {
            node.removeFromParent()
        }
        answerNodes.removeAll()
    }
}
