import Foundation

// MARK: - EventDataError

enum EventDataError: Error, LocalizedError, Sendable {
    case fetchFailed(String)
    case createFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case joinFailed(String)
    case leaveFailed(String)
    case notAuthenticated
    case notFound
    case invalidInviteCode
    case eventFull
    case alreadyJoined
    case notParticipant
    case permissionDenied
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message): return "取得失敗: \(message)"
        case .createFailed(let message): return "作成失敗: \(message)"
        case .updateFailed(let message): return "更新失敗: \(message)"
        case .deleteFailed(let message): return "削除失敗: \(message)"
        case .joinFailed(let message): return "参加失敗: \(message)"
        case .leaveFailed(let message): return "退出失敗: \(message)"
        case .notAuthenticated: return "認証が必要です"
        case .notFound: return "データが見つかりません"
        case .invalidInviteCode: return "招待コードが無効です"
        case .eventFull: return "イベントの参加人数が上限に達しています"
        case .alreadyJoined: return "すでに参加しています"
        case .notParticipant: return "イベントの参加者ではありません"
        case .permissionDenied: return "この操作を行う権限がありません"
        case .unknown(let error): return "エラー: \(error.localizedDescription)"
        }
    }
}

// MARK: - EventDataServiceProtocol

protocol EventDataServiceProtocol: AnyObject, Sendable {
    // MARK: - Events

    func fetchEvents(userId: String) async throws -> [Event]
    func fetchEvent(id: String) async throws -> Event?
    func createEvent(_ event: Event) async throws -> Event
    func updateEvent(_ event: Event) async throws
    func deleteEvent(_ eventId: String) async throws

    // MARK: - Event Join/Leave

    func joinEvent(eventId: String, inviteCode: String, participant: Participant) async throws -> Event
    func leaveEvent(eventId: String, userId: String) async throws

    // MARK: - Posts

    func fetchPosts(eventId: String) async throws -> [EventPost]
    func createPost(_ post: EventPost) async throws -> EventPost
    func updatePost(_ post: EventPost) async throws
    func deletePost(_ postId: String, eventId: String) async throws
    func toggleLike(postId: String, eventId: String, userId: String) async throws

    // MARK: - Participants

    func fetchParticipants(eventId: String) async throws -> [Participant]
    func updateParticipant(_ participant: Participant) async throws
    func updateOnlineStatus(eventId: String, userId: String, status: OnlineStatus) async throws

    // MARK: - Activities

    func fetchActivities(eventId: String, limit: Int) async throws -> [Activity]
    func createActivity(_ activity: Activity) async throws -> Activity

    // MARK: - Real-time Observation

    func observeEvents(userId: String, handler: @escaping ([Event]) -> Void) -> Any
    func observeEvent(eventId: String, handler: @escaping (Event?) -> Void) -> Any
    func observePosts(eventId: String, handler: @escaping ([EventPost]) -> Void) -> Any
    func observeParticipants(eventId: String, handler: @escaping ([Participant]) -> Void) -> Any
    func observeActivities(eventId: String, limit: Int, handler: @escaping ([Activity]) -> Void) -> Any
    func removeListener(_ listener: Any)
}

// MARK: - Default Implementations

extension EventDataServiceProtocol {
    func fetchEvent(id: String) async throws -> Event? {
        let events = try await fetchEvents(userId: "")
        return events.first { $0.id == id }
    }

    func fetchActivities(eventId: String, limit: Int = 50) async throws -> [Activity] {
        try await fetchActivities(eventId: eventId, limit: limit)
    }
}
