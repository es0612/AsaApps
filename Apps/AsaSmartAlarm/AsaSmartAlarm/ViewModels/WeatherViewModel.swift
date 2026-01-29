//
//  WeatherViewModel.swift
//  AsaSmartAlarm
//
//  天気情報管理のViewModel
//

import Foundation
import CoreLocation

// MARK: - 天気ViewModel

/// 天気情報の取得と管理を行うViewModel
@MainActor
@Observable
final class WeatherViewModel {
    // MARK: - Properties

    private(set) var morningForecast: MorningWeatherForecast?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var lastUpdated: Date?

    // Services
    private let weatherService = WeatherService.shared
    private let locationService: LocationService

    // MARK: - Computed Properties

    /// 天気データが利用可能かどうか
    var hasWeatherData: Bool {
        morningForecast != nil
    }

    /// 更新からの経過時間
    var timeSinceLastUpdate: String? {
        guard let lastUpdated = lastUpdated else { return nil }

        let interval = Date().timeIntervalSince(lastUpdated)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "たった今"
        } else if minutes < 60 {
            return "\(minutes)分前"
        } else {
            let hours = minutes / 60
            return "\(hours)時間前"
        }
    }

    /// アラーム調整が推奨されるかどうか
    var shouldAdjustAlarm: Bool {
        morningForecast?.shouldAdjustAlarm ?? false
    }

    // MARK: - Initializer

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    // MARK: - Public Methods

    /// 天気を取得
    func fetchWeather() async {
        // 位置情報を確認
        guard locationService.isLocationEnabled else {
            errorMessage = "位置情報の許可が必要です"
            return
        }

        // 位置情報がまだない場合はリクエスト
        if locationService.currentLocation == nil {
            locationService.requestCurrentLocation()
            // 少し待つ
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }

        guard let location = locationService.currentLocation else {
            errorMessage = "位置情報を取得できませんでした"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let forecast = try await weatherService.fetchMorningWeather(
                for: location,
                locationName: locationService.cityName
            )
            morningForecast = forecast
            lastUpdated = Date()

            print("🌤️ 天気取得完了: \(forecast.dominantCondition.displayName)")
        } catch {
            errorMessage = "天気の取得に失敗しました"
            print("🌤️ エラー: \(error)")
        }

        isLoading = false
    }

    /// デフォルト位置（東京）で天気を取得
    func fetchWeatherForDefaultLocation() async {
        isLoading = true
        errorMessage = nil

        let tokyoLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)

        do {
            let forecast = try await weatherService.fetchMorningWeather(
                for: tokyoLocation,
                locationName: "東京"
            )
            morningForecast = forecast
            lastUpdated = Date()

            print("🌤️ デフォルト天気取得完了: \(forecast.dominantCondition.displayName)")
        } catch {
            errorMessage = "天気の取得に失敗しました"
            print("🌤️ エラー: \(error)")
        }

        isLoading = false
    }

    /// 天気を更新（位置情報があれば現在地、なければ東京）
    func refreshWeather() async {
        if locationService.isLocationEnabled && locationService.currentLocation != nil {
            await fetchWeather()
        } else {
            await fetchWeatherForDefaultLocation()
        }
    }

    /// エラーをクリア
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Preview Support

extension WeatherViewModel {
    /// プレビュー用のViewModel
    static var preview: WeatherViewModel {
        let viewModel = WeatherViewModel(locationService: LocationService())
        viewModel.morningForecast = .preview
        viewModel.lastUpdated = Date()
        return viewModel
    }

    /// 晴れのプレビュー用ViewModel
    static var previewClear: WeatherViewModel {
        let viewModel = WeatherViewModel(locationService: LocationService())
        viewModel.morningForecast = .previewClear
        viewModel.lastUpdated = Date()
        return viewModel
    }
}
