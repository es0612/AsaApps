import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 論理ゲームシーン

/// 論理ゲーム（なかまはずれ・じゅんばん・つぎはなに？）のSpriteKitシーン
public class LogicGameScene: BaseGameScene {

    // MARK: - Properties

    /// 選択肢ノードの配列
    private var answerNodes: [AnswerOptionNode] = []

    /// アイテム表示ノード（なかまはずれ用）
    private var itemNodes: [SKNode] = []

    /// ドラッグ中のノード（じゅんばんモード用）
    private var draggedNode: SKNode?

    /// ドラッグ開始位置
    private var dragStartPosition: CGPoint = .zero

    /// じゅんばんモードかどうか
    private var isSequenceMode: Bool = false

    // MARK: - 問題表示

    public override func presentQuestion(_ question: GameQuestion) {
        super.presentQuestion(question)

        // 前の表示をクリア
        clearAnswerOptions()
        clearItemNodes()
        answerNodes.removeAll()
        isSequenceMode = false

        switch question.questionType {
        case .oddOneOut:
            presentOddOneOutQuestion(question)
        case .sequenceOrder:
            presentSequenceOrderQuestion(question)
        case .patternCompletion:
            presentPatternCompletionQuestion(question)
        default:
            presentOddOneOutQuestion(question)
        }

        gameState = .answering
    }

    // MARK: - なかまはずれモード

    /// 4-5個のアイテムから仲間はずれを1つ選択
    private func presentOddOneOutQuestion(_ question: GameQuestion) {
        isSequenceMode = false

        let options = question.options
        let itemCount = options.count
        let spacing: CGFloat = size.width / CGFloat(itemCount + 1)

        for (index, option) in options.enumerated() {
            // アイテムをタップ可能なノードとして作成
            let itemContainer = SKNode()
            itemContainer.position = CGPoint(
                x: spacing * CGFloat(index + 1),
                y: size.height * 0.50
            )
            itemContainer.zPosition = 10
            itemContainer.name = "item_\(index)"

            // 丸い背景
            let backgroundCircle = SKShapeNode(circleOfRadius: 45)
            backgroundCircle.fillColor = SKColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 1.0)
            backgroundCircle.strokeColor = SKColor(red: 0.70, green: 0.80, blue: 0.90, alpha: 1.0)
            backgroundCircle.lineWidth = 2
            itemContainer.addChild(backgroundCircle)

            // アイテムテキスト（絵文字やテキスト）
            let itemLabel = SKLabelNode(fontNamed: fontName)
            itemLabel.fontSize = 36
            itemLabel.text = option
            itemLabel.horizontalAlignmentMode = .center
            itemLabel.verticalAlignmentMode = .center
            itemLabel.fontColor = SKColor(red: 0.18, green: 0.24, blue: 0.27, alpha: 1.0)
            itemContainer.addChild(itemLabel)

            addChild(itemContainer)
            itemNodes.append(itemContainer)

            // バウンスインアニメーション
            TransitionEffect.bounceIn(node: itemContainer, delay: TimeInterval(index) * 0.12)
        }

        // 選択肢（テキスト）を画面下に配置
        setupAnswerOptions(options, startY: size.height * 0.25)
    }

    // MARK: - じゅんばんモード

    /// アイテムを正しい順番にドラッグで並べ替え
    private func presentSequenceOrderQuestion(_ question: GameQuestion) {
        isSequenceMode = true

        let options = question.options
        let itemCount = options.count

        // アイテムをランダムな順番で横一列に表示
        let shuffledOptions = options.shuffled()
        let spacing: CGFloat = size.width / CGFloat(itemCount + 1)

        for (index, option) in shuffledOptions.enumerated() {
            let itemContainer = SKNode()
            itemContainer.position = CGPoint(
                x: spacing * CGFloat(index + 1),
                y: size.height * 0.45
            )
            itemContainer.zPosition = 10
            itemContainer.name = "sequence_item"

            // 角丸四角の背景
            let bgRect = SKShapeNode(rectOf: CGSize(width: 70, height: 70), cornerRadius: 12)
            bgRect.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0)
            bgRect.strokeColor = SKColor(red: 0.78, green: 0.55, blue: 0.33, alpha: 1.0)
            bgRect.lineWidth = 2
            bgRect.name = "sequence_bg"
            itemContainer.addChild(bgRect)

            // アイテムテキスト
            let itemLabel = SKLabelNode(fontNamed: fontName)
            itemLabel.fontSize = 30
            itemLabel.text = option
            itemLabel.horizontalAlignmentMode = .center
            itemLabel.verticalAlignmentMode = .center
            itemLabel.fontColor = SKColor(red: 0.18, green: 0.24, blue: 0.27, alpha: 1.0)
            itemLabel.name = "sequence_label"
            itemContainer.addChild(itemLabel)

            // ユーザーデータにオプション値を格納
            itemContainer.userData = NSMutableDictionary()
            itemContainer.userData?["value"] = option

            addChild(itemContainer)
            itemNodes.append(itemContainer)

            TransitionEffect.bounceIn(node: itemContainer, delay: TimeInterval(index) * 0.12)
        }

        // ドラッグのヒントテキスト
        let hintLabel = SKLabelNode(fontNamed: fontName)
        hintLabel.fontSize = 18
        hintLabel.fontColor = SKColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1.0)
        hintLabel.text = "ドラッグしてならべかえよう！"
        hintLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.30)
        hintLabel.horizontalAlignmentMode = .center
        hintLabel.zPosition = 10
        hintLabel.name = "hint_label"
        addChild(hintLabel)
    }

    // MARK: - パターン完成モード

    /// パターンの次を選択
    private func presentPatternCompletionQuestion(_ question: GameQuestion) {
        isSequenceMode = false

        // パターンアイテムを表示
        if let imageName = question.imageName {
            let patternItems = imageName.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            let spacing: CGFloat = size.width / CGFloat(patternItems.count + 2)

            for (index, item) in patternItems.enumerated() {
                let itemLabel = SKLabelNode(fontNamed: fontName)
                itemLabel.fontSize = 40
                itemLabel.text = item
                itemLabel.position = CGPoint(
                    x: spacing * CGFloat(index + 1),
                    y: size.height * 0.52
                )
                itemLabel.horizontalAlignmentMode = .center
                itemLabel.verticalAlignmentMode = .center
                itemLabel.fontColor = SKColor(red: 0.18, green: 0.24, blue: 0.27, alpha: 1.0)
                itemLabel.zPosition = 10
                itemLabel.name = "pattern_item"
                addChild(itemLabel)

                TransitionEffect.slideInFromRight(
                    node: itemLabel,
                    in: self,
                    delay: TimeInterval(index) * 0.15
                )
            }

            // 「?」マーク
            let questionMark = SKLabelNode(fontNamed: fontName)
            questionMark.fontSize = 40
            questionMark.text = "?"
            questionMark.position = CGPoint(
                x: spacing * CGFloat(patternItems.count + 1),
                y: size.height * 0.52
            )
            questionMark.horizontalAlignmentMode = .center
            questionMark.verticalAlignmentMode = .center
            questionMark.fontColor = SKColor(red: 0.85, green: 0.40, blue: 0.20, alpha: 1.0)
            questionMark.zPosition = 10
            questionMark.name = "pattern_item"
            addChild(questionMark)

            // 点滅
            questionMark.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.5),
                SKAction.fadeAlpha(to: 1.0, duration: 0.5),
            ])))
        }

        // 選択肢を配置
        setupAnswerOptions(question.options, startY: size.height * 0.28)
    }

    // MARK: - 選択肢配置

    /// 選択肢ノードを配置
    private func setupAnswerOptions(_ options: [String], startY: CGFloat) {
        let optionSize = CGSize(width: size.width * 0.38, height: 65)
        let centerX = size.width / 2
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

        // じゅんばんモード: ドラッグ開始
        if isSequenceMode {
            if let itemNode = findSequenceItemAtLocation(location) {
                draggedNode = itemNode
                dragStartPosition = itemNode.position
                itemNode.zPosition = 100
                itemNode.run(SKAction.scale(to: 1.15, duration: 0.1))
                return
            }
        }

        handleTap(at: location)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isSequenceMode, let draggedNode = draggedNode else { return }
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        draggedNode.position = location
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleDragEnd()
    }
    #else
    // MARK: - マウス処理（macOS）

    public override func mouseDown(with event: NSEvent) {
        guard gameState.isInteractive else { return }

        let location = event.location(in: self)

        // じゅんばんモード: ドラッグ開始
        if isSequenceMode {
            if let itemNode = findSequenceItemAtLocation(location) {
                draggedNode = itemNode
                dragStartPosition = itemNode.position
                itemNode.zPosition = 100
                itemNode.run(SKAction.scale(to: 1.15, duration: 0.1))
                return
            }
        }

        handleTap(at: location)
    }

    public override func mouseDragged(with event: NSEvent) {
        guard isSequenceMode, let draggedNode = draggedNode else { return }

        let location = event.location(in: self)
        draggedNode.position = location
    }

    public override func mouseUp(with event: NSEvent) {
        handleDragEnd()
    }
    #endif

    // MARK: - 共通処理

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

    /// ドラッグ終了処理
    private func handleDragEnd() {
        guard isSequenceMode, let draggedNode = draggedNode else { return }

        draggedNode.run(SKAction.scale(to: 1.0, duration: 0.1))
        draggedNode.zPosition = 10

        // 近くのノードと位置交換
        if let nearestNode = findNearestSequenceNode(to: draggedNode) {
            let targetPos = nearestNode.position
            nearestNode.run(SKAction.move(to: dragStartPosition, duration: 0.2))
            draggedNode.run(SKAction.move(to: targetPos, duration: 0.2))
        } else {
            draggedNode.run(SKAction.move(to: dragStartPosition, duration: 0.2))
        }

        self.draggedNode = nil
    }

    /// 指定位置のシーケンスアイテムを探す
    private func findSequenceItemAtLocation(_ location: CGPoint) -> SKNode? {
        let touchedNodes = nodes(at: location)
        for node in touchedNodes {
            if let itemNode = findSequenceItemNode(from: node) {
                return itemNode
            }
        }
        return nil
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

    /// タッチされたノードからシーケンスアイテムを探す
    private func findSequenceItemNode(from node: SKNode) -> SKNode? {
        if node.name == "sequence_item" {
            return node
        }
        if let parent = node.parent {
            return findSequenceItemNode(from: parent)
        }
        return nil
    }

    /// 最も近いシーケンスノードを探す
    private func findNearestSequenceNode(to node: SKNode) -> SKNode? {
        var nearest: SKNode?
        var minDistance: CGFloat = CGFloat.greatestFiniteMagnitude

        for itemNode in itemNodes {
            guard itemNode !== node, itemNode.name == "sequence_item" else { continue }

            let distance = hypot(
                node.position.x - itemNode.position.x,
                node.position.y - itemNode.position.y
            )

            if distance < minDistance && distance < 80 {
                minDistance = distance
                nearest = itemNode
            }
        }

        return nearest
    }

    /// アイテムノードをクリア
    private func clearItemNodes() {
        for node in itemNodes {
            node.removeFromParent()
        }
        itemNodes.removeAll()

        enumerateChildNodes(withName: "pattern_item") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "hint_label") { node, _ in
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
