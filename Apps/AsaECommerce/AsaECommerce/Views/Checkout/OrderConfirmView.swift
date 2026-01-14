import SwiftUI
import AsaUIKit

struct OrderConfirmView: View {
    let cartItems: [CartItem]
    let shippingAddress: ShippingAddress
    let paymentMethod: PaymentMethod
    let totalAmount: Double
    let shippingFee: Double

    var grandTotal: Double {
        totalAmount + shippingFee
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("注文確認")
                .font(.title2.bold())
                .foregroundColor(AsaColors.darkSlate)

            // 配送先
            confirmSection(title: "配送先", iconName: "shippingbox") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shippingAddress.fullName)
                        .font(.subheadline.weight(.medium))
                    Text(shippingAddress.formattedAddress)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                    Text("TEL: \(shippingAddress.phoneNumber)")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }

            // 支払い方法
            confirmSection(title: "支払い方法", iconName: paymentMethod.iconName) {
                Text(paymentMethod.displayName)
                    .font(.subheadline.weight(.medium))
            }

            // 注文内容
            confirmSection(title: "注文内容", iconName: "bag") {
                VStack(spacing: 8) {
                    ForEach(cartItems) { item in
                        HStack {
                            Text(item.productName)
                                .font(.caption)
                                .foregroundColor(AsaColors.darkSlate)
                                .lineLimit(1)
                            Spacer()
                            Text("×\(item.quantity)")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                            Text(item.formattedSubtotal)
                                .font(.caption.weight(.medium))
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }
                }
            }

            // 金額
            VStack(spacing: 8) {
                HStack {
                    Text("小計")
                    Spacer()
                    Text("¥\(Int(totalAmount).formatted())")
                }
                .font(.subheadline)
                .foregroundColor(AsaColors.darkSlate)

                HStack {
                    Text("送料")
                    Spacer()
                    Text("¥\(Int(shippingFee).formatted())")
                }
                .font(.subheadline)
                .foregroundColor(AsaColors.darkSlate)

                Divider()

                HStack {
                    Text("合計")
                        .font(.headline)
                    Spacer()
                    Text("¥\(Int(grandTotal).formatted())")
                        .font(.title2.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
            .padding()
            .background(AsaColors.softCream)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func confirmSection<Content: View>(
        title: String,
        iconName: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundColor(AsaColors.coffeeBrown)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
            }

            content()
                .padding(.leading, 28)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ScrollView {
        OrderConfirmView(
            cartItems: [
                CartItem(product: Product.mock(name: "朝活タイマー Pro", price: 3980), quantity: 2),
                CartItem(product: Product.mock(name: "コーヒードリッパー", price: 2480), quantity: 1)
            ],
            shippingAddress: ShippingAddress(
                fullName: "山田 太郎",
                postalCode: "123-4567",
                prefecture: "東京都",
                city: "渋谷区",
                addressLine1: "1-2-3",
                addressLine2: "〇〇マンション 101号室",
                phoneNumber: "090-1234-5678"
            ),
            paymentMethod: .creditCard,
            totalAmount: 10440,
            shippingFee: 500
        )
        .padding()
    }
    .background(AsaColors.softCream.opacity(0.3))
}
