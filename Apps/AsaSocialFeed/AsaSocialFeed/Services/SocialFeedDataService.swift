import Foundation
import SwiftData

@MainActor
final class SocialFeedDataService {
    private let container: ModelContainer

    // MARK: - Initializer

    init() throws {
        let schema = Schema([
            Post.self,
            Like.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        self.container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    // MARK: - Container Access

    var modelContext: ModelContext {
        container.mainContext
    }

    // MARK: - Post Operations

    /// 新しい投稿を作成
    func createPost(content: String, authorName: String) throws -> Post {
        let context = modelContext
        let post = Post(content: content, authorName: authorName)
        context.insert(post)
        try context.save()
        return post
    }

    /// 全ての投稿を取得（新しい順）
    func fetchAllPosts() throws -> [Post] {
        let context = modelContext
        let descriptor = FetchDescriptor<Post>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// 投稿を削除
    func deletePost(_ post: Post) throws {
        let context = modelContext
        context.delete(post)
        try context.save()
    }

    // MARK: - Like Operations

    /// いいねをトグル（いいね/いいね解除）
    func toggleLike(on post: Post, by userName: String) throws {
        if post.isLikedBy(userName) {
            post.removeLike(from: userName)
        } else {
            post.addLike(from: userName)
        }
        try modelContext.save()
    }

    /// 変更を保存
    func save() throws {
        try modelContext.save()
    }
}

// MARK: - Preview Support

#if DEBUG
extension SocialFeedDataService {
    /// プレビュー用のサンプルサービス
    static func previewService() throws -> SocialFeedDataService {
        let schema = Schema([Post.self, Like.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        // インスタンス作成
        let service = try SocialFeedDataService()

        // サンプルデータ作成
        let post1 = try service.createPost(
            content: "朝活で今日も頑張ります！☀️ SwiftUIの学習が楽しい。",
            authorName: "朝活パパ"
        )
        let post2 = try service.createPost(
            content: "AsaSocialFeed実装中です。Swift Dataのリレーションが便利！",
            authorName: "朝活パパ"
        )
        let post3 = try service.createPost(
            content: "家族との時間を大切にしながらコーディング🎨",
            authorName: "朝活パパ"
        )

        // いいね追加
        try service.toggleLike(on: post1, by: "家族")
        try service.toggleLike(on: post2, by: "家族")
        try service.toggleLike(on: post2, by: "友人")

        return service
    }
}
#endif
