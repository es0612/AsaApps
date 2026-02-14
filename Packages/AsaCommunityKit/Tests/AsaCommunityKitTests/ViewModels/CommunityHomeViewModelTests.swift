import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("CommunityHomeViewModel テスト")
struct CommunityHomeViewModelTests {

    @MainActor
    @Test("loadDashboard - コミュニティ情報を正しく取得する")
    func testLoadDashboard() {
        let mock = MockCommunityDataService()
        mock.community = Community(name: "朝日町内会", area: "千代田区")
        let vm = CommunityHomeViewModel(dataService: mock)

        vm.loadDashboard()

        #expect(vm.community?.name == "朝日町内会")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @MainActor
    @Test("loadDashboard - 未読投稿数を正しく計算する")
    func testLoadDashboardUnreadCount() {
        let mock = MockCommunityDataService()
        let readPost = CommunityPost(title: "既読", content: "")
        readPost.isRead = true
        let unreadPost1 = CommunityPost(title: "未読1", content: "")
        let unreadPost2 = CommunityPost(title: "未読2", content: "")
        mock.posts = [readPost, unreadPost1, unreadPost2]

        let vm = CommunityHomeViewModel(dataService: mock)
        vm.loadDashboard()

        #expect(vm.unreadPostCount == 2)
    }

    @MainActor
    @Test("loadDashboard - アクティブアラートをフィルタする")
    func testLoadDashboardActiveAlerts() {
        let mock = MockCommunityDataService()
        let activeAlert = SafetyReport(title: "不審者", alertLevel: .warning)
        let infoReport = SafetyReport(title: "お知らせ", alertLevel: .info)
        mock.safetyReports = [activeAlert, infoReport]

        let vm = CommunityHomeViewModel(dataService: mock)
        vm.loadDashboard()

        #expect(vm.activeAlerts.count == 1)
        #expect(vm.activeAlerts.first?.title == "不審者")
    }

    @MainActor
    @Test("loadDashboard - 今日のゴミ出しをフィルタする")
    func testLoadDashboardTodaysGarbage() {
        let mock = MockCommunityDataService()
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        let todaySchedule = GarbageSchedule(
            garbageType: .burnable, weekday: todayWeekday, weekOfMonth: 0
        )
        let otherSchedule = GarbageSchedule(
            garbageType: .recyclePET, weekday: (todayWeekday % 7) + 1, weekOfMonth: 0
        )
        mock.garbageSchedules = [todaySchedule, otherSchedule]

        let vm = CommunityHomeViewModel(dataService: mock)
        vm.loadDashboard()

        #expect(vm.todaysGarbage.count == 1)
        #expect(vm.todaysGarbage.first?.garbageType == .burnable)
    }

    @MainActor
    @Test("loadDashboard - エラー発生時にerrorMessageが設定される")
    func testLoadDashboardError() {
        let mock = MockCommunityDataService()
        mock.shouldThrow = true

        let vm = CommunityHomeViewModel(dataService: mock)
        vm.loadDashboard()

        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
    }

    @MainActor
    @Test("loadDashboard - 直近イベントを取得する")
    func testLoadDashboardUpcomingEvents() {
        let mock = MockCommunityDataService()
        let futureEvent = CommunityEvent(
            title: "来月のイベント", location: "公園",
            startDate: Date().addingTimeInterval(86400 * 7),
            endDate: Date().addingTimeInterval(86400 * 7 + 3600)
        )
        mock.events = [futureEvent]

        let vm = CommunityHomeViewModel(dataService: mock)
        vm.loadDashboard()

        #expect(vm.upcomingEvents.count == 1)
    }
}
