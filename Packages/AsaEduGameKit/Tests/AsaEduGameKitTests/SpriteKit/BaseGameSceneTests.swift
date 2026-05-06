import Testing
import SpriteKit
@testable import AsaEduGameKit

// MARK: - BaseGameScene ライフサイクル競合テスト
//
// SwiftUI の SpriteView がシーンをマウントする前に
// presentQuestion(_:) が呼ばれてもクラッシュしないことを保証する。
// （IUO ノード `questionLabel!` 等の早期アクセスによる
//  Fatal error: Unexpectedly found nil ... の回帰防止）

@MainActor
@Suite("BaseGameScene シーン準備状態テスト")
struct BaseGameSceneTests {

    private let sceneSize = CGSize(width: 400, height: 600)

    private func sampleQuestion(text: String = "1+1=?") -> GameQuestion {
        GameQuestion(
            questionType: .addition,
            questionText: text,
            options: ["1", "2", "3", "4"],
            correctAnswer: "2"
        )
    }

    @Test("didMove 前の presentQuestion はクラッシュせずキューに退避される")
    func presentQuestionBeforeDidMoveQueues() {
        let scene = MathQuizScene(size: sceneSize)
        let question = sampleQuestion()

        // didMove 未実行の状態で呼ぶ → 旧実装ではここで nil unwrap クラッシュ
        scene.presentQuestion(question)

        // この時点では未反映（保留中）
        #expect(scene.currentQuestion == nil)
    }

    @Test("didMove 後にキューが反映され currentQuestion が更新される")
    func didMoveDrainsPendingQuestion() {
        let scene = MathQuizScene(size: sceneSize)
        let question = sampleQuestion(text: "1+1=?")

        scene.presentQuestion(question)
        scene.didMove(to: SKView())

        #expect(scene.currentQuestion?.questionText == "1+1=?")
    }

    @Test("didMove 後の presentQuestion は即時反映される（restart 経路）")
    func presentQuestionAfterDidMoveAppliesImmediately() {
        let scene = MathQuizScene(size: sceneSize)
        scene.didMove(to: SKView())

        let question = sampleQuestion(text: "2+3=?")
        scene.presentQuestion(question)

        #expect(scene.currentQuestion?.questionText == "2+3=?")
    }
}
