import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("CommunityEvent モデルテスト")
struct CommunityEventTests {

    @Test("初期化テスト - デフォルト値が正しく設定される")
    func testInitialization() {
        let start = Date()
        let end = start.addingTimeInterval(3600)
        let event = CommunityEvent(
            title: "花見大会",
            location: "公園",
            startDate: start,
            endDate: end,
            maxParticipants: 30
        )
        #expect(event.title == "花見大会")
        #expect(event.location == "公園")
        #expect(event.maxParticipants == 30)
        #expect(event.isRecurring == false)
    }

    @Test("attendeeCount - RSVPからの参加者数を正しく計算する")
    func testAttendeeCount() {
        let event = CommunityEvent(
            title: "テスト", location: "場所",
            startDate: Date(), endDate: Date().addingTimeInterval(3600)
        )
        #expect(event.attendeeCount == 0)

        let rsvpAttending = EventRSVP(status: .attending)
        let rsvpMaybe = EventRSVP(status: .maybe)
        let rsvpDeclined = EventRSVP(status: .declined)
        event.rsvps = [rsvpAttending, rsvpMaybe, rsvpDeclined]

        #expect(event.attendeeCount == 1)
    }

    @Test("remainingSlots - 残り枠数を正しく計算する")
    func testRemainingSlots() {
        let event = CommunityEvent(
            title: "テスト", location: "場所",
            startDate: Date(), endDate: Date().addingTimeInterval(3600),
            maxParticipants: 5
        )
        #expect(event.remainingSlots == 5)

        let rsvps = (0..<3).map { _ in EventRSVP(status: .attending) }
        event.rsvps = rsvps
        #expect(event.remainingSlots == 2)
    }

    @Test("remainingSlots - 上限なしの場合はnilを返す")
    func testRemainingSlotsUnlimited() {
        let event = CommunityEvent(
            title: "テスト", location: "場所",
            startDate: Date(), endDate: Date().addingTimeInterval(3600),
            maxParticipants: 0
        )
        #expect(event.remainingSlots == nil)
    }

    @Test("isPast - 終了したイベントを正しく判定する")
    func testIsPast() {
        let pastEvent = CommunityEvent(
            title: "過去", location: "場所",
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date().addingTimeInterval(-3600)
        )
        #expect(pastEvent.isPast == true)

        let futureEvent = CommunityEvent(
            title: "未来", location: "場所",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200)
        )
        #expect(futureEvent.isPast == false)
    }

    @Test("isToday - 本日開催のイベントを正しく判定する")
    func testIsToday() {
        let todayEvent = CommunityEvent(
            title: "今日", location: "場所",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )
        #expect(todayEvent.isToday == true)

        let tomorrowEvent = CommunityEvent(
            title: "明日", location: "場所",
            startDate: Date().addingTimeInterval(86400 * 2),
            endDate: Date().addingTimeInterval(86400 * 2 + 3600)
        )
        #expect(tomorrowEvent.isToday == false)
    }

    @Test("remainingSlots - 定員超過時は0を返す")
    func testRemainingSlotsOverflow() {
        let event = CommunityEvent(
            title: "テスト", location: "場所",
            startDate: Date(), endDate: Date().addingTimeInterval(3600),
            maxParticipants: 2
        )
        let rsvps = (0..<5).map { _ in EventRSVP(status: .attending) }
        event.rsvps = rsvps
        #expect(event.remainingSlots == 0)
    }
}
