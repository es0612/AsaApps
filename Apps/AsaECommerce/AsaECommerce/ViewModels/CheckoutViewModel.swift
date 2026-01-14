import Foundation
import SwiftData

@MainActor
@Observable
final class CheckoutViewModel {
    // MARK: - Properties

    var currentStep: CheckoutStep = .shipping
    var shippingAddress = ShippingAddress()
    var selectedPaymentMethod: PaymentMethod = .creditCard
    var isProcessing = false
    var errorMessage: String?
    var completedOrder: Order?

    // MARK: - Validation

    var isShippingValid: Bool {
        !shippingAddress.fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !shippingAddress.postalCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !shippingAddress.prefecture.isEmpty &&
        !shippingAddress.city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !shippingAddress.addressLine1.trimmingCharacters(in: .whitespaces).isEmpty &&
        !shippingAddress.phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canProceedToPayment: Bool {
        isShippingValid
    }

    var canProceedToConfirm: Bool {
        true
    }

    // MARK: - Navigation

    func nextStep() {
        switch currentStep {
        case .shipping:
            if canProceedToPayment {
                currentStep = .payment
            }
        case .payment:
            if canProceedToConfirm {
                currentStep = .confirm
            }
        case .confirm:
            break
        case .complete:
            break
        }
    }

    func previousStep() {
        switch currentStep {
        case .shipping:
            break
        case .payment:
            currentStep = .shipping
        case .confirm:
            currentStep = .payment
        case .complete:
            break
        }
    }

    // MARK: - Order Processing

    func placeOrder(
        cartItems: [CartItem],
        modelContext: ModelContext,
        onComplete: @escaping () -> Void
    ) {
        isProcessing = true
        errorMessage = nil

        // 模擬的な処理遅延
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            let order = Order(
                cartItems: cartItems,
                shippingAddress: shippingAddress,
                paymentMethod: selectedPaymentMethod
            )

            modelContext.insert(order)

            do {
                try modelContext.save()
                completedOrder = order
                currentStep = .complete
                onComplete()
            } catch {
                errorMessage = "注文の保存に失敗しました"
            }

            isProcessing = false
        }
    }

    // MARK: - Reset

    func reset() {
        currentStep = .shipping
        shippingAddress = ShippingAddress()
        selectedPaymentMethod = .creditCard
        isProcessing = false
        errorMessage = nil
        completedOrder = nil
    }
}

// MARK: - Checkout Step

enum CheckoutStep: Int, CaseIterable, Sendable {
    case shipping = 0
    case payment = 1
    case confirm = 2
    case complete = 3

    var title: String {
        switch self {
        case .shipping: return "配送先"
        case .payment: return "支払い方法"
        case .confirm: return "確認"
        case .complete: return "完了"
        }
    }

    var iconName: String {
        switch self {
        case .shipping: return "shippingbox"
        case .payment: return "creditcard"
        case .confirm: return "checkmark.circle"
        case .complete: return "checkmark.seal.fill"
        }
    }
}
