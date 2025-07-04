import Foundation

struct WeatherData: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
    let wind: Wind
    let sys: Sys
    
    struct Main: Codable {
        let temp: Double
        let feelsLike: Double
        let tempMin: Double
        let tempMax: Double
        let pressure: Int
        let humidity: Int
        
        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case tempMin = "temp_min"
            case tempMax = "temp_max"
            case pressure
            case humidity
        }
    }
    
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
        let deg: Int?
    }
    
    struct Sys: Codable {
        let country: String
        let sunrise: Int
        let sunset: Int
    }
}

extension WeatherData {
    var temperatureString: String {
        return String(format: "%.0f°C", main.temp)
    }
    
    var feelsLikeString: String {
        return String(format: "体感温度 %.0f°C", main.feelsLike)
    }
    
    var weatherIconName: String {
        switch weather.first?.main.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain":
            return "cloud.rain.fill"
        case "drizzle":
            return "cloud.drizzle.fill"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog":
            return "cloud.fog.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    var weatherDescription: String {
        return weather.first?.description.capitalized ?? "不明"
    }
    
    var windSpeedString: String {
        return String(format: "風速 %.1f m/s", wind.speed)
    }
    
    var humidityString: String {
        return "湿度 \(main.humidity)%"
    }
}

struct ForecastData: Codable {
    let list: [ForecastItem]
    let city: City
    
    struct ForecastItem: Codable {
        let dt: Int
        let main: WeatherData.Main
        let weather: [WeatherData.Weather]
        let wind: WeatherData.Wind
        let dtTxt: String
        
        enum CodingKeys: String, CodingKey {
            case dt
            case main
            case weather
            case wind
            case dtTxt = "dt_txt"
        }
    }
    
    struct City: Codable {
        let id: Int
        let name: String
        let country: String
    }
}

extension ForecastData.ForecastItem {
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(dt))
    }
    
    var temperatureString: String {
        return String(format: "%.0f°C", main.temp)
    }
    
    var weatherIconName: String {
        switch weather.first?.main.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain":
            return "cloud.rain.fill"
        case "drizzle":
            return "cloud.drizzle.fill"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog":
            return "cloud.fog.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}