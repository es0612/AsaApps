import Observation
import SwiftUI

@Observable
class TicTacToeViewModel {
    var board: [String?] = Array(repeating: nil, count: 9)
    var currentPlayer: String = "X"
    var gameOver: Bool = false
    var winner: String? = nil

    func makeMove(at index: Int) {
        guard !gameOver, board[index] == nil else { return }
        board[index] = currentPlayer
        checkWinner()
        if !gameOver {
            currentPlayer = currentPlayer == "X" ? "O" : "X"
        }
    }

    private func checkWinner() {
        let winningCombinations = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // 行
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // 列
            [0, 4, 8], [2, 4, 6]             // 対角線
        ]
        for combination in winningCombinations {
            if let first = board[combination[0]],
               first == board[combination[1]],
               first == board[combination[2]] {
                gameOver = true
                winner = first
                return
            }
        }
        if !board.contains(nil) {
            gameOver = true
            winner = "Draw"
        }
    }

    func resetGame() {
        board = Array(repeating: nil, count: 9)
        currentPlayer = "X"
        gameOver = false
        winner = nil
    }
}
