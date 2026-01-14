import SwiftUI
import SwiftData
import AsaUIKit

struct CheckoutView: View {
    @Bindable var cartViewModel: CartViewModel
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var checkoutViewModel = CheckoutViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ステップインジケーター
                stepIndicator

                // コンテンツ
                ScrollView {
                    stepContent
                        .padding()
                }

                // ボタン
                bottomButtons
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("ご注文手続き")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if checkoutViewModel.isProcessing {
                    processingOverlay
                }
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(Array(CheckoutStep.allCases.prefix(3).enumerated()), id: \.element) { index, step in
                HStack(spacing: 4) {
                    Circle()
                        .fill(stepColor(for: step))
                        .frame(width: 24, height: 24)
                        .overlay {
                            if checkoutViewModel.currentStep.rawValue > step.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            } else {
                                Text("\(step.rawValue + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(checkoutViewModel.currentStep == step ? .white : AsaColors.darkSlate)
                            }
                        }

                    Text(step.title)
                        .font(.caption)
                        .foregroundColor(stepColor(for: step))
                }

                if index < 2 {
                    Rectangle()
                        .fill(checkoutViewModel.currentStep.rawValue > step.rawValue ? AsaColors.coffeeBrown : AsaColors.mutedSage.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color.white)
    }

    private func stepColor(for step: CheckoutStep) -> Color {
        if checkoutViewModel.currentStep.rawValue > step.rawValue {
            return AsaColors.coffeeBrown
        } else if checkoutViewModel.currentStep == step {
            return AsaColors.coffeeBrown
        } else {
            return AsaColors.mutedSage.opacity(0.5)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch checkoutViewModel.currentStep {
        case .shipping:
            ShippingFormView(address: $checkoutViewModel.shippingAddress)
        case .payment:
            PaymentView(selectedMethod: $checkoutViewModel.selectedPaymentMethod)
        case .confirm:
            OrderConfirmView(
                cartItems: cartViewModel.items,
                shippingAddress: checkoutViewModel.shippingAddress,
                paymentMethod: checkoutViewModel.selectedPaymentMethod,
                totalAmount: cartViewModel.totalAmount,
                shippingFee: cartViewModel.shippingFee
            )
        case .complete:
            orderCompleteView
        }
    }

    // MARK: - Order Complete View

    private var orderCompleteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("ご注文ありがとうございます！")
                .font(.title2.bold())
                .foregroundColor(AsaColors.darkSlate)

            if let order = checkoutViewModel.completedOrder {
                VStack(spacing: 8) {
                    Text("注文番号")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)

                    Text(order.orderNumber)
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                }
                .padding()
                .background(AsaColors.softCream)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text("注文履歴から詳細をご確認いただけます")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                if checkoutViewModel.currentStep != .shipping && checkoutViewModel.currentStep != .complete {
                    Button {
                        checkoutViewModel.previousStep()
                    } label: {
                        Text("戻る")
                            .font(.headline)
                            .foregroundColor(AsaColors.coffeeBrown)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AsaColors.coffeeBrown, lineWidth: 1)
                            )
                    }
                }

                if checkoutViewModel.currentStep == .complete {
                    AsaButton(title: "閉じる") {
                        dismiss()
                        onComplete()
                    }
                } else if checkoutViewModel.currentStep == .confirm {
                    AsaButton(
                        title: "注文を確定する",
                        action: {
                            checkoutViewModel.placeOrder(
                                cartItems: cartViewModel.items,
                                modelContext: modelContext
                            ) {
                                cartViewModel.clearCart()
                            }
                        }
                    )
                } else {
                    AsaButton(
                        title: "次へ",
                        action: {
                            checkoutViewModel.nextStep()
                        },
                        isEnabled: checkoutViewModel.currentStep == .shipping ? checkoutViewModel.canProceedToPayment : true
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("注文処理中...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(AsaColors.darkSlate.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    CheckoutView(cartViewModel: CartViewModel(), onComplete: {})
        .modelContainer(for: Order.self, inMemory: true)
}
