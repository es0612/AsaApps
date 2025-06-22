import SwiftUI

struct TurnIndicatorView: View {
    @Binding var viewModel: TicTacToeViewModel

    var body: some View {
        if viewModel.gameOver {
            Text("ゲーム終了: \(viewModel.winner ?? "エラー")")
                .font(.body.weight(.medium))
                .foregroundColor(.black)
        } else {
            Text("ターン: \(viewModel.currentPlayer)")
                .font(.body.weight(.medium))
                .foregroundColor(.black)
        }
    }
}

struct TurnIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        TurnIndicatorView(viewModel: .constant(TicTacToeViewModel()))
    }
}
