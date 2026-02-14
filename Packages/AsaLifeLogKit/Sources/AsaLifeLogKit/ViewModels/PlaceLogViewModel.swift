import Foundation

// MARK: - PlaceLogViewModel

/// 場所ログ表示のViewModel
///
/// 訪問場所一覧、お気に入り切り替え、場所の詳細表示を管理する。
@MainActor @Observable
public final class PlaceLogViewModel {
    // MARK: - Dependencies

    private let dataService: any LifeLogDataServiceProtocol

    // MARK: - Properties

    public var places: [PlaceLog] = []
    public var selectedPlace: PlaceLog?
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Init

    public init(dataService: any LifeLogDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Computed Properties

    /// お気に入りの場所のみ
    public var favoritePlaces: [PlaceLog] {
        places.filter { $0.isFavorite }
    }

    /// カテゴリ別にグループ化
    public var placesByCategory: [PlaceCategory: [PlaceLog]] {
        Dictionary(grouping: places) { $0.category }
    }

    // MARK: - Methods

    /// 場所ログを読み込む
    public func loadPlaces() async {
        isLoading = true
        errorMessage = nil
        do {
            places = try await dataService.fetchPlaces()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// お気に入りを切り替える
    public func toggleFavorite(_ place: PlaceLog) async {
        errorMessage = nil
        place.isFavorite.toggle()
        do {
            try await dataService.savePlaceLog(place)
        } catch {
            // ロールバック
            place.isFavorite.toggle()
            errorMessage = error.localizedDescription
        }
    }

    /// 場所を選択する
    public func selectPlace(_ place: PlaceLog) {
        selectedPlace = place
    }

    /// 場所の選択を解除する
    public func clearSelection() {
        selectedPlace = nil
    }
}
