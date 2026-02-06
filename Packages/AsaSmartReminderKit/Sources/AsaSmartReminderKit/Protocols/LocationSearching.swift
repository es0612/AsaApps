import CoreLocation
import Foundation

// MARK: - 場所検索プロトコル

/// 場所検索結果
public struct LocationSearchResult: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let address: String?
    public let coordinate: CLLocationCoordinate2D

    public init(
        id: UUID = UUID(),
        name: String,
        address: String?,
        coordinate: CLLocationCoordinate2D
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
    }
}

/// 場所検索のインターフェース（テスト用モック注入可能）
public protocol LocationSearching: Sendable {
    /// テキストで場所を検索
    func search(query: String, region: CLLocationCoordinate2D?) async throws -> [LocationSearchResult]
}
