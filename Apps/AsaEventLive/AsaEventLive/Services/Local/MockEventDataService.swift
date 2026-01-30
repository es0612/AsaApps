import Foundation

// MARK: - MockEventDataService

final class MockEventDataService: EventDataServiceProtocol, @unchecked Sendable {
    // MARK: - Properties

    private var events: [String: Event] = [:]
    private var posts: [String: [EventPost]] = [:] // eventId -> posts
    private var participants: [String: [Participant]] = [:] // eventId -> participants
    private var activities: [String: [Activity]] = [:] // eventId -> activities

    private var eventObservers: [String: (String, ([Event]) -> Void)] = [:] // observerId -> (userId, handler)
    private var singleEventObservers: [String: (String, (Event?) -> Void)] = [:] // observerId -> (eventId, handler)
    private var postObservers: [String: (String, ([EventPost]) -> Void)] = [:] // observerId -> (eventId, handler)
    private var participantObservers: [String: (String, ([Participant]) -> Void)] = [:] // observerId -> (eventId, handler)
    private var activityObservers: [String: (String, Int, ([Activity]) -> Void)] = [:] // observerId -> (eventId, limit, handler)

    // MARK: - Initialization

    init() {
        // サンプルデータを初期化
        for event in Event.sampleEvents {
            events[event.id] = event
        }

        for post in EventPost.samplePosts {
            if posts[post.eventId] == nil {
                posts[post.eventId] = []
            }
            posts[post.eventId]?.append(post)
        }

        for participant in Participant.sampleParticipants {
            if participants[participant.eventId] == nil {
                participants[participant.eventId] = []
            }
            participants[participant.eventId]?.append(participant)
        }

        for activity in Activity.sampleActivities {
            if activities[activity.eventId] == nil {
                activities[activity.eventId] = []
            }
            activities[activity.eventId]?.append(activity)
        }
    }

    // MARK: - Events

    func fetchEvents(userId: String) async throws -> [Event] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return events.values
            .filter { !$0.isDeleted && $0.participantIds.contains(userId) }
            .sorted { ($0.startDate) > ($1.startDate) }
    }

    func fetchEvent(id: String) async throws -> Event? {
        try await Task.sleep(nanoseconds: 100_000_000)
        return events[id]
    }

    func createEvent(_ event: Event) async throws -> Event {
        try await Task.sleep(nanoseconds: 200_000_000)

        var newEvent = event
        newEvent.id = UUID().uuidString
        newEvent.inviteCode = InviteCodeGenerator.generate()
        newEvent.createdAt = Date()
        newEvent.updatedAt = Date()

        // ホストを参加者に追加
        if !newEvent.participantIds.contains(newEvent.hostId) {
            newEvent.participantIds.append(newEvent.hostId)
        }

        events[newEvent.id] = newEvent

        // ホストの参加者レコードを作成
        let hostParticipant = Participant(
            eventId: newEvent.id,
            userId: newEvent.hostId,
            displayName: newEvent.hostName,
            role: .host,
            onlineStatus: .online
        )
        participants[newEvent.id] = [hostParticipant]

        // アクティビティを記録
        let activity = Activity(
            eventId: newEvent.id,
            userId: newEvent.hostId,
            userName: newEvent.hostName,
            type: .settingChanged,
            message: "イベントを作成しました"
        )
        activities[newEvent.id] = [activity]

        notifyEventObservers()
        notifySingleEventObservers(eventId: newEvent.id)

        print("MockEventDataService: Event created - \(newEvent.title)")
        return newEvent
    }

    func updateEvent(_ event: Event) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard events[event.id] != nil else {
            throw EventDataError.notFound
        }

        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        events[event.id] = updatedEvent

        notifyEventObservers()
        notifySingleEventObservers(eventId: event.id)

        print("MockEventDataService: Event updated - \(event.title)")
    }

    func deleteEvent(_ eventId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard var event = events[eventId] else {
            throw EventDataError.notFound
        }

        event.isDeleted = true
        event.updatedAt = Date()
        events[eventId] = event

        notifyEventObservers()
        notifySingleEventObservers(eventId: eventId)

        print("MockEventDataService: Event deleted - \(eventId)")
    }

    // MARK: - Event Join/Leave

    func joinEvent(eventId: String, inviteCode: String, participant: Participant) async throws -> Event {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard var event = events[eventId] else {
            throw EventDataError.notFound
        }

        // 招待コードチェック
        guard InviteCodeGenerator.normalize(inviteCode) == event.inviteCode else {
            throw EventDataError.invalidInviteCode
        }

        // 既に参加しているかチェック
        guard !event.participantIds.contains(participant.userId) else {
            throw EventDataError.alreadyJoined
        }

        // 参加人数上限チェック
        if let maxParticipants = event.maxParticipants,
           event.participantIds.count >= maxParticipants {
            throw EventDataError.eventFull
        }

        // 参加者を追加
        event.participantIds.append(participant.userId)
        event.updatedAt = Date()
        events[eventId] = event

        // 参加者レコードを作成
        var newParticipant = participant
        newParticipant.eventId = eventId
        newParticipant.joinedAt = Date()
        newParticipant.onlineStatus = .online

        if participants[eventId] == nil {
            participants[eventId] = []
        }
        participants[eventId]?.append(newParticipant)

        // アクティビティを記録
        let activity = Activity(
            eventId: eventId,
            userId: participant.userId,
            userName: participant.displayName,
            type: .joined
        )
        if activities[eventId] == nil {
            activities[eventId] = []
        }
        activities[eventId]?.insert(activity, at: 0)

        notifyEventObservers()
        notifySingleEventObservers(eventId: eventId)
        notifyParticipantObservers(eventId: eventId)
        notifyActivityObservers(eventId: eventId)

        print("MockEventDataService: User joined event - \(participant.displayName) -> \(event.title)")
        return event
    }

    func leaveEvent(eventId: String, userId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard var event = events[eventId] else {
            throw EventDataError.notFound
        }

        // ホストは退出不可
        guard event.hostId != userId else {
            throw EventDataError.permissionDenied
        }

        // 参加者から削除
        event.participantIds.removeAll { $0 == userId }
        event.coHostIds.removeAll { $0 == userId }
        event.updatedAt = Date()
        events[eventId] = event

        // 参加者レコードを削除
        let leavingParticipant = participants[eventId]?.first { $0.userId == userId }
        participants[eventId]?.removeAll { $0.userId == userId }

        // アクティビティを記録
        if let participant = leavingParticipant {
            let activity = Activity(
                eventId: eventId,
                userId: userId,
                userName: participant.displayName,
                type: .left
            )
            activities[eventId]?.insert(activity, at: 0)
        }

        notifyEventObservers()
        notifySingleEventObservers(eventId: eventId)
        notifyParticipantObservers(eventId: eventId)
        notifyActivityObservers(eventId: eventId)

        print("MockEventDataService: User left event - \(userId)")
    }

    // MARK: - Posts

    func fetchPosts(eventId: String) async throws -> [EventPost] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return (posts[eventId] ?? [])
            .filter { !$0.isDeleted }
            .sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
    }

    func createPost(_ post: EventPost) async throws -> EventPost {
        try await Task.sleep(nanoseconds: 200_000_000)

        var newPost = post
        newPost.id = UUID().uuidString
        newPost.createdAt = Date()
        newPost.updatedAt = Date()

        if posts[post.eventId] == nil {
            posts[post.eventId] = []
        }
        posts[post.eventId]?.insert(newPost, at: 0)

        // アクティビティを記録
        let activity = Activity(
            eventId: post.eventId,
            userId: post.authorId,
            userName: post.authorName,
            type: post.type == .milestone ? .milestone : .posted,
            message: post.type == .milestone ? post.content : "",
            relatedObjectId: newPost.id
        )
        if activities[post.eventId] == nil {
            activities[post.eventId] = []
        }
        activities[post.eventId]?.insert(activity, at: 0)

        notifyPostObservers(eventId: post.eventId)
        notifyActivityObservers(eventId: post.eventId)

        print("MockEventDataService: Post created - \(newPost.content.prefix(20))...")
        return newPost
    }

    func updatePost(_ post: EventPost) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let index = posts[post.eventId]?.firstIndex(where: { $0.id == post.id }) else {
            throw EventDataError.notFound
        }

        var updatedPost = post
        updatedPost.updatedAt = Date()
        posts[post.eventId]?[index] = updatedPost

        notifyPostObservers(eventId: post.eventId)

        print("MockEventDataService: Post updated - \(post.id)")
    }

    func deletePost(_ postId: String, eventId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let index = posts[eventId]?.firstIndex(where: { $0.id == postId }) else {
            throw EventDataError.notFound
        }

        posts[eventId]?[index].isDeleted = true
        posts[eventId]?[index].updatedAt = Date()

        notifyPostObservers(eventId: eventId)

        print("MockEventDataService: Post deleted - \(postId)")
    }

    func toggleLike(postId: String, eventId: String, userId: String) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let index = posts[eventId]?.firstIndex(where: { $0.id == postId }) else {
            throw EventDataError.notFound
        }

        var post = posts[eventId]![index]

        if post.likedByUserIds.contains(userId) {
            post.likedByUserIds.removeAll { $0 == userId }
        } else {
            post.likedByUserIds.append(userId)

            // いいねのアクティビティを記録
            let participant = participants[eventId]?.first { $0.userId == userId }
            let activity = Activity(
                eventId: eventId,
                userId: userId,
                userName: participant?.displayName ?? "ユーザー",
                type: .liked,
                relatedObjectId: postId
            )
            activities[eventId]?.insert(activity, at: 0)
            notifyActivityObservers(eventId: eventId)
        }

        post.likeCount = post.likedByUserIds.count
        post.updatedAt = Date()
        posts[eventId]?[index] = post

        notifyPostObservers(eventId: eventId)

        print("MockEventDataService: Like toggled - \(postId)")
    }

    // MARK: - Participants

    func fetchParticipants(eventId: String) async throws -> [Participant] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return (participants[eventId] ?? [])
            .sorted { $0.role.rawValue < $1.role.rawValue }
    }

    func updateParticipant(_ participant: Participant) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let index = participants[participant.eventId]?.firstIndex(where: { $0.id == participant.id }) else {
            throw EventDataError.notFound
        }

        participants[participant.eventId]?[index] = participant
        notifyParticipantObservers(eventId: participant.eventId)

        print("MockEventDataService: Participant updated - \(participant.displayName)")
    }

    func updateOnlineStatus(eventId: String, userId: String, status: OnlineStatus) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let index = participants[eventId]?.firstIndex(where: { $0.userId == userId }) else {
            throw EventDataError.notFound
        }

        participants[eventId]?[index].onlineStatus = status
        participants[eventId]?[index].lastSeenAt = Date()

        notifyParticipantObservers(eventId: eventId)

        print("MockEventDataService: Online status updated - \(userId) -> \(status)")
    }

    // MARK: - Activities

    func fetchActivities(eventId: String, limit: Int = 50) async throws -> [Activity] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return Array((activities[eventId] ?? [])
            .sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
            .prefix(limit))
    }

    func createActivity(_ activity: Activity) async throws -> Activity {
        try await Task.sleep(nanoseconds: 100_000_000)

        var newActivity = activity
        newActivity.id = UUID().uuidString
        newActivity.createdAt = Date()

        if activities[activity.eventId] == nil {
            activities[activity.eventId] = []
        }
        activities[activity.eventId]?.insert(newActivity, at: 0)

        notifyActivityObservers(eventId: activity.eventId)

        print("MockEventDataService: Activity created - \(activity.type)")
        return newActivity
    }

    // MARK: - Real-time Observation

    func observeEvents(userId: String, handler: @escaping ([Event]) -> Void) -> Any {
        let observerId = UUID().uuidString
        eventObservers[observerId] = (userId, handler)

        // 初回コールバック
        let userEvents = events.values
            .filter { !$0.isDeleted && $0.participantIds.contains(userId) }
            .sorted { $0.startDate > $1.startDate }
        handler(Array(userEvents))

        return observerId
    }

    func observeEvent(eventId: String, handler: @escaping (Event?) -> Void) -> Any {
        let observerId = UUID().uuidString
        singleEventObservers[observerId] = (eventId, handler)

        // 初回コールバック
        handler(events[eventId])

        return observerId
    }

    func observePosts(eventId: String, handler: @escaping ([EventPost]) -> Void) -> Any {
        let observerId = UUID().uuidString
        postObservers[observerId] = (eventId, handler)

        // 初回コールバック
        let eventPosts = (posts[eventId] ?? [])
            .filter { !$0.isDeleted }
            .sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
        handler(eventPosts)

        return observerId
    }

    func observeParticipants(eventId: String, handler: @escaping ([Participant]) -> Void) -> Any {
        let observerId = UUID().uuidString
        participantObservers[observerId] = (eventId, handler)

        // 初回コールバック
        let eventParticipants = (participants[eventId] ?? [])
            .sorted { $0.role.rawValue < $1.role.rawValue }
        handler(eventParticipants)

        return observerId
    }

    func observeActivities(eventId: String, limit: Int = 50, handler: @escaping ([Activity]) -> Void) -> Any {
        let observerId = UUID().uuidString
        activityObservers[observerId] = (eventId, limit, handler)

        // 初回コールバック
        let eventActivities = Array((activities[eventId] ?? [])
            .sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
            .prefix(limit))
        handler(eventActivities)

        return observerId
    }

    func removeListener(_ listener: Any) {
        guard let observerId = listener as? String else { return }
        eventObservers.removeValue(forKey: observerId)
        singleEventObservers.removeValue(forKey: observerId)
        postObservers.removeValue(forKey: observerId)
        participantObservers.removeValue(forKey: observerId)
        activityObservers.removeValue(forKey: observerId)
    }

    // MARK: - Private Helpers

    private func notifyEventObservers() {
        for (_, (userId, handler)) in eventObservers {
            let userEvents = events.values
                .filter { !$0.isDeleted && $0.participantIds.contains(userId) }
                .sorted { $0.startDate > $1.startDate }
            handler(Array(userEvents))
        }
    }

    private func notifySingleEventObservers(eventId: String) {
        for (_, (observedEventId, handler)) in singleEventObservers {
            if observedEventId == eventId {
                handler(events[eventId])
            }
        }
    }

    private func notifyPostObservers(eventId: String) {
        for (_, (observedEventId, handler)) in postObservers {
            if observedEventId == eventId {
                let eventPosts = (posts[eventId] ?? [])
                    .filter { !$0.isDeleted }
                    .sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
                handler(eventPosts)
            }
        }
    }

    private func notifyParticipantObservers(eventId: String) {
        for (_, (observedEventId, handler)) in participantObservers {
            if observedEventId == eventId {
                let eventParticipants = (participants[eventId] ?? [])
                    .sorted { $0.role.rawValue < $1.role.rawValue }
                handler(eventParticipants)
            }
        }
    }

    private func notifyActivityObservers(eventId: String) {
        for (_, (observedEventId, limit, handler)) in activityObservers {
            if observedEventId == eventId {
                let eventActivities = Array((activities[eventId] ?? [])
                    .sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
                    .prefix(limit))
                handler(eventActivities)
            }
        }
    }
}
