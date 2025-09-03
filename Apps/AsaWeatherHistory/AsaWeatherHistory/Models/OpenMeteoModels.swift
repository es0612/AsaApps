import Foundation

// Open-Meteo API用のデータモデル
struct OpenMeteoResponse: Codable {
    let latitude: Double
    let longitude: Double
    let generationtime_ms: Double
    let utc_offset_seconds: Int
    let timezone: String
    let timezone_abbreviation: String
    let elevation: Double
    let current_units: CurrentUnits?  // Optionalに変更
    let current: Current?             // Optionalに変更
    let daily_units: DailyUnits
    let daily: Daily
    
    struct CurrentUnits: Codable {
        let time: String
        let interval: String
        let temperature_2m: String
        let relative_humidity_2m: String
        let weather_code: String
        let wind_speed_10m: String
    }
    
    struct Current: Codable {
        let time: String
        let interval: Int
        let temperature_2m: Double
        let relative_humidity_2m: Double
        let weather_code: Int
        let wind_speed_10m: Double
    }
    
    struct DailyUnits: Codable {
        let time: String
        let weather_code: String
        let temperature_2m_max: String
        let temperature_2m_min: String
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