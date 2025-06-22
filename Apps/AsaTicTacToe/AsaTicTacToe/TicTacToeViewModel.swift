import Observation
import SwiftUI

@Observable
class TicTacToeViewModel {
    var board: [String?] = Array(repeating: nil, count: 9)
    var currentPlayer: String = "X"
    
    func makeMove(at index: Int) {
        guard board[index] == nil else { return }
        board[index] = currentPlayer
        currentPlayer = currentPlayer == "X" ? "O" : "X"
    }
}
