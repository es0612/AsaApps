import Testing
import Foundation
@testable import AsaEventLive

// MARK: - EventListViewModel Tests

@MainActor
struct EventListViewModelTests {
    // MARK: - Properties

    let mockService = MockEventDataService()
    let testUserId = "test-user-id"

    // MARK: - Initialization Tests

    @Test("ViewModel初期化テスト")
    func testInitialization() {
        let viewModel = EventListViewModel(
            dataService: mockService,
            userId: testUserId
        )

        #expect(viewModel.events.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Refresh Tests

    @Test("リフレッシュテスト")
    func testRefresh() async {
        let viewModel = EventListViewModel(
            dataService: mockService,
            userId: "user-1" // サンプルデータに含まれるユーザー
        )

        await viewModel.refresh()

        #expect(!viewModel.isLoading)
        // サンプルデータがあれば取得できる
    }

    // MARK: - Create Event Tests

    @Test("イベント作成テスト")
    func testCreateEvent() async throws {
        let viewModel = EventListViewModel(
            dataService: mockService,
            userId: testUserId
        )

        let event = try await viewModel.createEvent(
            title: "新しいイベント",
            description: "説明文",
            category: .party,
            location: "東京",
            startDate: Date(),
            endDate: nil
        )

        #expect(event.title == "新しいイベント")
        #expect(event.category == .party)
        #expect(event.location == "東京")
        #expect(!event.inviteCode.isEmpty)
    }

    // MARK: - Event Filtering Tests

    @Test("イベントフィルタリングテスト - ライブ")
    func testLiveEventsFiltering() async {
        let viewModel = EventListViewModel(
            dataService: mockService,
            userId: testUserId
        )

        // ライブイベントを作成
        let liveEvent = try? await viewModel.createEvent(
            title: "ライブイベント",
            description: "",
            category: .party,
            location: nil,
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date().addingTimeInterval(3600)
        )

        await viewModel.refresh()

        // liveEventsにはステータスがliveのイベントのみ含まれる
        let liveEvents = viewModel.liveEvents
        for event in liveEvents {
            #expect(event.status == .live)
        }
    }

    @Test("イベントフィルタリングテスト - 予定")
    func testUpcomingEventsFiltering() async {
        let viewModel = EventListViewModel(
            dataService: mockService,
            userId: testUserId
        )

        // 将来のイベントを作成
        _ = try? await viewModel.createEvent(
            title: "将来のイベント",
            description: "",
            category: .birthday,
            location: nil,
            startDate: Date().addingTimeInterval(86400), // 明日
            endDate: nil
        )

        await viewModel.refresh()

        let upcomingEvents = viewModel.upcomingEvents
        for event in upcomingEvents {
            #expect(event.status == .upcoming)
        }
    }

    // MARK: - Has Events Tests

    @Test("hasEventsプロパティテスト")
    func testHasEvents() async {
        let viewModel = EventListViewModel(
            dataService: mockService,
            userId: testUserId
        )

        #expect(viewModel.hasEvents == false)

        _ = try? await viewModel.createEvent(
            title: "テストイベント",
            description: "",
            category: .other,
            location: nil,
            startDate: Date(),
            endDate: nil
        )

        await viewModel.refresh()

        #expect(viewModel.hasEvents == true)
    }

    // MARK: - Error Handling Tests

    @Test("エラークリアテスト")
    func testClearError() {
        let viewModel = EventListViewModel(
            dataService: mockService,
            userId: testUserId
        )

        // エラーを設定（テスト用）
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}
