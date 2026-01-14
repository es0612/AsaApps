import Foundation
import SwiftData

@Model
final class Order {
    @Attribute(.unique) var id: UUID
    var orderNumber: String
    var itemsData: Data
    var subtotal: Double
    var shippingFee: Double
    var totalAmount: Double
    var statusRawValue: String
    var shippingAddressData: Data
    var paymentMethodRawValue: String
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    var status: OrderStatus {
        get { OrderStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRawValue) ?? .creditCard }
        set { paymentMethodRawValue = newValue.rawValue }
    }

    var items: [OrderItem] {
        get {
            (try? JSONDecoder().decode([OrderItem].self, from: itemsData)) ?? []
        }
        set {
            itemsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var shippingAddress: ShippingAddressData {
        get {
            (try? JSONDecoder().decode(ShippingAddressData.self, from: shippingAddressData)) ?? ShippingAddressData.empty
        }
        set {
            shippingAddressData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var formattedTotalAmount: String {
        "¥\(Int(totalAmount).formatted())"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: createdAt)
    }

    // MARK: - Initializer

    init(
        cartItems: [CartItem],
        shippingAddress: ShippingAddress,
        paymentMethod: PaymentMethod
    ) {
        let calculatedSubtotal = cartItems.reduce(0) { $0 + $1.subtotal }
        let calculatedShippingFee: Double = 500

        self.id = UUID()
        self.orderNumber = Order.generateOrderNumber()
        self.itemsData = (try? JSONEncoder().encode(cartItems.map { OrderItem(from: $0) })) ?? Data()
        self.subtotal = calculatedSubtotal
        self.shippingFee = calculatedShippingFee
        self.totalAmount = calculatedSubtotal + calculatedShippingFee
        self.statusRawValue = OrderStatus.pending.rawValue
        self.shippingAddressData = (try? JSONEncoder().encode(ShippingAddressData(from: shippingAddress))) ?? Data()
        self.paymentMethodRawValue = paymentMethod.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    private static func generateOrderNumber() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let randomSuffix = String(format: "%04d", Int.random(in: 0...9999))
        return "ASA-\(dateFormatter.string(from: Date()))-\(randomSuffix)"
    }
}

// MARK: - Supporting Types

enum OrderStatus: String, CaseIterable, Codable, Sendable {
    case pending = "pending"
    case confirmed = "confirmed"
    case shipped = "shipped"
    case delivered = "delivered"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .pending: return "処理中"
        case .confirmed: return "確認済み"
        case .shipped: return "発送済み"
        case .delivered: return "配達完了"
        case .cancelled: return "キャンセル"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .shipped: return "shippingbox"
        case .delivered: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

enum PaymentMethod: String, CaseIterable, Codable, Sendable {
    case creditCard = "creditCard"
    case bankTransfer = "bankTransfer"
    case cashOnDelivery = "cashOnDelivery"

    var displayName: String {
        switch self {
        case .creditCard: return "クレジットカード"
        case .bankTransfer: return "銀行振込"
        case .cashOnDelivery: return "代金引換"
        }
    }

    var iconName: String {
        switch self {
        case .creditCard: return "creditcard"
        case .bankTransfer: return "building.columns"
        case .cashOnDelivery: return "yensign.circle"
        }
    }
}

struct OrderItem: Codable, Sendable {
    let productId: UUID
    let productName: String
    let unitPrice: Double
    let quantity: Int
    let subtotal: Double

    init(from cartItem: CartItem) {
        self.productId = cartItem.productId
        self.productName = cartItem.productName
        self.unitPrice = cartItem.unitPrice
        self.quantity = cartItem.quantity
        self.subtotal = cartItem.subtotal
    }
}

struct ShippingAddressData: Codable, Sendable {
    let fullName: String
    let postalCode: String
    let prefecture: String
    let city: String
    let addressLine1: String
    let addressLine2: String?
    let phoneNumber: String

    init(from address: ShippingAddress) {
        self.fullName = address.fullName
        self.postalCode = address.postalCode
        self.prefecture = address.prefecture
        self.city = address.city
        self.addressLine1 = address.addressLine1
        self.addressLine2 = address.addressLine2
        self.phoneNumber = address.phoneNumber
    }

    static var empty: ShippingAddressData {
        ShippingAddressData(from: ShippingAddress())
    }
}
