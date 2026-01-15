import Foundation
#if FIREBASE_ENABLED
@preconcurrency import FirebaseFirestore
#endif

// MARK: - Firebase Post Model

/// Firestoreに保存される投稿データ
struct FirebasePost: Codable, Identifiable, Sendable {
    #if FIREBASE_ENABLED
    @DocumentID var id: String?
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    #else
    var id: String?
    var createdAt: Date?
    var updatedAt: Date?
    #endif

    var content: String
    var authorId: String
    var authorName: String
    var authorPhotoURL: String?
    var imageURL: String?
    var likeCount: Int
    var likedByUserIds: [String]

    // MARK: - Computed Properties

    /// 投稿ID（存在しない場合は空文字）
    var postId: String {
        id ?? ""
    }

    /// 指定ユーザーがいいねしているか
    func isLikedBy(_ userId: String) -> Bool {
        likedByUserIds.contains(userId)
    }

    /// 相対時間表示（「3分前」「2時間前」など）
    var timeAgo: String {
        guard let createdAt = createdAt else { return "不明" }

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

    /// フォーマットされた日付
    var formattedDate: String {
        guard let createdAt = createdAt else { return "不明" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }

    // MARK: - Initializer

    init(
        id: String? = nil,
        content: String,
        authorId: String,
        authorName: String,
        authorPhotoURL: String? = nil,
        imageURL: String? = nil,
        likeCount: Int = 0,
        likedByUserIds: [String] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.authorId = authorId
        self.authorName = authorName
        self.authorPhotoURL = authorPhotoURL
        self.imageURL = imageURL
        self.likeCount = likeCount
        self.likedByUserIds = likedByUserIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - FirebasePost Extension for Equatable

extension FirebasePost: Equatable {
    static func == (lhs: FirebasePost, rhs: FirebasePost) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - FirebasePost Extension for Hashable

extension FirebasePost: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
