import SwiftUI

struct PostCardView: View {
    let post: Post
    @Bindable var viewModel: FeedViewModel
    @State private var isLikeAnimating = false

    var isLikedByCurrentUser: Bool {
        post.isLikedBy(viewModel.currentUserName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - ヘッダー（投稿者 + 時間）

            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))

                    Text(post.timeAgo)
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }

                Spacer()

                // 削除ボタン（自分の投稿のみ）
                if post.authorName == viewModel.currentUserName {
                    Button {
                        viewModel.deletePost(post)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
            }

            // MARK: - 投稿内容

            Text(post.content)
                .font(.body)
                .foregroundColor(Color("AsaDarkSlate"))
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // MARK: - いいねボタン

            HStack {
                Button {
                    // スプリングアニメーション開始
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLikeAnimating = true
                        viewModel.toggleLike(on: post)
                    }

                    // 0.3秒後にアニメーションをリセット
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLikeAnimating = false
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLikedByCurrentUser ? "heart.fill" : "heart")
                            .foregroundColor(isLikedByCurrentUser ? .red : Color("AsaMutedSage"))
                            .scaleEffect(isLikeAnimating ? 1.3 : 1.0)

                        Text("\(post.likeCount)")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
