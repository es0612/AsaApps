import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// 投稿カードコンポーネント
struct PostCardView: View {
    let post: CommunityPost
    var onLike: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: - Header
            HStack {
                Label(post.category.rawValue, systemImage: post.category.iconName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AsaColors.softCream)
                    .clipShape(Capsule())

                Spacer()

                Text(post.timeAgoText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if !post.isRead {
                    Circle()
                        .fill(AsaColors.coffeeBrown)
                        .frame(width: 8, height: 8)
                }
            }

            // MARK: - Title & Content
            Text(post.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AsaColors.darkSlate)

            Text(post.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // MARK: - Image
            if post.imageData != nil {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            // MARK: - Footer
            HStack {
                if let authorName = post.author?.displayName {
                    Label(authorName, systemImage: "person.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { onLike?() }) {
                    Label("\(post.likeCount)", systemImage: "heart")
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                }
                Label("\(post.commentCount)", systemImage: "bubble.right")
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
