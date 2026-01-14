import Foundation

struct CartItem: Identifiable, Codable, Sendable {
    let id: UUID
    let productId: UUID
    let productName: String
    let productImageURL: String
    let unitPrice: Double
    var quantity: Int
    let addedAt: Date

    // MARK: - Computed Properties

    var subtotal: Double {
        unitPrice * Double(quantity)
    }

    var formattedSubtotal: String {
        "¥\(Int(subtotal).formatted())"
    }

    var formattedUnitPrice: String {
        "¥\(Int(unitPrice).formatted())"
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        productId: UUID,
        productName: String,
        productImageURL: String,
        unitPrice: Double,
        quantity: Int = 1,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.productImageURL = productImageURL
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.addedAt = addedAt
    }

    init(product: Product, quantity: Int = 1) {
        self.id = UUID()
        self.productId = product.id
        self.productName = product.name
        self.productImageURL = product.imageURL
        self.unitPrice = product.price
        self.quantity = quantity
        self.addedAt = Date()
    }
}
