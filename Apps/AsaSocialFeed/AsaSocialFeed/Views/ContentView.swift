import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: FeedViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.posts.isEmpty {
                    emptyStateView
                } else {
                    postList
                }
            }
            .navigationTitle("AsaSocialFeed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // ユーザー名表示・設定ボタン
                    Button {
                        viewModel.showingUserNameSetting = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                            if viewModel.hasUserName {
                                Text(viewModel.currentUserName)
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    }

                    // 新規投稿ボタン
                    Button {
                        viewModel.showingNewPost = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    .disabled(!viewModel.hasUserName)
                }
            }
            .sheet(isPresented: $viewModel.showingNewPost) {
                NewPostView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingUserNameSetting) {
                UserNameSettingView(viewModel: viewModel)
            }
            .onAppear {
                if !viewModel.hasUserName {
                    viewModel.showingUserNameSetting = true
                }
                viewModel.loadPosts()
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Post List

    private var postList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.posts) { post in
                    PostCardView(post: post, viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding()
        }
        .background(Color("AsaSoftCream").opacity(0.3))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(Color("AsaMutedSage"))

            Text("まだ投稿がありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))

            Text("最初の投稿をしてみましょう！")
                .font(.body)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

#Preview {
    ContentView(viewModel: FeedViewModel(dataService: try! SocialFeedDataService.previewService()))
}
