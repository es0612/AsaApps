import SwiftUI

struct ContentView: View {
    @State private var viewModel = NumberGameViewModel()
    @State private var guess: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image("AsaPapaLabLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .shadow(radius: 1)

                    VStack(spacing: 5) {
                        Text("1〜100を当ててみて！")
                            .font(.title2.weight(.medium))
                            .foregroundColor(.asaCoffeeBrown)
                        
                        Text("ベストスコア: \(viewModel.bestScore == 999 ? "-" : "\(viewModel.bestScore)回")")
                            .font(.caption)
                            .foregroundColor(.asaMutedSage)
                    }

                    AsaCard {
                        VStack(spacing: 10) {
                            TextField("数字を入力", text: $guess)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .background(Color.asaSoftCreamDark)
                                .cornerRadius(8)

                            AsaButton(
                                title: "推測",
                                action: {
                                    if let number = Int(guess) {
                                        viewModel.makeGuess(number)
                                        guess = ""
                                    }
                                },
                                color: .asaCoffeeBrown,
                                isEnabled: !guess.isEmpty && !viewModel.gameOver
                            )

                            Text(viewModel.hint)
                                .font(.body)
                                .foregroundColor(.asaMutedSage)
                                .multilineTextAlignment(.center)
                            
                            if viewModel.gameOver {
                                AsaButton(
                                    title: "もう一度挑戦",
                                    action: {
                                        viewModel.resetGame()
                                        guess = ""
                                    },
                                    color: .asaMocha
                                )
                                .padding(.top, 10)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Number Game")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
