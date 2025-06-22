import SwiftUI

struct TurnIndicatorView: View {
    @Binding var viewModel: TicTacToeViewModel

    var body: some View {
        if viewModel.gameOver {
            Text("ゲーム終了: \(viewModel.winner ?? "エラー")")
                .font(.body.weight(.medium))
                .foregroundColor(.asaMutedSage)
        } else {
            Text("ターン: \(viewModel.currentPlayer)")
                .font(.body.weight(.medium))
                .foregroundColor(.asaMutedSage)
        }
    }
}

struct TurnIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        TurnIndicatorView(viewModel: .constant(TicTacToeViewModel()))
    }
}
