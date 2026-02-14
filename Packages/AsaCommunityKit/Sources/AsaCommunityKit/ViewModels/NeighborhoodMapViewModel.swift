import Foundation
import CoreLocation

// MARK: - NeighborhoodMapViewModel

/// 近隣マップのViewModel
///
/// 投稿・イベント・店舗・避難所を地図上に表示し、
/// 位置情報サービスと連携してフィルタリングする。
@MainActor @Observable
public final class NeighborhoodMapViewModel {
    // MARK: - Dependencies

    private let dataService: CommunityDataServiceProtocol
    private let locationService: LocationServiceProtocol

    // MARK: - Properties

    public var posts: [CommunityPost] = []
    public var events: [CommunityEvent] = []
    public var businesses: [LocalBusiness] = []
    public var shelters: [EvacuationShelter] = []
    public var showPosts: Bool = true
    public var showEvents: Bool = true
    public var showBusinesses: Bool = true
    public var showShelters: Bool = false
    public var radiusMeters: Double = 1000
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        dataService: CommunityDataServiceProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.dataService = dataService
        self.locationService = locationService
    }

    // MARK: - Computed Properties

    /// 位置情報が付与された投稿のみ
    public var filteredPosts: [CommunityPost] {
        posts.filter { $0.hasLocation }
    }

    // MARK: - Methods

    /// マップ表示用の全データを取得する
    public func loadMapData() {
        isLoading = true
        errorMessage = nil
        do {
            posts = try dataService.fetchPosts(category: nil)
            events = try dataService.fetchEvents(includePast: false)
            businesses = try dataService.fetchBusinesses(category: nil)
            shelters = try dataService.fetchShelters()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 位置情報の利用許可をリクエストする
    public func requestLocationPermission() {
        locationService.requestAuthorization()
        locationService.startUpdatingLocation()
    }
}
