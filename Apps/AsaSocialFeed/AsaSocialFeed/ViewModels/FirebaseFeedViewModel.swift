import Foundation
import SwiftUI

// MARK: - Firebase Feed View Model

@MainActor
@Observable
final class FirebaseFeedViewModel {
    // MARK: - Dependencies

    private let dataService: SocialFeedDataServiceProtocol
    private let authViewModel: AuthViewModel

    // MARK: - State

    private(set) var posts: [FirebasePost] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private var postsListener: Any?

    // MARK: - UI State

    var showingNewPost = false
    var showingProfile = false

    // MARK: - Computed Properties

    var currentUser: User? {
        authViewModel.currentUser
    }

    var isAuthenticated: Bool {
        authViewModel.isAuthenticated
    }

    var currentUserId: String {
        currentUser?.uid ?? ""
    }

    var currentUserName: String {
        currentUser?.displayNameOrEmail ?? ""
    }

    // MARK: - Initializer

    init(dataService: SocialFeedDataServiceProtocol, authViewModel: AuthViewModel) {
        self.dataService = dataService
        self.authViewModel = authViewModel
    }

    // Note: deinitでMainActorプロパティにアクセスできないため、
    // stopObservingPosts()はViewのonDisappearで明示的に呼び出す必要があります

    // MARK: - Real-time Posts Observation

    func startObservingPosts() {
        guard postsListener == nil else { return }

        postsListener = dataService.observePosts { [weak self] posts in
            Task { @MainActor in
                self?.posts = posts
            }
        }
    }

    func stopObservingPosts() {
        if let listener = postsListener {
            dataService.removeListener(listener)
            postsListener = nil
        }
    }

    // MARK: - Manual Fetch

    func loadPosts() async {
        isLoading = true
        errorMessage = nil

        do {
            posts = try await dataService.fetchPosts()
        } catch {
            errorMessage = "投稿の読み込みに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Post Operations

    func createPost(content: String, imageData: Data?) async {
        guard isAuthenticated else {
            errorMessage = "サインインしてください"
            return
        }

        guard let user = currentUser else {
            errorMessage = "ユーザー情報が取得できません"
            return
        }

        guard !content.isEmpty else {
            errorMessage = "投稿内容を入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await dataService.createPost(
                content: content,
                authorId: user.uid,
                authorName: user.displayNameOrEmail,
                authorPhotoURL: user.photoURL,
                imageData: imageData
            )
            showingNewPost = false
        } catch {
            errorMessage = "投稿の作成に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func deletePost(_ post: FirebasePost) async {
        guard isAuthenticated else {
            errorMessage = "サインインしてください"
            return
        }

        guard post.authorId == currentUserId else {
            errorMessage = "自分の投稿のみ削除できます"
            return
        }

        do {
            try await dataService.deletePost(post.postId)
        } catch {
            errorMessage = "投稿の削除に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Like Operations

    func toggleLike(on post: FirebasePost) async {
        guard isAuthenticated else {
            errorMessage = "サインインしてください"
            return
        }

        do {
            try await dataService.toggleLike(on: post.postId, userId: currentUserId)
        } catch {
            errorMessage = "いいね操作に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Helper Methods

    func isOwnPost(_ post: FirebasePost) -> Bool {
        post.authorId == currentUserId
    }

    func isLikedByCurrentUser(_ post: FirebasePost) -> Bool {
        post.isLikedBy(currentUserId)
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }
}
