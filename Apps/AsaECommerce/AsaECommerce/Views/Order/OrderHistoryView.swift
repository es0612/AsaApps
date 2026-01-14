import SwiftUI
import SwiftData
import AsaUIKit

struct OrderHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Order.createdAt, order: .reverse) private var orders: [Order]

    @State private var selectedOrder: Order?

    var body: some View {
        NavigationStack {
            Group {
                if orders.isEmpty {
                    emptyState
                } else {
                    orderList
                }
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("注文履歴")
            .navigationDestination(item: $selectedOrder) { order in
                OrderDetailView(order: order)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 60))
                .foregroundColor(AsaColors.mutedSage)

            Text("注文履歴がありません")
                .font(.title2.weight(.medium))
                .foregroundColor(AsaColors.darkSlate)

            Text("商品を購入すると\nこちらに履歴が表示されます")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Order List

    private var orderList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(orders) { order in
                    OrderRowView(order: order) {
                        selectedOrder = order
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Order Row View

struct OrderRowView: View {
    let order: Order
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.orderNumber)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AsaColors.darkSlate)

                        Text(order.formattedDate)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: order.status.iconName)
                        Text(order.status.displayName)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(statusColor(for: order.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: order.status).opacity(0.1))
                    .clipShape(Capsule())
                }

                Divider()

                // 商品サマリー
                HStack {
                    Text("\(order.items.count)点の商品")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    Spacer()

                    Text(order.formattedTotalAmount)
                        .font(.subheadline.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                }

                // 商品名リスト（最大2件）
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(order.items.prefix(2)), id: \.productId) { item in
                        Text("・\(item.productName)")
                            .font(.caption)
                            .foregroundColor(AsaColors.darkSlate)
                            .lineLimit(1)
                    }
                    if order.items.count > 2 {
                        Text("他 \(order.items.count - 2) 件")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }
            .padding()
            .background(AsaColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 1)
        }
        .buttonStyle(.plain)
    }

    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .shipped: return .purple
        case .delivered: return .green
        case .cancelled: return .red
        }
    }
}

#Preview {
    OrderHistoryView()
        .modelContainer(for: Order.self, inMemory: true)
}
