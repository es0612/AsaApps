import Testing
import Foundation
@testable import AsaEventLive

// MARK: - Participant Tests

struct ParticipantTests {
    // MARK: - Initialization Tests

    @Test("参加者初期化テスト")
    func testParticipantInitialization() {
        let participant = Participant(
            eventId: "event-1",
            userId: "user-1",
            displayName: "テストユーザー"
        )

        #expect(participant.eventId == "event-1")
        #expect(participant.userId == "user-1")
        #expect(participant.displayName == "テストユーザー")
        #expect(participant.role == .participant)
        #expect(participant.onlineStatus == .offline)
    }

    // MARK: - Role Tests

    @Test("ロール表示名テスト")
    func testRoleDisplayNames() {
        #expect(ParticipantRole.host.displayName == "ホスト")
        #expect(ParticipantRole.coHost.displayName == "共同ホスト")
        #expect(ParticipantRole.participant.displayName == "参加者")
    }

    @Test("ロール管理権限テスト")
    func testRoleManagePermission() {
        #expect(ParticipantRole.host.canManageEvent == true)
        #expect(ParticipantRole.coHost.canManageEvent == true)
        #expect(ParticipantRole.participant.canManageEvent == false)
    }

    @Test("ロール投稿権限テスト")
    func testRolePostPermission() {
        #expect(ParticipantRole.host.canPost == true)
        #expect(ParticipantRole.coHost.canPost == true)
        #expect(ParticipantRole.participant.canPost == true)
    }

    // MARK: - Online Status Tests

    @Test("オンラインステータス色テスト")
    func testOnlineStatusColors() {
        #expect(OnlineStatus.online.color == "green")
        #expect(OnlineStatus.away.color == "yellow")
        #expect(OnlineStatus.offline.color == "gray")
    }

    // MARK: - Initials Tests

    @Test("イニシャル生成テスト - フルネーム")
    func testInitialsFullName() {
        let participant = Participant(
            eventId: "event-1",
            userId: "user-1",
            displayName: "山田 太郎"
        )

        #expect(participant.initials == "山太")
    }

    @Test("イニシャル生成テスト - 単語")
    func testInitialsSingleWord() {
        let participant = Participant(
            eventId: "event-1",
            userId: "user-1",
            displayName: "太郎"
        )

        #expect(participant.initials == "太郎")
    }

    // MARK: - Last Seen Tests

    @Test("最終確認テキストテスト - オンライン")
    func testLastSeenOnline() {
        let participant = Participant(
            eventId: "event-1",
            userId: "user-1",
            displayName: "ユーザー",
            onlineStatus: .online,
            lastSeenAt: Date()
        )

        #expect(participant.lastSeenText == "オンライン")
    }

    @Test("最終確認テキストテスト - オフライン")
    func testLastSeenOffline() {
        let participant = Participant(
            eventId: "event-1",
            userId: "user-1",
            displayName: "ユーザー",
            onlineStatus: .offline,
            lastSeenAt: Date().addingTimeInterval(-3600)
        )

        #expect(participant.lastSeenText.hasPrefix("最終:"))
    }

    // MARK: - Equatable Tests

    @Test("参加者等価性テスト")
    func testParticipantEquality() {
        let participant1 = Participant(
            id: "part-1",
            eventId: "event-1",
            userId: "user-1",
            displayName: "ユーザー1"
        )

        let participant2 = Participant(
            id: "part-1",
            eventId: "event-2",
            userId: "user-2",
            displayName: "ユーザー2"
        )

        let participant3 = Participant(
            id: "part-2",
            eventId: "event-1",
            userId: "user-1",
            displayName: "ユーザー1"
        )

        #expect(participant1 == participant2)
        #expect(participant1 != participant3)
    }

    // MARK: - Sample Data Tests

    @Test("サンプル参加者データ存在確認")
    func testSampleParticipantsExist() {
        #expect(!Participant.sampleParticipants.isEmpty)
        #expect(Participant.sampleParticipants.count >= 3)
    }
}
