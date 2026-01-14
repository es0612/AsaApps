import Testing
@testable import AsaECommerce

struct ProductTests {

    @Test("商品が在庫ありの場合isInStockがtrue")
    func testProductInStock() {
        let product = Product(
            id: UUID(),
            name: "テスト商品",
            description: "説明",
            price: 1000,
            originalPrice: nil,
            imageURL: "test",
            categoryId: UUID(),
            stockQuantity: 10,
            rating: 4.5,
            reviewCount: 100,
            tags: [],
            createdAt: Date()
        )

        #expect(product.isInStock == true)
    }

    @Test("在庫がゼロの場合isInStockがfalse")
    func testProductOutOfStock() {
        let product = Product(
            id: UUID(),
            name: "在庫切れ商品",
            description: "説明",
            price: 1000,
            originalPrice: nil,
            imageURL: "test",
            categoryId: UUID(),
            stockQuantity: 0,
            rating: 4.5,
            reviewCount: 100,
            tags: [],
            createdAt: Date()
        )

        #expect(product.isInStock == false)
    }

    @Test("割引率計算が正しい")
    func testDiscountPercentage() {
        let product = Product(
            id: UUID(),
            name: "セール商品",
            description: "説明",
            price: 800,
            originalPrice: 1000,
            imageURL: "test",
            categoryId: UUID(),
            stockQuantity: 5,
            rating: 4.0,
            reviewCount: 50,
            tags: [],
            createdAt: Date()
        )

        #expect(product.isOnSale == true)
        #expect(product.discountPercentage == 20)
    }

    @Test("割引なしの場合isOnSaleがfalse")
    func testNoDiscount() {
        let product = Product(
            id: UUID(),
            name: "通常商品",
            description: "説明",
            price: 1000,
            originalPrice: nil,
            imageURL: "test",
            categoryId: UUID(),
            stockQuantity: 5,
            rating: 4.0,
            reviewCount: 50,
            tags: [],
            createdAt: Date()
        )

        #expect(product.isOnSale == false)
        #expect(product.discountPercentage == nil)
    }

    @Test("価格フォーマットが正しい")
    func testFormattedPrice() {
        let product = Product(
            id: UUID(),
            name: "テスト商品",
            description: "説明",
            price: 1000,
            originalPrice: nil,
            imageURL: "test",
            categoryId: UUID(),
            stockQuantity: 10,
            rating: 4.5,
            reviewCount: 100,
            tags: [],
            createdAt: Date()
        )

        #expect(product.formattedPrice == "¥1,000")
    }
}
