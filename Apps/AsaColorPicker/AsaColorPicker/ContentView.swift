import SwiftUI

struct ContentView: View {
    @State private var red: Double = 0.5
    @State private var green: Double = 0.5
    @State private var blue: Double = 0.5
    @Environment(\.colorScheme) var colorScheme

    var selectedColor: Color {
        Color(red: red, green: green, blue: blue)
    }

    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                .opacity(colorScheme == .dark ? 0.9 : 0.1)
                .ignoresSafeArea()
            Color(colorScheme == .dark ? "AsaSoftCream" : "AsaDarkSlate")
                .opacity(colorScheme == .dark ? 0.2 : 0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("AsaColorPicker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                // カラー表示エリア
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedColor)
                    .frame(width: 200, height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                    .padding()

                // RGB スライダー
                VStack(spacing: 15) {
                    // Red スライダー
                    HStack {
                        Text("Red: \(Int(red * 255))")
                            .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))
                            .frame(width: 100, alignment: .leading)
                        Slider(value: $red, in: 0...1, step: 0.01)
                            .accentColor(.red)
                    }

                    // Green スライダー
                    HStack {
                        Text("Green: \(Int(green * 255))")
                            .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))
                            .frame(width: 100, alignment: .leading)
                        Slider(value: $green, in: 0...1, step: 0.01)
                            .accentColor(.green)
                    }

                    // Blue スライダー
                    HStack {
                        Text("Blue: \(Int(blue * 255))")
                            .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))
                            .frame(width: 100, alignment: .leading)
                        Slider(value: $blue, in: 0...1, step: 0.01)
                            .accentColor(.blue)
                    }
                }
                .padding(.horizontal)

                // RGB 値のテキスト表示
                Text("RGB: (\(Int(red * 255)), \(Int(green * 255)), \(Int(blue * 255)))")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream").opacity(0.7) : Color("AsaCoffeeBrown").opacity(0.7))
                    .padding(.top, 10)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
