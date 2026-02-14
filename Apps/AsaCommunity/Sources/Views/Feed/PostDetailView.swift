import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// 投稿詳細画面
struct PostDetailView: View {
    let post: CommunityPost

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Header
                HStack {
                    Label(post.category.rawValue, systemImage: post.category.iconName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AsaColors.softCream)
                        .clipShape(Capsule())
                    Spacer()
                    Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Title
                Text(post.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.darkSlate)

                // MARK: - Author
                if let author = post.author {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AsaColors.coffeeBrown)
                        VStack(alignment: .leading) {
                            Text(author.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if author.isVerified {
                                Label("認証済み", systemImage: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundStyle(AsaColors.coffeeBrown)
                            }
                        }
                    }
                }

                Divider()

                // MARK: - Content
                Text(post.content)
                    .font(.body)
                    .lineSpacing(6)

                // MARK: - Image
                if post.imageData != nil {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }

                // MARK: - Location
                if post.hasLocation {
                    Label("位置情報あり", systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AsaColors.coffeeBrown)
                }

                Divider()

                // MARK: - Engagement
                HStack(spacing: 24) {
                    Label("\(post.likeCount) いいね", systemImage: "heart.fill")
                        .foregroundStyle(AsaColors.coffeeBrown)
                    Label("\(post.commentCount) コメント", systemImage: "bubble.right.fill")
                        .foregroundStyle(AsaColors.mutedSage)
                }
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("投稿詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}
