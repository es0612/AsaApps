import Testing
import Foundation
@testable import AsaSocialFeed

@MainActor
@Test("FeedViewModel: ユーザー名設定テスト")
func testSetUserName() async {
    let service = try! SocialFeedDataService()
    let viewModel = FeedViewModel(dataService: service)

    viewModel.setUserName("テストユーザー")

    #expect(viewModel.currentUserName == "テストユーザー")
    #expect(viewModel.hasUserName)
}

@MainActor
@Test("FeedViewModel: 空白ユーザー名の拒否テスト")
func testSetEmptyUserName() async {
    let service = try! SocialFeedDataService()
    let viewModel = FeedViewModel(dataService: service)

    viewModel.setUserName("   ") // 空白のみ

    #expect(viewModel.errorMessage != nil)
    #expect(!viewModel.hasUserName)
}

@MainActor
@Test("FeedViewModel: 投稿作成テスト")
func testCreatePost() async {
    let service = try! SocialFeedDataService()
    let viewModel = FeedViewModel(dataService: service)

    viewModel.setUserName("テストユーザー")
    viewModel.createPost(content: "テスト投稿内容")
    viewModel.loadPosts()

    #expect(viewModel.posts.count > 0)
    #expect(viewModel.posts.first?.content == "テスト投稿内容")
    #expect(viewModel.posts.first?.authorName == "テストユーザー")
}

@MainActor
@Test("FeedViewModel: 空投稿の拒否テスト")
func testCreateEmptyPost() async {
    let service = try! SocialFeedDataService()
    let viewModel = FeedViewModel(dataService: service)

    viewModel.setUserName("テストユーザー")
    viewModel.createPost(content: "") // 空投稿

    #expect(viewModel.errorMessage != nil)
}

@MainActor
@Test("FeedViewModel: ユーザー名未設定時の投稿拒否テスト")
func testCreatePostWithoutUserName() async {
    let service = try! SocialFeedDataService()
    let viewModel = FeedViewModel(dataService: service)

    viewModel.createPost(content: "テスト投稿")

    #expect(viewModel.errorMessage != nil)
}
