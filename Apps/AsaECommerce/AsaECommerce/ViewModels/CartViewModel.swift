import Foundation

@MainActor
@Observable
final class CartViewModel {
    // MARK: - Properties

    private(set) var items: [CartItem] = []
    private let userDefaultsKey = "AsaECommerce.Cart"

    var showingCheckout = false
    var toastMessage: String?

    // MARK: - Computed Properties

    var totalAmount: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }

    var formattedTotalAmount: String {
        "¥\(Int(totalAmount).formatted())"
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    var shippingFee: Double {
        isEmpty ? 0 : 500
    }

    var formattedShippingFee: String {
        "¥\(Int(shippingFee).formatted())"
    }

    var grandTotal: Double {
        totalAmount + shippingFee
    }

    var formattedGrandTotal: String {
        "¥\(Int(grandTotal).formatted())"
    }

    // MARK: - Initialization

    init() {
        loadCart()
    }

    // MARK: - Cart Operations

    func addToCart(product: Product, quantity: Int = 1) {
        if let index = items.firstIndex(where: { $0.productId == product.id }) {
            items[index].quantity += quantity
        } else {
            let item = CartItem(product: product, quantity: quantity)
            items.append(item)
        }
        saveCart()
        toastMessage = "\(product.name)をカートに追加しました"
    }

    func removeFromCart(item: CartItem) {
        items.removeAll { $0.id == item.id }
        saveCart()
    }

    func removeFromCart(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveCart()
    }

    func updateQuantity(itemId: UUID, quantity: Int) {
        guard quantity > 0 else {
            items.removeAll { $0.id == itemId }
            saveCart()
            return
        }

        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].quantity = quantity
            saveCart()
        }
    }

    func clearCart() {
        items.removeAll()
        saveCart()
    }

    func clearToast() {
        toastMessage = nil
    }

    // MARK: - Persistence

    private func saveCart() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadCart() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([CartItem].self, from: data) {
            items = decoded
        }
    }
}
