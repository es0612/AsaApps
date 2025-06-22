import SwiftUI

struct GridView: View {
    @State var viewModel: TicTacToeViewModel

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 2) {
            ForEach(0..<9, id: \.self) { index in
                Button(action: {
                    viewModel.makeMove(at: index)
                }) {
                    Text(viewModel.board[index] ?? "")
                        .font(.system(size: 40))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.asaSoftCreamDark)
                        .foregroundColor(.asaCoffeeBrown)
                }
                .disabled(viewModel.board[index] != nil)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(width: 300, height: 300)
        .background(Color.asaSoftCream)
        .cornerRadius(10)
    }
}

struct GridView_Previews: PreviewProvider {
    static var previews: some View {
        GridView(viewModel: TicTacToeViewModel())
    }
}
