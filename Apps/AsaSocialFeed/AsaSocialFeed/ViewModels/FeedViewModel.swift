import Foundation
import SwiftUI

@MainActor
@Observable
final class FeedViewModel {
    // MARK: - Dependencies

    private let dataService: SocialFeedDataService

    // MARK: - State

    private(set) var posts: [Post] = []
    private(set) var currentUserName: String
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - UI State

    var showingNewPost = false
    var showingUserNameSetting = false

    // MARK: - Computed Properties

    var hasUserName: Bool {
        !currentUserName.isEmpty
    }

    // MARK: - Initializer

    init(dataService: SocialFeedDataService) {
        self.dataService = dataService
        self.currentUserName = UserDefaults.standard.string(forKey: "currentUserName") ?? ""
    }

    // MARK: - Data Loading

    func loadPosts() {
        isLoading = true
        errorMessage = nil

        do {
            posts = try dataService.fetchAllPosts()
        } catch {
            errorMessage = "投稿の読み込みに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Post Operations

    func createPost(content: String) {
        guard hasUserName else {
            errorMessage = "ユーザー名を設定してください"
            return
        }

        guard !content.isEmpty else {
            errorMessage = "投稿内容を入力してください"
            return
        }

        do {
            _ = try dataService.createPost(content: content, authorName: currentUserName)
            loadPosts()
        } catch {
            errorMessage = "投稿の作成に失敗しました: \(error.localizedDescription)"
        }
    }

    func deletePost(_ post: Post) {
        do {
            try dataService.deletePost(post)
            loadPosts()
        } catch {
            errorMessage = "投稿の削除に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Like Operations

    func toggleLike(on post: Post) {
        guard hasUserName else {
            errorMessage = "ユーザー名を設定してください"
            return
        }

        do {
            try dataService.toggleLike(on: post, by: currentUserName)
            loadPosts()
        } catch {
            errorMessage = "いいね操作に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - User Operations

    func setUserName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "ユーザー名を入力してください"
            return
        }

        currentUserName = trimmed
        UserDefaults.standard.set(trimmed, forKey: "currentUserName")
    }

    // MARK: - Error Handling

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
}
