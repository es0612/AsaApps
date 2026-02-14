import Foundation
import SwiftData

// MARK: - CommunityPost

/// 掲示板投稿モデル
@Model
public final class CommunityPost {
    public var id: UUID = UUID()
    public var title: String = ""
    public var content: String = ""
    public var categoryRawValue: String = PostCategory.general.rawValue
    public var imageData: Data?
    public var latitude: Double?
    public var longitude: Double?
    public var isRead: Bool = false
    public var isPinned: Bool = false
    public var likeCount: Int = 0
    public var commentCount: Int = 0
    public var sentimentScore: Double?
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public var community: Community?
    public var author: CommunityProfile?

    public init(
        title: String,
        content: String,
        category: PostCategory = .general,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.categoryRawValue = category.rawValue
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Category Accessor

    /// PostCategory への変換アクセサ（SwiftData enum保存パターン）
    public var category: PostCategory {
        get { PostCategory(rawValue: categoryRawValue) ?? .general }
        set { categoryRawValue = newValue.rawValue }
    }

    // MARK: - Computed Properties

    /// 位置情報が付与されているか
    public var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    /// 投稿からの経過時間（表示用テキスト）
    public var timeAgoText: String {
        let interval = Date().timeIntervalSince(createdAt)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "たった今" }
        if minutes < 60 { return "\(minutes)分前" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)時間前" }
        let days = hours / 24
        if days < 7 { return "\(days)日前" }
        let weeks = days / 7
        return "\(weeks)週間前"
    }
}
