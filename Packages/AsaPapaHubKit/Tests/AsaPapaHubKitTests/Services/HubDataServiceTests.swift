import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("HubDataService テスト")
struct HubDataServiceTests {
    // MockHubDataService を使用してプロトコル準拠をテスト

    @Test("ダッシュボード保存と取得")
    @MainActor func testSaveAndFetchDashboard() async throws {
        let service = MockHubDataService()
        let dashboard = HubDashboard(morningScore: 80, stepsCount: 5000)
        try await service.saveDashboard(dashboard)
        let fetched = try await service.fetchDashboard(for: Date())
        #expect(fetched != nil)
        #expect(fetched?.morningScore == 80)
    }

    @Test("ダッシュボード範囲取得")
    @MainActor func testFetchDashboardsRange() async throws {
        let service = MockHubDataService()
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let d1 = HubDashboard(date: today, morningScore: 80)
        let d2 = HubDashboard(date: yesterday, morningScore: 60)
        try await service.saveDashboard(d1)
        try await service.saveDashboard(d2)
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        let results = try await service.fetchDashboards(from: twoDaysAgo, to: today)
        #expect(results.count == 2)
    }

    @Test("設定の取得 - デフォルト生成")
    @MainActor func testFetchPreferencesDefault() async throws {
        let service = MockHubDataService()
        let prefs = try await service.fetchPreferences()
        #expect(prefs.stepsGoal == 10000)
    }

    @Test("設定の保存")
    @MainActor func testSavePreferences() async throws {
        let service = MockHubDataService()
        let prefs = HubUserPreferences(stepsGoal: 15000)
        service.preferences = prefs
        try await service.savePreferences(prefs)
        let fetched = try await service.fetchPreferences()
        #expect(fetched.stepsGoal == 15000)
    }

    @Test("スナップショット保存と取得")
    @MainActor func testSaveAndFetchSnapshot() async throws {
        let service = MockHubDataService()
        let snapshot = DomainSnapshot(domainRawValue: "health", score: 75)
        try await service.saveSnapshot(snapshot)
        let results = try await service.fetchSnapshots(for: Date())
        #expect(results.count == 1)
        #expect(results.first?.score == 75)
    }

    @Test("ブリーフィング保存と取得")
    @MainActor func testSaveAndFetchBriefing() async throws {
        let service = MockHubDataService()
        let briefing = DailyBriefing(greeting: "おはよう")
        try await service.saveBriefing(briefing)
        let fetched = try await service.fetchBriefing(for: Date())
        #expect(fetched?.greeting == "おはよう")
    }

    @Test("週次サマリー保存と取得")
    @MainActor func testSaveAndFetchWeeklySummary() async throws {
        let service = MockHubDataService()
        let summary = WeeklySummary(weekStartDate: Date(), summaryText: "良い週でした")
        try await service.saveWeeklySummary(summary)
        let fetched = try await service.fetchWeeklySummary(for: Date())
        #expect(fetched?.summaryText == "良い週でした")
    }

    @Test("クイックアクション保存と取得")
    @MainActor func testSaveAndFetchQuickAction() async throws {
        let service = MockHubDataService()
        let action = QuickAction(title: "瞑想開始", iconName: "brain.head.profile")
        try await service.saveQuickAction(action)
        let results = try await service.fetchQuickActions()
        #expect(results.count == 1)
        #expect(results.first?.title == "瞑想開始")
    }

    @Test("エラー発生時のダッシュボード取得")
    @MainActor func testFetchDashboardError() async {
        let service = MockHubDataService()
        service.shouldThrowError = true
        do {
            _ = try await service.fetchDashboard(for: Date())
            #expect(Bool(false), "エラーが発生するべき")
        } catch {
            #expect(error is PapaHubError)
        }
    }

    @Test("エラー発生時の保存")
    @MainActor func testSaveError() async {
        let service = MockHubDataService()
        service.shouldThrowError = true
        do {
            try await service.saveDashboard(HubDashboard())
            #expect(Bool(false), "エラーが発生するべき")
        } catch {
            #expect(error is PapaHubError)
        }
    }

    @Test("存在しない日付のダッシュボード")
    @MainActor func testFetchDashboardNotFound() async throws {
        let service = MockHubDataService()
        let farFuture = Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        let result = try await service.fetchDashboard(for: farFuture)
        #expect(result == nil)
    }

    @Test("空のスナップショットリスト")
    @MainActor func testFetchEmptySnapshots() async throws {
        let service = MockHubDataService()
        let results = try await service.fetchSnapshots(for: Date())
        #expect(results.isEmpty)
    }

    @Test("ブリーフィングが存在しない場合")
    @MainActor func testFetchBriefingNotFound() async throws {
        let service = MockHubDataService()
        let farFuture = Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        let result = try await service.fetchBriefing(for: farFuture)
        #expect(result == nil)
    }

    @Test("週次サマリーが存在しない場合")
    @MainActor func testFetchWeeklySummaryNotFound() async throws {
        let service = MockHubDataService()
        let farFuture = Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        let result = try await service.fetchWeeklySummary(for: farFuture)
        #expect(result == nil)
    }

    @Test("空のクイックアクションリスト")
    @MainActor func testFetchEmptyQuickActions() async throws {
        let service = MockHubDataService()
        let results = try await service.fetchQuickActions()
        #expect(results.isEmpty)
    }
}
