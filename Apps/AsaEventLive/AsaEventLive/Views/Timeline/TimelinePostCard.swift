import SwiftUI
import AsaUIKit

// MARK: - TimelinePostCard

struct TimelinePostCard: View {
    // MARK: - Properties

    let post: EventPost
    let currentUserId: String
    let canManage: Bool

    let onLike: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void

    @State private var showDeleteAlert = false

    // MARK: - Computed Properties

    private var isMyPost: Bool {
        post.authorId == currentUserId
    }

    private var isLiked: Bool {
        post.likedByUserIds.contains(currentUserId)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack(spacing: 12) {
                // アバター
                Circle()
                    .fill(avatarColor)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(post.authorName.prefix(1))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.authorName)
                            .font(.subheadline.bold())
                            .foregroundStyle(AsaColors.darkSlate)

                        if post.type == .announcement {
                            Text("お知らせ")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AsaColors.coffeeBrown)
                                .clipShape(Capsule())
                        }

                        if post.type == .milestone {
                            Text("マイルストーン")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.purple)
                                .clipShape(Capsule())
                        }
                    }

                    Text(post.timeAgo)
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                }

                Spacer()

                // メニュー
                if isMyPost || canManage {
                    Menu {
                        if canManage {
                            Button {
                                onTogglePin()
                            } label: {
                                Label(
                                    post.isPinned ? "ピン留め解除" : "ピン留め",
                                    systemImage: post.isPinned ? "pin.slash" : "pin"
                                )
                            }
                        }

                        if isMyPost || canManage {
                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(AsaColors.mutedSage)
                            .padding(8)
                    }
                }
            }

            // ピン留めバッジ
            if post.isPinned {
                HStack(spacing: 4) {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                    Text("ピン留め")
                        .font(.caption2)
                }
                .foregroundStyle(AsaColors.coffeeBrown)
            }

            // コンテンツ
            Text(post.content)
                .font(.body)
                .foregroundStyle(AsaColors.darkSlate)
                .fixedSize(horizontal: false, vertical: true)

            // 画像（将来対応）
            if let imageURL = post.imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        EmptyView()
                    case .empty:
                        ProgressView()
                            .frame(height: 100)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // アクションバー
            HStack(spacing: 24) {
                // いいねボタン
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? .red : AsaColors.mutedSage)
                        if post.likeCount > 0 {
                            Text("\(post.likeCount)")
                                .font(.caption)
                                .foregroundStyle(isLiked ? .red : AsaColors.mutedSage)
                        }
                    }
                }
                .buttonStyle(.plain)

                // コメント表示（将来対応）
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .foregroundStyle(AsaColors.mutedSage)
                    if post.commentCount > 0 {
                        Text("\(post.commentCount)")
                            .font(.caption)
                            .foregroundStyle(AsaColors.mutedSage)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4)
        .overlay {
            if post.isPinned {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AsaColors.coffeeBrown.opacity(0.3), lineWidth: 1)
            }
        }
        .alert("この投稿を削除しますか？", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive, action: onDelete)
        }
    }

    // MARK: - Private Properties

    private var avatarColor: Color {
        let colors: [Color] = [
            AsaColors.coffeeBrown,
            AsaColors.mocha,
            AsaColors.mutedSage,
            .purple,
            .orange,
            .cyan
        ]
        let index = abs(post.authorId.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        TimelinePostCard(
            post: EventPost.samplePosts[0],
            currentUserId: "user-1",
            canManage: true,
            onLike: {},
            onDelete: {},
            onTogglePin: {}
        )

        TimelinePostCard(
            post: EventPost.samplePosts[1],
            currentUserId: "user-1",
            canManage: false,
            onLike: {},
            onDelete: {},
            onTogglePin: {}
        )
    }
    .padding()
    .background(AsaColors.background)
}
