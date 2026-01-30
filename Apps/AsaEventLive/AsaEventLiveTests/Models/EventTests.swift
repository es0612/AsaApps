import Testing
import Foundation
@testable import AsaEventLive

// MARK: - Event Tests

struct EventTests {
    // MARK: - Initialization Tests

    @Test("イベント初期化テスト")
    func testEventInitialization() {
        let event = Event(
            title: "テストイベント",
            startDate: Date(),
            hostId: "host-1",
            hostName: "テストホスト"
        )

        #expect(event.title == "テストイベント")
        #expect(event.hostId == "host-1")
        #expect(event.hostName == "テストホスト")
        #expect(event.participantIds.isEmpty)
        #expect(!event.isDeleted)
    }

    @Test("イベントカテゴリ表示名テスト")
    func testCategoryDisplayNames() {
        #expect(EventCategory.birthday.displayName == "誕生日")
        #expect(EventCategory.sports.displayName == "運動会・スポーツ")
        #expect(EventCategory.travel.displayName == "旅行")
        #expect(EventCategory.party.displayName == "パーティー")
        #expect(EventCategory.wedding.displayName == "結婚式")
        #expect(EventCategory.graduation.displayName == "卒業式")
        #expect(EventCategory.reunion.displayName == "同窓会")
        #expect(EventCategory.other.displayName == "その他")
    }

    @Test("イベントカテゴリアイコンテスト")
    func testCategoryIcons() {
        #expect(EventCategory.birthday.icon == "birthday.cake")
        #expect(EventCategory.sports.icon == "sportscourt")
        #expect(EventCategory.travel.icon == "airplane")
    }

    // MARK: - Status Tests

    @Test("イベントステータス - 開催前")
    func testUpcomingStatus() {
        let futureDate = Date().addingTimeInterval(3600) // 1時間後
        let event = Event(
            title: "未来のイベント",
            startDate: futureDate,
            hostId: "host-1",
            hostName: "ホスト"
        )

        #expect(event.status == .upcoming)
        #expect(event.status.displayName == "開催前")
    }

    @Test("イベントステータス - ライブ中")
    func testLiveStatus() {
        let pastDate = Date().addingTimeInterval(-3600) // 1時間前
        let futureEndDate = Date().addingTimeInterval(3600) // 1時間後
        let event = Event(
            title: "進行中のイベント",
            startDate: pastDate,
            endDate: futureEndDate,
            hostId: "host-1",
            hostName: "ホスト"
        )

        #expect(event.status == .live)
        #expect(event.status.displayName == "ライブ中")
    }

    @Test("イベントステータス - 終了")
    func testEndedStatus() {
        let pastDate = Date().addingTimeInterval(-7200) // 2時間前
        let pastEndDate = Date().addingTimeInterval(-3600) // 1時間前
        let event = Event(
            title: "終了したイベント",
            startDate: pastDate,
            endDate: pastEndDate,
            hostId: "host-1",
            hostName: "ホスト"
        )

        #expect(event.status == .ended)
        #expect(event.status.displayName == "終了")
    }

    // MARK: - Participant Count Tests

    @Test("参加者数カウントテスト")
    func testParticipantCount() {
        var event = Event(
            title: "テストイベント",
            startDate: Date(),
            hostId: "host-1",
            hostName: "ホスト",
            participantIds: ["user-1", "user-2", "user-3"]
        )

        #expect(event.participantCount == 3)

        event.participantIds.append("user-4")
        #expect(event.participantCount == 4)
    }

    // MARK: - Equatable Tests

    @Test("イベント等価性テスト")
    func testEventEquality() {
        let event1 = Event(
            id: "event-1",
            title: "イベント1",
            startDate: Date(),
            hostId: "host-1",
            hostName: "ホスト"
        )

        let event2 = Event(
            id: "event-1",
            title: "別のタイトル", // タイトルは異なる
            startDate: Date().addingTimeInterval(3600),
            hostId: "host-2",
            hostName: "別のホスト"
        )

        let event3 = Event(
            id: "event-2", // IDが異なる
            title: "イベント1",
            startDate: Date(),
            hostId: "host-1",
            hostName: "ホスト"
        )

        #expect(event1 == event2) // IDが同じなので等価
        #expect(event1 != event3) // IDが異なるので不等価
    }

    // MARK: - Sample Data Tests

    @Test("サンプルデータ存在確認")
    func testSampleDataExists() {
        #expect(!Event.sampleEvents.isEmpty)
        #expect(Event.sampleEvents.count >= 3)
    }
}
