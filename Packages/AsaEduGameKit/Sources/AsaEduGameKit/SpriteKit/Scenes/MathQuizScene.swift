import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 算数クイズシーン

/// 算数クイズ（たしざん・ひきざん・くらべっこ・あなうめ）のSpriteKitシーン
public class MathQuizScene: BaseGameScene {

    // MARK: - Properties

    /// 選択肢ノードの配列
    private var answerNodes: [AnswerOptionNode] = []

    // MARK: - 問題表示

    public override func presentQuestion(_ question: GameQuestion) {
        super.presentQuestion(question)

        // 前の選択肢をクリア
        clearAnswerOptions()
        answerNodes.removeAll()

        // 選択肢を2x2グリッドで配置（画面下半分）
        let options = question.options
        let optionSize = CGSize(width: size.width * 0.38, height: 70)
        let centerX = size.width / 2
        let startY = size.height * 0.35

        // グリッド間隔
        let horizontalSpacing = optionSize.width + 20
        let verticalSpacing = optionSize.height + 20

        for (index, option) in options.enumerated() {
            let column = index % 2
            let row = index / 2

            let x = centerX + CGFloat(column == 0 ? -1 : 1) * (horizontalSpacing / 2)
            let y = startY - CGFloat(row) * verticalSpacing

            let answerNode = AnswerOptionNode(
                answer: option,
                size: optionSize,
                fontSize: 28
            )
            answerNode.position = CGPoint(x: x, y: y)
            answerNode.zPosition = 10
            addChild(answerNode)

            // 遅延付きバウンスインアニメーション
            answerNode.animateIn(delay: TimeInterval(index) * 0.1)

            answerNodes.append(answerNode)
        }

        // ゲーム状態を回答受付中に変更
        gameState = .answering
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

        // 全選択肢を無効化
        for node in answerNodes {
            node.isEnabled = false
        }

        let isCorrect = selectedNode.answer == question.correctAnswer

        if isCorrect {
            selectedNode.showCorrect()
        } else {
            selectedNode.showIncorrect()
            // 正解を表示
            for node in answerNodes where node.answer == question.correctAnswer {
                node.showCorrect()
            }
        }

        // デリゲートに通知
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

    /// 選択肢クリア（オーバーライド）
    override func clearAnswerOptions() {
        for node in answerNodes {
            node.removeFromParent()
        }
        answerNodes.removeAll()
    }
}
