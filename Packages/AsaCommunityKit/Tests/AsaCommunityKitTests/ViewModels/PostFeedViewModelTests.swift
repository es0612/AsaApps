import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("PostFeedViewModel テスト")
struct PostFeedViewModelTests {

    @MainActor
    @Test("loadPosts - 投稿一覧を正しく取得する")
    func testLoadPosts() {
        let mock = MockCommunityDataService()
        mock.posts = [
            CommunityPost(title: "投稿1", content: "内容1"),
            CommunityPost(title: "投稿2", content: "内容2"),
        ]
        let moderator = MockContentModerator()
        let vm = PostFeedViewModel(dataService: mock, moderator: moderator)

        vm.loadPosts()

        #expect(vm.posts.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @MainActor
    @Test("loadPosts - エラー時にerrorMessageが設定される")
    func testLoadPostsError() {
        let mock = MockCommunityDataService()
        mock.shouldThrow = true
        let moderator = MockContentModerator()
        let vm = PostFeedViewModel(dataService: mock, moderator: moderator)

        vm.loadPosts()

        #expect(vm.errorMessage != nil)
        #expect(vm.posts.isEmpty)
    }

    @MainActor
    @Test("createPost - 感情分析を実行して投稿を作成する")
    func testCreatePost() {
        let mock = MockCommunityDataService()
        let moderator = MockContentModerator()
        let vm = PostFeedViewModel(dataService: mock, moderator: moderator)

        vm.createPost(title: "新規投稿", content: "テスト内容", category: .general)

        #expect(vm.posts.count == 1)
        #expect(vm.posts.first?.title == "新規投稿")
        #expect(vm.posts.first?.sentimentScore == 0.5)
        #expect(vm.errorMessage == nil)
    }

    @MainActor
    @Test("createPost - 不適切な内容は投稿を拒否する")
    func testCreatePostRejected() {
        let mock = MockCommunityDataService()
        let moderator = MockContentModerator(
            resultToReturn: ModerationResult(
                sentimentScore: -0.8,
                isAcceptable: false,
                warningMessage: "不適切な内容です"
            )
        )
        let vm = PostFeedViewModel(dataService: mock, moderator: moderator)

        vm.createPost(title: "不適切な投稿", content: "NG内容", category: .general)

        #expect(vm.posts.isEmpty)
        #expect(vm.errorMessage == "不適切な内容です")
    }

    @MainActor
    @Test("filteredPosts - 検索テキストで投稿をフィルタする")
    func testFilteredPosts() {
        let mock = MockCommunityDataService()
        let moderator = MockContentModerator()
        let vm = PostFeedViewModel(dataService: mock, moderator: moderator)
        vm.posts = [
            CommunityPost(title: "花見のお知らせ", content: "公園で花見します"),
            CommunityPost(title: "清掃活動", content: "町内清掃のお願い"),
            CommunityPost(title: "夏祭り情報", content: "今年も夏祭り開催"),
        ]

        vm.searchText = "花見"
        #expect(vm.filteredPosts.count == 1)
        #expect(vm.filteredPosts.first?.title == "花見のお知らせ")
    }

    @MainActor
    @Test("filteredPosts - 検索テキストが空なら全件返す")
    func testFilteredPostsEmpty() {
        let mock = MockCommunityDataService()
        let moderator = MockContentModerator()
        let vm = PostFeedViewModel(dataService: mock, moderator: moderator)
        vm.posts = [
            CommunityPost(title: "投稿1", content: ""),
            CommunityPost(title: "投稿2", content: ""),
        ]

        vm.searchText = ""
        #expect(vm.filteredPosts.count == 2)
    }

    @MainActor
    @Test("deletePost - 投稿を削除する")
    func testDeletePost() {
        let mock = MockCommunityDataService()
        let moderator = MockContentModerator()
        let vm = PostFeedViewModel(dataService: mock, moderator: moderator)
        let post = CommunityPost(title: "削除する投稿", content: "")
        vm.posts = [post]
        mock.posts = [post]

        vm.deletePost(post)

        #expect(vm.posts.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    @MainActor
    @Test("deletePost - エラー時にerrorMessageが設定される")
    func testDeletePostError() {
        let mock = MockCommunityDataService()
        mock.shouldThrow = true
        let moderator = MockContentModerator()
        let vm = PostFeedViewModel(dataService: mock, moderator: moderator)
        let post = CommunityPost(title: "テスト", content: "")
        vm.posts = [post]

        vm.deletePost(post)

        #expect(vm.errorMessage != nil)
    }
}
