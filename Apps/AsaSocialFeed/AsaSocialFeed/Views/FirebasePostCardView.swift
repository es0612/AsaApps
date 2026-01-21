import SwiftUI

// MARK: - Firebase Post Card View

struct FirebasePostCardView: View {
    // MARK: - Properties

    let post: FirebasePost
    @Bindable var viewModel: FirebaseFeedViewModel

    @State private var isLikeAnimating = false
    @State private var showingDeleteConfirmation = false
    // @State private var showingImageViewer = false  // Firebase Storage未使用

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー（ユーザー情報）
            headerView

            // 投稿内容
            Text(post.content)
                .font(.body)
                .foregroundStyle(Color("AsaDarkSlate"))
                .lineLimit(nil)

            // 画像（Firebase Storage未使用のため無効化）
            // if let imageURL = post.imageURL, let url = URL(string: imageURL) {
            //     imageView(url: url)
            // }

            // フッター（いいね・時間）
            footerView
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color("AsaDarkSlate").opacity(0.1), radius: 4, x: 0, y: 2)
        .contextMenu {
            if viewModel.isOwnPost(post) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("この投稿を削除しますか？", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                Task {
                    await viewModel.deletePost(post)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        // 画像ビューアは無効化（Firebase Storage未使用）
        // .fullScreenCover(isPresented: $showingImageViewer) {
        //     if let imageURL = post.imageURL, let url = URL(string: imageURL) {
        //         ImageViewerView(url: url, isPresented: $showingImageViewer)
        //     }
        // }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 12) {
            // アバター
            if let photoURL = post.authorPhotoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                defaultAvatar
            }

            // ユーザー名と時間
            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AsaDarkSlate"))

                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            Spacer()

            // 自分の投稿マーク
            if viewModel.isOwnPost(post) {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(Color("AsaCoffeeBrown"))
            }
        }
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(Color("AsaSoftCream"))
            .frame(width: 40, height: 40)
            .overlay {
                Text(String(post.authorName.prefix(1)))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("AsaCoffeeBrown"))
            }
    }

    // MARK: - Image View (Firebase Storage未使用のため無効化)
    /*
    private func imageView(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color("AsaSoftCream"))
                    .frame(height: 200)
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 300)
                    .clipped()
                    .cornerRadius(8)
                    .onTapGesture {
                        showingImageViewer = true
                    }
            case .failure:
                Rectangle()
                    .fill(Color("AsaSoftCream"))
                    .frame(height: 100)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(Color("AsaMutedSage"))
                    }
                    .cornerRadius(8)
            @unknown default:
                EmptyView()
            }
        }
    }
    */

    // MARK: - Footer View

    private var footerView: some View {
        HStack {
            // いいねボタン
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLikeAnimating = true
                }

                Task {
                    await viewModel.toggleLike(on: post)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLikeAnimating = false
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isLikedByCurrentUser(post) ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isLikedByCurrentUser(post) ? .red : Color("AsaMutedSage"))
                        .scaleEffect(isLikeAnimating ? 1.3 : 1.0)

                    Text("\(post.likeCount)")
                        .font(.subheadline)
                        .foregroundStyle(Color("AsaMutedSage"))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // 日付
            Text(post.formattedDate)
                .font(.caption2)
                .foregroundStyle(Color("AsaMutedSage"))
        }
    }
}

// MARK: - Image Viewer View (Firebase Storage未使用のため無効化)
/*
struct ImageViewerView: View {
    let url: URL
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = value.magnification
                            }
                            .onEnded { _ in
                                withAnimation {
                                    scale = 1.0
                                }
                            }
                    )
            } placeholder: {
                ProgressView()
                    .tint(.white)
            }

            // 閉じるボタン
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
*/

// MARK: - Preview

#Preview {
    let authService = FirebaseAuthService()
    let dataService = FirestoreSocialFeedDataService()
    let authVM = AuthViewModel(authService: authService)
    let feedVM = FirebaseFeedViewModel(dataService: dataService, authViewModel: authVM)

    let samplePost = FirebasePost(
        id: "1",
        content: "今日も朝活頑張りました！SwiftUIの勉強を続けています。",
        authorId: "user1",
        authorName: "朝活パパ",
        likeCount: 5,
        likedByUserIds: [],
        createdAt: Date()
    )

    FirebasePostCardView(post: samplePost, viewModel: feedVM)
        .padding()
        .background(Color("AsaSoftCream"))
}
