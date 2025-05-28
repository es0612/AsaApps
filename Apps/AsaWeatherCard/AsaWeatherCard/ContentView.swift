import SwiftUI

struct ContentView: View {
    @StateObject private var weatherManager = WeatherManager()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                .opacity(colorScheme == .dark ? 0.9 : 0.1)
                .ignoresSafeArea()
            Color(colorScheme == .dark ? "AsaSoftCream" : "AsaDarkSlate")
                .opacity(colorScheme == .dark ? 0.2 : 0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("AsaWeatherCard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                // 天気カード
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color("AsaDarkSlate").opacity(0.8) : Color.white)
                        .frame(width: 300, height: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        .shadow(radius: 5)

                    VStack(spacing: 10) {
                        Text(weatherManager.weatherData.city)
                            .font(.title)
                            .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                        Image(systemName: weatherManager.weatherData.iconName)
                            .font(.system(size: 50))
                            .foregroundColor(weatherManager.weatherData.condition == "Sunny" ? .yellow : .gray)

                        Text("\(weatherManager.weatherData.temperature)°C")
                            .font(.system(size: 40))
                            .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                        Text(weatherManager.weatherData.condition)
                            .font(.title2)
                            .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream").opacity(0.7) : Color("AsaCoffeeBrown").opacity(0.7))
                    }
                    
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
