import SwiftUI

struct WeatherCard: View {
    let weather: WeatherData
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text(weather.weatherDescription)
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                
                Spacer()
                
                Image(systemName: weather.weatherIconName)
                    .font(.system(size: 40))
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(weather.temperatureString)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text(weather.feelsLikeString)
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 12) {
                    WeatherDetailRow(
                        icon: "thermometer",
                        title: "最高/最低",
                        value: "\(Int(weather.main.tempMax))°/\(Int(weather.main.tempMin))°"
                    )
                    
                    WeatherDetailRow(
                        icon: "wind",
                        title: "風速",
                        value: weather.windSpeedString
                    )
                    
                    WeatherDetailRow(
                        icon: "humidity",
                        title: "湿度",
                        value: weather.humidityString
                    )
                }
            }
        }
        .padding()
        .background(Color("AsaSoftCream").opacity(0.3))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct WeatherDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(Color("AsaMutedSage"))
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
        }
    }
}

struct ForecastCard: View {
    let forecast: DailyForecast
    
    var body: some View {
        VStack(spacing: 8) {
            Text(forecast.dayOfWeek)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaMutedSage"))
            
            Image(systemName: forecast.weatherIconName)
                .font(.title2)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text(forecast.temperatureString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
        .padding()
        .background(Color("AsaSoftCream").opacity(0.2))
        .cornerRadius(12)
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    let onSearch: (String) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("AsaMutedSage"))
            
            TextField("都市名を検索", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    onSearch(searchText)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            Button("検索") {
                let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedText.isEmpty {
                    onSearch(trimmedText)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color("AsaCoffeeBrown"))
            .cornerRadius(6)
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color("AsaSoftCream").opacity(0.3))
        .cornerRadius(10)
    }
}

#Preview {
    VStack {
        WeatherCard(weather: WeatherData(
            name: "Tokyo",
            main: WeatherData.Main(
                temp: 25.0,
                feelsLike: 28.0,
                tempMin: 20.0,
                tempMax: 30.0,
                pressure: 1013,
                humidity: 65
            ),
            weather: [WeatherData.Weather(
                id: 800,
                main: "Clear",
                description: "晴れ",
                icon: "01d"
            )],
            wind: WeatherData.Wind(speed: 3.5, deg: 180),
            sys: WeatherData.Sys(country: "JP", sunrise: 1234567890, sunset: 1234567890)
        ))
        
        HStack {
            ForecastCard(forecast: DailyForecast(
                date: Date(),
                maxTemp: 25,
                minTemp: 18,
                weatherIconName: "sun.max.fill",
                description: "晴れ"
            ))
            
            ForecastCard(forecast: DailyForecast(
                date: Date(),
                maxTemp: 22,
                minTemp: 16,
                weatherIconName: "cloud.fill",
                description: "曇り"
            ))
        }
    }
    .padding()
    .background(Color("AsaDarkSlate").opacity(0.1))
}