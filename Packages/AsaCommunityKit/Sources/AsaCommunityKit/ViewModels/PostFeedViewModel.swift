import Foundation

// MARK: - PostFeedViewModel

/// 掲示板フィードのViewModel
///
/// 投稿一覧表示、カテゴリフィルタ、検索、作成、いいね、削除を管理する。
/// 感情分析（ContentModerating）を用いて投稿内容を自動チェックする。
@MainActor @Observable
public final class PostFeedViewModel {
    // MARK: - Dependencies

    private let dataService: CommunityDataServiceProtocol
    private let moderator: ContentModerating

    // MARK: - Properties

    public var posts: [CommunityPost] = []
    public var selectedCategory: PostCategory?
    public var searchText: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        dataService: CommunityDataServiceProtocol,
        moderator: ContentModerating
    ) {
        self.dataService = dataService
        self.moderator = moderator
    }

    // MARK: - Computed Properties

    /// 検索テキストでフィルタされた投稿一覧
    public var filteredPosts: [CommunityPost] {
        guard !searchText.isEmpty else { return posts }
        let query = searchText.lowercased()
        return posts.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
    }

    // MARK: - Methods

    /// カテゴリフィルタ付きで投稿を取得する
    public func loadPosts() {
        isLoading = true
        errorMessage = nil
        do {
            posts = try dataService.fetchPosts(category: selectedCategory)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 感情分析を実行して投稿を作成する
    public func createPost(
        title: String,
        content: String,
        category: PostCategory,
        imageData: Data? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        isLoading = true
        errorMessage = nil
        do {
            // 感情分析
            let result = moderator.analyzeSentiment(text: "\(title) \(content)")
            guard result.isAcceptable else {
                errorMessage = result.warningMessage ?? "投稿内容に問題があります"
                isLoading = false
                return
            }

            let post = CommunityPost(
                title: title,
                content: content,
                category: category,
                latitude: latitude,
                longitude: longitude
            )
            post.imageData = imageData
            post.sentimentScore = result.sentimentScore
            try dataService.savePost(post)

            // リスト更新
            posts.insert(post, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 投稿を削除する
    public func deletePost(_ post: CommunityPost) {
        errorMessage = nil
        do {
            try dataService.deletePost(post)
            posts.removeAll { $0.id == post.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// いいね数を切り替える
    public func toggleLike(_ post: CommunityPost) {
        errorMessage = nil
        do {
            // シンプルにカウントを増減（ローカルのみ）
            if post.likeCount > 0 {
                post.likeCount -= 1
            } else {
                post.likeCount += 1
            }
            try dataService.savePost(post)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
