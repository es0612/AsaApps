import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - ひらがな練習シーン

/// ひらがな練習（よみかた・くみあわせ・かきかた）のSpriteKitシーン
public class HiraganaScene: BaseGameScene {

    // MARK: - Properties

    /// 選択肢ノードの配列
    private var answerNodes: [AnswerOptionNode] = []

    /// ひらがな大文字表示ラベル
    private var hiraganaDisplayLabel: SKLabelNode?

    /// 手書きキャンバス（かきかたモード用）
    private var drawingCanvas: DrawingCanvasNode?

    /// 手書きストロークデータ
    public var drawingPoints: [[CGPoint]] = []

    /// 現在手書きモードかどうか
    private var isDrawingMode: Bool = false

    // MARK: - 問題表示

    public override func presentQuestion(_ question: GameQuestion) {
        super.presentQuestion(question)

        // 前の表示をクリア
        clearAnswerOptions()
        cleanupHiraganaDisplay()
        answerNodes.removeAll()
        drawingPoints.removeAll()

        if question.questionType == .hiraganaWriting {
            presentWritingQuestion(question)
        } else {
            presentReadingQuestion(question)
        }

        gameState = .answering
    }

    // MARK: - よみかた・くみあわせ 表示

    /// 読み方/組み合わせ問題の表示（大きなひらがな + 4つの選択肢）
    private func presentReadingQuestion(_ question: GameQuestion) {
        isDrawingMode = false

        // ひらがなを大きく表示
        let hiraganaLabel = SKLabelNode(fontNamed: fontName)
        hiraganaLabel.fontSize = 80
        hiraganaLabel.fontColor = SKColor(red: 0.18, green: 0.24, blue: 0.27, alpha: 1.0)
        hiraganaLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        hiraganaLabel.horizontalAlignmentMode = .center
        hiraganaLabel.verticalAlignmentMode = .center
        hiraganaLabel.zPosition = 10
        hiraganaLabel.name = "hiragana_display"

        // 問題文からひらがな文字を抽出して表示
        let displayText = extractHiraganaCharacter(from: question.questionText)
        hiraganaLabel.text = displayText
        addChild(hiraganaLabel)
        hiraganaDisplayLabel = hiraganaLabel

        // フェードイン + スケールアニメーション
        hiraganaLabel.setScale(0)
        hiraganaLabel.alpha = 0
        hiraganaLabel.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3),
        ]))

        // 選択肢を横一列で配置（画面下部）
        setupAnswerOptions(question.options, startY: size.height * 0.25)
    }

    // MARK: - かきかた 表示

    /// 書き方問題の表示（お手本 + 手書きキャンバス）
    private func presentWritingQuestion(_ question: GameQuestion) {
        isDrawingMode = true

        // お手本を左側に表示
        let sampleLabel = SKLabelNode(fontNamed: fontName)
        sampleLabel.fontSize = 60
        sampleLabel.fontColor = SKColor(red: 0.55, green: 0.35, blue: 0.17, alpha: 0.6)
        sampleLabel.position = CGPoint(x: size.width * 0.2, y: size.height * 0.50)
        sampleLabel.horizontalAlignmentMode = .center
        sampleLabel.verticalAlignmentMode = .center
        sampleLabel.zPosition = 10
        sampleLabel.name = "hiragana_display"

        let displayText = extractHiraganaCharacter(from: question.questionText)
        sampleLabel.text = displayText
        addChild(sampleLabel)
        hiraganaDisplayLabel = sampleLabel

        // 手書きキャンバスを右側に配置
        let canvasSize = CGSize(width: size.width * 0.5, height: size.width * 0.5)
        let canvas = DrawingCanvasNode(size: canvasSize)
        canvas.position = CGPoint(x: size.width * 0.6, y: size.height * 0.45)
        canvas.zPosition = 10
        addChild(canvas)
        drawingCanvas = canvas

        // 選択肢も表示（読み方の確認）
        if !question.options.isEmpty {
            setupAnswerOptions(question.options, startY: size.height * 0.15)
        }
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
                fontSize: 26
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

        // 手書きモード: キャンバス内のタッチを手書きとして処理
        if isDrawingMode, let canvas = drawingCanvas {
            let canvasLocation = touch.location(in: canvas)
            if canvas.contains(location) {
                canvas.beginStroke(at: canvasLocation)
                return
            }
        }

        handleTap(at: location)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingMode, gameState.isInteractive else { return }
        guard let touch = touches.first, let canvas = drawingCanvas else { return }

        let canvasLocation = touch.location(in: canvas)
        canvas.continueStroke(to: canvasLocation)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingMode, let canvas = drawingCanvas else { return }

        canvas.endStroke()
        drawingPoints = canvas.drawingPoints
    }
    #else
    // MARK: - マウス処理（macOS）

    public override func mouseDown(with event: NSEvent) {
        guard gameState.isInteractive else { return }

        let location = event.location(in: self)

        // 手書きモード: キャンバス内のクリックを手書きとして処理
        if isDrawingMode, let canvas = drawingCanvas {
            let canvasLocation = event.location(in: canvas)
            if canvas.contains(location) {
                canvas.beginStroke(at: canvasLocation)
                return
            }
        }

        handleTap(at: location)
    }

    public override func mouseDragged(with event: NSEvent) {
        guard isDrawingMode, gameState.isInteractive else { return }
        guard let canvas = drawingCanvas else { return }

        let canvasLocation = event.location(in: canvas)
        canvas.continueStroke(to: canvasLocation)
    }

    public override func mouseUp(with event: NSEvent) {
        guard isDrawingMode, let canvas = drawingCanvas else { return }

        canvas.endStroke()
        drawingPoints = canvas.drawingPoints
    }
    #endif

    // MARK: - 共通タップ処理

    /// タップ/クリック位置の処理（選択肢の判定）
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

        // 全選択肢を無効化
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

    /// 問題文からひらがな文字を抽出
    private func extractHiraganaCharacter(from text: String) -> String {
        // 「あ」のような形式からひらがなを抽出
        if let startIndex = text.firstIndex(of: "\u{300C}"),  // 「
           let endIndex = text.firstIndex(of: "\u{300D}")     // 」
        {
            let nextIndex = text.index(after: startIndex)
            return String(text[nextIndex ..< endIndex])
        }
        // 抽出できない場合は問題文全体の最初の文字
        return String(text.prefix(1))
    }

    /// ひらがな表示要素のクリーンアップ
    private func cleanupHiraganaDisplay() {
        hiraganaDisplayLabel?.removeFromParent()
        hiraganaDisplayLabel = nil
        drawingCanvas?.removeFromParent()
        drawingCanvas = nil
        isDrawingMode = false

        enumerateChildNodes(withName: "hiragana_display") { node, _ in
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
