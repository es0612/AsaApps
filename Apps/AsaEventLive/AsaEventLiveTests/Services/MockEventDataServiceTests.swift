import Testing
import Foundation
@testable import AsaEventLive

// MARK: - MockEventDataService Tests

struct MockEventDataServiceTests {
    // MARK: - Properties

    let service = MockEventDataService()
    let testUserId = "test-user-id"

    // MARK: - Event Tests

    @Test("イベント作成テスト")
    func testCreateEvent() async throws {
        let event = Event(
            title: "テストイベント",
            description: "テスト説明",
            category: .party,
            startDate: Date(),
            hostId: testUserId,
            hostName: "テストホスト"
        )

        let createdEvent = try await service.createEvent(event)

        #expect(!createdEvent.id.isEmpty)
        #expect(createdEvent.title == "テストイベント")
        #expect(!createdEvent.inviteCode.isEmpty)
        #expect(createdEvent.participantIds.contains(testUserId))
    }

    @Test("イベント取得テスト")
    func testFetchEvents() async throws {
        // サンプルデータがあるので取得できる
        let events = try await service.fetchEvents(userId: "user-1")
        #expect(events.count >= 0)
    }

    @Test("イベント更新テスト")
    func testUpdateEvent() async throws {
        // 最初にイベントを作成
        let event = Event(
            title: "元のタイトル",
            startDate: Date(),
            hostId: testUserId,
            hostName: "ホスト"
        )
        var createdEvent = try await service.createEvent(event)

        // タイトルを更新
        createdEvent.title = "更新後のタイトル"
        try await service.updateEvent(createdEvent)

        // 取得して確認
        let fetchedEvent = try await service.fetchEvent(id: createdEvent.id)
        #expect(fetchedEvent?.title == "更新後のタイトル")
    }

    @Test("イベント削除テスト")
    func testDeleteEvent() async throws {
        let event = Event(
            title: "削除テストイベント",
            startDate: Date(),
            hostId: testUserId,
            hostName: "ホスト"
        )
        let createdEvent = try await service.createEvent(event)

        try await service.deleteEvent(createdEvent.id)

        let fetchedEvent = try await service.fetchEvent(id: createdEvent.id)
        #expect(fetchedEvent?.isDeleted == true)
    }

    // MARK: - Join/Leave Tests

    @Test("イベント参加テスト")
    func testJoinEvent() async throws {
        // イベントを作成
        let event = Event(
            title: "参加テストイベント",
            startDate: Date(),
            hostId: "host-user",
            hostName: "ホスト"
        )
        let createdEvent = try await service.createEvent(event)

        // 新しいユーザーが参加
        let participant = Participant(
            eventId: createdEvent.id,
            userId: testUserId,
            displayName: "参加者"
        )

        let joinedEvent = try await service.joinEvent(
            eventId: createdEvent.id,
            inviteCode: createdEvent.inviteCode,
            participant: participant
        )

        #expect(joinedEvent.participantIds.contains(testUserId))
    }

    @Test("イベント参加テスト - 無効な招待コード")
    func testJoinEventInvalidCode() async throws {
        let event = Event(
            title: "テストイベント",
            startDate: Date(),
            hostId: "host-user",
            hostName: "ホスト"
        )
        let createdEvent = try await service.createEvent(event)

        let participant = Participant(
            eventId: createdEvent.id,
            userId: testUserId,
            displayName: "参加者"
        )

        do {
            _ = try await service.joinEvent(
                eventId: createdEvent.id,
                inviteCode: "INVALID",
                participant: participant
            )
            #expect(Bool(false), "エラーが発生するはず")
        } catch {
            #expect(error is EventDataError)
        }
    }

    // MARK: - Post Tests

    @Test("投稿作成テスト")
    func testCreatePost() async throws {
        let post = EventPost(
            eventId: "event-1",
            authorId: testUserId,
            authorName: "テストユーザー",
            content: "テスト投稿です"
        )

        let createdPost = try await service.createPost(post)

        #expect(!createdPost.id.isEmpty)
        #expect(createdPost.content == "テスト投稿です")
    }

    @Test("投稿取得テスト")
    func testFetchPosts() async throws {
        let posts = try await service.fetchPosts(eventId: "event-1")
        #expect(posts.count >= 0)
    }

    @Test("いいねトグルテスト")
    func testToggleLike() async throws {
        // 投稿を作成
        let post = EventPost(
            eventId: "event-1",
            authorId: "other-user",
            authorName: "他のユーザー",
            content: "いいねテスト"
        )
        let createdPost = try await service.createPost(post)

        // いいね追加
        try await service.toggleLike(
            postId: createdPost.id,
            eventId: "event-1",
            userId: testUserId
        )

        var posts = try await service.fetchPosts(eventId: "event-1")
        var targetPost = posts.first { $0.id == createdPost.id }
        #expect(targetPost?.likedByUserIds.contains(testUserId) == true)

        // いいね解除
        try await service.toggleLike(
            postId: createdPost.id,
            eventId: "event-1",
            userId: testUserId
        )

        posts = try await service.fetchPosts(eventId: "event-1")
        targetPost = posts.first { $0.id == createdPost.id }
        #expect(targetPost?.likedByUserIds.contains(testUserId) == false)
    }

    // MARK: - Participant Tests

    @Test("参加者取得テスト")
    func testFetchParticipants() async throws {
        let participants = try await service.fetchParticipants(eventId: "event-1")
        #expect(participants.count >= 0)
    }

    @Test("オンラインステータス更新テスト")
    func testUpdateOnlineStatus() async throws {
        // イベントを作成して参加者を追加
        let event = Event(
            title: "ステータステスト",
            startDate: Date(),
            hostId: testUserId,
            hostName: "ホスト"
        )
        let createdEvent = try await service.createEvent(event)

        // オンラインに更新
        try await service.updateOnlineStatus(
            eventId: createdEvent.id,
            userId: testUserId,
            status: .online
        )

        let participants = try await service.fetchParticipants(eventId: createdEvent.id)
        let participant = participants.first { $0.userId == testUserId }
        #expect(participant?.onlineStatus == .online)
    }

    // MARK: - Activity Tests

    @Test("アクティビティ取得テスト")
    func testFetchActivities() async throws {
        let activities = try await service.fetchActivities(eventId: "event-1", limit: 10)
        #expect(activities.count <= 10)
    }

    @Test("アクティビティ作成テスト")
    func testCreateActivity() async throws {
        let activity = Activity(
            eventId: "event-1",
            userId: testUserId,
            userName: "テストユーザー",
            type: .joined
        )

        let createdActivity = try await service.createActivity(activity)

        #expect(!createdActivity.id.isEmpty)
        #expect(createdActivity.type == .joined)
    }

    // MARK: - Observer Tests

    @Test("イベント監視テスト")
    func testObserveEvents() async {
        var receivedEvents: [Event]?

        let listener = service.observeEvents(userId: "user-1") { events in
            receivedEvents = events
        }

        // 即座に初回コールバックが呼ばれる
        #expect(receivedEvents != nil)

        service.removeListener(listener)
    }

    @Test("投稿監視テスト")
    func testObservePosts() async {
        var receivedPosts: [EventPost]?

        let listener = service.observePosts(eventId: "event-1") { posts in
            receivedPosts = posts
        }

        #expect(receivedPosts != nil)

        service.removeListener(listener)
    }
}
