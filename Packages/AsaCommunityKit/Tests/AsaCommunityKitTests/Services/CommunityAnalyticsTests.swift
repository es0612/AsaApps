import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("CommunityAnalytics テスト")
struct CommunityAnalyticsTests {

    @Test("postCountByCategory - カテゴリ別の投稿数を正しく集計する")
    func testPostCountByCategory() {
        let posts = [
            CommunityPost(title: "イベント1", content: "", category: .event),
            CommunityPost(title: "イベント2", content: "", category: .event),
            CommunityPost(title: "質問1", content: "", category: .question),
            CommunityPost(title: "一般1", content: "", category: .general),
        ]

        let result = CommunityAnalytics.postCountByCategory(posts: posts)
        let eventCount = result.first(where: { $0.category == .event })?.count
        let questionCount = result.first(where: { $0.category == .question })?.count
        let generalCount = result.first(where: { $0.category == .general })?.count

        #expect(eventCount == 2)
        #expect(questionCount == 1)
        #expect(generalCount == 1)
    }

    @Test("postCountByCategory - 空の配列は空を返す")
    func testPostCountByCategoryEmpty() {
        let result = CommunityAnalytics.postCountByCategory(posts: [])
        #expect(result.isEmpty)
    }

    @Test("postCountByCategory - 0件のカテゴリは除外される")
    func testPostCountByCategoryExcludesZero() {
        let posts = [
            CommunityPost(title: "イベント", content: "", category: .event),
        ]
        let result = CommunityAnalytics.postCountByCategory(posts: posts)
        // event のみ含まれるはず
        #expect(result.count == 1)
        #expect(result.first?.category == .event)
    }

    @Test("eventAttendanceRate - イベント参加率を正しく計算する")
    func testEventAttendanceRate() {
        let event1 = CommunityEvent(
            title: "イベント1", location: "場所",
            startDate: Date(), endDate: Date().addingTimeInterval(3600),
            maxParticipants: 10
        )
        event1.rsvps = (0..<5).map { _ in EventRSVP(status: .attending) }

        let event2 = CommunityEvent(
            title: "イベント2", location: "場所",
            startDate: Date(), endDate: Date().addingTimeInterval(3600),
            maxParticipants: 20
        )
        event2.rsvps = (0..<10).map { _ in EventRSVP(status: .attending) }

        let rate = CommunityAnalytics.eventAttendanceRate(events: [event1, event2])
        // (5/10 + 10/20) / 2 = (0.5 + 0.5) / 2 = 0.5
        #expect(abs(rate - 0.5) < 0.0001)
    }

    @Test("eventAttendanceRate - 定員なしイベントは除外される")
    func testEventAttendanceRateExcludesUnlimited() {
        let unlimitedEvent = CommunityEvent(
            title: "定員なし", location: "場所",
            startDate: Date(), endDate: Date().addingTimeInterval(3600),
            maxParticipants: 0
        )

        let limitedEvent = CommunityEvent(
            title: "定員あり", location: "場所",
            startDate: Date(), endDate: Date().addingTimeInterval(3600),
            maxParticipants: 10
        )
        limitedEvent.rsvps = (0..<8).map { _ in EventRSVP(status: .attending) }

        let rate = CommunityAnalytics.eventAttendanceRate(events: [unlimitedEvent, limitedEvent])
        // 定員なしイベントは除外: 8/10 = 0.8
        #expect(abs(rate - 0.8) < 0.0001)
    }

    @Test("eventAttendanceRate - 空のイベントは0.0を返す")
    func testEventAttendanceRateEmpty() {
        let rate = CommunityAnalytics.eventAttendanceRate(events: [])
        #expect(rate == 0.0)
    }

    @Test("safetyReportsByLevel - 警戒レベル別の集計が正しい")
    func testSafetyReportsByLevel() {
        let reports = [
            SafetyReport(title: "情報1", alertLevel: .info),
            SafetyReport(title: "警告1", alertLevel: .warning),
            SafetyReport(title: "警告2", alertLevel: .warning),
            SafetyReport(title: "緊急1", alertLevel: .emergency),
        ]

        let result = CommunityAnalytics.safetyReportsByLevel(reports: reports)
        let infoCount = result.first(where: { $0.level == .info })?.count
        let warningCount = result.first(where: { $0.level == .warning })?.count
        let emergencyCount = result.first(where: { $0.level == .emergency })?.count

        #expect(infoCount == 1)
        #expect(warningCount == 2)
        #expect(emergencyCount == 1)
    }
}
