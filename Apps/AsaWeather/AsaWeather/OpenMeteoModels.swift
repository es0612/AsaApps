import Foundation

// Open-Meteo API用のデータモデル
struct OpenMeteoResponse: Codable {
    let latitude: Double
    let longitude: Double
    let current: Current
    let daily: Daily
    
    struct Current: Codable {
        let time: String
        let temperature_2m: Double
        let relative_humidity_2m: Double
        let weather_code: Int
        let wind_speed_10m: Double
    }
    
    struct Daily: Codable {
        let time: [String]
        let weather_code: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }
}

// ジオコーディング用のレスポンス
struct GeocodingResponse: Codable {
    let results: [GeocodingResult]
}

struct GeocodingResult: Codable {
    let id: Int?
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?
}