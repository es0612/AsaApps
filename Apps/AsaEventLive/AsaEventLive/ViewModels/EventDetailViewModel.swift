import Foundation
import SwiftUI

// MARK: - EventDetailTab

enum EventDetailTab: String, CaseIterable {
    case timeline = "タイムライン"
    case participants = "参加者"
    case activity = "アクティビティ"

    var icon: String {
        switch self {
        case .timeline: return "bubble.left.and.bubble.right"
        case .participants: return "person.3"
        case .activity: return "clock"
        }
    }
}

// MARK: - EventDetailViewModel

@Observable
@MainActor
final class EventDetailViewModel {
    // MARK: - Properties

    private(set) var event: Event
    private(set) var posts: [EventPost] = []
    private(set) var participants: [Participant] = []
    private(set) var activities: [Activity] = []

    private(set) var isLoading: Bool = false
    var errorMessage: String?

    var selectedTab: EventDetailTab = .timeline

    private let dataService: any EventDataServiceProtocol
    private let userId: String

    private var eventListener: Any?
    private var postsListener: Any?
    private var participantsListener: Any?
    private var activitiesListener: Any?

    // MARK: - Computed Properties

    var isHost: Bool {
        event.hostId == userId
    }

    var isCoHost: Bool {
        event.coHostIds.contains(userId)
    }

    var canManage: Bool {
        isHost || isCoHost
    }

    var currentParticipant: Participant? {
        participants.first { $0.userId == userId }
    }

    var onlineCount: Int {
        participants.filter { $0.onlineStatus == .online }.count
    }

    var pinnedPosts: [EventPost] {
        posts.filter { $0.isPinned }
    }

    var regularPosts: [EventPost] {
        posts.filter { !$0.isPinned }
    }

    // MARK: - Initialization

    init(event: Event, userId: String, dataService: any EventDataServiceProtocol) {
        self.event = event
        self.userId = userId
        self.dataService = dataService
    }

    // Note: ViewのonDisappearでstopObserving()を呼び出してリスナーを解除する
    // deinitからはMainActor隔離メソッドにアクセスできないため、明示的な解除が必要

    // MARK: - Public Methods

    func startObserving() {
        // イベント監視
        eventListener = dataService.observeEvent(eventId: event.id) { [weak self] updatedEvent in
            Task { @MainActor [weak self] in
                if let event = updatedEvent {
                    self?.event = event
                }
            }
        }

        // 投稿監視
        postsListener = dataService.observePosts(eventId: event.id) { [weak self] posts in
            Task { @MainActor [weak self] in
                self?.posts = posts
            }
        }

        // 参加者監視
        participantsListener = dataService.observeParticipants(eventId: event.id) { [weak self] participants in
            Task { @MainActor [weak self] in
                self?.participants = participants
            }
        }

        // アクティビティ監視
        activitiesListener = dataService.observeActivities(eventId: event.id, limit: 50) { [weak self] activities in
            Task { @MainActor [weak self] in
                self?.activities = activities
            }
        }

        // オンライン状態を更新
        updateOnlineStatus(.online)
    }

    func stopObserving() {
        if let listener = eventListener {
            dataService.removeListener(listener)
            eventListener = nil
        }
        if let listener = postsListener {
            dataService.removeListener(listener)
            postsListener = nil
        }
        if let listener = participantsListener {
            dataService.removeListener(listener)
            participantsListener = nil
        }
        if let listener = activitiesListener {
            dataService.removeListener(listener)
            activitiesListener = nil
        }

        // オフラインに更新
        updateOnlineStatus(.offline)
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            async let fetchedEvent = dataService.fetchEvent(id: event.id)
            async let fetchedPosts = dataService.fetchPosts(eventId: event.id)
            async let fetchedParticipants = dataService.fetchParticipants(eventId: event.id)
            async let fetchedActivities = dataService.fetchActivities(eventId: event.id, limit: 50)

            let (eventResult, postsResult, participantsResult, activitiesResult) = await (
                try fetchedEvent,
                try fetchedPosts,
                try fetchedParticipants,
                try fetchedActivities
            )

            if let e = eventResult {
                event = e
            }
            posts = postsResult
            participants = participantsResult
            activities = activitiesResult

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Post Actions

    func createPost(content: String, type: EventPostType = .text) async throws {
        guard let participant = currentParticipant else {
            throw EventDataError.notParticipant
        }

        let post = EventPost(
            eventId: event.id,
            authorId: userId,
            authorName: participant.displayName,
            authorPhotoURL: participant.photoURL,
            type: type,
            content: content
        )

        _ = try await dataService.createPost(post)
    }

    func toggleLike(on post: EventPost) async {
        do {
            try await dataService.toggleLike(
                postId: post.id,
                eventId: event.id,
                userId: userId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deletePost(_ post: EventPost) async throws {
        guard post.authorId == userId || canManage else {
            throw EventDataError.permissionDenied
        }

        try await dataService.deletePost(post.id, eventId: event.id)
    }

    func togglePin(on post: EventPost) async throws {
        guard canManage else {
            throw EventDataError.permissionDenied
        }

        var updatedPost = post
        updatedPost.isPinned.toggle()
        try await dataService.updatePost(updatedPost)
    }

    // MARK: - Participant Actions

    func updateRole(for participant: Participant, to role: ParticipantRole) async throws {
        guard isHost else {
            throw EventDataError.permissionDenied
        }

        var updatedParticipant = participant
        updatedParticipant.role = role

        try await dataService.updateParticipant(updatedParticipant)

        // 共同ホストリストを更新
        var updatedEvent = event
        if role == .coHost && !updatedEvent.coHostIds.contains(participant.userId) {
            updatedEvent.coHostIds.append(participant.userId)
        } else if role != .coHost {
            updatedEvent.coHostIds.removeAll { $0 == participant.userId }
        }
        try await dataService.updateEvent(updatedEvent)
    }

    func leaveEvent() async throws {
        try await dataService.leaveEvent(eventId: event.id, userId: userId)
    }

    // MARK: - Private Methods

    private func updateOnlineStatus(_ status: OnlineStatus) {
        Task {
            try? await dataService.updateOnlineStatus(
                eventId: event.id,
                userId: userId,
                status: status
            )
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
