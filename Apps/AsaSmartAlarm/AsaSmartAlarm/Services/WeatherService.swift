//
//  WeatherService.swift
//  AsaSmartAlarm
//
//  Open-Meteo APIを使用した天気サービス
//

import Foundation
import CoreLocation

// MARK: - 天気データ

/// 時間ごとの天気データ
struct HourlyWeatherData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let weatherCode: Int
    let weatherCondition: WeatherCondition

    static func == (lhs: HourlyWeatherData, rhs: HourlyWeatherData) -> Bool {
        lhs.date == rhs.date && lhs.weatherCode == rhs.weatherCode
    }

    var temperatureString: String {
        String(format: "%.0f°", temperature)
    }

    var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H時"
        return formatter.string(from: date)
    }
}

/// 朝の天気予報データ
struct MorningWeatherForecast: Equatable {
    let date: Date
    let location: String?
    let hourlyData: [HourlyWeatherData]
    let dominantCondition: WeatherCondition
    let minTemperature: Double
    let maxTemperature: Double

    /// 朝の天気の要約
    var summary: String {
        let conditionName = dominantCondition.displayName
        return "明日の朝は\(conditionName)、\(temperatureRangeString)"
    }

    /// 温度範囲の表示文字列
    var temperatureRangeString: String {
        String(format: "%.0f°〜%.0f°", minTemperature, maxTemperature)
    }

    /// アラーム調整が推奨されるかどうか
    var shouldAdjustAlarm: Bool {
        switch dominantCondition {
        case .rain, .snow, .thunderstorm, .fog:
            return true
        case .clear, .clouds:
            return false
        }
    }
}

// MARK: - Open-Meteo APIレスポンス

private struct OpenMeteoHourlyResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let hourly: HourlyData

    struct HourlyData: Codable {
        let time: [String]
        let temperature_2m: [Double]
        let weather_code: [Int]
    }
}

// MARK: - 天気サービスエラー

enum WeatherServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noDataAvailable
    case locationRequired

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .decodingError(let error):
            return "データの解析に失敗しました: \(error.localizedDescription)"
        case .noDataAvailable:
            return "天気データが取得できませんでした"
        case .locationRequired:
            return "位置情報が必要です"
        }
    }
}

// MARK: - 天気サービス

/// Open-Meteo APIを使用して天気情報を取得するサービス
final class WeatherService {
    // MARK: - Properties

    static let shared = WeatherService()

    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private let session = URLSession.shared
    private let decoder: JSONDecoder

    // MARK: - Initializer

    private init() {
        decoder = JSONDecoder()
    }

    // MARK: - Public Methods

    /// 指定位置の翌朝（6:00-9:00）の天気を取得
    /// - Parameters:
    ///   - location: 位置情報
    ///   - locationName: 地名（オプション）
    /// - Returns: 朝の天気予報データ
    func fetchMorningWeather(
        for location: CLLocation,
        locationName: String? = nil
    ) async throws -> MorningWeatherForecast {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        print("🌤️ 天気取得開始: lat=\(lat), lon=\(lon)")

        // 翌日の日付を計算
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            throw WeatherServiceError.noDataAvailable
        }

        // Open-Meteo APIリクエスト
        // hourlyパラメータで時間ごとの天気コードと気温を取得
        let urlString = "\(baseURL)?latitude=\(lat)&longitude=\(lon)" +
            "&hourly=temperature_2m,weather_code" +
            "&timezone=auto" +
            "&forecast_days=2"

        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }

        print("🌤️ リクエストURL: \(urlString)")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            print("🌤️ ネットワークエラー: \(error)")
            throw WeatherServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherServiceError.networkError(
                NSError(domain: "WeatherService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "無効なレスポンス"])
            )
        }

        let openMeteoResponse: OpenMeteoHourlyResponse

        do {
            openMeteoResponse = try decoder.decode(OpenMeteoHourlyResponse.self, from: data)
            print("🌤️ レスポンス受信: \(openMeteoResponse.hourly.time.count)時間分のデータ")
        } catch {
            print("🌤️ デコードエラー: \(error)")
            throw WeatherServiceError.decodingError(error)
        }

        // 翌朝6:00-9:00のデータを抽出
        let morningData = extractMorningData(
            from: openMeteoResponse,
            date: tomorrow
        )

        guard !morningData.isEmpty else {
            throw WeatherServiceError.noDataAvailable
        }

        // 最も多い天気条件を判定
        let dominantCondition = determineDominantCondition(from: morningData)

        // 気温の範囲を計算
        let temperatures = morningData.map { $0.temperature }
        let minTemp = temperatures.min() ?? 0
        let maxTemp = temperatures.max() ?? 0

        print("🌤️ 朝の天気: \(dominantCondition.displayName), \(minTemp)°〜\(maxTemp)°")

        return MorningWeatherForecast(
            date: tomorrow,
            location: locationName,
            hourlyData: morningData,
            dominantCondition: dominantCondition,
            minTemperature: minTemp,
            maxTemperature: maxTemp
        )
    }

    /// 現在の天気を取得（簡易版）
    func fetchCurrentWeather(for location: CLLocation) async throws -> WeatherCondition {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        let urlString = "\(baseURL)?latitude=\(lat)&longitude=\(lon)" +
            "&current=weather_code" +
            "&timezone=auto"

        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }

        let (data, _) = try await session.data(from: url)

        struct CurrentWeatherResponse: Codable {
            let current: CurrentData

            struct CurrentData: Codable {
                let weather_code: Int
            }
        }

        let response = try decoder.decode(CurrentWeatherResponse.self, from: data)
        return WeatherCondition.from(weatherCode: response.current.weather_code)
    }

    // MARK: - Private Methods

    /// 翌朝のデータを抽出
    private func extractMorningData(
        from response: OpenMeteoHourlyResponse,
        date: Date
    ) -> [HourlyWeatherData] {
        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]

        // 日付のみのフォーマッター
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        let targetDateString = dayFormatter.string(from: date)

        var morningData: [HourlyWeatherData] = []

        for (index, timeString) in response.hourly.time.enumerated() {
            // 時刻文字列をパース（"2024-01-15T06:00"形式）
            guard timeString.hasPrefix(targetDateString) else { continue }

            // 時刻を抽出（T以降の部分）
            let timePart = timeString.replacingOccurrences(of: "\(targetDateString)T", with: "")
            guard let hour = Int(timePart.prefix(2)) else { continue }

            // 朝の時間帯（6:00-9:00）のみ
            guard hour >= 6 && hour <= 9 else { continue }

            // 日時を作成
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            components.minute = 0

            guard let hourDate = calendar.date(from: components) else { continue }

            let temperature = response.hourly.temperature_2m[index]
            let weatherCode = response.hourly.weather_code[index]
            let condition = WeatherCondition.from(weatherCode: weatherCode)

            morningData.append(HourlyWeatherData(
                date: hourDate,
                temperature: temperature,
                weatherCode: weatherCode,
                weatherCondition: condition
            ))
        }

        return morningData.sorted { $0.date < $1.date }
    }

    /// 最も多い天気条件を判定
    private func determineDominantCondition(from data: [HourlyWeatherData]) -> WeatherCondition {
        var conditionCounts: [WeatherCondition: Int] = [:]

        for hourly in data {
            conditionCounts[hourly.weatherCondition, default: 0] += 1
        }

        // 悪天候を優先（雨、雪、雷雨は少なくても優先）
        let badWeatherConditions: [WeatherCondition] = [.thunderstorm, .snow, .rain, .fog]
        for condition in badWeatherConditions {
            if let count = conditionCounts[condition], count > 0 {
                return condition
            }
        }

        // それ以外は最も多い条件を返す
        return conditionCounts.max(by: { $0.value < $1.value })?.key ?? .clouds
    }
}

// MARK: - Preview Support

extension MorningWeatherForecast {
    /// プレビュー用のサンプルデータ
    static var preview: MorningWeatherForecast {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1

        let hourlyData: [HourlyWeatherData] = (6...9).map { hour in
            var hourComponents = components
            hourComponents.hour = hour
            hourComponents.minute = 0
            let date = calendar.date(from: hourComponents)!

            return HourlyWeatherData(
                date: date,
                temperature: Double.random(in: 5...15),
                weatherCode: 61,  // 雨
                weatherCondition: .rain
            )
        }

        return MorningWeatherForecast(
            date: calendar.date(from: components)!,
            location: "東京",
            hourlyData: hourlyData,
            dominantCondition: .rain,
            minTemperature: 5,
            maxTemperature: 15
        )
    }

    /// 晴れのプレビューデータ
    static var previewClear: MorningWeatherForecast {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1

        let hourlyData: [HourlyWeatherData] = (6...9).map { hour in
            var hourComponents = components
            hourComponents.hour = hour
            hourComponents.minute = 0
            let date = calendar.date(from: hourComponents)!

            return HourlyWeatherData(
                date: date,
                temperature: Double.random(in: 10...20),
                weatherCode: 0,  // 晴れ
                weatherCondition: .clear
            )
        }

        return MorningWeatherForecast(
            date: calendar.date(from: components)!,
            location: "東京",
            hourlyData: hourlyData,
            dominantCondition: .clear,
            minTemperature: 10,
            maxTemperature: 20
        )
    }
}
