import Foundation

// MARK: - Social Feed Data Service Error

enum SocialFeedDataError: Error, LocalizedError {
    case fetchFailed(String)
    case createFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case uploadFailed(String)
    case notAuthenticated
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "データの取得に失敗しました: \(message)"
        case .createFailed(let message):
            return "投稿の作成に失敗しました: \(message)"
        case .updateFailed(let message):
            return "更新に失敗しました: \(message)"
        case .deleteFailed(let message):
            return "削除に失敗しました: \(message)"
        case .uploadFailed(let message):
            return "アップロードに失敗しました: \(message)"
        case .notAuthenticated:
            return "認証が必要です"
        case .unknown(let error):
            return "エラーが発生しました: \(error.localizedDescription)"
        }
    }
}

// MARK: - Social Feed Data Service Protocol

/// ソーシャルフィードデータサービスのプロトコル
protocol SocialFeedDataServiceProtocol: Sendable {
    /// 全投稿を取得
    func fetchPosts() async throws -> [FirebasePost]

    /// 投稿を作成
    func createPost(content: String, authorId: String, authorName: String, authorPhotoURL: String?, imageData: Data?) async throws -> FirebasePost

    /// 投稿を削除
    func deletePost(_ postId: String) async throws

    /// いいねをトグル
    func toggleLike(on postId: String, userId: String) async throws

    /// 投稿のリアルタイムリスナーを設定
    func observePosts(_ handler: @escaping ([FirebasePost]) -> Void) -> Any

    /// リスナーを解除
    func removeListener(_ listener: Any)

    /// 画像をアップロード
    func uploadImage(_ data: Data) async throws -> String
}
