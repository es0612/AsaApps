import Foundation

@MainActor
@Observable
final class ProductViewModel {
    // MARK: - Properties

    private(set) var products: [Product] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var searchText = ""
    var selectedCategory: Category = Category.allCategory
    var sortOption: SortOption = .newest

    // MARK: - Computed Properties

    var filteredProducts: [Product] {
        var result = products

        // カテゴリフィルター
        if selectedCategory.id != Category.allCategory.id {
            result = result.filter { $0.categoryId == selectedCategory.id }
        }

        // 検索フィルター
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // ソート
        switch sortOption {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .priceAsc:
            result.sort { $0.price < $1.price }
        case .priceDesc:
            result.sort { $0.price > $1.price }
        case .rating:
            result.sort { $0.rating > $1.rating }
        }

        return result
    }

    var categories: [Category] {
        Category.defaultCategories
    }

    // MARK: - Initialization

    init() {
        loadProducts()
    }

    // MARK: - Methods

    func loadProducts() {
        isLoading = true
        errorMessage = nil

        guard let url = Bundle.main.url(forResource: "products", withExtension: "json") else {
            errorMessage = "商品データが見つかりません"
            isLoading = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            products = try decoder.decode([Product].self, from: data)
        } catch {
            errorMessage = "商品データの読み込みに失敗しました"
        }

        isLoading = false
    }

    func product(by id: UUID) -> Product? {
        products.first { $0.id == id }
    }

    func clearSearch() {
        searchText = ""
    }

    func resetFilters() {
        selectedCategory = Category.allCategory
        sortOption = .newest
        searchText = ""
    }
}

// MARK: - Sort Option

enum SortOption: String, CaseIterable, Sendable {
    case newest = "newest"
    case priceAsc = "priceAsc"
    case priceDesc = "priceDesc"
    case rating = "rating"

    var displayName: String {
        switch self {
        case .newest: return "新着順"
        case .priceAsc: return "価格が安い順"
        case .priceDesc: return "価格が高い順"
        case .rating: return "評価が高い順"
        }
    }
}
