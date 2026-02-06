import CoreLocation
import Foundation
import MapKit

// MARK: - 場所検索サービス

/// MKLocalSearchを使った場所検索
public final class LocationSearchService: LocationSearching, @unchecked Sendable {
    public init() {}

    // MARK: - LocationSearching プロトコル

    /// テキストで場所を検索
    /// - Parameters:
    ///   - query: 検索クエリ（住所、店名等）
    ///   - region: 検索の中心座標（nilなら全域）
    /// - Returns: 検索結果の配列
    public func search(
        query: String,
        region: CLLocationCoordinate2D?
    ) async throws -> [LocationSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        if let center = region {
            request.region = MKCoordinateRegion(
                center: center,
                latitudinalMeters: 10_000,
                longitudinalMeters: 10_000
            )
        }

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            return response.mapItems.map { item in
                LocationSearchResult(
                    name: item.name ?? "不明な場所",
                    address: formatAddress(item.placemark),
                    coordinate: item.placemark.coordinate
                )
            }
        } catch {
            throw SmartReminderError.searchFailed(error.localizedDescription)
        }
    }

    // MARK: - 住所フォーマット

    private func formatAddress(_ placemark: MKPlacemark) -> String? {
        var components: [String] = []
        if let state = placemark.administrativeArea { components.append(state) }
        if let city = placemark.locality { components.append(city) }
        if let subLocality = placemark.subLocality { components.append(subLocality) }
        if let thoroughfare = placemark.thoroughfare { components.append(thoroughfare) }
        if let subThoroughfare = placemark.subThoroughfare { components.append(subThoroughfare) }
        return components.isEmpty ? nil : components.joined()
    }
}
