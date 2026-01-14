import SwiftUI
import AsaUIKit

struct ProductCardView: View {
    let product: Product
    let onTap: () -> Void
    let onAddToCart: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 商品画像
                ZStack(alignment: .topTrailing) {
                    Image(systemName: product.imageURL)
                        .font(.system(size: 40))
                        .foregroundColor(AsaColors.coffeeBrown)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(AsaColors.softCream.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if product.isOnSale {
                        Text("SALE")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .padding(6)
                    }

                    if !product.isInStock {
                        Text("在庫切れ")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray)
                            .clipShape(Capsule())
                            .padding(6)
                    }
                }

                // 商品名
                Text(product.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // 評価
                RatingView(rating: product.rating, reviewCount: product.reviewCount)

                // 価格
                PriceLabel(price: product.price, originalPrice: product.originalPrice, size: .small)

                // カートに追加ボタン
                Button {
                    onAddToCart()
                } label: {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                        Text("カートに追加")
                            .font(.caption.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(product.isInStock ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!product.isInStock)
            }
            .padding(12)
            .background(AsaColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        ProductCardView(
            product: Product.mock(name: "朝活タイマー Pro", price: 3980),
            onTap: {},
            onAddToCart: {}
        )
        ProductCardView(
            product: Product(
                id: UUID(),
                name: "コーヒードリッパー",
                description: "説明",
                price: 2480,
                originalPrice: 3000,
                imageURL: "cup.and.saucer.fill",
                categoryId: UUID(),
                stockQuantity: 0,
                rating: 4.5,
                reviewCount: 128,
                tags: [],
                createdAt: Date()
            ),
            onTap: {},
            onAddToCart: {}
        )
    }
    .padding()
}
