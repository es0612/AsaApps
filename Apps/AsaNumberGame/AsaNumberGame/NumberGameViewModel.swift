import Observation
import SwiftUI

@Observable
class NumberGameViewModel {
    private var targetNumber = Int.random(in: 1...100)
    var hint: String = "ヒント: 1〜100の数を推測してください"
    var gameOver: Bool = false
    var winner: Bool = false
    var attempts: Int = 0
    var bestScore: Int = UserDefaults.standard.integer(forKey: "bestScore") == 0 ? 999 : UserDefaults.standard.integer(forKey: "bestScore")
    var errorMessage: String = ""

    func makeGuess(_ number: Int) {
        guard !gameOver else { return }
        
        // 入力値の検証
        guard (1...100).contains(number) else {
            errorMessage = "1から100までの数字を入力してください"
            return
        }
        
        errorMessage = ""
        attempts += 1
        
        if number == targetNumber {
            hint = "正解！\(targetNumber)です！\n\(attempts)回で当てました！"
            gameOver = true
            winner = true
            updateBestScore()
        } else if number < targetNumber {
            hint = "低すぎます！もう一度試してください。\n試行回数: \(attempts)"
        } else {
            hint = "高すぎます！もう一度試してください。\n試行回数: \(attempts)"
        }
    }
    
    func validateInput(_ input: String) -> Bool {
        guard let number = Int(input) else {
            errorMessage = "有効な数字を入力してください"
            return false
        }
        guard (1...100).contains(number) else {
            errorMessage = "1から100までの数字を入力してください"
            return false
        }
        errorMessage = ""
        return true
    }
    
    private func updateBestScore() {
        if attempts < bestScore {
            bestScore = attempts
            UserDefaults.standard.set(bestScore, forKey: "bestScore")
        }
    }

    func resetGame() {
        targetNumber = Int.random(in: 1...100)
        hint = "ヒント: 1〜100の数を推測してください"
        gameOver = false
        winner = false
        attempts = 0
        errorMessage = ""
    }
}
