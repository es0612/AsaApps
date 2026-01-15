import SwiftUI

// MARK: - Firebase Content View

struct FirebaseContentView: View {
    // MARK: - Properties

    @State private var authViewModel: AuthViewModel
    @State private var feedViewModel: FirebaseFeedViewModel

    // MARK: - Initializer

    init() {
        let authService = FirebaseAuthService()
        let dataService = FirestoreSocialFeedDataService()
        let authVM = AuthViewModel(authService: authService)
        let feedVM = FirebaseFeedViewModel(dataService: dataService, authViewModel: authVM)

        _authViewModel = State(initialValue: authVM)
        _feedViewModel = State(initialValue: feedVM)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                FirebaseFeedView(
                    authViewModel: authViewModel,
                    feedViewModel: feedViewModel
                )
            } else {
                AuthView(viewModel: authViewModel)
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

// MARK: - Firebase Feed View

struct FirebaseFeedView: View {
    // MARK: - Properties

    @Bindable var authViewModel: AuthViewModel
    @Bindable var feedViewModel: FirebaseFeedViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color("AsaSoftCream")
                    .ignoresSafeArea()

                if feedViewModel.posts.isEmpty && !feedViewModel.isLoading {
                    emptyStateView
                } else {
                    postsList
                }

                // 新規投稿ボタン
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        newPostButton
                    }
                }
                .padding()
            }
            .navigationTitle("フィード")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    profileButton
                }
            }
            .sheet(isPresented: $feedViewModel.showingNewPost) {
                FirebaseNewPostView(viewModel: feedViewModel)
            }
            .sheet(isPresented: $feedViewModel.showingProfile) {
                ProfileView(authViewModel: authViewModel, feedViewModel: feedViewModel)
            }
            .alert("エラー", isPresented: Binding(
                get: { feedViewModel.errorMessage != nil },
                set: { _ in feedViewModel.clearError() }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(feedViewModel.errorMessage ?? "")
            }
            .onAppear {
                feedViewModel.startObservingPosts()
            }
            .onDisappear {
                feedViewModel.stopObservingPosts()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.bubble")
                .font(.system(size: 60))
                .foregroundStyle(Color("AsaMutedSage"))

            Text("投稿がありません")
                .font(.headline)
                .foregroundStyle(Color("AsaDarkSlate"))

            Text("最初の投稿を作成しましょう！")
                .font(.subheadline)
                .foregroundStyle(Color("AsaMutedSage"))
        }
    }

    // MARK: - Posts List

    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(feedViewModel.posts) { post in
                    FirebasePostCardView(
                        post: post,
                        viewModel: feedViewModel
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await feedViewModel.loadPosts()
        }
    }

    // MARK: - New Post Button

    private var newPostButton: some View {
        Button {
            feedViewModel.showingNewPost = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color("AsaCoffeeBrown"))
                .clipShape(Circle())
                .shadow(color: Color("AsaDarkSlate").opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Profile Button

    private var profileButton: some View {
        Button {
            feedViewModel.showingProfile = true
        } label: {
            if let photoURL = authViewModel.currentUser?.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                defaultAvatar
            }
        }
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(Color("AsaSoftCream"))
            .frame(width: 32, height: 32)
            .overlay {
                Text(String(feedViewModel.currentUserName.prefix(1)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("AsaCoffeeBrown"))
            }
    }
}

// MARK: - Preview

#Preview {
    FirebaseContentView()
}
