import SwiftUI

struct ContentView: View {
    @StateObject private var calculator = Calculator()
    @Environment(\.colorScheme) var colorScheme

    let buttons: [[String]] = [
        ["C", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["0", ".", "="]
    ]

    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                .opacity(colorScheme == .dark ? 0.9 : 0.1)
                .ignoresSafeArea()
            Color(colorScheme == .dark ? "AsaSoftCream" : "AsaDarkSlate")
                .opacity(colorScheme == .dark ? 0.2 : 0.8)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Text("AsaCalculator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                // 表示エリア
                Text(calculator.display)
                    .font(.system(size: 60))
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)

                // ボタングリッド
                VStack(spacing: 10) {
                    ForEach(buttons, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(row, id: \.self) { button in
                                Button(action: {
                                    calculator.input(button)
                                }) {
                                    Text(button)
                                        .font(.title)
                                        .frame(maxWidth: button == "0" ? .infinity : 80, maxHeight: 80)
                                        .background(buttonColor(for: button))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
    }

    // ボタンの色を決定
    private func buttonColor(for button: String) -> Color {
        switch button {
        case "C", "±", "%":
            return Color.gray
        case "+", "-", "×", "÷", "=":
            return Color("AsaMocha")
        default:
            return Color("AsaCoffeeBrown")
        }
    }
}

#Preview {
    ContentView()
}
