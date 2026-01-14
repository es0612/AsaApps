import SwiftUI
import SwiftData
import AsaUIKit

struct CartView: View {
    @Bindable var cartViewModel: CartViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showingCheckout = false

    var body: some View {
        NavigationStack {
            Group {
                if cartViewModel.isEmpty {
                    emptyState
                } else {
                    cartContent
                }
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("カート")
            .sheet(isPresented: $showingCheckout) {
                CheckoutView(
                    cartViewModel: cartViewModel,
                    onComplete: {
                        showingCheckout = false
                    }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(AsaColors.mutedSage)

            Text("カートは空です")
                .font(.title2.weight(.medium))
                .foregroundColor(AsaColors.darkSlate)

            Text("商品を追加してください")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Cart Content

    private var cartContent: some View {
        VStack(spacing: 0) {
            // カートアイテムリスト
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cartViewModel.items) { item in
                        CartItemView(
                            item: item,
                            onQuantityChange: { newQuantity in
                                cartViewModel.updateQuantity(itemId: item.id, quantity: newQuantity)
                            },
                            onDelete: {
                                cartViewModel.removeFromCart(item: item)
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                cartViewModel.removeFromCart(item: item)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }

            // 合計金額セクション
            summarySection
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(spacing: 16) {
            Divider()

            VStack(spacing: 8) {
                HStack {
                    Text("小計（\(cartViewModel.itemCount)点）")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    Text(cartViewModel.formattedTotalAmount)
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                }

                HStack {
                    Text("送料")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    Text(cartViewModel.formattedShippingFee)
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                }

                Divider()

                HStack {
                    Text("合計")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    Text(cartViewModel.formattedGrandTotal)
                        .font(.title2.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }

            AsaButton(
                title: "レジに進む",
                action: {
                    showingCheckout = true
                }
            )
        }
        .padding()
        .background(AsaColors.cardBackground)
    }
}

#Preview {
    CartView(cartViewModel: CartViewModel())
        .modelContainer(for: Order.self, inMemory: true)
}
