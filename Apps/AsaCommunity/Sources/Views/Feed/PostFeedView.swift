import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// 掲示板メイン画面
struct PostFeedView: View {
    @Bindable var viewModel: PostFeedViewModel
    @State private var showCreatePost = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChipView<PostCategory>(
                            label: "すべて",
                            iconName: "tray.full",
                            isSelected: viewModel.selectedCategory == nil,
                            action: { viewModel.selectedCategory = nil }
                        )
                        ForEach(PostCategory.allCases, id: \.self) { category in
                            CategoryChipView<PostCategory>(
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

                Divider()

                // MARK: - Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("投稿を検索...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                // MARK: - Post List
                if viewModel.filteredPosts.isEmpty {
                    Spacer()
                    EmptyStateView(
                        iconName: "text.bubble",
                        title: "投稿がありません",
                        message: "最初の投稿を作成してみましょう",
                        actionTitle: "投稿する",
                        action: { showCreatePost = true }
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredPosts) { post in
                                NavigationLink {
                                    PostDetailView(post: post)
                                } label: {
                                    PostCardView(
                                        post: post,
                                        onLike: { viewModel.toggleLike(post) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("掲示板")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostSheet(viewModel: viewModel)
            }
            .refreshable {
                viewModel.loadPosts()
            }
            .onAppear {
                viewModel.loadPosts()
            }
        }
    }
}
