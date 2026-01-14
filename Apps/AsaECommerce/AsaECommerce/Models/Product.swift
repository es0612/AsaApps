import Foundation

struct Product: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let originalPrice: Double?
    let imageURL: String
    let categoryId: UUID
    let stockQuantity: Int
    let rating: Double
    let reviewCount: Int
    let tags: [String]
    let createdAt: Date

    // MARK: - Computed Properties

    var isOnSale: Bool {
        originalPrice != nil && originalPrice! > price
    }

    var discountPercentage: Int? {
        guard let original = originalPrice, original > price else { return nil }
        return Int(((original - price) / original) * 100)
    }

    var isInStock: Bool {
        stockQuantity > 0
    }

    var formattedPrice: String {
        "¥\(Int(price).formatted())"
    }

    var formattedOriginalPrice: String? {
        guard let original = originalPrice else { return nil }
        return "¥\(Int(original).formatted())"
    }

    // MARK: - Mock Data

    static func mock(
        id: UUID = UUID(),
        name: String = "テスト商品",
        price: Double = 1000
    ) -> Product {
        Product(
            id: id,
            name: name,
            description: "テスト商品の説明",
            price: price,
            originalPrice: nil,
            imageURL: "photo",
            categoryId: Category.defaultCategories[1].id,
            stockQuantity: 10,
            rating: 4.5,
            reviewCount: 100,
            tags: ["テスト"],
            createdAt: Date()
        )
    }
}
