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

                    Text("1〜100を当ててみて！")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)

                    AsaCard {
                        VStack(spacing: 10) {
                            TextField("数字を入力", text: $guess)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .background(Color.asaSoftCreamDark)
                                .cornerRadius(8)

                            Button(action: {
                                if let number = Int(guess) {
                                    viewModel.makeGuess(number)
                                    guess = ""
                                }
                            }) {
                                Text("推測")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(.asaCoffeeBrown)
                                    .padding()
                                    .background(Color.asaSoftCreamDark)
                                    .cornerRadius(10)
                            }
                            .disabled(guess.isEmpty)

                            Text(viewModel.hint)
                                .font(.body)
                                .foregroundColor(.asaMutedSage)
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
