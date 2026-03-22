import Foundation
#if FIREBASE_ENABLED
import FirebaseFirestore
#endif

// MARK: - Post Type

enum EventPostType: String, Codable, Sendable {
    case text = "text"
    case photo = "photo"
    case milestone = "milestone"
    case announcement = "announcement"

    var icon: String {
        switch self {
        case .text: return "text.bubble"
        case .photo: return "photo"
        case .milestone: return "flag.fill"
        case .announcement: return "megaphone.fill"
        }
    }
}

// MARK: - Event Post

struct EventPost: Identifiable, Codable, Sendable, Equatable {
    // MARK: - Properties

    var id: String
    var eventId: String
    var authorId: String
    var authorName: String
    var authorPhotoURL: String?

    var type: EventPostType
    var content: String
    var imageURL: String?

    var likeCount: Int
    var likedByUserIds: [String]
    var commentCount: Int

    var isPinned: Bool
    var isDeleted: Bool

    var createdAt: Date?
    var updatedAt: Date?

    // MARK: - Computed Properties

    var timeAgo: String {
        guard let createdAt = createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    func isLikedBy(userId: String) -> Bool {
        likedByUserIds.contains(userId)
    }

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        eventId: String,
        authorId: String,
        authorName: String,
        authorPhotoURL: String? = nil,
        type: EventPostType = .text,
        content: String,
        imageURL: String? = nil,
        likeCount: Int = 0,
        likedByUserIds: [String] = [],
        commentCount: Int = 0,
        isPinned: Bool = false,
        isDeleted: Bool = false,
        createdAt: Date? = Date(),
        updatedAt: Date? = Date()
    ) {
        self.id = id
        self.eventId = eventId
        self.authorId = authorId
        self.authorName = authorName
        self.authorPhotoURL = authorPhotoURL
        self.type = type
        self.content = content
        self.imageURL = imageURL
        self.likeCount = likeCount
        self.likedByUserIds = likedByUserIds
        self.commentCount = commentCount
        self.isPinned = isPinned
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Equatable

    static func == (lhs: EventPost, rhs: EventPost) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Firestore Codable

#if FIREBASE_ENABLED
extension EventPost {
    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case authorId
        case authorName
        case authorPhotoURL
        case type
        case content
        case imageURL
        case likeCount
        case likedByUserIds
        case commentCount
        case isPinned
        case isDeleted
        case createdAt
        case updatedAt
    }
}
#endif

// MARK: - Sample Data

extension EventPost {
    static let samplePosts: [EventPost] = [
        // MARK: - event-1: 太郎の5歳誕生日会（時系列順）
        EventPost(
            id: "post-1",
            eventId: "event-1",
            authorId: "user-1",
            authorName: "山田パパ",
            type: .announcement,
            content: "太郎の誕生日会、間もなく始まります！みんな楽しんでいきましょう🎉",
            isPinned: true,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        EventPost(
            id: "post-2",
            eventId: "event-1",
            authorId: "user-2",
            authorName: "佐藤ママ",
            type: .text,
            content: "飾り付け完了！風船たくさん膨らませました🎈 部屋がカラフルになったよ",
            likeCount: 4,
            likedByUserIds: ["user-1", "user-3", "user-4", "user-5"],
            commentCount: 1,
            createdAt: Date().addingTimeInterval(-6000)
        ),
        EventPost(
            id: "post-3",
            eventId: "event-1",
            authorId: "user-3",
            authorName: "田中おじいちゃん",
            type: .text,
            content: "到着しました！太郎くんに会えるの楽しみです。プレゼントも持ってきたよ",
            likeCount: 3,
            likedByUserIds: ["user-1", "user-2", "user-5"],
            createdAt: Date().addingTimeInterval(-5400)
        ),
        EventPost(
            id: "post-4",
            eventId: "event-1",
            authorId: "user-4",
            authorName: "鈴木おばあちゃん",
            type: .text,
            content: "手作りのぬいぐるみを持ってきました！太郎くん気に入ってくれるかな🧸",
            likeCount: 5,
            likedByUserIds: ["user-1", "user-2", "user-3", "user-5", "user-4"],
            commentCount: 2,
            createdAt: Date().addingTimeInterval(-4800)
        ),
        EventPost(
            id: "post-5",
            eventId: "event-1",
            authorId: "user-2",
            authorName: "佐藤ママ",
            type: .text,
            content: "ケーキが届きました！とても可愛いです🎂 太郎の大好きな恐竜デザイン",
            likeCount: 5,
            likedByUserIds: ["user-1", "user-3", "user-4", "user-5", "user-2"],
            commentCount: 3,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        EventPost(
            id: "post-6",
            eventId: "event-1",
            authorId: "user-5",
            authorName: "木村おじさん",
            type: .text,
            content: "太郎くん、プレゼントに大喜び！目がキラキラしてる✨",
            likeCount: 4,
            likedByUserIds: ["user-1", "user-2", "user-3", "user-4"],
            commentCount: 1,
            createdAt: Date().addingTimeInterval(-2400)
        ),
        EventPost(
            id: "post-7",
            eventId: "event-1",
            authorId: "user-1",
            authorName: "山田パパ",
            type: .announcement,
            content: "これからケーキカットです！みんな集まってください🎂🔪",
            likeCount: 3,
            likedByUserIds: ["user-2", "user-3", "user-5"],
            createdAt: Date().addingTimeInterval(-1500)
        ),
        EventPost(
            id: "post-8",
            eventId: "event-1",
            authorId: "user-3",
            authorName: "田中おじいちゃん",
            type: .milestone,
            content: "ケーキカット完了！太郎、5本のろうそくを一気に消しました🕯️ すごい！",
            likeCount: 5,
            likedByUserIds: ["user-1", "user-2", "user-4", "user-5", "user-3"],
            commentCount: 4,
            createdAt: Date().addingTimeInterval(-900)
        ),
        EventPost(
            id: "post-9",
            eventId: "event-1",
            authorId: "user-2",
            authorName: "佐藤ママ",
            type: .text,
            content: "Happy Birthday の歌、みんなで歌いました🎵 太郎の笑顔が最高でした！",
            likeCount: 5,
            likedByUserIds: ["user-1", "user-3", "user-4", "user-5", "user-2"],
            commentCount: 2,
            createdAt: Date().addingTimeInterval(-480)
        ),
        EventPost(
            id: "post-10",
            eventId: "event-1",
            authorId: "user-5",
            authorName: "木村おじさん",
            type: .milestone,
            content: "プレゼントタイム開始！太郎くんの反応が楽しみ🎁",
            likeCount: 3,
            likedByUserIds: ["user-1", "user-2", "user-4"],
            commentCount: 1,
            createdAt: Date().addingTimeInterval(-180)
        ),

        // MARK: - event-2: 春の運動会
        EventPost(
            id: "post-11",
            eventId: "event-2",
            authorId: "user-1",
            authorName: "山田パパ",
            type: .text,
            content: "太郎、かけっこで1位！素晴らしい！",
            likeCount: 4,
            likedByUserIds: ["user-2", "user-3", "user-4", "user-5"],
            createdAt: Date().addingTimeInterval(-300)
        )
    ]
}
