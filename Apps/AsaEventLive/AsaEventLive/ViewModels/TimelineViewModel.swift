import Foundation
import SwiftUI

// MARK: - TimelineViewModel

@Observable
@MainActor
final class TimelineViewModel {
    // MARK: - Properties

    private(set) var posts: [EventPost] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    var newPostContent: String = ""
    var isCreatingPost: Bool = false

    private let dataService: any EventDataServiceProtocol
    private let eventId: String
    private let userId: String
    private let authorName: String

    private var postsListener: Any?

    // MARK: - Computed Properties

    var canCreatePost: Bool {
        !newPostContent.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var pinnedPosts: [EventPost] {
        posts.filter { $0.isPinned }
    }

    var regularPosts: [EventPost] {
        posts.filter { !$0.isPinned }
    }

    // MARK: - Initialization

    init(
        eventId: String,
        userId: String,
        authorName: String,
        dataService: any EventDataServiceProtocol
    ) {
        self.eventId = eventId
        self.userId = userId
        self.authorName = authorName
        self.dataService = dataService
    }

    // Note: ViewのonDisappearでstopObserving()を呼び出してリスナーを解除する
    // deinitからはMainActor隔離プロパティにアクセスできないため、明示的な解除が必要

    // MARK: - Public Methods

    func startObserving() {
        postsListener = dataService.observePosts(eventId: eventId) { [weak self] posts in
            Task { @MainActor [weak self] in
                self?.posts = posts
            }
        }
    }

    func stopObserving() {
        if let listener = postsListener {
            dataService.removeListener(listener)
            postsListener = nil
        }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            posts = try await dataService.fetchPosts(eventId: eventId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func createPost(type: EventPostType = .text) async {
        guard canCreatePost else { return }

        isCreatingPost = true
        errorMessage = nil

        let content = newPostContent.trimmingCharacters(in: .whitespaces)

        do {
            let post = EventPost(
                eventId: eventId,
                authorId: userId,
                authorName: authorName,
                type: type,
                content: content
            )

            _ = try await dataService.createPost(post)
            newPostContent = ""
            isCreatingPost = false
        } catch {
            isCreatingPost = false
            errorMessage = error.localizedDescription
        }
    }

    func toggleLike(on post: EventPost) async {
        // オプティミスティックUI: 即座にUIを更新
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            var updatedPost = posts[index]
            if updatedPost.likedByUserIds.contains(userId) {
                updatedPost.likedByUserIds.removeAll { $0 == userId }
            } else {
                updatedPost.likedByUserIds.append(userId)
            }
            updatedPost.likeCount = updatedPost.likedByUserIds.count
            posts[index] = updatedPost
        }

        // サーバーに同期
        do {
            try await dataService.toggleLike(
                postId: post.id,
                eventId: eventId,
                userId: userId
            )
        } catch {
            // エラー時は元に戻す（リスナーから最新データが来る）
            errorMessage = error.localizedDescription
        }
    }

    func deletePost(_ post: EventPost) async {
        do {
            try await dataService.deletePost(post.id, eventId: eventId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
