import SwiftUI

// MARK: - Profile View

struct ProfileView: View {
    // MARK: - Properties

    @Bindable var authViewModel: AuthViewModel
    @Bindable var feedViewModel: FirebaseFeedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingName = false
    @State private var editedName = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // ユーザー情報セクション
                Section {
                    userInfoRow
                } header: {
                    Text("アカウント")
                }

                // 統計セクション
                Section {
                    statisticsRow
                } header: {
                    Text("アクティビティ")
                }

                // アクションセクション
                Section {
                    signOutButton
                }
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $isEditingName) {
                editNameSheet
            }
        }
    }

    // MARK: - User Info Row

    private var userInfoRow: some View {
        HStack(spacing: 16) {
            // アバター
            if let photoURL = authViewModel.currentUser?.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                defaultAvatar
            }

            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                Text(authViewModel.displayName)
                    .font(.headline)
                    .foregroundStyle(Color("AsaDarkSlate"))

                if let email = authViewModel.currentUser?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(Color("AsaMutedSage"))
                }
            }

            Spacer()

            // 編集ボタン
            Button {
                editedName = authViewModel.displayName
                isEditingName = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color("AsaCoffeeBrown"))
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Default Avatar

    private var defaultAvatar: some View {
        Circle()
            .fill(Color("AsaSoftCream"))
            .frame(width: 60, height: 60)
            .overlay {
                Text(String(authViewModel.displayName.prefix(1)))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("AsaCoffeeBrown"))
            }
    }

    // MARK: - Statistics Row

    private var statisticsRow: some View {
        let myPosts = feedViewModel.posts.filter { $0.authorId == authViewModel.currentUser?.uid }
        let totalLikes = myPosts.reduce(0) { $0 + $1.likeCount }

        return VStack(spacing: 16) {
            HStack {
                statisticItem(value: myPosts.count, label: "投稿")
                Divider()
                statisticItem(value: totalLikes, label: "いいね獲得")
            }
        }
        .padding(.vertical, 8)
    }

    private func statisticItem(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color("AsaCoffeeBrown"))

            Text(label)
                .font(.caption)
                .foregroundStyle(Color("AsaMutedSage"))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button(role: .destructive) {
            authViewModel.signOut()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("サインアウト")
            }
        }
    }

    // MARK: - Edit Name Sheet

    private var editNameSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("表示名", text: $editedName)
                } header: {
                    Text("表示名")
                } footer: {
                    Text("他のユーザーに表示される名前です")
                }
            }
            .navigationTitle("名前を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        isEditingName = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        Task {
                            await authViewModel.updateDisplayName(editedName)
                            isEditingName = false
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    let authService = FirebaseAuthService()
    let dataService = FirestoreSocialFeedDataService()
    let authVM = AuthViewModel(authService: authService)
    let feedVM = FirebaseFeedViewModel(dataService: dataService, authViewModel: authVM)

    ProfileView(authViewModel: authVM, feedViewModel: feedVM)
}
