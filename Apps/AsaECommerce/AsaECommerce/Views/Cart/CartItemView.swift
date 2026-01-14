import SwiftUI
import AsaUIKit

struct CartItemView: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void

    @State private var quantity: Int

    init(item: CartItem, onQuantityChange: @escaping (Int) -> Void, onDelete: @escaping () -> Void) {
        self.item = item
        self.onQuantityChange = onQuantityChange
        self.onDelete = onDelete
        self._quantity = State(initialValue: item.quantity)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 商品画像
            Image(systemName: item.productImageURL)
                .font(.title)
                .foregroundColor(AsaColors.coffeeBrown)
                .frame(width: 60, height: 60)
                .background(AsaColors.softCream.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // 商品情報
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                    .lineLimit(2)

                Text(item.formattedUnitPrice)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                HStack {
                    QuantitySelector(quantity: $quantity)
                        .onChange(of: quantity) { _, newValue in
                            onQuantityChange(newValue)
                        }

                    Spacer()

                    Text(item.formattedSubtotal)
                        .font(.subheadline.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
        .padding()
        .background(AsaColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 1)
    }
}

#Preview {
    VStack {
        CartItemView(
            item: CartItem(
                product: Product.mock(name: "朝活タイマー Pro", price: 3980),
                quantity: 2
            ),
            onQuantityChange: { _ in },
            onDelete: {}
        )
    }
    .padding()
    .background(AsaColors.softCream.opacity(0.3))
}
