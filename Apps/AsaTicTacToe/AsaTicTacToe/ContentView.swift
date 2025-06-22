import SwiftUI

struct ContentView: View {
    @State private var viewModel = TicTacToeViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.asaSoftCream.opacity(0.9), .asaMocha.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    HeaderView()
                    AsaCard {
                        GridView(viewModel: $viewModel)
                    }
                    TurnIndicatorView(viewModel: $viewModel)
                    Button(action: {
                        viewModel.resetGame()
                    }) {
                        Text("リセット")
                            .font(.body.weight(.medium))
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.asaSoftCreamDark)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Tic-Tac-Toe")
            .foregroundColor(.black)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
