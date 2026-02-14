import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// 地域のお店一覧画面
struct BusinessListView: View {
    @Bindable var viewModel: LocalBusinessViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChipView<BusinessCategory>(
                            label: "すべて",
                            iconName: "building.2",
                            isSelected: viewModel.selectedCategory == nil,
                            action: { viewModel.selectedCategory = nil }
                        )
                        ForEach(BusinessCategory.allCases, id: \.self) { category in
                            CategoryChipView<BusinessCategory>(
                                label: category.rawValue,
                                iconName: category.iconName,
                                isSelected: viewModel.selectedCategory == category,
                                action: { viewModel.selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // MARK: - Search & Favorite Toggle
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("お店を検索...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    Spacer()
                    Button {
                        viewModel.showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundStyle(viewModel.showFavoritesOnly ? .red : .secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                // MARK: - Business List
                if viewModel.filteredBusinesses.isEmpty {
                    Spacer()
                    EmptyStateView(
                        iconName: "building.2",
                        title: "お店が見つかりません",
                        message: "条件を変えて検索してください"
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredBusinesses) { business in
                            NavigationLink {
                                BusinessDetailView(
                                    business: business,
                                    viewModel: viewModel
                                )
                            } label: {
                                BusinessRow(
                                    business: business,
                                    onToggleFavorite: { viewModel.toggleFavorite(business) }
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("地域のお店")
            .onAppear {
                viewModel.loadBusinesses()
            }
        }
    }
}

/// 店舗行コンポーネント
struct BusinessRow: View {
    let business: LocalBusiness
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: business.category.iconName)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(AsaColors.softCream)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(business.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(business.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !business.businessHours.isEmpty {
                    Text(business.businessHours)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button(action: onToggleFavorite) {
                Image(systemName: business.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(business.isFavorite ? .red : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
