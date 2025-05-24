import SwiftUI

struct ContentView: View {
    @State private var diceNumber: Int = 1
    @State private var isRolling: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                .opacity(colorScheme == .dark ? 0.9 : 0.1)
                .ignoresSafeArea()
            Color(colorScheme == .dark ? "AsaSoftCream" : "AsaDarkSlate")
                .opacity(colorScheme == .dark ? 0.2 : 0.8)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("AsaDice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                // サイコロ表示
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 100, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        .shadow(radius: 5)

                    Text("\(diceNumber)")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.black)
                        .rotationEffect(.degrees(isRolling ? 360 : 0))
                        .scaleEffect(isRolling ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: isRolling)
                }

                // 振るボタン
                Button(action: rollDice) {
                    Text("サイコロを振る")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("AsaMocha"))
                        .cornerRadius(10)
                }
                .disabled(isRolling)

                Spacer()
            }
            .padding()
        }
    }

    // サイコロを振る
    private func rollDice() {
        isRolling = true
        // 振るアニメーション中にランダムな数字を高速で更新（演出）
        for _ in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.1...0.3)) {
                diceNumber = Int.random(in: 1...6)
            }
        }
        // 最終的な数字を確定
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            diceNumber = Int.random(in: 1...6)
            isRolling = false
        }
    }
}

#Preview {
    ContentView()
}
