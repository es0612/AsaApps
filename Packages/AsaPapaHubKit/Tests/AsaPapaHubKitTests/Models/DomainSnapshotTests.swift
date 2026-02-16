import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("DomainSnapshot テスト")
struct DomainSnapshotTests {
    @Test("初期値が正しい")
    func testDefaultValues() {
        let snapshot = DomainSnapshot()
        #expect(snapshot.score == 0)
        #expect(snapshot.summary == "")
        #expect(snapshot.domain == .morning)
        #expect(snapshot.trend == .stable)
        #expect(snapshot.detailJSON == nil)
    }

    @Test("domain computed property")
    func testDomainComputed() {
        let snapshot = DomainSnapshot(domainRawValue: "health")
        #expect(snapshot.domain == .health)
        snapshot.domain = .finance
        #expect(snapshot.domainRawValue == "finance")
    }

    @Test("trend computed property")
    func testTrendComputed() {
        let snapshot = DomainSnapshot(trendRawValue: "up")
        #expect(snapshot.trend == .up)
        snapshot.trend = .down
        #expect(snapshot.trendRawValue == "down")
    }

    @Test("不正なrawValueのフォールバック")
    func testInvalidRawValueFallback() {
        let snapshot = DomainSnapshot(domainRawValue: "invalid", trendRawValue: "invalid")
        #expect(snapshot.domain == .morning)
        #expect(snapshot.trend == .stable)
    }

    @Test("カスタム初期化")
    func testCustomInit() {
        let snapshot = DomainSnapshot(
            domainRawValue: "learning",
            score: 85,
            summary: "よく学習しています",
            trendRawValue: "up"
        )
        #expect(snapshot.domain == .learning)
        #expect(snapshot.score == 85)
        #expect(snapshot.summary == "よく学習しています")
        #expect(snapshot.trend == .up)
    }

    @Test("IDはユニーク")
    func testUniqueId() {
        let s1 = DomainSnapshot()
        let s2 = DomainSnapshot()
        #expect(s1.id != s2.id)
    }
}
