import Testing
@testable import AsaECommerce

struct CartItemTests {

    @Test("カートアイテムの小計計算が正しい")
    func testSubtotalCalculation() {
        let product = Product.mock(price: 1000)
        let cartItem = CartItem(product: product, quantity: 3)

        #expect(cartItem.subtotal == 3000)
    }

    @Test("カートアイテムの小計フォーマットが正しい")
    func testFormattedSubtotal() {
        let product = Product.mock(price: 1500)
        let cartItem = CartItem(product: product, quantity: 2)

        #expect(cartItem.formattedSubtotal == "¥3,000")
    }

    @Test("カートアイテムが商品情報を正しく保持する")
    func testCartItemStoresProductInfo() {
        let productId = UUID()
        let product = Product(
            id: productId,
            name: "テスト商品",
            description: "説明",
            price: 2000,
            originalPrice: nil,
            imageURL: "test.image",
            categoryId: UUID(),
            stockQuantity: 10,
            rating: 4.5,
            reviewCount: 100,
            tags: [],
            createdAt: Date()
        )

        let cartItem = CartItem(product: product, quantity: 1)

        #expect(cartItem.productId == productId)
        #expect(cartItem.productName == "テスト商品")
        #expect(cartItem.productImageURL == "test.image")
        #expect(cartItem.unitPrice == 2000)
    }
}
