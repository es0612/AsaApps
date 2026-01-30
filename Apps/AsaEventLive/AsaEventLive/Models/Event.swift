import Foundation
#if FIREBASE_ENABLED
import FirebaseFirestore
#endif

// MARK: - Event Category

enum EventCategory: String, Codable, CaseIterable, Sendable {
    case birthday = "birthday"
    case sports = "sports"
    case travel = "travel"
    case party = "party"
    case wedding = "wedding"
    case graduation = "graduation"
    case reunion = "reunion"
    case other = "other"

    var displayName: String {
        switch self {
        case .birthday: return "誕生日"
        case .sports: return "運動会・スポーツ"
        case .travel: return "旅行"
        case .party: return "パーティー"
        case .wedding: return "結婚式"
        case .graduation: return "卒業式"
        case .reunion: return "同窓会"
        case .other: return "その他"
        }
    }

    var icon: String {
        switch self {
        case .birthday: return "birthday.cake"
        case .sports: return "sportscourt"
        case .travel: return "airplane"
        case .party: return "party.popper"
        case .wedding: return "heart.fill"
        case .graduation: return "graduationcap"
        case .reunion: return "person.3.fill"
        case .other: return "calendar"
        }
    }
}

// MARK: - Event Status

enum EventStatus: String, Codable, Sendable {
    case upcoming = "upcoming"
    case live = "live"
    case ended = "ended"

    var displayName: String {
        switch self {
        case .upcoming: return "開催前"
        case .live: return "ライブ中"
        case .ended: return "終了"
        }
    }
}

// MARK: - Event

struct Event: Identifiable, Codable, Sendable, Equatable, Hashable {
    // MARK: - Properties

    var id: String
    var title: String
    var description: String
    var category: EventCategory
    var location: String?
    var coverImageURL: String?

    var startDate: Date
    var endDate: Date?

    var hostId: String
    var hostName: String
    var coHostIds: [String]

    var inviteCode: String
    var participantIds: [String]
    var maxParticipants: Int?

    var isPublic: Bool
    var isDeleted: Bool

    var createdAt: Date?
    var updatedAt: Date?

    // MARK: - Computed Properties

    var status: EventStatus {
        let now = Date()
        if now < startDate {
            return .upcoming
        } else if let endDate = endDate, now > endDate {
            return .ended
        } else {
            return .live
        }
    }

    var participantCount: Int {
        participantIds.count
    }

    var isHostOrCoHost: Bool {
        // This will be checked with current user ID in ViewModel
        false
    }

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String = "",
        category: EventCategory = .other,
        location: String? = nil,
        coverImageURL: String? = nil,
        startDate: Date,
        endDate: Date? = nil,
        hostId: String,
        hostName: String,
        coHostIds: [String] = [],
        inviteCode: String = "",
        participantIds: [String] = [],
        maxParticipants: Int? = nil,
        isPublic: Bool = false,
        isDeleted: Bool = false,
        createdAt: Date? = Date(),
        updatedAt: Date? = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.location = location
        self.coverImageURL = coverImageURL
        self.startDate = startDate
        self.endDate = endDate
        self.hostId = hostId
        self.hostName = hostName
        self.coHostIds = coHostIds
        self.inviteCode = inviteCode
        self.participantIds = participantIds
        self.maxParticipants = maxParticipants
        self.isPublic = isPublic
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Equatable & Hashable

    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Firestore Codable

#if FIREBASE_ENABLED
extension Event {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case location
        case coverImageURL
        case startDate
        case endDate
        case hostId
        case hostName
        case coHostIds
        case inviteCode
        case participantIds
        case maxParticipants
        case isPublic
        case isDeleted
        case createdAt
        case updatedAt
    }
}
#endif

// MARK: - Sample Data

extension Event {
    static let sampleEvents: [Event] = [
        Event(
            id: "event-1",
            title: "太郎の5歳誕生日会",
            description: "太郎の誕生日を一緒にお祝いしましょう！",
            category: .birthday,
            location: "自宅",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200),
            hostId: "user-1",
            hostName: "山田パパ",
            inviteCode: "TARO05",
            participantIds: ["user-1", "user-2", "user-3"]
        ),
        Event(
            id: "event-2",
            title: "春の運動会",
            description: "子供たちの運動会をリアルタイムで共有！",
            category: .sports,
            location: "○○小学校",
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date().addingTimeInterval(10800),
            hostId: "user-1",
            hostName: "山田パパ",
            inviteCode: "UNDOU",
            participantIds: ["user-1", "user-2", "user-3", "user-4", "user-5"]
        ),
        Event(
            id: "event-3",
            title: "家族旅行 in 沖縄",
            description: "3泊4日の沖縄旅行",
            category: .travel,
            location: "沖縄県",
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date().addingTimeInterval(172800),
            hostId: "user-2",
            hostName: "佐藤ママ",
            inviteCode: "OKI24",
            participantIds: ["user-1", "user-2"]
        )
    ]
}
