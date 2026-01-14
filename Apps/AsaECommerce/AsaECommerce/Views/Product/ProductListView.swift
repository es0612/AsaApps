import SwiftUI
import AsaUIKit

struct ProductListView: View {
    @Bindable var productViewModel: ProductViewModel
    @Bindable var cartViewModel: CartViewModel

    @State private var selectedProduct: Product?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // カテゴリフィルター
                    categoryFilter

                    // ソートメニュー
                    sortMenu

                    // 商品グリッド
                    if productViewModel.filteredProducts.isEmpty {
                        emptyState
                    } else {
                        productGrid
                    }
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("商品一覧")
            .searchable(text: $productViewModel.searchText, prompt: "商品を検索")
            .navigationDestination(item: $selectedProduct) { product in
                ProductDetailView(
                    product: product,
                    cartViewModel: cartViewModel
                )
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(productViewModel.categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: productViewModel.selectedCategory.id == category.id
                    ) {
                        productViewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        HStack {
            Text("\(productViewModel.filteredProducts.count)件の商品")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            Spacer()

            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        productViewModel.sortOption = option
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if productViewModel.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(productViewModel.sortOption.displayName)
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(AsaColors.coffeeBrown)
            }
        }
    }

    // MARK: - Product Grid

    private var productGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(productViewModel.filteredProducts) { product in
                ProductCardView(
                    product: product,
                    onTap: {
                        selectedProduct = product
                    },
                    onAddToCart: {
                        cartViewModel.addToCart(product: product)
                    }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(AsaColors.mutedSage)

            Text("商品が見つかりません")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            Text("検索条件を変更してお試しください")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            Button("フィルターをリセット") {
                productViewModel.resetFilters()
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(AsaColors.coffeeBrown)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    ProductListView(
        productViewModel: ProductViewModel(),
        cartViewModel: CartViewModel()
    )
}
