import SwiftUI
import AsaUIKit

struct ProductDetailView: View {
    let product: Product
    @Bindable var cartViewModel: CartViewModel

    @State private var quantity = 1
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 商品画像
                productImage

                VStack(alignment: .leading, spacing: 16) {
                    // 商品名
                    Text(product.name)
                        .font(.title2.bold())
                        .foregroundColor(AsaColors.darkSlate)

                    // 評価
                    RatingView(rating: product.rating, reviewCount: product.reviewCount)

                    // 価格
                    PriceLabel(price: product.price, originalPrice: product.originalPrice, size: .large)

                    // 在庫状況
                    stockStatus

                    Divider()

                    // 商品説明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("商品説明")
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)

                        Text(product.description)
                            .font(.body)
                            .foregroundColor(AsaColors.darkSlate.opacity(0.8))
                    }

                    // タグ
                    if !product.tags.isEmpty {
                        tagSection
                    }

                    Divider()

                    // 数量選択
                    if product.isInStock {
                        quantitySection
                    }

                    // カートに追加ボタン
                    addToCartButton
                }
                .padding(.horizontal)
            }
        }
        .background(AsaColors.softCream.opacity(0.3))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Product Image

    private var productImage: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: product.imageURL)
                .font(.system(size: 80))
                .foregroundColor(AsaColors.coffeeBrown)
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .background(AsaColors.softCream.opacity(0.5))

            if product.isOnSale {
                Text("SALE")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .padding()
            }
        }
    }

    // MARK: - Stock Status

    private var stockStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: product.isInStock ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(product.isInStock ? "在庫あり（残り\(product.stockQuantity)個）" : "在庫切れ")
        }
        .font(.subheadline.weight(.medium))
        .foregroundColor(product.isInStock ? .green : .red)
    }

    // MARK: - Tag Section

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タグ")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            FlowLayout(spacing: 8) {
                ForEach(product.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(AsaColors.coffeeBrown)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AsaColors.softCream)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Quantity Section

    private var quantitySection: some View {
        HStack {
            Text("数量")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            Spacer()

            QuantitySelector(
                quantity: $quantity,
                maxValue: min(product.stockQuantity, 10)
            )
        }
    }

    // MARK: - Add to Cart Button

    private var addToCartButton: some View {
        AsaButton(
            title: product.isInStock ? "カートに追加（¥\(Int(product.price * Double(quantity)).formatted())）" : "在庫切れ",
            action: {
                cartViewModel.addToCart(product: product, quantity: quantity)
            },
            isEnabled: product.isInStock
        )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(
            product: Product(
                id: UUID(),
                name: "朝活タイマー Pro",
                description: "早起きをサポートする高機能タイマー。優しいアラーム音と睡眠サイクル分析機能付き。朝活を習慣化したい方におすすめです。",
                price: 3980,
                originalPrice: 4980,
                imageURL: "timer.circle.fill",
                categoryId: UUID(),
                stockQuantity: 50,
                rating: 4.8,
                reviewCount: 256,
                tags: ["朝活", "タイマー", "睡眠"],
                createdAt: Date()
            ),
            cartViewModel: CartViewModel()
        )
    }
}
