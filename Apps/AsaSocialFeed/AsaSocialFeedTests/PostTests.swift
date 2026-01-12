import Testing
import Foundation
@testable import AsaSocialFeed

@Test("Post: いいね追加テスト")
func testAddLike() {
    let post = Post(content: "テスト投稿", authorName: "テストユーザー")
    post.addLike(from: "いいねユーザー")

    #expect(post.likeCount == 1)
    #expect(post.isLikedBy("いいねユーザー"))
}

@Test("Post: いいね重複防止テスト")
func testDuplicateLike() {
    let post = Post(content: "テスト投稿", authorName: "テストユーザー")
    post.addLike(from: "いいねユーザー")
    post.addLike(from: "いいねユーザー") // 重複

    #expect(post.likeCount == 1)
}

@Test("Post: いいね削除テスト")
func testRemoveLike() {
    let post = Post(content: "テスト投稿", authorName: "テストユーザー")
    post.addLike(from: "いいねユーザー")
    post.removeLike(from: "いいねユーザー")

    #expect(post.likeCount == 0)
    #expect(!post.isLikedBy("いいねユーザー"))
}

@Test("Post: timeAgo プロパティテスト - たった今")
func testTimeAgoJustNow() {
    let post = Post(content: "テスト投稿", authorName: "テストユーザー")

    #expect(post.timeAgo == "たった今")
}

@Test("Post: 複数ユーザーのいいねテスト")
func testMultipleUserLikes() {
    let post = Post(content: "テスト投稿", authorName: "テストユーザー")
    post.addLike(from: "ユーザー1")
    post.addLike(from: "ユーザー2")
    post.addLike(from: "ユーザー3")

    #expect(post.likeCount == 3)
    #expect(post.isLikedBy("ユーザー1"))
    #expect(post.isLikedBy("ユーザー2"))
    #expect(post.isLikedBy("ユーザー3"))
}
