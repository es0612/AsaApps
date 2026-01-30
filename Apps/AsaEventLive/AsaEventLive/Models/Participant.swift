import Foundation
#if FIREBASE_ENABLED
import FirebaseFirestore
#endif

// MARK: - Participant Role

enum ParticipantRole: String, Codable, Sendable {
    case host = "host"
    case coHost = "coHost"
    case participant = "participant"

    var displayName: String {
        switch self {
        case .host: return "ホスト"
        case .coHost: return "共同ホスト"
        case .participant: return "参加者"
        }
    }

    var canManageEvent: Bool {
        switch self {
        case .host, .coHost: return true
        case .participant: return false
        }
    }

    var canPost: Bool {
        true
    }
}

// MARK: - Online Status

enum OnlineStatus: String, Codable, Sendable {
    case online = "online"
    case away = "away"
    case offline = "offline"

    var color: String {
        switch self {
        case .online: return "green"
        case .away: return "yellow"
        case .offline: return "gray"
        }
    }
}

// MARK: - Participant

struct Participant: Identifiable, Codable, Sendable, Equatable {
    // MARK: - Properties

    var id: String
    var eventId: String
    var userId: String
    var displayName: String
    var photoURL: String?

    var role: ParticipantRole
    var onlineStatus: OnlineStatus

    var joinedAt: Date?
    var lastSeenAt: Date?

    var isNotificationsEnabled: Bool
    var isMuted: Bool

    // MARK: - Computed Properties

    var initials: String {
        let components = displayName.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(displayName.prefix(2)).uppercased()
    }

    var lastSeenText: String {
        guard let lastSeenAt = lastSeenAt else { return "" }
        if onlineStatus == .online { return "オンライン" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ja_JP")
        return "最終: " + formatter.localizedString(for: lastSeenAt, relativeTo: Date())
    }

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        eventId: String,
        userId: String,
        displayName: String,
        photoURL: String? = nil,
        role: ParticipantRole = .participant,
        onlineStatus: OnlineStatus = .offline,
        joinedAt: Date? = Date(),
        lastSeenAt: Date? = Date(),
        isNotificationsEnabled: Bool = true,
        isMuted: Bool = false
    ) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.displayName = displayName
        self.photoURL = photoURL
        self.role = role
        self.onlineStatus = onlineStatus
        self.joinedAt = joinedAt
        self.lastSeenAt = lastSeenAt
        self.isNotificationsEnabled = isNotificationsEnabled
        self.isMuted = isMuted
    }

    // MARK: - Equatable

    static func == (lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Firestore Codable

#if FIREBASE_ENABLED
extension Participant {
    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case userId
        case displayName
        case photoURL
        case role
        case onlineStatus
        case joinedAt
        case lastSeenAt
        case isNotificationsEnabled
        case isMuted
    }
}
#endif

// MARK: - Sample Data

extension Participant {
    static let sampleParticipants: [Participant] = [
        Participant(
            id: "part-1",
            eventId: "event-1",
            userId: "user-1",
            displayName: "山田パパ",
            role: .host,
            onlineStatus: .online
        ),
        Participant(
            id: "part-2",
            eventId: "event-1",
            userId: "user-2",
            displayName: "佐藤ママ",
            role: .coHost,
            onlineStatus: .online
        ),
        Participant(
            id: "part-3",
            eventId: "event-1",
            userId: "user-3",
            displayName: "田中おじいちゃん",
            role: .participant,
            onlineStatus: .away,
            lastSeenAt: Date().addingTimeInterval(-600)
        ),
        Participant(
            id: "part-4",
            eventId: "event-1",
            userId: "user-4",
            displayName: "鈴木おばあちゃん",
            role: .participant,
            onlineStatus: .offline,
            lastSeenAt: Date().addingTimeInterval(-3600)
        ),
        Participant(
            id: "part-5",
            eventId: "event-1",
            userId: "user-5",
            displayName: "木村おじさん",
            role: .participant,
            onlineStatus: .online
        )
    ]
}
