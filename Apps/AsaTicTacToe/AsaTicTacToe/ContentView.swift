import SwiftUI

struct ContentView: View {
    @State private var viewModel = TicTacToeViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    HeaderView()
                    AsaCard {
                        GridView(viewModel: viewModel)
                    }
                    TurnIndicatorView(viewModel: viewModel)
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Tic-Tac-Toe")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
