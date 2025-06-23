import Observation
import SwiftUI

@Observable
class NumberGameViewModel {
    private var targetNumber = Int.random(in: 1...100)
    var hint: String = "ヒント: 1〜100の数を推測してください"
    var gameOver: Bool = false
    var winner: Bool = false

    func makeGuess(_ number: Int) {
        guard !gameOver, (1...100).contains(number) else { return }
        if number == targetNumber {
            hint = "正解！\(targetNumber)です！"
            gameOver = true
            winner = true
        } else if number < targetNumber {
            hint = "低すぎます！もう一度試してください。"
        } else {
            hint = "高すぎます！もう一度試してください。"
        }
    }

    func resetGame() {
        targetNumber = Int.random(in: 1...100)
        hint = "ヒント: 1〜100の数を推測してください"
        gameOver = false
        winner = false
    }
}
