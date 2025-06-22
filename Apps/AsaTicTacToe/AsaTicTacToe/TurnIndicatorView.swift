import SwiftUI

struct TurnIndicatorView: View {
    @State var viewModel: TicTacToeViewModel

    var body: some View {
        Text("ターン: \(viewModel.currentPlayer)")
            .font(.body.weight(.medium))
            .foregroundColor(.asaMutedSage)
    }
}

struct TurnIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        TurnIndicatorView(viewModel: TicTacToeViewModel())
    }
}
