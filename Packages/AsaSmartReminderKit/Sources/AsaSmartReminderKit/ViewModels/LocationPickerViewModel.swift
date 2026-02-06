#if os(iOS)
import CoreLocation
import Foundation
import MapKit

// MARK: - 場所選択ViewModel

/// 地図上での場所選択とMKLocalSearch検索を管理
@MainActor
@Observable
public final class LocationPickerViewModel {
    // MARK: - Properties

    public var searchText: String = ""
    public var searchResults: [LocationSearchResult] = []
    public var isSearching: Bool = false

    public var selectedCoordinate: CLLocationCoordinate2D?
    public var selectedName: String = ""
    public var selectedAddress: String?
    public var selectedRadius: Double = 100
    public var selectedCategory: LocationCategory = .custom

    public var cameraRegion: MKCoordinateRegion?
    public var errorMessage: String?

    private let searchService: LocationSearching
    private var searchTask: Task<Void, Never>?

    // MARK: - Init

    public init(searchService: LocationSearching = LocationSearchService()) {
        self.searchService = searchService
    }

    // MARK: - 検索

    /// テキストで場所を検索（デバウンス付き）
    public func search() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        searchTask = Task {
            // 300ms デバウンス
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            do {
                let results = try await searchService.search(
                    query: query,
                    region: selectedCoordinate
                )
                if !Task.isCancelled {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = "検索に失敗: \(error.localizedDescription)"
                    isSearching = false
                }
            }
        }
    }

    // MARK: - 場所選択

    /// 検索結果から場所を選択
    public func selectSearchResult(_ result: LocationSearchResult) {
        selectedCoordinate = result.coordinate
        selectedName = result.name
        selectedAddress = result.address
        searchResults = []
        searchText = ""

        cameraRegion = MKCoordinateRegion(
            center: result.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
    }

    /// 地図タップで場所を選択
    public func selectCoordinate(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        if selectedName.isEmpty {
            selectedName = "選択した場所"
        }
    }

    /// 半径を更新
    public func updateRadius(_ radius: Double) {
        selectedRadius = max(10, min(5000, radius))
    }

    /// 入力が有効かどうか
    public var isValid: Bool {
        selectedCoordinate != nil && !selectedName.isEmpty && selectedRadius >= 10
    }

    /// 選択をリセット
    public func reset() {
        searchText = ""
        searchResults = []
        selectedCoordinate = nil
        selectedName = ""
        selectedAddress = nil
        selectedRadius = 100
        selectedCategory = .custom
        errorMessage = nil
    }

    /// カテゴリ変更時にデフォルト半径を適用
    public func applyDefaultRadius(for category: LocationCategory) {
        selectedCategory = category
        selectedRadius = category.defaultRadius
    }
}
#endif
