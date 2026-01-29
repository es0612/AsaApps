//
//  AlarmSettings.swift
//  AsaSmartAlarm
//
//  アプリ全体の設定モデル
//

import Foundation
import SwiftData

// MARK: - アラーム設定

/// アプリ全体の設定を管理
@Model
final class AlarmSettings {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID

    // 通知設定
    var notificationsEnabled: Bool
    var snoozeMinutes: Int          // スヌーズ時間（分）
    var maxSnoozeCount: Int         // 最大スヌーズ回数

    // 天気設定
    var weatherUpdateEnabled: Bool
    var weatherCheckHour: Int       // 天気チェック時刻（時）

    // 位置情報設定
    var useCurrentLocation: Bool
    var savedLatitude: Double?
    var savedLongitude: Double?
    var savedLocationName: String?

    // 表示設定
    var use24HourFormat: Bool
    var showWeatherOnMainScreen: Bool
    var showNextEventOnMainScreen: Bool

    // 作成・更新日時
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    /// スヌーズ時間の表示文字列
    var snoozeDescription: String {
        "\(snoozeMinutes)分"
    }

    /// 天気チェック時刻の表示文字列
    var weatherCheckTimeDescription: String {
        String(format: "%02d:00", weatherCheckHour)
    }

    /// 保存された位置情報があるかどうか
    var hasSavedLocation: Bool {
        savedLatitude != nil && savedLongitude != nil
    }

    // MARK: - Initializer

    init(
        notificationsEnabled: Bool = true,
        snoozeMinutes: Int = 5,
        maxSnoozeCount: Int = 3,
        weatherUpdateEnabled: Bool = true,
        weatherCheckHour: Int = 20,  // 夜8時にチェック
        useCurrentLocation: Bool = true,
        use24HourFormat: Bool = true,
        showWeatherOnMainScreen: Bool = true,
        showNextEventOnMainScreen: Bool = true
    ) {
        self.id = UUID()
        self.notificationsEnabled = notificationsEnabled
        self.snoozeMinutes = snoozeMinutes
        self.maxSnoozeCount = maxSnoozeCount
        self.weatherUpdateEnabled = weatherUpdateEnabled
        self.weatherCheckHour = weatherCheckHour
        self.useCurrentLocation = useCurrentLocation
        self.use24HourFormat = use24HourFormat
        self.showWeatherOnMainScreen = showWeatherOnMainScreen
        self.showNextEventOnMainScreen = showNextEventOnMainScreen
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// 位置情報を保存
    func saveLocation(latitude: Double, longitude: Double, name: String?) {
        savedLatitude = latitude
        savedLongitude = longitude
        savedLocationName = name
        updatedAt = Date()
    }

    /// 位置情報をクリア
    func clearSavedLocation() {
        savedLatitude = nil
        savedLongitude = nil
        savedLocationName = nil
        updatedAt = Date()
    }

    /// 設定をリセット
    func resetToDefaults() {
        notificationsEnabled = true
        snoozeMinutes = 5
        maxSnoozeCount = 3
        weatherUpdateEnabled = true
        weatherCheckHour = 20
        useCurrentLocation = true
        use24HourFormat = true
        showWeatherOnMainScreen = true
        showNextEventOnMainScreen = true
        clearSavedLocation()
        updatedAt = Date()
    }
}

// MARK: - Preview Support

extension AlarmSettings {
    /// プレビュー/デフォルト用の設定
    static var `default`: AlarmSettings {
        AlarmSettings()
    }
}

// MARK: - スヌーズオプション

/// スヌーズ時間の選択肢
enum SnoozeOption: Int, CaseIterable, Identifiable {
    case oneMinute = 1
    case threeMinutes = 3
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue)分"
    }
}

// MARK: - 天気チェック時刻オプション

/// 天気チェック時刻の選択肢
enum WeatherCheckHourOption: Int, CaseIterable, Identifiable {
    case evening18 = 18
    case evening19 = 19
    case evening20 = 20
    case evening21 = 21
    case evening22 = 22

    var id: Int { rawValue }

    var displayName: String {
        String(format: "%02d:00", rawValue)
    }
}
