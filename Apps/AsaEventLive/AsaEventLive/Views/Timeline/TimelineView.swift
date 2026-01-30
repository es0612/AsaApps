import SwiftUI
import AsaUIKit

// MARK: - TimelineView

struct TimelineView: View {
    // MARK: - Properties

    @Bindable var viewModel: EventDetailViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.posts.isEmpty {
                emptyStateView
            } else {
                postsList
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(AsaColors.coffeeBrown.opacity(0.3))

            Text("まだ投稿がありません")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            Text("最初の投稿をしてみましょう！")
                .font(.subheadline)
                .foregroundStyle(AsaColors.mutedSage)
        }
    }

    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // ピン留め投稿
                if !viewModel.pinnedPosts.isEmpty {
                    ForEach(viewModel.pinnedPosts) { post in
                        TimelinePostCard(
                            post: post,
                            currentUserId: viewModel.isHost ? viewModel.event.hostId : "",
                            canManage: viewModel.canManage
                        ) {
                            Task { await viewModel.toggleLike(on: post) }
                        } onDelete: {
                            Task { try? await viewModel.deletePost(post) }
                        } onTogglePin: {
                            Task { try? await viewModel.togglePin(on: post) }
                        }
                    }
                }

                // 通常投稿
                ForEach(viewModel.regularPosts) { post in
                    TimelinePostCard(
                        post: post,
                        currentUserId: viewModel.isHost ? viewModel.event.hostId : "",
                        canManage: viewModel.canManage
                    ) {
                        Task { await viewModel.toggleLike(on: post) }
                    } onDelete: {
                        Task { try? await viewModel.deletePost(post) }
                    } onTogglePin: {
                        Task { try? await viewModel.togglePin(on: post) }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    TimelineView(
        viewModel: EventDetailViewModel(
            event: Event.sampleEvents[0],
            userId: "user-1",
            dataService: MockEventDataService()
        )
    )
}
