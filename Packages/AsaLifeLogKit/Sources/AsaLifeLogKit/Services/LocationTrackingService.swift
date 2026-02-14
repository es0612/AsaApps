import Foundation
import CoreLocation

// MARK: - LocationTrackingService

/// CoreLocation ラッパーサービス
///
/// 位置情報の取得・トラッキング・逆ジオコーディングを提供する。
@MainActor
@Observable
public final class LocationTrackingService: NSObject, LocationTrackingServiceProtocol {
    /// 現在位置
    public var currentLocation: (latitude: Double, longitude: Double)?

    /// 位置情報利用許可状態
    public var authorizationStatus: Int

    private let locationManager: CLLocationManager
    private let geocoder: CLGeocoder

    // MARK: - Init

    public override init() {
        self.locationManager = CLLocationManager()
        self.geocoder = CLGeocoder()
        self.authorizationStatus = Int(locationManager.authorizationStatus.rawValue)
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - LocationTrackingServiceProtocol

    public func requestAuthorization() async {
        locationManager.requestWhenInUseAuthorization()
    }

    public func startTracking() {
        locationManager.startUpdatingLocation()
    }

    public func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    public func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else {
            throw LifeLogError.locationNotAvailable
        }
        // 住所文字列を組み立てる
        let components = [
            placemark.administrativeArea,
            placemark.locality,
            placemark.subLocality,
            placemark.thoroughfare,
            placemark.subThoroughfare,
        ].compactMap { $0 }
        return components.joined()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationTrackingService: CLLocationManagerDelegate {
    /// 位置情報が更新された時
    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }
        let lat = latest.coordinate.latitude
        let lon = latest.coordinate.longitude
        Task { @MainActor in
            self.currentLocation = (latitude: lat, longitude: lon)
        }
    }

    /// 位置情報の取得に失敗した時
    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // エラーログのみ（UIで別途ハンドリング）
    }

    /// 権限状態が変更された時
    nonisolated public func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        let status = Int(manager.authorizationStatus.rawValue)
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}
