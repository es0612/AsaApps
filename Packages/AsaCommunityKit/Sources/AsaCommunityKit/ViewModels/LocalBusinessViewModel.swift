import Foundation

// MARK: - LocalBusinessViewModel

/// 地域店舗のViewModel
///
/// 店舗一覧、カテゴリフィルタ、検索、お気に入り管理を行う。
@MainActor @Observable
public final class LocalBusinessViewModel {
    // MARK: - Dependencies

    private let dataService: CommunityDataServiceProtocol

    // MARK: - Properties

    public var businesses: [LocalBusiness] = []
    public var selectedCategory: BusinessCategory?
    public var searchText: String = ""
    public var showFavoritesOnly: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(dataService: CommunityDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Computed Properties

    /// カテゴリ・検索テキスト・お気に入りでフィルタされた店舗一覧
    public var filteredBusinesses: [LocalBusiness] {
        var result = businesses

        // カテゴリフィルタ
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // お気に入りフィルタ
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        // 検索テキストフィルタ
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.businessDescription.lowercased().contains(query) ||
                $0.address.lowercased().contains(query)
            }
        }

        return result
    }

    // MARK: - Methods

    /// 店舗一覧を取得する
    public func loadBusinesses() {
        isLoading = true
        errorMessage = nil
        do {
            businesses = try dataService.fetchBusinesses(category: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// お気に入りを切り替える
    public func toggleFavorite(_ business: LocalBusiness) {
        errorMessage = nil
        do {
            try dataService.toggleFavorite(business)
            // ローカルの状態も反映
            business.isFavorite.toggle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
