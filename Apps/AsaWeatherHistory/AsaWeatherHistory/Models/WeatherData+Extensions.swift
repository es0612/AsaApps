import Foundation
import CoreData

// 既存のWeatherDataをそのまま利用（AsaWeatherから）
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

// MARK: - WeatherData Extensions for Display
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
    
    var pressureString: String {
        return "気圧 \(main.pressure) hPa"
    }
}

// MARK: - Core Data Extensions
extension WeatherData {
    /// Core DataのWeatherRecordから WeatherDataを作成
    init(from record: WeatherRecord) {
        self.name = record.locationName ?? "不明な場所"
        
        self.main = Main(
            temp: record.temperature,
            feelsLike: record.feelsLikeTemperature,
            tempMin: record.minTemperature,
            tempMax: record.maxTemperature,
            pressure: Int(record.pressure),
            humidity: Int(record.humidity)
        )
        
        self.weather = [Weather(
            id: Int(record.weatherCode),
            main: record.weatherMain ?? "Unknown",
            description: record.weatherDescription ?? "不明",
            icon: ""
        )]
        
        self.wind = Wind(
            speed: record.windSpeed,
            deg: Int(record.windDirection)
        )
        
        self.sys = Sys(
            country: record.country ?? "JP",
            sunrise: Int(record.sunrise?.timeIntervalSince1970 ?? 0),
            sunset: Int(record.sunset?.timeIntervalSince1970 ?? 0)
        )
    }
    
    /// WeatherDataをCore DataのWeatherRecordに保存
    func saveToRecord(context: NSManagedObjectContext, location: (latitude: Double, longitude: Double)) -> WeatherRecord {
        // WeatherRecord.createを使用して、createdAtとupdatedAtが自動的に設定される
        let record = WeatherRecord.create(in: context)
        
        record.recordDate = Date()
        record.locationName = name
        record.latitude = location.latitude
        record.longitude = location.longitude
        record.country = sys.country
        
        // 天気情報
        record.temperature = main.temp
        record.feelsLikeTemperature = main.feelsLike
        record.minTemperature = main.tempMin
        record.maxTemperature = main.tempMax
        record.pressure = Int32(main.pressure)
        record.humidity = Int32(main.humidity)
        
        // 天気状況
        record.weatherCode = Int32(weather.first?.id ?? 0)
        record.weatherMain = weather.first?.main
        record.weatherDescription = weather.first?.description
        
        // 風情報
        record.windSpeed = wind.speed
        record.windDirection = Int32(wind.deg ?? 0)
        
        // 日の出・日の入り
        if sys.sunrise > 0 {
            record.sunrise = Date(timeIntervalSince1970: TimeInterval(sys.sunrise))
        }
        if sys.sunset > 0 {
            record.sunset = Date(timeIntervalSince1970: TimeInterval(sys.sunset))
        }
        
        return record
    }
}

// MARK: - Data Analysis Extensions
extension WeatherData {
    /// 天気タイプの分類
    enum WeatherType: String, CaseIterable {
        case sunny = "晴れ"
        case cloudy = "曇り"
        case rainy = "雨"
        case snowy = "雪"
        case stormy = "嵐"
        case foggy = "霧"
        case unknown = "不明"
        
        init(from weatherData: WeatherData) {
            switch weatherData.weather.first?.main.lowercased() {
            case "clear":
                self = .sunny
            case "clouds":
                self = .cloudy
            case "rain", "drizzle":
                self = .rainy
            case "snow":
                self = .snowy
            case "thunderstorm":
                self = .stormy
            case "mist", "fog":
                self = .foggy
            default:
                self = .unknown
            }
        }
    }
    
    var weatherType: WeatherType {
        return WeatherType(from: self)
    }
    
    /// 気温に基づく体感分類
    enum TemperatureFeeling: String, CaseIterable {
        case veryCold = "極寒"     // < 0°C
        case cold = "寒い"         // 0-10°C
        case cool = "涼しい"       // 10-20°C
        case comfortable = "快適"   // 20-25°C
        case warm = "暖かい"       // 25-30°C
        case hot = "暑い"          // 30-35°C
        case veryHot = "猛暑"      // > 35°C
        
        init(temperature: Double) {
            switch temperature {
            case ..<0:
                self = .veryCold
            case 0..<10:
                self = .cold
            case 10..<20:
                self = .cool
            case 20..<25:
                self = .comfortable
            case 25..<30:
                self = .warm
            case 30..<35:
                self = .hot
            default:
                self = .veryHot
            }
        }
    }
    
    var temperatureFeeling: TemperatureFeeling {
        return TemperatureFeeling(temperature: main.temp)
    }
}