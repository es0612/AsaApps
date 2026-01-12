import Foundation
import SwiftData

@Model
final class Post: Identifiable {
    var id: UUID
    var content: String
    var authorName: String
    var createdAt: Date

    // MARK: - Swift Data リレーション（1対多）

    @Relationship(deleteRule: .cascade, inverse: \Like.post)
    var likes: [Like] = []

    // MARK: - Initializer

    init(content: String, authorName: String) {
        self.id = UUID()
        self.content = content
        self.authorName = authorName
        self.createdAt = Date()
        self.likes = []
    }

    // MARK: - Computed Properties

    /// いいね数
    var likeCount: Int {
        likes.count
    }

    /// 現在のユーザーがいいねしているか
    func isLikedBy(_ userName: String) -> Bool {
        likes.contains { $0.userName == userName }
    }

    /// 相対時間表示（「3分前」「2時間前」など）
    var timeAgo: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)

        if timeInterval < 60 {
            return "たった今"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)時間前"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)日前"
        }
    }

    // MARK: - Methods

    /// いいねを追加（ユーザー名重複チェック）
    func addLike(from userName: String) {
        guard !isLikedBy(userName) else { return }
        let like = Like(userName: userName)
        like.post = self
        likes.append(like)
    }

    /// いいねを削除
    func removeLike(from userName: String) {
        likes.removeAll { $0.userName == userName }
    }
}
