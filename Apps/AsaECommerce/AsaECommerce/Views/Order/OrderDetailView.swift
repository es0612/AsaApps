import SwiftUI
import AsaUIKit

struct OrderDetailView: View {
    let order: Order

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 注文ステータス
                statusSection

                // 注文情報
                orderInfoSection

                // 配送先
                shippingSection

                // 支払い方法
                paymentSection

                // 注文商品
                itemsSection

                // 金額詳細
                amountSection
            }
            .padding()
        }
        .background(AsaColors.softCream.opacity(0.3))
        .navigationTitle("注文詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack(spacing: 12) {
            Image(systemName: order.status.iconName)
                .font(.title)
                .foregroundColor(statusColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(order.status.displayName)
                    .font(.headline)
                    .foregroundColor(statusColor)

                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            Spacer()
        }
        .padding()
        .background(statusColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        switch order.status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .shipped: return .purple
        case .delivered: return .green
        case .cancelled: return .red
        }
    }

    private var statusMessage: String {
        switch order.status {
        case .pending: return "ご注文を受け付けました"
        case .confirmed: return "ご注文を確認しました"
        case .shipped: return "商品を発送しました"
        case .delivered: return "商品をお届けしました"
        case .cancelled: return "ご注文はキャンセルされました"
        }
    }

    // MARK: - Order Info Section

    private var orderInfoSection: some View {
        detailSection(title: "注文情報", iconName: "doc.text") {
            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "注文番号", value: order.orderNumber)
                infoRow(label: "注文日時", value: order.formattedDate)
            }
        }
    }

    // MARK: - Shipping Section

    private var shippingSection: some View {
        detailSection(title: "配送先", iconName: "shippingbox") {
            let address = order.shippingAddress
            VStack(alignment: .leading, spacing: 4) {
                Text(address.fullName)
                    .font(.subheadline.weight(.medium))

                Text("〒\(address.postalCode)")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                Text("\(address.prefecture)\(address.city)\(address.addressLine1)")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                if let line2 = address.addressLine2, !line2.isEmpty {
                    Text(line2)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Text("TEL: \(address.phoneNumber)")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
    }

    // MARK: - Payment Section

    private var paymentSection: some View {
        detailSection(title: "支払い方法", iconName: order.paymentMethod.iconName) {
            Text(order.paymentMethod.displayName)
                .font(.subheadline)
        }
    }

    // MARK: - Items Section

    private var itemsSection: some View {
        detailSection(title: "注文商品", iconName: "bag") {
            VStack(spacing: 12) {
                ForEach(order.items, id: \.productId) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.productName)
                                .font(.subheadline)
                                .foregroundColor(AsaColors.darkSlate)

                            Text("¥\(Int(item.unitPrice).formatted()) × \(item.quantity)")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                        }

                        Spacer()

                        Text("¥\(Int(item.subtotal).formatted())")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AsaColors.darkSlate)
                    }

                    if item.productId != order.items.last?.productId {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        detailSection(title: "金額詳細", iconName: "yensign.circle") {
            VStack(spacing: 8) {
                HStack {
                    Text("小計")
                    Spacer()
                    Text("¥\(Int(order.subtotal).formatted())")
                }
                .font(.subheadline)
                .foregroundColor(AsaColors.darkSlate)

                HStack {
                    Text("送料")
                    Spacer()
                    Text("¥\(Int(order.shippingFee).formatted())")
                }
                .font(.subheadline)
                .foregroundColor(AsaColors.darkSlate)

                Divider()

                HStack {
                    Text("合計")
                        .font(.headline)
                    Spacer()
                    Text(order.formattedTotalAmount)
                        .font(.title3.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func detailSection<Content: View>(
        title: String,
        iconName: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundColor(AsaColors.coffeeBrown)
                Text(title)
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)
            }

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AsaColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(AsaColors.darkSlate)
        }
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(order: {
            let order = Order(
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
                paymentMethod: .creditCard
            )
            return order
        }())
    }
}
