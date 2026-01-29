//
//  WeatherCondition.swift
//  AsaSmartAlarm
//
//  天気条件の定義
//

import Foundation
import SwiftUI

// MARK: - 天気条件

/// Open-Meteo APIの天気コードに対応した天気条件
enum WeatherCondition: String, Codable, CaseIterable, Identifiable {
    case clear = "clear"           // 晴れ
    case clouds = "clouds"         // 曇り
    case rain = "rain"             // 雨
    case snow = "snow"             // 雪
    case thunderstorm = "thunderstorm" // 雷雨
    case fog = "fog"               // 霧

    var id: String { rawValue }

    // MARK: - 表示名

    var displayName: String {
        switch self {
        case .clear: return "晴れ"
        case .clouds: return "曇り"
        case .rain: return "雨"
        case .snow: return "雪"
        case .thunderstorm: return "雷雨"
        case .fog: return "霧"
        }
    }

    // MARK: - アイコン

    var iconName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .clouds: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .fog: return "cloud.fog.fill"
        }
    }

    // MARK: - カラー

    var color: Color {
        switch self {
        case .clear: return .orange
        case .clouds: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .fog: return .gray.opacity(0.7)
        }
    }

    // MARK: - デフォルトの調整時間（分）

    /// この天気条件でのデフォルト調整時間（正=早める、負=遅らせる）
    var defaultAdjustmentMinutes: Int {
        switch self {
        case .clear: return 0          // 晴れは調整なし
        case .clouds: return 0         // 曇りは調整なし
        case .rain: return 15          // 雨は15分早める
        case .snow: return 30          // 雪は30分早める
        case .thunderstorm: return 20  // 雷雨は20分早める
        case .fog: return 10           // 霧は10分早める
        }
    }

    // MARK: - Open-Meteo天気コードからの変換

    /// Open-Meteo APIの天気コードからWeatherConditionに変換
    /// 参考: https://open-meteo.com/en/docs
    static func from(weatherCode: Int) -> WeatherCondition {
        switch weatherCode {
        case 0, 1:
            // 0: Clear sky, 1: Mainly clear
            return .clear
        case 2, 3:
            // 2: Partly cloudy, 3: Overcast
            return .clouds
        case 45, 48:
            // 45: Fog, 48: Depositing rime fog
            return .fog
        case 51, 53, 55, 56, 57:
            // Drizzle
            return .rain
        case 61, 63, 65, 66, 67:
            // Rain
            return .rain
        case 71, 73, 75, 77:
            // Snow fall
            return .snow
        case 80, 81, 82:
            // Rain showers
            return .rain
        case 85, 86:
            // Snow showers
            return .snow
        case 95, 96, 99:
            // Thunderstorm
            return .thunderstorm
        default:
            return .clouds
        }
    }
}

// MARK: - 条件タイプ

/// 調整ルールの条件タイプ
enum ConditionType: String, Codable, CaseIterable {
    case weather = "weather"   // 天気条件
    case event = "event"       // イベント条件

    var displayName: String {
        switch self {
        case .weather: return "天気"
        case .event: return "予定"
        }
    }

    var iconName: String {
        switch self {
        case .weather: return "cloud.sun.fill"
        case .event: return "calendar"
        }
    }
}
