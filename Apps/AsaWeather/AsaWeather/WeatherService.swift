import Foundation
import CoreLocation

class WeatherService: ObservableObject {
    private let baseURL = "https://api.open-meteo.com/v1"
    private let geocodingURL = "https://geocoding-api.open-meteo.com/v1"
    private let session = URLSession.shared
    
    func fetchWeather(for location: CLLocation) async throws -> WeatherData {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        print("🌐 WeatherService: Fetching weather for \(lat), \(lon)")
        
        // 現在の天気と予報を取得
        let weatherURL = "\(baseURL)/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto"
        
        print("🌐 WeatherService: API URL: \(weatherURL)")
        
        // 都市名を取得
        let cityName = await getCityName(for: location)
        print("🌐 WeatherService: City name: \(cityName)")
        
        guard let url = URL(string: weatherURL) else {
            print("🌐 WeatherService: Invalid URL")
            throw WeatherError.invalidURL
        }
        
        print("🌐 WeatherService: Making API request...")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }
        
        do {
            let openMeteoResponse = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            print("🌐 WeatherService: Successfully decoded API response")
            print("🌐 WeatherService: Converting to WeatherData...")
            let weatherData = convertToWeatherData(openMeteoResponse, cityName: cityName)
            print("🌐 WeatherService: Successfully converted to WeatherData")
            return weatherData
        } catch {
            print("🌐 WeatherService: Decoding error: \(error)")
            // デバッグ用：レスポンスの内容を出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("🌐 WeatherService: API Response: \(responseString)")
            }
            throw WeatherError.decodingError
        }
    }
    
    func fetchWeather(for cityName: String) async throws -> WeatherData {
        // まず都市の座標を取得
        let coordinates = try await getCoordinates(for: cityName)
        
        // 座標を使って天気を取得
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        return try await fetchWeather(for: location)
    }
    
    func fetchForecast(for location: CLLocation) async throws -> ForecastData {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        print("🌐 WeatherService: Fetching forecast for \(lat), \(lon)")
        
        let forecastURL = "\(baseURL)/forecast?latitude=\(lat)&longitude=\(lon)&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=7"
        
        print("🌐 WeatherService: Forecast URL: \(forecastURL)")
        
        guard let url = URL(string: forecastURL) else {
            print("🌐 WeatherService: Invalid forecast URL")
            throw WeatherError.invalidURL
        }
        
        print("🌐 WeatherService: Making forecast API request...")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("🌐 WeatherService: Invalid forecast response")
            throw WeatherError.invalidResponse
        }
        
        do {
            let openMeteoResponse = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            print("🌐 WeatherService: Successfully decoded forecast API response")
            let cityName = await getCityName(for: location)
            print("🌐 WeatherService: Converting to ForecastData...")
            let forecastData = convertToForecastData(openMeteoResponse, cityName: cityName)
            print("🌐 WeatherService: Successfully converted to ForecastData")
            return forecastData
        } catch {
            print("🌐 WeatherService: Forecast decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🌐 WeatherService: Forecast API Response: \(responseString)")
            }
            throw WeatherError.decodingError
        }
    }
    
    private func getCoordinates(for cityName: String) async throws -> (latitude: Double, longitude: Double) {
        let encodedCity = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cityName
        let geocodingURLString = "\(geocodingURL)/search?name=\(encodedCity)&count=1&language=ja&format=json"
        
        guard let url = URL(string: geocodingURLString) else {
            throw WeatherError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }
        
        do {
            let geocodingResponse = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            guard let location = geocodingResponse.results.first else {
                throw WeatherError.invalidResponse
            }
            return (location.latitude, location.longitude)
        } catch {
            throw WeatherError.decodingError
        }
    }
    
    private func getCityName(for location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.locality ?? "不明な場所"
        } catch {
            return "不明な場所"
        }
    }
    
    private func convertToWeatherData(_ response: OpenMeteoResponse, cityName: String) -> WeatherData {
        print("🌐 WeatherService: Starting convertToWeatherData")
        print("🌐 WeatherService: City name: \(cityName)")
        
        let current = response.current
        let weatherCode = current.weather_code
        let description = getWeatherDescription(for: weatherCode)
        
        print("🌐 WeatherService: Current temperature: \(current.temperature_2m)")
        print("🌐 WeatherService: Weather code: \(weatherCode)")
        print("🌐 WeatherService: Daily temps count: \(response.daily.temperature_2m_max.count)")
        
        let tempMin = response.daily.temperature_2m_min.first ?? current.temperature_2m
        let tempMax = response.daily.temperature_2m_max.first ?? current.temperature_2m
        
        print("🌐 WeatherService: Temp min: \(tempMin), max: \(tempMax)")
        
        let weatherData = WeatherData(
            name: cityName,
            main: WeatherData.Main(
                temp: current.temperature_2m,
                feelsLike: current.temperature_2m, // Open-Meteoには体感温度がないので同じ値を使用
                tempMin: tempMin,
                tempMax: tempMax,
                pressure: 1013, // デフォルト値
                humidity: Int(current.relative_humidity_2m)
            ),
            weather: [WeatherData.Weather(
                id: weatherCode,
                main: getWeatherMain(for: weatherCode),
                description: description,
                icon: ""
            )],
            wind: WeatherData.Wind(
                speed: current.wind_speed_10m,
                deg: nil
            ),
            sys: WeatherData.Sys(
                country: "JP",
                sunrise: 0,
                sunset: 0
            )
        )
        
        print("🌐 WeatherService: WeatherData created successfully")
        return weatherData
    }
    
    private func convertToForecastData(_ response: OpenMeteoResponse, cityName: String) -> ForecastData {
        print("🌐 WeatherService: Starting convertToForecastData")
        print("🌐 WeatherService: City name: \(cityName)")
        
        let daily = response.daily
        var forecastItems: [ForecastData.ForecastItem] = []
        
        print("🌐 WeatherService: Daily times count: \(daily.time.count)")
        print("🌐 WeatherService: Daily weather codes count: \(daily.weather_code.count)")
        print("🌐 WeatherService: Daily max temps count: \(daily.temperature_2m_max.count)")
        print("🌐 WeatherService: Daily min temps count: \(daily.temperature_2m_min.count)")
        
        for (index, date) in daily.time.enumerated() {
            guard index < daily.weather_code.count,
                  index < daily.temperature_2m_max.count,
                  index < daily.temperature_2m_min.count else { 
                print("🌐 WeatherService: Skipping index \(index) due to array bounds")
                continue 
            }
            
            let weatherCode = daily.weather_code[index]
            let maxTemp = daily.temperature_2m_max[index]
            let minTemp = daily.temperature_2m_min[index]
            
            print("🌐 WeatherService: Processing day \(index): \(date), temp: \(minTemp)-\(maxTemp), code: \(weatherCode)")
            
            let item = ForecastData.ForecastItem(
                dt: Int(Date().timeIntervalSince1970) + (index * 86400),
                main: WeatherData.Main(
                    temp: (maxTemp + minTemp) / 2,
                    feelsLike: (maxTemp + minTemp) / 2,
                    tempMin: minTemp,
                    tempMax: maxTemp,
                    pressure: 1013,
                    humidity: 50
                ),
                weather: [WeatherData.Weather(
                    id: weatherCode,
                    main: getWeatherMain(for: weatherCode),
                    description: getWeatherDescription(for: weatherCode),
                    icon: ""
                )],
                wind: WeatherData.Wind(speed: 0, deg: nil),
                dtTxt: date
            )
            forecastItems.append(item)
        }
        
        print("🌐 WeatherService: Created \(forecastItems.count) forecast items")
        
        let forecastData = ForecastData(
            list: forecastItems,
            city: ForecastData.City(id: 0, name: cityName, country: "JP")
        )
        
        print("🌐 WeatherService: ForecastData created successfully")
        return forecastData
    }
    
    private func getWeatherMain(for code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2, 3: return "Clouds"
        case 45, 48: return "Mist"
        case 51, 53, 55, 56, 57: return "Drizzle"
        case 61, 63, 65, 66, 67: return "Rain"
        case 71, 73, 75, 77: return "Snow"
        case 80, 81, 82: return "Rain"
        case 85, 86: return "Snow"
        case 95, 96, 99: return "Thunderstorm"
        default: return "Unknown"
        }
    }
    
    private func getWeatherDescription(for code: Int) -> String {
        switch code {
        case 0: return "快晴"
        case 1: return "晴れ"
        case 2: return "やや曇り"
        case 3: return "曇り"
        case 45: return "霧"
        case 48: return "着氷霧"
        case 51: return "弱い霧雨"
        case 53: return "霧雨"
        case 55: return "強い霧雨"
        case 56, 57: return "着氷霧雨"
        case 61: return "弱い雨"
        case 63: return "雨"
        case 65: return "強い雨"
        case 66, 67: return "着氷雨"
        case 71: return "弱い雪"
        case 73: return "雪"
        case 75: return "強い雪"
        case 77: return "みぞれ"
        case 80: return "弱いにわか雨"
        case 81: return "にわか雨"
        case 82: return "強いにわか雨"
        case 85: return "弱いにわか雪"
        case 86: return "にわか雪"
        case 95: return "雷雨"
        case 96: return "弱い雹を伴う雷雨"
        case 99: return "雹を伴う雷雨"
        default: return "不明"
        }
    }
}

enum WeatherError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .decodingError:
            return "データの解析に失敗しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .apiKeyMissing:
            return "APIキーが設定されていません"
        }
    }
}

extension WeatherService {
    static let shared = WeatherService()
}