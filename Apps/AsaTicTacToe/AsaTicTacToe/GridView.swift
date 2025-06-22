import SwiftUI

struct GridView: View {
    @Binding var viewModel: TicTacToeViewModel

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 2) {
            ForEach(0..<9, id: \.self) { index in
                Button(action: {
                    viewModel.makeMove(at: index)
                }) {
                    Text(viewModel.board[index] ?? "")
                        .font(.system(size: 40))
                        .frame(width: 100, height: 100) // 各マスのサイズを固定
                        .background(Color.asaSoftCreamDark)
                        .foregroundColor(.black)
                }
                .disabled(viewModel.board[index] != nil || viewModel.gameOver)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(width: 300, height: 300) // 元のサイズに戻す
        .background(Color.asaSoftCream)
        .cornerRadius(10)
    }
}

struct GridView_Previews: PreviewProvider {
    static var previews: some View {
        GridView(viewModel: .constant(TicTacToeViewModel()))
    }
}
