import Foundation
@testable import AsaLifeLogKit

// MARK: - MockLocationService

/// テスト用のモック位置情報サービス
@MainActor
final class MockLocationService: LocationTrackingServiceProtocol {
    var currentLocation: (latitude: Double, longitude: Double)?
    var authorizationStatus: Int = 0
    var reverseGeocodeResult: String = "東京都 渋谷区"
    var shouldThrowError = false

    func requestAuthorization() async {
        authorizationStatus = 3 // authorizedWhenInUse
    }

    func startTracking() {
        // no-op
    }

    func stopTracking() {
        // no-op
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        if shouldThrowError { throw LifeLogError.locationNotAvailable }
        return reverseGeocodeResult
    }
}
