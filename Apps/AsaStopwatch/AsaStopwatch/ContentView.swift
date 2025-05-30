import SwiftUI

struct ContentView: View {
    @State private var stopwatch = Stopwatch()
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
                Text("AsaStopwatch")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                Text(stopwatch.formattedTime())
                    .font(.system(size: 60, design: .monospaced))
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                HStack(spacing: 20) {
                    Button(action: {
                        if stopwatch.isRunning {
                            stopwatch.stop()
                        } else {
                            stopwatch.start()
                        }
                    }) {
                        Text(stopwatch.isRunning ? "停止" : "開始")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 50)
                            .background(stopwatch.isRunning ? Color.red : Color.green)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        stopwatch.reset()
                    }) {
                        Text("リセット")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 50)
                            .background(Color("AsaMocha"))
                            .cornerRadius(10)
                    }
                    .disabled(stopwatch.isRunning)
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
