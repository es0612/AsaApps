import SwiftUI

struct ContentView: View {
    @State private var viewModel = NumberGameViewModel()
    @State private var guess: String = ""
    @State private var showCelebration = false
    @FocusState private var isInputFocused: Bool

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
                                .focused($isInputFocused)
                                .disabled(viewModel.gameOver)
                                .padding()
                                .background(Color.asaSoftCreamDark)
                                .cornerRadius(8)
                                .onChange(of: guess) { _, newValue in
                                    if !newValue.isEmpty {
                                        viewModel.errorMessage = ""
                                    }
                                }

                            AsaButton(
                                title: "推測",
                                action: {
                                    if viewModel.validateInput(guess) {
                                        if let number = Int(guess) {
                                            viewModel.makeGuess(number)
                                            guess = ""
                                        }
                                    }
                                },
                                color: .asaCoffeeBrown,
                                isEnabled: !guess.isEmpty && !viewModel.gameOver
                            )
                            .onChange(of: viewModel.winner) { _, newValue in
                                if newValue {
                                    showCelebration = true
                                }
                            }
                            
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 5)
                            }

                            Text(viewModel.hint)
                                .font(.body)
                                .foregroundColor(viewModel.winner ? .asaCoffeeBrown : .asaMutedSage)
                                .fontWeight(viewModel.winner ? .bold : .regular)
                                .multilineTextAlignment(.center)
                                .scaleEffect(showCelebration ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true), value: showCelebration)
                            
                            if viewModel.winner {
                                HStack {
                                    Text("🎉")
                                        .font(.title)
                                        .scaleEffect(showCelebration ? 1.3 : 1.0)
                                        .animation(.easeInOut(duration: 0.5).repeatCount(5, autoreverses: true), value: showCelebration)
                                    
                                    Text("おめでとう！")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.asaCoffeeBrown)
                                    
                                    Text("🎉")
                                        .font(.title)
                                        .scaleEffect(showCelebration ? 1.3 : 1.0)
                                        .animation(.easeInOut(duration: 0.5).repeatCount(5, autoreverses: true), value: showCelebration)
                                }
                                .padding(.top, 5)
                            }
                            
                            if viewModel.gameOver {
                                AsaButton(
                                    title: "もう一度挑戦",
                                    action: {
                                        viewModel.resetGame()
                                        guess = ""
                                        showCelebration = false
                                        isInputFocused = true
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
