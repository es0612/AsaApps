import Foundation
import CoreLocation

// MARK: - LocationService

/// CoreLocationラッパーサービス
@MainActor
@Observable
public final class LocationService: NSObject, LocationServiceProtocol {
    /// 現在位置
    public var currentLocation: CLLocation?

    /// 位置情報の利用許可状態
    public var authorizationStatus: CLAuthorizationStatus

    private let locationManager: CLLocationManager

    // MARK: - Init

    public override init() {
        self.locationManager = CLLocationManager()
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - LocationServiceProtocol

    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    public func distance(from: CLLocation, to: CLLocation) -> CLLocationDistance {
        from.distance(from: to)
    }

    public func distanceFromCurrent(latitude: Double, longitude: Double) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: latitude, longitude: longitude)
        return current.distance(from: target)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    /// 位置情報が更新された時
    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = latest
        }
    }

    /// 位置情報の取得に失敗した時
    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // 位置情報エラーはログのみ（UIで別途ハンドリング）
    }

    /// 権限状態が変更された時
    nonisolated public func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}
