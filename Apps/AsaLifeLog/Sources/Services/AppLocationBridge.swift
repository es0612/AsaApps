import Foundation
import CoreLocation
import AsaLifeLogKit

// MARK: - AppLocationBridge

/// CoreLocation と AsaLifeLogKit の橋渡しサービス
@MainActor
@Observable
final class AppLocationBridge: NSObject, LocationTrackingServiceProtocol {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    var currentLocation: (latitude: Double, longitude: Double)?
    var authorizationStatus: Int

    override init() {
        self.authorizationStatus = Int(CLLocationManager().authorizationStatus.rawValue)
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestAuthorization() async {
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else {
            throw LifeLogError.locationNotAvailable
        }
        let components = [placemark.locality, placemark.subLocality, placemark.thoroughfare]
        return components.compactMap { $0 }.joined(separator: " ")
    }
}

// MARK: - CLLocationManagerDelegate

extension AppLocationBridge: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = (latitude: latest.coordinate.latitude, longitude: latest.coordinate.longitude)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = Int(manager.authorizationStatus.rawValue)
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}
