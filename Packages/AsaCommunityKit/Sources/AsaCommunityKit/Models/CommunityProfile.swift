import Foundation
import SwiftData

// MARK: - CommunityProfile

/// ユーザープロフィールモデル
@Model
public final class CommunityProfile {
    public var id: UUID = UUID()
    public var displayName: String = ""
    public var bio: String = ""
    public var avatarImageData: Data?
    public var joinedAt: Date = Date()
    public var isVerified: Bool = false
    public var postCount: Int = 0
    public var helpfulCount: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \CommunityPost.author)
    public var posts: [CommunityPost] = []

    @Relationship(deleteRule: .cascade, inverse: \EventRSVP.profile)
    public var rsvps: [EventRSVP] = []

    public init(
        displayName: String,
        bio: String = ""
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.bio = bio
        self.joinedAt = Date()
    }

    // MARK: - Computed Properties

    /// 活動スコア（投稿数 + お役立ち数の合計）
    public var activityScore: Int {
        postCount + helpfulCount
    }
}
