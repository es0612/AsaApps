import Testing
import Foundation
@testable import AsaEventLive

// MARK: - EventPost Tests

struct EventPostTests {
    // MARK: - Initialization Tests

    @Test("投稿初期化テスト")
    func testPostInitialization() {
        let post = EventPost(
            eventId: "event-1",
            authorId: "user-1",
            authorName: "テストユーザー",
            content: "テスト投稿です"
        )

        #expect(post.eventId == "event-1")
        #expect(post.authorId == "user-1")
        #expect(post.authorName == "テストユーザー")
        #expect(post.content == "テスト投稿です")
        #expect(post.type == .text)
        #expect(post.likeCount == 0)
        #expect(post.likedByUserIds.isEmpty)
        #expect(!post.isPinned)
        #expect(!post.isDeleted)
    }

    @Test("投稿タイプアイコンテスト")
    func testPostTypeIcons() {
        #expect(EventPostType.text.icon == "text.bubble")
        #expect(EventPostType.photo.icon == "photo")
        #expect(EventPostType.milestone.icon == "flag.fill")
        #expect(EventPostType.announcement.icon == "megaphone.fill")
    }

    // MARK: - Like Tests

    @Test("いいねチェックテスト")
    func testIsLikedBy() {
        let post = EventPost(
            eventId: "event-1",
            authorId: "user-1",
            authorName: "ユーザー",
            content: "投稿内容",
            likedByUserIds: ["user-2", "user-3"]
        )

        #expect(post.isLikedBy(userId: "user-2") == true)
        #expect(post.isLikedBy(userId: "user-3") == true)
        #expect(post.isLikedBy(userId: "user-1") == false)
        #expect(post.isLikedBy(userId: "user-99") == false)
    }

    // MARK: - Time Ago Tests

    @Test("時間経過表示テスト")
    func testTimeAgo() {
        let recentPost = EventPost(
            eventId: "event-1",
            authorId: "user-1",
            authorName: "ユーザー",
            content: "最近の投稿",
            createdAt: Date()
        )

        // timeAgoが空でないことを確認
        #expect(!recentPost.timeAgo.isEmpty)
    }

    // MARK: - Equatable Tests

    @Test("投稿等価性テスト")
    func testPostEquality() {
        let post1 = EventPost(
            id: "post-1",
            eventId: "event-1",
            authorId: "user-1",
            authorName: "ユーザー1",
            content: "内容1"
        )

        let post2 = EventPost(
            id: "post-1",
            eventId: "event-2", // 異なるイベント
            authorId: "user-2",
            authorName: "ユーザー2",
            content: "内容2"
        )

        let post3 = EventPost(
            id: "post-2", // 異なるID
            eventId: "event-1",
            authorId: "user-1",
            authorName: "ユーザー1",
            content: "内容1"
        )

        #expect(post1 == post2) // IDが同じなので等価
        #expect(post1 != post3) // IDが異なるので不等価
    }

    // MARK: - Sample Data Tests

    @Test("サンプル投稿データ存在確認")
    func testSamplePostsExist() {
        #expect(!EventPost.samplePosts.isEmpty)
        #expect(EventPost.samplePosts.count >= 3)
    }
}
