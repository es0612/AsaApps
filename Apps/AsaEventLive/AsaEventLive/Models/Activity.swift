import Foundation
#if FIREBASE_ENABLED
import FirebaseFirestore
#endif

// MARK: - Activity Type

enum ActivityType: String, Codable, Sendable {
    case joined = "joined"
    case left = "left"
    case posted = "posted"
    case liked = "liked"
    case commented = "commented"
    case milestone = "milestone"
    case photoAdded = "photoAdded"
    case settingChanged = "settingChanged"

    var icon: String {
        switch self {
        case .joined: return "person.badge.plus"
        case .left: return "person.badge.minus"
        case .posted: return "text.bubble"
        case .liked: return "heart.fill"
        case .commented: return "bubble.left"
        case .milestone: return "flag.fill"
        case .photoAdded: return "photo"
        case .settingChanged: return "gear"
        }
    }

    var color: String {
        switch self {
        case .joined: return "green"
        case .left: return "gray"
        case .posted: return "blue"
        case .liked: return "pink"
        case .commented: return "orange"
        case .milestone: return "purple"
        case .photoAdded: return "cyan"
        case .settingChanged: return "gray"
        }
    }
}

// MARK: - Activity

struct Activity: Identifiable, Codable, Sendable, Equatable {
    // MARK: - Properties

    var id: String
    var eventId: String
    var userId: String
    var userName: String
    var userPhotoURL: String?

    var type: ActivityType
    var message: String
    var relatedObjectId: String?

    var createdAt: Date?

    // MARK: - Computed Properties

    var timeAgo: String {
        guard let createdAt = createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var formattedMessage: String {
        switch type {
        case .joined:
            return "\(userName)さんが参加しました"
        case .left:
            return "\(userName)さんが退出しました"
        case .posted:
            return "\(userName)さんが投稿しました"
        case .liked:
            return "\(userName)さんがいいねしました"
        case .commented:
            return "\(userName)さんがコメントしました"
        case .milestone:
            return message
        case .photoAdded:
            return "\(userName)さんが写真を追加しました"
        case .settingChanged:
            return message
        }
    }

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        eventId: String,
        userId: String,
        userName: String,
        userPhotoURL: String? = nil,
        type: ActivityType,
        message: String = "",
        relatedObjectId: String? = nil,
        createdAt: Date? = Date()
    ) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.userName = userName
        self.userPhotoURL = userPhotoURL
        self.type = type
        self.message = message
        self.relatedObjectId = relatedObjectId
        self.createdAt = createdAt
    }

    // MARK: - Equatable

    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Firestore Codable

#if FIREBASE_ENABLED
extension Activity {
    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case userId
        case userName
        case userPhotoURL
        case type
        case message
        case relatedObjectId
        case createdAt
    }
}
#endif

// MARK: - Sample Data

extension Activity {
    static let sampleActivities: [Activity] = [
        Activity(
            id: "activity-1",
            eventId: "event-1",
            userId: "user-3",
            userName: "田中おじいちゃん",
            type: .joined,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        Activity(
            id: "activity-2",
            eventId: "event-1",
            userId: "user-2",
            userName: "佐藤ママ",
            type: .posted,
            message: "ケーキが届きました！",
            relatedObjectId: "post-2",
            createdAt: Date().addingTimeInterval(-1800)
        ),
        Activity(
            id: "activity-3",
            eventId: "event-1",
            userId: "user-1",
            userName: "山田パパ",
            type: .liked,
            relatedObjectId: "post-2",
            createdAt: Date().addingTimeInterval(-1500)
        ),
        Activity(
            id: "activity-4",
            eventId: "event-1",
            userId: "user-3",
            userName: "田中おじいちゃん",
            type: .milestone,
            message: "ケーキカット完了！",
            createdAt: Date().addingTimeInterval(-600)
        ),
        Activity(
            id: "activity-5",
            eventId: "event-1",
            userId: "user-5",
            userName: "木村おじさん",
            type: .joined,
            createdAt: Date().addingTimeInterval(-300)
        )
    ]
}
