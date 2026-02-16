import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("HubDashboard テスト")
struct HubDashboardTests {
    @Test("初期値が正しい")
    func testDefaultValues() {
        let dashboard = HubDashboard()
        #expect(dashboard.morningScore == 0)
        #expect(dashboard.stepsCount == 0)
        #expect(dashboard.sleepHours == 0.0)
        #expect(dashboard.overallProgress == 0.0)
        #expect(dashboard.briefingSummary == nil)
        #expect(dashboard.moodRawValue == nil)
    }

    @Test("カスタム値で初期化")
    func testCustomInit() {
        let dashboard = HubDashboard(
            morningScore: 85,
            stepsCount: 8000,
            sleepHours: 7.5,
            overallProgress: 0.75
        )
        #expect(dashboard.morningScore == 85)
        #expect(dashboard.stepsCount == 8000)
        #expect(abs(dashboard.sleepHours - 7.5) < 0.0001)
        #expect(abs(dashboard.overallProgress - 0.75) < 0.0001)
    }

    @Test("activeDomains computed property - セット")
    func testActiveDomainsSet() {
        let dashboard = HubDashboard()
        dashboard.activeDomains = [.morning, .health, .learning]
        #expect(dashboard.activeDomainsRawValue.contains("morning"))
        #expect(dashboard.activeDomainsRawValue.contains("health"))
        #expect(dashboard.activeDomainsRawValue.contains("learning"))
    }

    @Test("activeDomains computed property - ゲット")
    func testActiveDomainsGet() {
        let dashboard = HubDashboard(activeDomainsRawValue: "morning,health,learning")
        let domains = dashboard.activeDomains
        #expect(domains.count == 3)
        #expect(domains.contains(.morning))
        #expect(domains.contains(.health))
        #expect(domains.contains(.learning))
    }

    @Test("activeDomains - 空文字列")
    func testActiveDomainsEmpty() {
        let dashboard = HubDashboard(activeDomainsRawValue: "")
        #expect(dashboard.activeDomains.isEmpty)
    }

    @Test("activeDomains - 不正な値はフィルタされる")
    func testActiveDomainsInvalidFiltered() {
        let dashboard = HubDashboard(activeDomainsRawValue: "morning,invalid,health")
        #expect(dashboard.activeDomains.count == 2)
    }

    @Test("briefingSummary の設定")
    func testBriefingSummary() {
        let dashboard = HubDashboard(briefingSummary: "今日も頑張りましょう")
        #expect(dashboard.briefingSummary == "今日も頑張りましょう")
    }

    @Test("IDはユニーク")
    func testUniqueId() {
        let d1 = HubDashboard()
        let d2 = HubDashboard()
        #expect(d1.id != d2.id)
    }
}
