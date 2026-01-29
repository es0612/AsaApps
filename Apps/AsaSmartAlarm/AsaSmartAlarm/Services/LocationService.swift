//
//  LocationService.swift
//  AsaSmartAlarm
//
//  位置情報サービス
//

import Foundation
import CoreLocation

// MARK: - 位置情報サービス

/// 位置情報の取得と管理を行うサービス
@MainActor
final class LocationService: NSObject, ObservableObject {
    // MARK: - Properties

    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isLocationEnabled: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var cityName: String?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // MARK: - Initializer

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus
        updateLocationEnabledStatus()
    }

    // MARK: - Public Methods

    /// 位置情報の権限をリクエスト
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 現在地を取得
    func requestCurrentLocation() {
        guard isLocationEnabled else {
            errorMessage = "位置情報のアクセス許可が必要です"
            return
        }

        isLoading = true
        errorMessage = nil
        locationManager.requestLocation()
    }

    /// 座標から都市名を取得
    func fetchCityName(for location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.locality ?? placemarks.first?.administrativeArea
        } catch {
            print("🌍 逆ジオコーディングエラー: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Private Methods

    private func updateLocationEnabledStatus() {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationEnabled = true
            errorMessage = nil
        case .denied, .restricted:
            isLocationEnabled = false
            errorMessage = "位置情報へのアクセスが拒否されています。設定から許可してください。"
        case .notDetermined:
            isLocationEnabled = false
            errorMessage = nil
        @unknown default:
            isLocationEnabled = false
            errorMessage = "不明な位置情報の状態です"
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            self.isLoading = false
            self.errorMessage = nil

            // 都市名を取得
            if let name = await self.fetchCityName(for: location) {
                self.cityName = name
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.isLoading = false

            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.errorMessage = "位置情報へのアクセスが拒否されています"
                case .locationUnknown:
                    self.errorMessage = "位置情報を特定できませんでした"
                default:
                    self.errorMessage = "位置情報の取得に失敗しました"
                }
            } else {
                self.errorMessage = error.localizedDescription
            }

            print("🌍 位置情報エラー: \(error.localizedDescription)")
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        Task { @MainActor in
            self.authorizationStatus = status
            self.updateLocationEnabledStatus()

            // 権限が許可された場合、自動的に位置情報を取得
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.requestCurrentLocation()
            }
        }
    }
}

// MARK: - Preview Support

extension LocationService {
    /// プレビュー用の位置情報（東京駅）
    static var preview: LocationService {
        let service = LocationService()
        // プレビュー用にモックデータをセット
        return service
    }

    /// 東京の座標を取得
    static var tokyoLocation: CLLocation {
        CLLocation(latitude: 35.6762, longitude: 139.6503)
    }
}
